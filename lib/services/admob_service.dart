import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 인터스티셜 광고를 관리하는 서비스 클래스
///
/// 이 클래스는 다음 기능을 제공합니다:
/// - 앱 시작 시 인터스티셜 광고 로드 및 표시
/// - 디버그/릴리즈 환경에 따른 광고 ID 관리
/// - GDPR/CCPA 동의 상태 확인
/// - 광고 성공/실패 로깅
/// - 광고 실패 시 타임아웃 처리
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Production Ad Unit IDs
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-5294358720517664/6026027260';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-5294358720517664/3403749268';

  // Test Ad Unit IDs
  static const String _testAndroidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isAdShown = false;
  bool _isInitialized = false;

  /// AdMob SDK 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _logEvent('AdMob SDK 초기화 성공');
    } catch (e) {
      _logError('AdMob SDK 초기화 실패', e);
      rethrow;
    }
  }

  /// 현재 환경에 맞는 광고 ID 반환
  String get _currentInterstitialAdId {
    if (kDebugMode) {
      // 디버그 모드에서는 플랫폼별 테스트 ID 반환
      if (Platform.isAndroid) {
        return _testAndroidInterstitialAdUnitId;
      } else if (Platform.isIOS) {
        return _testIosInterstitialAdUnitId;
      }
    }
    // 릴리즈 모드에서는 플랫폼별 실제 ID 반환
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _iosInterstitialAdUnitId;
    }

    // 지원하지 않는 플랫폼 처리
    _logError('Unsupported platform for Ads',
        UnsupportedError('Unsupported platform'));
    // 기본으로 Android 테스트 ID를 반환하여 크래시 방지
    return _testAndroidInterstitialAdUnitId;
  }

  /// 인터스티셜 광고 로드
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isAdLoaded || _interstitialAd != null) {
      _logEvent('광고가 이미 로드되었습니다');
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: _currentInterstitialAdId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;
            _logEvent('인터스티셜 광고 로드 성공');
            _logAdStats('ad_load_success');

            // 광고 이벤트 리스너 설정
            _setAdEventListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isAdLoaded = false;
            _logError('인터스티셜 광고 로드 실패', error);
            _logAdStats('ad_load_failed', parameters: {
              'error_code': error.code,
              'error_domain': error.domain,
              'error_message': error.message,
            });
          },
        ),
      );
    } catch (e) {
      _isAdLoaded = false;
      _logError('인터스티셜 광고 로드 중 예외 발생', e);
    }
  }

  /// 광고 이벤트 리스너 설정
  void _setAdEventListeners() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        _logEvent('인터스티셜 광고 표시됨');
        _logAdStats('ad_show_success');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        _logEvent('인터스티셜 광고 닫힘');
        _logAdStats('ad_dismissed');
        _isAdShown = true;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        _logError('인터스티셜 광고 표시 실패', error);
        _logAdStats('ad_show_failed', parameters: {
          'error_code': error.code,
          'error_message': error.message,
        });
        _isAdShown = true;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
      },
      onAdClicked: (InterstitialAd ad) {
        _logEvent('인터스티셜 광고 클릭됨');
        _logAdStats('ad_clicked');
      },
    );
  }

  /// 인터스티셜 광고 표시
  ///
  /// [timeout] 광고 로드 최대 대기 시간 (기본값: 2초)
  /// 반환값: 광고가 성공적으로 표시되었는지 여부
  Future<bool> showInterstitialAd(
      {Duration timeout = const Duration(seconds: 2)}) async {
    if (_isAdShown) {
      _logEvent('광고가 이미 표시되었습니다');
      return false;
    }

    // 광고가 아직 로드되지 않았다면 로드 시도
    if (!_isAdLoaded) {
      _logEvent('광고 로드 중...');
      await loadInterstitialAd();

      // 타임아웃 내에서 광고 로드 대기
      final stopwatch = Stopwatch()..start();
      while (!_isAdLoaded && stopwatch.elapsed < timeout) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      stopwatch.stop();
    }

    if (_interstitialAd == null || !_isAdLoaded) {
      _logEvent('광고 로드 실패 또는 타임아웃');
      _isAdShown = true; // 실패해도 다시 시도하지 않도록 설정
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      _logError('광고 표시 중 예외 발생', e);
      _isAdShown = true;
      return false;
    }
  }

  /// 광고가 이미 표시되었는지 확인
  bool get isAdShown => _isAdShown;

  /// 광고가 로드되었는지 확인
  bool get isAdLoaded => _isAdLoaded;

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
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
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
      ...?parameters,
    };

    _logEvent('광고 통계: $stats');

    // TODO: Firebase Analytics 또는 다른 분석 도구와 연동
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: parameters);
  }
}
