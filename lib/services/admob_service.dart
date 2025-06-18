import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 전면광고를 관리하는 서비스 클래스
///
/// 이 클래스는 다음 기능을 제공합니다:
/// - 전면광고 로드 및 표시
/// - 디버그/릴리즈 환경에 따른 광고 ID 관리
/// - 광고 성공/실패 로깅
/// - 광고 유효성 관리 (4시간 만료)
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Production Interstitial Ad Unit IDs (사용자 제공)
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-8647279125417942/1069800782';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-8647279125417942/5176566750';

  // Test Interstitial Ad Unit IDs (Google 제공)
  static const String _testAndroidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isShowingAd = false;
  bool _isInitialized = false;
  DateTime? _interstitialLoadTime;

  /// 전면광고 유효 시간 (4시간)
  static const Duration _maxAdAge = Duration(hours: 4);

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

  /// 현재 환경에 맞는 전면광고 ID 반환
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
    _logError('Unsupported platform for Ads', UnsupportedError('Unsupported platform'));
    // 기본으로 Android 테스트 ID를 반환하여 크래시 방지
    return _testAndroidInterstitialAdUnitId;
  }

  /// 전면광고 로드
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isAdLoaded || _interstitialAd != null) {
      _logEvent('전면광고가 이미 로드되었습니다');
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
            _interstitialLoadTime = DateTime.now();
            _logEvent('전면광고 로드 성공');
            _logAdStats('interstitial_ad_load_success');

            // 광고 이벤트 리스너 설정
            _setAdEventListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isAdLoaded = false;
            _logError('전면광고 로드 실패', error);
            _logAdStats('interstitial_ad_load_failed', parameters: {
              'error_code': error.code,
              'error_domain': error.domain,
              'error_message': error.message,
            });
          },
        ),
      );
    } catch (e) {
      _isAdLoaded = false;
      _logError('전면광고 로드 중 예외 발생', e);
    }
  }

  /// 광고 이벤트 리스너 설정
  void _setAdEventListeners() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        _isShowingAd = true;
        _logEvent('전면광고 표시됨');
        _logAdStats('interstitial_ad_show_success');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        _isShowingAd = false;
        _logEvent('전면광고 닫힘');
        _logAdStats('interstitial_ad_dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        _interstitialLoadTime = null;

        // 새로운 광고 미리 로드
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        _isShowingAd = false;
        _logError('전면광고 표시 실패', error);
        _logAdStats('interstitial_ad_show_failed', parameters: {
          'error_code': error.code,
          'error_message': error.message,
        });
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        _interstitialLoadTime = null;

        // 새로운 광고 미리 로드
        loadInterstitialAd();
      },
      onAdClicked: (InterstitialAd ad) {
        _logEvent('전면광고 클릭됨');
        _logAdStats('interstitial_ad_clicked');
      },
      onAdImpression: (InterstitialAd ad) {
        _logEvent('전면광고 노출됨');
        _logAdStats('interstitial_ad_impression');
      },
    );
  }

  /// 전면광고 표시
  ///
  /// 반환값: 광고가 성공적으로 표시되었는지 여부
  Future<bool> showInterstitialAd() async {
    if (_isShowingAd) {
      _logEvent('이미 광고가 표시 중입니다');
      return false;
    }

    if (!isAdAvailable) {
      _logEvent('표시할 전면광고가 없습니다');
      return false;
    }

    if (_isAdExpired) {
      _logEvent('전면광고가 만료되었습니다. 새로 로드합니다.');
      _disposeCurrentAd();
      loadInterstitialAd();
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      _logError('전면광고 표시 중 예외 발생', e);
      return false;
    }
  }

  /// 현재 광고 해제
  void _disposeCurrentAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _interstitialLoadTime = null;
  }

  /// 광고가 사용 가능한지 확인
  bool get isAdAvailable {
    return _interstitialAd != null && _isAdLoaded;
  }

  /// 광고가 만료되었는지 확인 (4시간 후 만료)
  bool get _isAdExpired {
    if (_interstitialLoadTime == null) return true;

    final now = DateTime.now();
    final timeSinceLoad = now.difference(_interstitialLoadTime!);
    return timeSinceLoad >= _maxAdAge;
  }

  /// 광고가 현재 표시 중인지 확인
  bool get isShowingAd => _isShowingAd;

  /// 리소스 정리
  void dispose() {
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
      'ad_age_minutes': _interstitialLoadTime != null ? DateTime.now().difference(_interstitialLoadTime!).inMinutes : null,
      ...?parameters,
    };

    _logEvent('광고 통계: $stats');

    // TODO: Firebase Analytics 또는 다른 분석 도구와 연동
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: parameters);
  }
}
