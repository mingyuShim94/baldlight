import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'bald_style_service.dart';

/// 카운팅 및 해금 관리 서비스
///
/// 이 서비스는 다음 기능을 제공합니다:
/// - 사용자의 카운트 상태 관리 및 저장
/// - 카운트 증가 시 진동 피드백
/// - 카운트에 따른 대머리 스타일 자동 해금
/// - 카운트 증가 애니메이션 트리거
class CountingService {
  static final CountingService _instance = CountingService._internal();
  factory CountingService() => _instance;
  CountingService._internal();

  static const String _countKey = 'user_count';
  static const String _totalAdsWatchedKey = 'total_ads_watched';
  static const String _vibrationEnabledKey = 'vibration_enabled';

  final BaldStyleService _baldStyleService = BaldStyleService();

  int _currentCount = 0;
  int _totalAdsWatched = 0;
  bool _vibrationEnabled = true;
  bool _isInitialized = false;

  /// 현재 카운트
  int get currentCount => _currentCount;

  /// 총 시청한 광고 수
  int get totalAdsWatched => _totalAdsWatched;

  /// 진동 설정 상태
  bool get vibrationEnabled => _vibrationEnabled;

  /// 다음 해금까지 필요한 카운트 (해금되지 않은 첫 번째 스타일 기준)
  int get countToNextUnlock {
    final lockedStyles = _baldStyleService.availableStyles
        .where((style) => !style.isUnlocked)
        .toList();
    
    if (lockedStyles.isEmpty) return 0;
    
    lockedStyles.sort((a, b) => a.unlockCount.compareTo(b.unlockCount));
    return lockedStyles.first.unlockCount - _currentCount;
  }

  /// 다음 해금될 스타일 이름
  String get nextUnlockStyleName {
    final lockedStyles = _baldStyleService.availableStyles
        .where((style) => !style.isUnlocked)
        .toList();
    
    if (lockedStyles.isEmpty) return 'All styles unlocked!';
    
    lockedStyles.sort((a, b) => a.unlockCount.compareTo(b.unlockCount));
    return lockedStyles.first.name;
  }

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      _currentCount = prefs.getInt(_countKey) ?? 0;
      _totalAdsWatched = prefs.getInt(_totalAdsWatchedKey) ?? 0;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
      
      _isInitialized = true;
      _logEvent('CountingService 초기화 완료 - 현재 카운트: $_currentCount');
    } catch (e) {
      _logEvent('CountingService 초기화 실패: $e', isError: true);
      _currentCount = 0;
      _totalAdsWatched = 0;
      _vibrationEnabled = true;
      _isInitialized = true;
    }
  }

  /// 카운트 1 증가
  /// 반환: 새로 해금된 스타일 목록
  Future<List<BaldStyle>> incrementCount() async {
    if (!_isInitialized) {
      await initialize();
    }

    _currentCount++;
    
    // 진동 피드백
    if (_vibrationEnabled) {
      await _triggerVibration();
    }

    // 햅틱 피드백
    await _triggerHapticFeedback();

    // 데이터 저장
    await _saveCount();

    // 스타일 해금 체크
    final newlyUnlocked = await _baldStyleService.checkAndUnlockStyles(_currentCount);

    if (newlyUnlocked.isNotEmpty) {
      _logEvent('카운트 증가로 새 스타일 해금: ${newlyUnlocked.map((s) => s.name).join(', ')}');
    }

    _logEvent('카운트 증가: $_currentCount');
    return newlyUnlocked;
  }

  /// 광고 시청으로 카운트 증가 (+100)
  /// 반환: 새로 해금된 스타일 목록
  Future<List<BaldStyle>> addCountFromAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    _currentCount += 100;
    _totalAdsWatched++;

    // 특별한 햅틱 피드백 (광고 보상)
    await _triggerSuccessHapticFeedback();

    // 데이터 저장
    await _saveCount();
    await _saveTotalAdsWatched();

    // 스타일 해금 체크
    final newlyUnlocked = await _baldStyleService.checkAndUnlockStyles(_currentCount);

    _logEvent('광고 시청으로 카운트 +100: $_currentCount (총 광고 시청: $_totalAdsWatched회)');
    
    if (newlyUnlocked.isNotEmpty) {
      _logEvent('광고 보상으로 새 스타일 해금: ${newlyUnlocked.map((s) => s.name).join(', ')}');
    }

    return newlyUnlocked;
  }

  /// 진동 설정 토글
  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, _vibrationEnabled);
    
    // 설정 변경 확인용 진동
    if (_vibrationEnabled) {
      await _triggerVibration();
    }

    _logEvent('진동 설정 변경: $_vibrationEnabled');
  }

  /// 카운트 리셋 (개발/테스트용)
  Future<void> resetCount() async {
    _currentCount = 0;
    _totalAdsWatched = 0;
    
    await _saveCount();
    await _saveTotalAdsWatched();
    
    // 모든 스타일 잠금 (기본 스타일 제외)
    for (final style in _baldStyleService.availableStyles) {
      if (style.id != 'bald1') {
        style.isUnlocked = false;
      }
    }
    
    _logEvent('카운트 리셋 완료');
  }

  /// 특정 스타일이 해금되었는지 확인
  bool isStyleUnlocked(String styleId) {
    return _baldStyleService.isStyleUnlocked(styleId);
  }

  /// 카운트 저장
  Future<void> _saveCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_countKey, _currentCount);
    } catch (e) {
      _logEvent('카운트 저장 실패: $e', isError: true);
    }
  }

  /// 총 광고 시청 수 저장
  Future<void> _saveTotalAdsWatched() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_totalAdsWatchedKey, _totalAdsWatched);
    } catch (e) {
      _logEvent('광고 시청 수 저장 실패: $e', isError: true);
    }
  }

  /// 진동 피드백 트리거
  Future<void> _triggerVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // 짧은 진동 (50ms)
        await Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      _logEvent('진동 실행 실패: $e', isError: true);
    }
  }

  /// 햅틱 피드백 트리거 (일반 카운트)
  Future<void> _triggerHapticFeedback() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      _logEvent('햅틱 피드백 실행 실패: $e', isError: true);
    }
  }

  /// 성공 햅틱 피드백 트리거 (광고 보상)
  Future<void> _triggerSuccessHapticFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
      // 추가 성공 효과
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (e) {
      _logEvent('성공 햅틱 피드백 실행 실패: $e', isError: true);
    }
  }

  /// 디버그 로깅
  void _logEvent(String message, {bool isError = false}) {
    if (isError) {
      developer.log(message, name: 'CountingService', level: 1000);
    } else {
      developer.log(message, name: 'CountingService');
    }
  }

  /// 서비스 정리
  void dispose() {
    _logEvent('CountingService 정리');
  }
}