import 'package:flutter/material.dart';
import 'services/flashlight_service.dart';
import 'services/admob_service.dart';
import 'dart:async';

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

class _FlashlightMainPageState extends State<FlashlightMainPage> with TickerProviderStateMixin {
  final FlashlightService _flashlightService = FlashlightService();
  final AdMobService _adMobService = AdMobService();

  bool _isLoading = false;
  bool? _isFlashlightSupported;
  late AnimationController _scaleController;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkFlashlightSupport();
    _initializeAdMob();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _flashlightService.dispose();
    _adMobService.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  /// 애니메이션 컨트롤러 초기화
  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  /// AdMob 서비스 초기화 및 광고 미리 로드
  Future<void> _initializeAdMob() async {
    try {
      await _adMobService.initialize();
      // 광고 미리 로드
      await _adMobService.loadInterstitialAd();
    } catch (e) {
      print('AdMob 초기화 실패: $e');
    }
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
      _showErrorDialog('플래시라이트가 지원되지 않는 기기입니다.');
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
      final wasFlashlightOn = _flashlightService.isFlashlightOn;
      await _flashlightService.toggleFlashlight();

      setState(() {
        _isLoading = false;
      });

      // 손전등이 켜졌을 때만 5초 후 전면광고 표시
      if (!wasFlashlightOn && _flashlightService.isFlashlightOn) {
        _scheduleInterstitialAd();
      }
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
      _showErrorDialog('알 수 없는 오류가 발생했습니다: $e');
    }
  }

  /// 손전등 켜기 후 5초 뒤에 전면광고 표시 스케줄링
  void _scheduleInterstitialAd() {
    // 기존 타이머가 있으면 취소
    _adTimer?.cancel();

    _adTimer = Timer(const Duration(seconds: 5), () async {
      // 광고가 준비되어 있으면 표시
      if (_adMobService.isAdAvailable) {
        await _adMobService.showInterstitialAd();
      } else {
        // 광고가 준비되지 않았으면 로드 시도
        await _adMobService.loadInterstitialAd();
      }
    });
  }

  /// 에러 메시지를 다이얼로그로 표시합니다
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
            // 이미지 영역 (화면의 대부분을 차지)
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    _flashlightService.isFlashlightOn ? 'assets/images/on.webp' : 'assets/images/off.webp',
                    key: ValueKey(_flashlightService.isFlashlightOn),
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
                                '이미지를 불러올 수 없습니다',
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

            // 손전등 토글 버튼 (이미지 아래 영역)
            SizedBox(
              height: 150,
              child: Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.95).animate(_scaleController),
                  child: Semantics(
                    button: true,
                    label: _flashlightService.isFlashlightOn ? '손전등 끄기' : '손전등 켜기',
                    hint: '탭하여 손전등을 켜거나 끄세요',
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
                          onTap: _isLoading || _isFlashlightSupported != true ? null : _toggleFlashlight,
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Icon(
                                  _flashlightService.isFlashlightOn ? Icons.flashlight_on : Icons.flashlight_off,
                                  size: 40,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
