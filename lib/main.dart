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
  late AnimationController _imageAnimationController;

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
    _imageAnimationController.dispose();
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
    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

      // 이미지 변화 애니메이션
      _imageAnimationController.forward().then((_) {
        _imageAnimationController.reverse();
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

          // 이미지 변화 애니메이션 (광고 보상)
          _imageAnimationController.forward().then((_) {
            _imageAnimationController.reverse();
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

            // 이미지 영역 (화면의 대부분을 차지) - 강화된 애니메이션 + 손전등 토글
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.05)
                      .animate(CurvedAnimation(
                    parent: _imageAnimationController,
                    curve: Curves.elasticOut,
                  )),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Container(
                      key: ValueKey(
                          '${_baldStyleService.selectedStyle.id}_${_flashlightService.isFlashlightOn}'),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
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
                          onTap: _isLoading || _isFlashlightSupported != true
                              ? null
                              : _toggleFlashlight,
                          child: Semantics(
                            button: true,
                            label: _flashlightService.isFlashlightOn
                                ? 'Turn off flashlight'
                                : 'Turn on flashlight',
                            hint: 'Tap the image to turn flashlight on or off',
                            child: Image.asset(
                              _baldStyleService.getCurrentImagePath(
                                  _flashlightService.isFlashlightOn),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                    ),
                  ),
                ),
              ),
            ),

            // 하단 컨트롤 영역
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 메인 버튼 영역 (카운트, 광고)
                  Row(
                    children: [
                      // 카운트 증가 버튼 (메인, 75% 너비)
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 100,
                          child: ElevatedButton(
                            onPressed: _incrementCount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 10,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    color: Colors.white, size: 42),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to Count!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '+1',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 광고 시청 버튼 (25% 너비)
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 100,
                          child: ElevatedButton(
                            onPressed: _isRewardedAdLoading ||
                                    !_adMobService.isRewardedAdAvailable
                                ? null
                                : _watchRewardedAd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _adMobService.isRewardedAdAvailable
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
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : !_adMobService.isRewardedAdAvailable
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Loading\nAd...',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )
                                    : const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.video_library,
                                              color: Colors.white, size: 20),
                                          SizedBox(height: 4),
                                          Text(
                                            'Ad\n+100',
                                            style: TextStyle(
                                              fontSize: 11,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
