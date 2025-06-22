import 'package:flutter/foundation.dart';

/// 게임 상태 관리 서비스
/// 
/// 대머리 클리커 게임의 전반적인 상태를 관리합니다:
/// - 게임 플레이 상태
/// - 타격 통계
/// - 게임 설정
class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  // 게임 상태
  bool _isGamePaused = false;
  int _totalTaps = 0;
  int _dailyTaps = 0;
  int _maxComboTaps = 0;
  int _currentCombo = 0;
  DateTime _lastTapTime = DateTime.now();

  // 설정
  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = true;
  double _soundVolume = 0.8;

  // Getters
  bool get isGamePaused => _isGamePaused;
  int get totalTaps => _totalTaps;
  int get dailyTaps => _dailyTaps;
  int get maxComboTaps => _maxComboTaps;
  int get currentCombo => _currentCombo;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  double get soundVolume => _soundVolume;

  /// 게임 일시정지/재개
  void pauseGame() {
    _isGamePaused = true;
  }

  void resumeGame() {
    _isGamePaused = false;
  }

  /// 탭 처리
  void registerTap() {
    if (_isGamePaused) return;

    _totalTaps++;
    _dailyTaps++;

    // 콤보 계산 (1초 이내에 연속 탭하면 콤보 증가)
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 1000) {
      _currentCombo++;
    } else {
      _currentCombo = 1;
    }
    _lastTapTime = now;

    // 최대 콤보 업데이트
    if (_currentCombo > _maxComboTaps) {
      _maxComboTaps = _currentCombo;
    }

    if (kDebugMode) {
      print('Tap registered: Total=$_totalTaps, Daily=$_dailyTaps, Combo=$_currentCombo');
    }
  }

  /// 일일 통계 리셋
  void resetDailyStats() {
    _dailyTaps = 0;
  }

  /// 설정 업데이트
  void updateVibrationSetting(bool enabled) {
    _isVibrationEnabled = enabled;
  }

  void updateSoundSetting(bool enabled) {
    _isSoundEnabled = enabled;
  }

  void updateSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
  }

  /// 통계 정보 가져오기
  Map<String, dynamic> getGameStats() {
    return {
      'totalTaps': _totalTaps,
      'dailyTaps': _dailyTaps,
      'maxCombo': _maxComboTaps,
      'currentCombo': _currentCombo,
    };
  }

  /// 서비스 정리
  void dispose() {
    // 필요한 정리 작업 수행
  }
}