import 'dart:async';
import 'package:flutter/foundation.dart';

/// 피버타임 관리 서비스
/// 
/// 광고 시청 후 피버타임 상태를 관리합니다:
/// - 피버타임 지속시간 (3분)
/// - 카운트 배수 효과 (x2)
/// - 피버타임 UI 상태
class FeverTimeService {
  static final FeverTimeService _instance = FeverTimeService._internal();
  factory FeverTimeService() => _instance;
  FeverTimeService._internal();

  // 피버타임 설정
  static const int _feverDurationSeconds = 180; // 3분
  static const int _feverMultiplier = 2; // x2 배수

  // 상태 변수
  bool _isInFeverTime = false;
  int _remainingSeconds = 0;
  Timer? _feverTimer;
  
  // 콜백 함수
  Function(int)? _onTimeUpdated;
  Function()? _onFeverEnded;

  // Getters
  bool get isInFeverTime => _isInFeverTime;
  int get remainingSeconds => _remainingSeconds;
  int get feverMultiplier => _feverMultiplier;
  double get remainingProgress => _remainingSeconds / _feverDurationSeconds;

  /// 피버타임 시작
  void startFeverTime({
    Function(int)? onTimeUpdated,
    Function()? onFeverEnded,
  }) {
    if (_isInFeverTime) {
      if (kDebugMode) {
        print('FeverTime already active, extending duration');
      }
      // 이미 피버타임이 활성화된 경우 시간 연장
      _remainingSeconds = _feverDurationSeconds;
      return;
    }

    _onTimeUpdated = onTimeUpdated;
    _onFeverEnded = onFeverEnded;
    
    _isInFeverTime = true;
    _remainingSeconds = _feverDurationSeconds;

    if (kDebugMode) {
      print('FeverTime started: ${_feverDurationSeconds}s with x$_feverMultiplier multiplier');
    }

    // 1초마다 타이머 업데이트
    _feverTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      
      // 콜백 호출
      _onTimeUpdated?.call(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _endFeverTime();
      }
    });
  }

  /// 피버타임 강제 종료
  void endFeverTime() {
    _endFeverTime();
  }

  /// 피버타임 종료 처리
  void _endFeverTime() {
    _feverTimer?.cancel();
    _feverTimer = null;
    _isInFeverTime = false;
    _remainingSeconds = 0;

    if (kDebugMode) {
      print('FeverTime ended');
    }

    // 종료 콜백 호출
    _onFeverEnded?.call();
  }

  /// 피버타임 적용된 카운트 계산
  int applyFeverMultiplier(int baseCount) {
    return _isInFeverTime ? baseCount * _feverMultiplier : baseCount;
  }

  /// 남은 시간을 분:초 형식으로 반환
  String getFormattedTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 피버타임 상태 정보 반환
  Map<String, dynamic> getFeverTimeInfo() {
    return {
      'isActive': _isInFeverTime,
      'remainingSeconds': _remainingSeconds,
      'multiplier': _feverMultiplier,
      'progress': remainingProgress,
      'formattedTime': getFormattedTime(),
    };
  }

  /// 서비스 정리
  void dispose() {
    _feverTimer?.cancel();
    _feverTimer = null;
    _isInFeverTime = false;
    _remainingSeconds = 0;
    _onTimeUpdated = null;
    _onFeverEnded = null;
  }
}