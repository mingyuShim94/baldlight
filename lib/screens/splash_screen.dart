import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admob_service.dart';
import '../services/app_lifecycle_service.dart';
import '../main.dart';

/// 앱 시작 시 표시되는 스플래시 화면
///
/// 이 화면은 다음 순서로 동작합니다:
/// 1. 스플래시 화면 표시 (로고/브랜딩)
/// 2. 광고 로드 및 표시
/// 3. 메인 화면으로 이동
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final AdMobService _adMobService = AdMobService();
  final AppLifecycleService _lifecycleService = AppLifecycleService();

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoadingAds = false;
  String _statusText = 'Starting BaldLight...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// 애니메이션 컨트롤러 초기화
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  /// 스플래시 시퀀스 시작
  Future<void> _startSplashSequence() async {
    try {
      // 1. 애니메이션 시작
      _fadeController.forward();
      _scaleController.forward();

      // 2. 최소 스플래시 시간 보장 (1.5초)
      await Future.delayed(const Duration(milliseconds: 1500));

      // 3. 광고 초기화 및 로드
      await _initializeAndShowAds();
    } catch (e) {
      debugPrint('스플래시 시퀀스 오류: $e');
      // 오류 발생 시에도 메인 화면으로 이동
      _navigateToMain();
    }
  }

  /// 광고 초기화 및 표시
  Future<void> _initializeAndShowAds() async {
    setState(() {
      _isLoadingAds = true;
      _statusText = 'Loading ads...';
    });

    debugPrint('=== 광고 초기화 시작 ===');

    // 광고를 표시해야 하는지 확인
    final shouldShow = _lifecycleService.shouldShowAd();
    debugPrint('광고 표시 조건 확인: $shouldShow');
    debugPrint('첫 번째 실행: ${_lifecycleService.isFirstLaunch}');
    debugPrint('초기 광고 표시됨: ${_lifecycleService.hasShownInitialAd}');

    if (!shouldShow) {
      debugPrint('광고 표시 조건 미충족, 메인 화면으로 이동');
      _navigateToMain();
      return;
    }

    try {
      // 동의 상태 확인
      debugPrint('동의 상태 확인 중...');
      final hasConsent = await _adMobService.checkConsentStatus();
      debugPrint('동의 상태: $hasConsent');

      if (!hasConsent) {
        debugPrint('광고 동의 없음, 메인 화면으로 이동');
        _lifecycleService.markInitialAdShown();
        _navigateToMain();
        return;
      }

      // AdMob 초기화 (포그라운드 감지 비활성화)
      debugPrint('AdMob 초기화 중...');
      await _adMobService.initialize(enableForegroundDetection: false);
      debugPrint('AdMob 초기화 완료');

      setState(() {
        _statusText = 'Preparing ads...';
      });

      // 앱 오프닝 광고 로드
      debugPrint('앱 오프닝 광고 로드 시작...');
      await _adMobService.loadAppOpenAd();
      debugPrint('앱 오프닝 광고 로드 요청 완료');

      // 광고 로드 완료 대기 (최대 5초로 증가)
      debugPrint('광고 로드 대기 중...');
      await _waitForAdLoad();

      final isAvailable = _adMobService.isAdAvailable;
      debugPrint('광고 사용 가능 여부: $isAvailable');

      if (!isAvailable) {
        debugPrint('광고가 로드되지 않음, 메인 화면으로 이동');
        _lifecycleService.markInitialAdShown();
        _navigateToMain();
        return;
      }

      // 짧은 지연 후 광고 표시 (UI 안정화)
      await Future.delayed(const Duration(milliseconds: 300));

      // 광고 표시
      debugPrint('앱 오프닝 광고 표시 시도...');
      final adShown = await _adMobService.showAppOpenAd();
      debugPrint('광고 표시 결과: $adShown');

      if (adShown) {
        debugPrint('앱 오프닝 광고 표시 성공, 광고 닫힘 대기 중...');
        // 광고가 닫힐 때까지 대기
        await _waitForAdDismissal();
        debugPrint('광고 닫힘 확인됨');
      } else {
        debugPrint('앱 오프닝 광고 표시 실패');
      }

      _lifecycleService.markInitialAdShown();
      debugPrint('메인 화면으로 이동');
      _navigateToMain();
    } catch (e) {
      debugPrint('광고 초기화 실패: $e');
      _lifecycleService.markInitialAdShown();
      _navigateToMain();
    }
  }

  /// 광고 로드 완료 대기
  Future<void> _waitForAdLoad() async {
    const maxWaitTime = Duration(seconds: 5);
    const checkInterval = Duration(milliseconds: 200);

    final stopwatch = Stopwatch()..start();

    while (!_adMobService.isAdAvailable && stopwatch.elapsed < maxWaitTime) {
      debugPrint('광고 로드 확인 중... 경과 시간: ${stopwatch.elapsedMilliseconds}ms');
      await Future.delayed(checkInterval);
    }

    stopwatch.stop();
    debugPrint(
        '광고 로드 대기 완료. 시간: ${stopwatch.elapsedMilliseconds}ms, 사용 가능: ${_adMobService.isAdAvailable}');
  }

  /// 광고 닫힘 대기
  Future<void> _waitForAdDismissal() async {
    // 광고가 표시되는 동안 대기
    while (_adMobService.isShowingAd) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    debugPrint('광고 닫힘 감지됨');
  }

  /// 메인 화면으로 이동
  void _navigateToMain() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FlashlightMainPage(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 영역
              Expanded(
                flex: 3,
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 앱 아이콘 또는 로고
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.orange,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.flashlight_on,
                              size: 60,
                              color: Colors.orange,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 앱 이름
                          const Text(
                            'BaldLight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 앱 태그라인
                          Text(
                            'Smart Bald Flashlight',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 로딩 상태 영역
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로딩 인디케이터
                    if (_isLoadingAds) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 상태 텍스트
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
