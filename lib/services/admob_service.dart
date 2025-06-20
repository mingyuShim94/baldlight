import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 광고를 관리하는 서비스 클래스
///
/// 이 클래스는 다음 기능을 제공합니다:
/// - 보상형 광고 로드 및 표시
/// - 전면 광고 로드 및 표시
/// - 디버그/릴리즈 환경에 따른 광고 ID 관리
/// - 광고 성공/실패 로깅
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Production Rewarded Ad Unit IDs
  static const String _androidRewardedAdUnitId = 'ca-app-pub-8647279125417942/8813958235';
  static const String _iosRewardedAdUnitId = 'ca-app-pub-8647279125417942/6394279655';

  // Test Rewarded Ad Unit IDs (Google 제공)
  static const String _testAndroidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testIosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  // Production Interstitial Ad Unit IDs
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-8647279125417942/1069800782';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-8647279125417942/5176566750';

  // Test Interstitial Ad Unit IDs (Google 제공)
  static const String _testAndroidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  bool _isInitialized = false;

  // Rewarded Ad 관련 변수들
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  bool _isShowingRewardedAd = false;

  // Interstitial Ad 관련 변수들
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  bool _isShowingInterstitialAd = false;

  /// AdMob SDK 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logEvent('AdMob SDK 초기화 시작');
      final initializationStatus = await MobileAds.instance.initialize();
      _isInitialized = true;
      _logEvent('AdMob SDK 초기화 성공');
      _logEvent('초기화 상태: ${initializationStatus.adapterStatuses.length}개 어댑터');
      
      // 각 어댑터 상태 로그
      for (final entry in initializationStatus.adapterStatuses.entries) {
        _logEvent('어댑터 ${entry.key}: ${entry.value.state.name} - ${entry.value.description}');
      }
      
      // 약간 지연 후 첫 번째 광고 로드 시도
      Future.delayed(const Duration(seconds: 1), () {
        loadRewardedAd();
        loadInterstitialAd();
      });
    } catch (e) {
      _logError('AdMob SDK 초기화 실패', e);
      rethrow;
    }
  }

  /// 보상형 광고 사용 가능 여부
  bool get isRewardedAdAvailable => _rewardedAd != null && _isRewardedAdLoaded;

  /// 전면 광고 사용 가능 여부
  bool get isInterstitialAdAvailable => _interstitialAd != null && _isInterstitialAdLoaded;

  /// 보상형 광고 로드
  void loadRewardedAd() {
    if (!_isInitialized) {
      _logEvent('AdMob이 초기화되지 않았습니다.');
      return;
    }

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _logEvent('보상형 광고가 이미 로드되어 있습니다');
      return;
    }

    // 기존 광고 정리
    _disposeRewardedAd();

    final adUnitId = _getRewardedAdUnitId();
    _logEvent('보상형 광고 로드 시작: $adUnitId');
    _logEvent('Debug mode: ${kDebugMode ? 'ON (Test ads)' : 'OFF (Production ads)'}');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _logEvent('보상형 광고 로드 성공');
          
          // 풀스크린 콜백 설정
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) {
              _logEvent('보상형 광고 전체 화면 표시됨');
            },
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              _logEvent('보상형 광고 닫힘');
              _isShowingRewardedAd = false;
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              // 다음 광고 미리 로드
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              _logError('보상형 광고 표시 실패', error);
              _isShowingRewardedAd = false;
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              // 다음 광고 미리 로드
              loadRewardedAd();
            },
            onAdImpression: (RewardedAd ad) {
              _logEvent('보상형 광고 노출됨');
            },
            onAdClicked: (RewardedAd ad) {
              _logEvent('보상형 광고 클릭됨');
            },
          );

          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _logError('보상형 광고 로드 실패', error);
          _logEvent('Error details - Code: ${error.code}, Domain: ${error.domain}, Message: ${error.message}');
          _logEvent('ResponseInfo: ${error.responseInfo?.toString() ?? 'No response info'}');
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          
          // 재시도 로직 제거 (무한로딩 방지)
          _logEvent('광고 로드 실패 - 재시도하지 않음');
        },
      ),
    );
  }

  /// 보상형 광고 표시
  /// [onUserEarnedReward] 사용자가 보상을 받았을 때 호출되는 콜백
  void showRewardedAd({
    required Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
  }) {
    if (_isShowingRewardedAd) {
      _logEvent('이미 보상형 광고가 표시 중입니다');
      return;
    }

    if (!isRewardedAdAvailable) {
      _logEvent('표시할 보상형 광고가 없습니다');
      return;
    }

    _isShowingRewardedAd = true;
    _logEvent('보상형 광고 표시 시작');

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _logEvent('보상 획득: ${reward.amount} ${reward.type}');
        onUserEarnedReward(ad, reward);
      },
    );
  }

  /// 전면 광고 로드
  void loadInterstitialAd() {
    if (!_isInitialized) {
      _logEvent('AdMob이 초기화되지 않았습니다.');
      return;
    }

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _logEvent('전면 광고가 이미 로드되어 있습니다');
      return;
    }

    // 기존 광고 정리
    _disposeInterstitialAd();

    final adUnitId = _getInterstitialAdUnitId();
    _logEvent('전면 광고 로드 시작: $adUnitId');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _logEvent('전면 광고 로드 성공');
          
          // 풀스크린 콜백 설정
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              _logEvent('전면 광고 전체 화면 표시됨');
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              _logEvent('전면 광고 닫힘');
              _isShowingInterstitialAd = false;
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // 다음 광고 미리 로드
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              _logError('전면 광고 표시 실패', error);
              _isShowingInterstitialAd = false;
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // 다음 광고 미리 로드
              loadInterstitialAd();
            },
            onAdImpression: (InterstitialAd ad) {
              _logEvent('전면 광고 노출됨');
            },
            onAdClicked: (InterstitialAd ad) {
              _logEvent('전면 광고 클릭됨');
            },
          );

          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _logError('전면 광고 로드 실패', error);
          _logEvent('Error details - Code: ${error.code}, Domain: ${error.domain}, Message: ${error.message}');
          _logEvent('ResponseInfo: ${error.responseInfo?.toString() ?? 'No response info'}');
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          
          // 재시도 로직 제거 (무한로딩 방지)
          _logEvent('전면 광고 로드 실패 - 재시도하지 않음');
        },
      ),
    );
  }

  /// 전면 광고 표시
  void showInterstitialAd() {
    if (_isShowingInterstitialAd) {
      _logEvent('이미 전면 광고가 표시 중입니다');
      return;
    }

    if (!isInterstitialAdAvailable) {
      _logEvent('표시할 전면 광고가 없습니다');
      return;
    }

    _isShowingInterstitialAd = true;
    _logEvent('전면 광고 표시 시작');

    _interstitialAd!.show();
  }

  /// 보상형 광고 단위 ID 반환
  String _getRewardedAdUnitId() {
    // 테스트 광고 ID를 항상 사용 (무한로딩 문제 해결을 위해)
    return Platform.isAndroid ? _testAndroidRewardedAdUnitId : _testIosRewardedAdUnitId;
  }

  /// 전면 광고 단위 ID 반환
  String _getInterstitialAdUnitId() {
    if (kDebugMode) {
      return Platform.isAndroid ? _testAndroidInterstitialAdUnitId : _testIosInterstitialAdUnitId;
    } else {
      return Platform.isAndroid ? _androidInterstitialAdUnitId : _iosInterstitialAdUnitId;
    }
  }

  /// 보상형 광고 정리
  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    _isShowingRewardedAd = false;
  }

  /// 전면 광고 정리
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
    _isShowingInterstitialAd = false;
  }

  /// 리소스 정리
  void dispose() {
    _disposeRewardedAd();
    _disposeInterstitialAd();
    _logEvent('AdMobService 정리 완료');
  }

  /// 이벤트 로깅
  void _logEvent(String message) {
    developer.log(
      message,
      name: 'AdMobService',
    );
  }

  /// 에러 로깅
  void _logError(String message, dynamic error) {
    developer.log(
      '$message: $error',
      name: 'AdMobService',
      level: 1000, // ERROR level
    );
    if (kDebugMode) {
      print('[AdMobService ERROR] $message: $error');
    }
  }
}