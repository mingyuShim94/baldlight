import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_lifecycle_service.dart';

/// AdMob 앱 오프닝 광고를 관리하는 서비스 클래스
///
/// 이 클래스는 다음 기능을 제공합니다:
/// - 앱 시작 시 앱 오프닝 광고 로드 및 표시
/// - 포그라운드 이벤트 감지 및 광고 표시
/// - 디버그/릴리즈 환경에 따른 광고 ID 관리
/// - GDPR/CCPA 동의 상태 확인
/// - 광고 성공/실패 로깅
/// - 광고 유효성 관리 (4시간 만료)
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Production App Open Ad Unit IDs
  static const String _androidAppOpenAdUnitId = 'ca-app-pub-5294358720517664/6026027260';
  static const String _iosAppOpenAdUnitId = 'ca-app-pub-5294358720517664/3403749268';

  // Test App Open Ad Unit IDs (Google 제공)
  static const String _testAndroidAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';
  static const String _testIosAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5575463023';

  AppOpenAd? _appOpenAd;
  bool _isAdLoaded = false;
  bool _isShowingAd = false;
  bool _isInitialized = false;
  DateTime? _appOpenLoadTime;
  StreamSubscription<AppState>? _appStateSubscription;

  /// 앱 오프닝 광고 유효 시간 (4시간)
  static const Duration _maxAdAge = Duration(hours: 4);

  /// AdMob SDK 초기화 및 앱 상태 감지 시작
  /// [enableForegroundDetection] 포그라운드 감지 활성화 여부 (기본값: true)
  Future<void> initialize({bool enableForegroundDetection = true}) async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _logEvent('AdMob SDK 초기화 성공');

      // 앱 상태 변화 감지 시작 (옵션에 따라)
      if (enableForegroundDetection) {
        _startListeningToAppStateChanges();
        _logEvent('포그라운드 감지 활성화됨');
      } else {
        _logEvent('포그라운드 감지 비활성화됨');
      }
    } catch (e) {
      _logError('AdMob SDK 초기화 실패', e);
      rethrow;
    }
  }

  /// 앱 상태 변화 감지 시작
  void _startListeningToAppStateChanges() {
    _appStateSubscription = AppStateEventNotifier.appStateStream.listen(
      (AppState state) {
        _logEvent('앱 상태 변화: $state');

        // 앱이 포그라운드로 올 때 광고 표시
        if (state == AppState.foreground) {
          _handleAppForeground();
        }
      },
    );
  }

  /// 앱이 포그라운드로 올 때 처리
  void _handleAppForeground() {
    if (_isShowingAd) {
      _logEvent('이미 광고가 표시 중이므로 건너뜀');
      return;
    }

    // 첫 번째 실행이 아닐 때만 포그라운드 광고 표시
    final lifecycleService = AppLifecycleService();
    if (lifecycleService.hasShownInitialAd) {
      // 광고가 유효하면 표시, 아니면 새로 로드
      if (isAdAvailable && !_isAdExpired) {
        showAppOpenAd();
      } else {
        loadAppOpenAd();
      }
    }
  }

  /// 현재 환경에 맞는 광고 ID 반환
  String get _currentAppOpenAdId {
    if (kDebugMode) {
      // 디버그 모드에서는 플랫폼별 테스트 ID 반환
      if (Platform.isAndroid) {
        return _testAndroidAppOpenAdUnitId;
      } else if (Platform.isIOS) {
        return _testIosAppOpenAdUnitId;
      }
    }
    // 릴리즈 모드에서는 플랫폼별 실제 ID 반환
    if (Platform.isAndroid) {
      return _androidAppOpenAdUnitId;
    } else if (Platform.isIOS) {
      return _iosAppOpenAdUnitId;
    }

    // 지원하지 않는 플랫폼 처리
    _logError('Unsupported platform for Ads', UnsupportedError('Unsupported platform'));
    // 기본으로 Android 테스트 ID를 반환하여 크래시 방지
    return _testAndroidAppOpenAdUnitId;
  }

  /// 앱 오프닝 광고 로드
  Future<void> loadAppOpenAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isAdLoaded || _appOpenAd != null) {
      _logEvent('광고가 이미 로드되었습니다');
      return;
    }

    try {
      await AppOpenAd.load(
        adUnitId: _currentAppOpenAdId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (AppOpenAd ad) {
            _appOpenAd = ad;
            _isAdLoaded = true;
            _appOpenLoadTime = DateTime.now();
            _logEvent('앱 오프닝 광고 로드 성공');
            _logAdStats('app_open_ad_load_success');

            // 광고 이벤트 리스너 설정
            _setAdEventListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isAdLoaded = false;
            _logError('앱 오프닝 광고 로드 실패', error);
            _logAdStats('app_open_ad_load_failed', parameters: {
              'error_code': error.code,
              'error_domain': error.domain,
              'error_message': error.message,
            });
          },
        ),
      );
    } catch (e) {
      _isAdLoaded = false;
      _logError('앱 오프닝 광고 로드 중 예외 발생', e);
    }
  }

  /// 광고 이벤트 리스너 설정
  void _setAdEventListeners() {
    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (AppOpenAd ad) {
        _isShowingAd = true;
        _logEvent('앱 오프닝 광고 표시됨');
        _logAdStats('app_open_ad_show_success');
      },
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        _isShowingAd = false;
        _logEvent('앱 오프닝 광고 닫힘');
        _logAdStats('app_open_ad_dismissed');
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        _appOpenLoadTime = null;

        // 새로운 광고 미리 로드
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        _isShowingAd = false;
        _logError('앱 오프닝 광고 표시 실패', error);
        _logAdStats('app_open_ad_show_failed', parameters: {
          'error_code': error.code,
          'error_message': error.message,
        });
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        _appOpenLoadTime = null;

        // 새로운 광고 미리 로드
        loadAppOpenAd();
      },
      onAdClicked: (AppOpenAd ad) {
        _logEvent('앱 오프닝 광고 클릭됨');
        _logAdStats('app_open_ad_clicked');
      },
    );
  }

  /// 앱 오프닝 광고 표시
  ///
  /// 반환값: 광고가 성공적으로 표시되었는지 여부
  Future<bool> showAppOpenAd() async {
    if (_isShowingAd) {
      _logEvent('이미 광고가 표시 중입니다');
      return false;
    }

    if (!isAdAvailable) {
      _logEvent('표시할 광고가 없습니다');
      return false;
    }

    if (_isAdExpired) {
      _logEvent('광고가 만료되었습니다. 새로 로드합니다.');
      _disposeCurrentAd();
      loadAppOpenAd();
      return false;
    }

    try {
      await _appOpenAd!.show();
      return true;
    } catch (e) {
      _logError('광고 표시 중 예외 발생', e);
      return false;
    }
  }

  /// 현재 광고 해제
  void _disposeCurrentAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAdLoaded = false;
    _appOpenLoadTime = null;
  }

  /// 광고가 사용 가능한지 확인
  bool get isAdAvailable {
    return _appOpenAd != null && _isAdLoaded;
  }

  /// 광고가 만료되었는지 확인 (4시간 후 만료)
  bool get _isAdExpired {
    if (_appOpenLoadTime == null) return true;

    final now = DateTime.now();
    final timeSinceLoad = now.difference(_appOpenLoadTime!);
    return timeSinceLoad >= _maxAdAge;
  }

  /// 광고가 현재 표시 중인지 확인
  bool get isShowingAd => _isShowingAd;

  /// GDPR/CCPA 동의 상태 확인 (향후 구현 예정)
  ///
  /// 현재는 항상 true를 반환하지만, 실제 배포 시에는
  /// ConsentInformation API를 사용하여 동의 상태를 확인해야 합니다.
  Future<bool> checkConsentStatus() async {
    try {
      // TODO: 실제 GDPR/CCPA 동의 로직 구현
      // ConsentInformation.instance.getConsentStatus() 등을 사용
      _logEvent('동의 상태 확인 (현재는 항상 승인으로 처리)');
      return true;
    } catch (e) {
      _logError('동의 상태 확인 실패', e);
      return true; // 실패 시에도 광고 표시 허용
    }
  }

  /// 리소스 정리
  void dispose() {
    _appStateSubscription?.cancel();
    _appStateSubscription = null;
    _disposeCurrentAd();
  }

  /// 이벤트 로깅
  void _logEvent(String message) {
    developer.log(
      message,
      name: 'AdMobService',
      level: 800, // INFO level
    );

    if (kDebugMode) {
      print('[AdMobService] $message');
    }
  }

  /// 에러 로깅
  void _logError(String message, dynamic error) {
    developer.log(
      '$message: $error',
      name: 'AdMobService',
      level: 1000, // ERROR level
      error: error,
    );

    if (kDebugMode) {
      print('[AdMobService ERROR] $message: $error');
    }
  }

  /// 광고 통계 로깅 (향후 Firebase Analytics 등과 연동 가능)
  void _logAdStats(String event, {Map<String, dynamic>? parameters}) {
    final stats = {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      'debug_mode': kDebugMode,
      'ad_age_minutes': _appOpenLoadTime != null ? DateTime.now().difference(_appOpenLoadTime!).inMinutes : null,
      ...?parameters,
    };

    _logEvent('광고 통계: $stats');

    // TODO: Firebase Analytics 또는 다른 분석 도구와 연동
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: parameters);
  }
}
