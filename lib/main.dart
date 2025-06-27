import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/game_service.dart';
import 'services/sound_service.dart';
import 'services/fever_time_service.dart';
import 'services/admob_service.dart';
import 'services/bald_style_service.dart';
import 'services/counting_service.dart';
import 'screens/collection_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/hand_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bald Clicker',
      debugShowCheckedModeBanner: false,
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
      home: const BaldClickerMainPage(),
    );
  }
}

/// 대머리 클리커 게임의 메인 화면
///
/// 이 페이지는 다음 기능을 제공합니다:
/// - 전체 화면 대머리 이미지 표시
/// - 대머리 이미지 탭으로 타격 기능
/// - 피버타임 및 광고 시스템
class BaldClickerMainPage extends StatefulWidget {
  const BaldClickerMainPage({super.key});

  @override
  State<BaldClickerMainPage> createState() => _BaldClickerMainPageState();
}

class _BaldClickerMainPageState extends State<BaldClickerMainPage>
    with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  final SoundService _soundService = SoundService();
  final FeverTimeService _feverTimeService = FeverTimeService();
  final BaldStyleService _baldStyleService = BaldStyleService();
  final CountingService _countingService = CountingService();
  final AdMobService _adMobService = AdMobService();

  late AnimationController _scaleController;
  late AnimationController _countAnimationController;
  late AnimationController _imageAnimationController;

  int _currentCount = 0;
  bool _isRewardedAdLoading = false;
  final bool _hasShownInterstitialAd = false;
  Timer? _interstitialAdTimer;

  // 손바닥 오버레이 관리
  final List<Offset> _handOverlayPositions = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  /// 서비스들을 초기화합니다
  Future<void> _initializeServices() async {
    await _soundService.initialize();
    await _baldStyleService.initialize();
    await _countingService.initialize();
    await _adMobService.initialize(); // AdMob 초기화 (자동으로 첫 광고 로드)

    // 현재 카운트 상태 반영
    setState(() {
      _currentCount = _countingService.currentCount;
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _countAnimationController.dispose();
    _imageAnimationController.dispose();
    _interstitialAdTimer?.cancel();
    _gameService.dispose();
    _soundService.dispose();
    _feverTimeService.dispose();
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
    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  /// 대머리 타격 처리
  Future<void> _onBaldImageTapped(Offset globalPosition) async {
    // 게임 서비스에 탭 등록
    _gameService.registerTap();

    // 사운드 재생
    await _soundService.playTapSound();

    // 진동 피드백
    if (_gameService.isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }

    // 손바닥 오버레이 표시 (피버타임 시 2개)
    if (_feverTimeService.isInFeverTime) {
      _showMultipleHandOverlays(2);
    } else {
      _showHandOverlay(globalPosition);
    }

    // 카운트 증가 처리
    await _incrementCount();

    // 이미지 반응 애니메이션
    _playImageReactionAnimation();

    // 첫 번째 탭 시 5초 후 전면 광고 표시
    if (_currentCount == 1 && !_hasShownInterstitialAd) {
      _scheduleInterstitialAd();
    }
  }

  /// 손바닥 오버레이 표시 (대머리 영역 내 랜덤 위치)
  void _showHandOverlay(Offset globalPosition) {
    final randomPosition = _getRandomBaldPosition();

    setState(() {
      _handOverlayPositions.add(randomPosition);
    });

    // 0.4초 후 오버레이 제거
    Timer(const Duration(milliseconds: 400), () {
      setState(() {
        if (_handOverlayPositions.isNotEmpty) {
          _handOverlayPositions.removeAt(0);
        }
      });
    });
  }

  /// 다중 손바닥 오버레이 표시 (피버타임용)
  void _showMultipleHandOverlays(int count) {
    final List<Offset> newPositions = [];

    // 여러 개의 랜덤 위치 생성
    for (int i = 0; i < count; i++) {
      newPositions.add(_getRandomBaldPosition());
    }

    setState(() {
      _handOverlayPositions.addAll(newPositions);
    });

    // 0.4초 후 오버레이들 제거
    Timer(const Duration(milliseconds: 400), () {
      setState(() {
        // 추가된 손바닥들만 제거
        for (int i = 0; i < count && _handOverlayPositions.isNotEmpty; i++) {
          _handOverlayPositions.removeAt(0);
        }
      });
    });
  }

  /// 대머리 영역 내 랜덤 위치 계산 (이미지 좌표를 화면 좌표로 변환)
  Offset _getRandomBaldPosition() {
    // 원본 이미지 크기 (1024x1536)
    const double originalImageWidth = 1024.0;
    const double originalImageHeight = 1536.0;

    // 이미지 내 대머리 영역 (주어진 좌표)
    const double baldImageX = 330.0;
    const double baldImageY = 100.0;
    const double baldImageWidth = 350.0;
    const double baldImageHeight = 400.0;

    // 화면에서 이미지 영역 가져오기
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return const Offset(400, 400); // 기본 위치 반환
    }

    final screenSize = renderBox.size;

    // BoxFit.cover 로직에 따른 실제 이미지 표시 크기 계산
    final screenAspectRatio = screenSize.width / screenSize.height;
    final imageAspectRatio = originalImageWidth / originalImageHeight;

    double displayedImageWidth;
    double displayedImageHeight;
    double imageOffsetX = 0;
    double imageOffsetY = 0;

    if (screenAspectRatio > imageAspectRatio) {
      // 화면이 이미지보다 넓음 - 이미지의 너비가 화면에 맞춰짐
      displayedImageWidth = screenSize.width;
      displayedImageHeight = screenSize.width / imageAspectRatio;
      imageOffsetY = (screenSize.height - displayedImageHeight) / 2;
    } else {
      // 화면이 이미지보다 높음 - 이미지의 높이가 화면에 맞춰짐
      displayedImageHeight = screenSize.height;
      displayedImageWidth = screenSize.height * imageAspectRatio;
      imageOffsetX = (screenSize.width - displayedImageWidth) / 2;
    }

    // 이미지 좌표를 화면 좌표로 변환
    final scaleX = displayedImageWidth / originalImageWidth;
    final scaleY = displayedImageHeight / originalImageHeight;

    final random = Random();

    // 대머리 영역 내에서 랜덤 위치 생성 (이미지 좌표 기준)
    final randomBaldX = baldImageX + random.nextDouble() * baldImageWidth;
    final randomBaldY = baldImageY + random.nextDouble() * baldImageHeight;

    // 화면 좌표로 변환
    final screenX = imageOffsetX + (randomBaldX * scaleX);
    final screenY = imageOffsetY + (randomBaldY * scaleY);

    return Offset(screenX, screenY);
  }

  /// 이미지 반응 애니메이션
  void _playImageReactionAnimation() {
    _imageAnimationController.forward().then((_) {
      _imageAnimationController.reverse();
    });
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

  /// 카운트 증가 처리 (피버타임 적용)
  Future<void> _incrementCount() async {
    try {
      // 기본 카운트 증가량
      int incrementAmount = 1;

      // 피버타임 적용
      if (_feverTimeService.isInFeverTime) {
        incrementAmount =
            _feverTimeService.applyFeverMultiplier(incrementAmount);
      }

      // 카운팅 서비스에 실제 증가량 적용
      final newlyUnlocked = await _countingService.addCount(incrementAmount);

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

  /// 보상형 광고 시청 (피버타임 활성화)
  Future<void> _watchRewardedAd() async {
    if (_isRewardedAdLoading || _feverTimeService.isInFeverTime) return;

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
          // 피버타임 시작
          _feverTimeService.startFeverTime(
            onTimeUpdated: (remainingSeconds) {
              setState(() {}); // UI 업데이트
            },
            onFeverEnded: () {
              setState(() {}); // UI 업데이트
              _showSuccessDialog('Fever Time ended!\nBack to normal mode.');
            },
          );

          // 피버타임 시작 사운드
          await _soundService.playFeverSound();

          // 성공 애니메이션
          _countAnimationController.forward().then((_) {
            _countAnimationController.reverse();
          });

          // 보상 획득 메시지
          _showSuccessDialog('Fever Time activated!\n3 minutes of 2x counts!');
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

  /// 해금 성공 다이얼로그 표시 (강화된 애니메이션)
  void _showUnlockDialog(List<BaldStyle> unlockedStyles) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 축하 아이콘
              const Icon(
                Icons.celebration,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),

              // 제목
              const Text(
                '🎉 NEW STYLE UNLOCKED! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 서브 타이틀
              const Text(
                'Congratulations! You have unlocked:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 해금된 스타일 목록
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: unlockedStyles
                      .map((style) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.yellowAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    style.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Awesome!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CollectionScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white, width: 1),
                        ),
                      ),
                      child: const Text(
                        'View Collection',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  /// 전면 광고 스케줄링 (5초 후 표시) - 임시 비활성화
  void _scheduleInterstitialAd() {
    _interstitialAdTimer?.cancel(); // 기존 타이머 취소

    // 임시로 전면광고 비활성화 - 필요시 아래 주석 해제
    return;

    // _interstitialAdTimer = Timer(const Duration(seconds: 5), () {
    //   if (_adMobService.isInterstitialAdAvailable && !_hasShownInterstitialAd) {
    //     _hasShownInterstitialAd = true;
    //     _adMobService.showInterstitialAd();
    //   }
    // });
  }

  /// 다음 해금까지의 진행률 계산
  double _getProgressToNextUnlock() {
    if (_countingService.countToNextUnlock <= 0) return 1.0;

    final lockedStyles = _baldStyleService.availableStyles
        .where((style) => !style.isUnlocked)
        .toList();

    if (lockedStyles.isEmpty) return 1.0;

    lockedStyles.sort((a, b) => a.unlockCount.compareTo(b.unlockCount));
    final nextStyle = lockedStyles.first;

    // 이전 단계의 해금 수준 계산
    final unlockedStyles = _baldStyleService.availableStyles
        .where((style) => style.isUnlocked && style.unlockCount > 0)
        .toList();

    int previousUnlockCount = 0;
    if (unlockedStyles.isNotEmpty) {
      unlockedStyles.sort((a, b) => b.unlockCount.compareTo(a.unlockCount));
      previousUnlockCount = unlockedStyles.first.unlockCount;
    }

    final currentProgress = _currentCount - previousUnlockCount;
    final totalProgress = nextStyle.unlockCount - previousUnlockCount;

    return totalProgress > 0
        ? (currentProgress / totalProgress).clamp(0.0, 1.0)
        : 0.0;
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

                  // 카운트 및 진행률 표시
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.1)
                        .animate(_countAnimationController),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // 카운트 숫자
                          Text(
                            '$_currentCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Bald Counts',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),

                          // 진행률 바
                          if (_countingService.countToNextUnlock > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _getProgressToNextUnlock(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Next: ${_countingService.nextUnlockStyleName} (${_countingService.countToNextUnlock} left)',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            const Text(
                              '🎉 All Unlocked!',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

            // 이미지 영역 (화면의 대부분을 차지) - 대머리 타격 시스템
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    // 메인 대머리 이미지
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.05)
                          .animate(CurvedAnimation(
                        parent: _imageAnimationController,
                        curve: Curves.elasticOut,
                      )),
                      child: Container(
                        key: ValueKey(_baldStyleService.selectedStyle.id),
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: _feverTimeService.isInFeverTime
                                  ? Colors.orange.withValues(alpha: 0.5)
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTapDown: (details) {
                              // 전역 위치 전달
                              _onBaldImageTapped(details.globalPosition);
                            },
                            child: Semantics(
                              button: true,
                              label: 'Tap to hit the bald',
                              hint: 'Tap the bald image to increase your count',
                              child: Image.asset(
                                _baldStyleService.getCurrentImagePath(),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.black,
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
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
                      ),
                    ),

                    // 손바닥 오버레이들
                    ..._handOverlayPositions.map((position) => HandOverlay(
                          position: position,
                          onAnimationComplete: () {
                            setState(() {
                              _handOverlayPositions.remove(position);
                            });
                          },
                        )),

                    // 피버타임 표시
                    if (_feverTimeService.isInFeverTime)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FEVER TIME x${_feverTimeService.feverMultiplier} - ${_feverTimeService.getFormattedTime()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 피버타임 버튼 (우측 하단 오버레이)
                    // 광고가 준비되었거나 피버타임이 활성화된 경우에만 표시
                    if (_adMobService.isRewardedAdAvailable || _feverTimeService.isInFeverTime)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _feverTimeService.isInFeverTime
                                  ? [Colors.grey, Colors.grey.shade700]
                                  : [
                                      Colors.orange.shade400,
                                      Colors.red.shade600
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_feverTimeService.isInFeverTime
                                        ? Colors.grey
                                        : Colors.orange)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: _isRewardedAdLoading ||
                                      _feverTimeService.isInFeverTime
                                  ? null
                                  : _watchRewardedAd,
                              child: Center(
                                child: _isRewardedAdLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : _feverTimeService.isInFeverTime
                                        ? const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.local_fire_department,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                              Text(
                                                'Active',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.local_fire_department,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              Text(
                                                'x2',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'AD',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 배너 광고를 화면 맨 아래에 고정
      bottomNavigationBar: _adMobService.isBannerAdAvailable
          ? Container(
              height: 60,
              alignment: Alignment.center,
              child: AdWidget(ad: _adMobService.bannerAd!),
            )
          : null,
    );
  }
}
