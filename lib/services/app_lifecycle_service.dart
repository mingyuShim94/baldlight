import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 앱의 생명주기를 관리하는 서비스 클래스
///
/// 이 클래스는 다음 기능을 제공합니다:
/// - 앱 시작 시 광고 표시 여부 추적
/// - 앱 생명주기 상태 관리
/// - 광고 표시 조건 확인
class AppLifecycleService {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _hasShownInitialAd = false;
  bool _isFirstLaunch = true;
  AppLifecycleState _currentState = AppLifecycleState.resumed;

  /// 초기 광고가 표시되었는지 확인
  bool get hasShownInitialAd => _hasShownInitialAd;

  /// 첫 번째 실행인지 확인
  bool get isFirstLaunch => _isFirstLaunch;

  /// 현재 앱 생명주기 상태
  AppLifecycleState get currentState => _currentState;

  /// 초기 광고 표시 완료 표시
  void markInitialAdShown() {
    _hasShownInitialAd = true;
    _isFirstLaunch = false;

    if (kDebugMode) {
      print('[AppLifecycleService] 초기 광고 표시 완료');
    }
  }

  /// 앱 생명주기 상태 업데이트
  void updateLifecycleState(AppLifecycleState state) {
    _currentState = state;

    if (kDebugMode) {
      print('[AppLifecycleService] 생명주기 상태 변경: $state');
    }
  }

  /// 광고를 표시해야 하는지 확인
  bool shouldShowAd() {
    // 첫 번째 실행이고 아직 광고를 표시하지 않았을 때만 true
    return _isFirstLaunch && !_hasShownInitialAd;
  }

  /// 앱이 포그라운드로 돌아왔는지 확인
  bool isResumedFromBackground() {
    return _currentState == AppLifecycleState.resumed && !_isFirstLaunch;
  }

  /// 서비스 리셋 (테스트용)
  void reset() {
    _hasShownInitialAd = false;
    _isFirstLaunch = true;
    _currentState = AppLifecycleState.resumed;

    if (kDebugMode) {
      print('[AppLifecycleService] 서비스 리셋');
    }
  }
}
