import 'dart:async';
import 'package:flutter/material.dart';
import 'services/flashlight_service.dart';
import 'services/admob_service.dart';
import 'services/bald_style_service.dart';
import 'services/counting_service.dart';
import 'screens/collection_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaldLight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const FlashlightMainPage(),
    );
  }
}

/// 대머리 손전등 앱의 메인 화면
///
/// 이 페이지는 다음 기능을 제공합니다:
/// - 전체 화면 대머리 이미지 표시
/// - 이미지 위에 배치된 손전등 토글 버튼
/// - 직관적인 손전등 제어
class FlashlightMainPage extends StatefulWidget {
  const FlashlightMainPage({super.key});

  @override
  State<FlashlightMainPage> createState() => _FlashlightMainPageState();
}

class _FlashlightMainPageState extends State<FlashlightMainPage>
    with TickerProviderStateMixin {
  final FlashlightService _flashlightService = FlashlightService();
  final BaldStyleService _baldStyleService = BaldStyleService();
  final CountingService _countingService = CountingService();
  final AdMobService _adMobService = AdMobService();

  bool _isLoading = false;
  bool? _isFlashlightSupported;
  late AnimationController _scaleController;
  late AnimationController _countAnimationController;

  int _currentCount = 0;
  bool _isRewardedAdLoading = false;
  bool _hasShownInterstitialAd = false;
  Timer? _interstitialAdTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  /// 서비스들을 초기화합니다
  Future<void> _initializeServices() async {
    await _baldStyleService.initialize();
    await _countingService.initialize();
    await _adMobService.initialize(); // AdMob 초기화 (자동으로 첫 광고 로드)
    await _checkFlashlightSupport();

    // 현재 카운트 상태 반영
    setState(() {
      _currentCount = _countingService.currentCount;
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _countAnimationController.dispose();
    _interstitialAdTimer?.cancel();
    _flashlightService.dispose();
    _baldStyleService.dispose();
    _countingService.dispose();
    _adMobService.dispose();
    super.dispose();
  }

  /// 애니메이션 컨트롤러 초기화
  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _countAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  /// 기기의 플래시라이트 지원 여부를 확인합니다
  Future<void> _checkFlashlightSupport() async {
    try {
      final isSupported = await _flashlightService.isFlashlightAvailable();
      setState(() {
        _isFlashlightSupported = isSupported;
      });
    } catch (e) {
      setState(() {
        _isFlashlightSupported = false;
      });
    }
  }

  /// 플래시라이트 상태를 토글합니다 (켜기/끄기)
  Future<void> _toggleFlashlight() async {
    if (_isFlashlightSupported != true) {
      _showErrorDialog('Flashlight is not supported on this device.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 버튼 누름 애니메이션 실행
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    try {
      await _flashlightService.toggleFlashlight();
      
      // 첫 번째로 손전등을 켰을 때 5초 후 전면 광고 표시
      if (_flashlightService.isFlashlightOn && !_hasShownInterstitialAd) {
        _scheduleInterstitialAd();
      }
      
      setState(() {
        _isLoading = false;
      });
    } on FlashlightNotSupportedException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.message);
    } on FlashlightInUseException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.message);
    } on FlashlightException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.message);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An unknown error occurred: $e');
    }
  }

  /// 에러 메시지를 다이얼로그로 표시합니다
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 카운트 증가 처리
  Future<void> _incrementCount() async {
    try {
      final newlyUnlocked = await _countingService.incrementCount();

      setState(() {
        _currentCount = _countingService.currentCount;
      });

      // 카운트 증가 애니메이션
      _countAnimationController.forward().then((_) {
        _countAnimationController.reverse();
      });

      // 새로 해금된 스타일이 있다면 알림 표시
      if (newlyUnlocked.isNotEmpty) {
        _showUnlockDialog(newlyUnlocked);
      }
    } catch (e) {
      _showErrorDialog('An error occurred while increasing count: $e');
    }
  }

  /// 보상형 광고 시청
  Future<void> _watchRewardedAd() async {
    if (_isRewardedAdLoading) return;

    setState(() {
      _isRewardedAdLoading = true;
    });

    try {
      if (!_adMobService.isRewardedAdAvailable) {
        _showErrorDialog('Ad is not ready yet. Please try again in a moment.');
        _adMobService.loadRewardedAd(); // 새로운 광고 로드 시도
        return;
      }

      _adMobService.showRewardedAd(
        onUserEarnedReward: (ad, reward) async {
          // 광고 시청 완료 시 카운트 +100
          final newlyUnlocked = await _countingService.addCountFromAd();

          setState(() {
            _currentCount = _countingService.currentCount;
          });

          // 성공 애니메이션
          _countAnimationController.forward().then((_) {
            _countAnimationController.reverse();
          });

          // 새로 해금된 스타일이 있다면 알림 표시
          if (newlyUnlocked.isNotEmpty) {
            _showUnlockDialog(newlyUnlocked);
          }

          // 보상 획득 메시지
          _showSuccessDialog('Ad completed!\nYou received +100 counts!');
        },
      );
    } catch (e) {
      _showErrorDialog('An error occurred while watching ad: $e');
    } finally {
      setState(() {
        _isRewardedAdLoading = false;
      });
    }
  }

  /// 해금 성공 다이얼로그 표시
  void _showUnlockDialog(List<BaldStyle> unlockedStyles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 New Style Unlocked!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Congratulations! New bald style has been unlocked:'),
            const SizedBox(height: 16),
            ...unlockedStyles.map((style) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• ${style.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 성공 메시지 다이얼로그 표시
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 전면 광고 스케줄링 (5초 후 표시)
  void _scheduleInterstitialAd() {
    _interstitialAdTimer?.cancel(); // 기존 타이머 취소
    
    _interstitialAdTimer = Timer(const Duration(seconds: 5), () {
      if (_adMobService.isInterstitialAdAvailable && !_hasShownInterstitialAd) {
        _hasShownInterstitialAd = true;
        _adMobService.showInterstitialAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더 (설정, 카운트 표시, 보관함)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 설정 버튼
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  // 카운트 표시
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.2)
                        .animate(_countAnimationController),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_currentCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Bald Count',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 보관함 버튼
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CollectionScreen(),
                        ),
                      );
                      // 보관함에서 돌아온 후 항상 UI 업데이트 (스타일 변경 가능성)
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // 이미지 영역 (화면의 대부분을 차지)
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    _baldStyleService
                        .getCurrentImagePath(_flashlightService.isFlashlightOn),
                    key: ValueKey(
                        '${_baldStyleService.selectedStyle.id}_${_flashlightService.isFlashlightOn}'),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Unable to load image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 하단 컨트롤 영역
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 카운트 버튼과 광고 버튼
                  Row(
                    children: [
                      // 카운트 증가 버튼 (메인)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 80,
                          child: ElevatedButton(
                            onPressed: _incrementCount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle,
                                    color: Colors.white, size: 32),
                                SizedBox(height: 4),
                                Text(
                                  'Count +1',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 광고 시청 버튼
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 80,
                          child: ElevatedButton(
                            onPressed: _isRewardedAdLoading || !_adMobService.isRewardedAdAvailable
                                ? null 
                                : _watchRewardedAd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _adMobService.isRewardedAdAvailable 
                                  ? Colors.green 
                                  : Colors.green.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                            ),
                            child: _isRewardedAdLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : !_adMobService.isRewardedAdAvailable
                                    ? const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Loading\nAd...',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.video_library,
                                              color: Colors.white, size: 24),
                                          SizedBox(height: 4),
                                          Text(
                                            'Watch Ad\n+100',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 손전등 토글 버튼
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 0.95)
                        .animate(_scaleController),
                    child: Semantics(
                      button: true,
                      label: _flashlightService.isFlashlightOn
                          ? 'Turn off flashlight'
                          : 'Turn on flashlight',
                      hint: 'Tap to turn flashlight on or off',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: _isLoading || _isFlashlightSupported != true
                                ? null
                                : _toggleFlashlight,
                            child: _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _flashlightService.isFlashlightOn
                                        ? Icons.flashlight_on
                                        : Icons.flashlight_off,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
