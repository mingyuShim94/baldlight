import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

/// 대머리 스타일 데이터 모델
///
/// 각 대머리 스타일의 정보를 담고 있습니다:
/// - 스타일 ID, 이름, 이미지 경로
/// - 해금 조건 및 상태
class BaldStyle {
  final String id;
  final String name;
  final String offImagePath;
  final String onImagePath;
  final int unlockCount;
  bool isUnlocked;

  BaldStyle({
    required this.id,
    required this.name,
    required this.offImagePath,
    required this.onImagePath,
    required this.unlockCount,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'offImagePath': offImagePath,
      'onImagePath': onImagePath,
      'unlockCount': unlockCount,
      'isUnlocked': isUnlocked,
    };
  }

  factory BaldStyle.fromJson(Map<String, dynamic> json) {
    return BaldStyle(
      id: json['id'],
      name: json['name'],
      offImagePath: json['offImagePath'],
      onImagePath: json['onImagePath'],
      unlockCount: json['unlockCount'],
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}

/// 대머리 스타일 관리 서비스
///
/// 이 서비스는 다음 기능을 제공합니다:
/// - 사용 가능한 대머리 스타일 목록 관리
/// - 현재 선택된 스타일 상태 관리
/// - 해금 상태 관리 및 저장
/// - 카운트에 따른 자동 해금 처리
class BaldStyleService {
  static final BaldStyleService _instance = BaldStyleService._internal();
  factory BaldStyleService() => _instance;
  BaldStyleService._internal();

  static const String _selectedStyleKey = 'selected_style_id';
  static const String _unlockedStylesKey = 'unlocked_styles';

  List<BaldStyle>? _styles;
  String _selectedStyleId = 'bald1'; // 기본 선택 스타일

  /// 사용 가능한 모든 대머리 스타일 목록
  List<BaldStyle> get availableStyles {
    _styles ??= _initializeStyles();
    return _styles!;
  }

  /// 현재 선택된 스타일
  BaldStyle get selectedStyle {
    return availableStyles.firstWhere(
      (style) => style.id == _selectedStyleId,
      orElse: () => availableStyles.first,
    );
  }

  /// 해금된 스타일 목록
  List<BaldStyle> get unlockedStyles {
    return availableStyles.where((style) => style.isUnlocked).toList();
  }

  /// 서비스 초기화
  /// SharedPreferences에서 저장된 데이터를 로드합니다
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 선택된 스타일 ID 로드
      _selectedStyleId = prefs.getString(_selectedStyleKey) ?? 'bald1';

      // 해금된 스타일 목록 로드
      final unlockedStyleIds =
          prefs.getStringList(_unlockedStylesKey) ?? ['bald1'];

      // 해금 상태 업데이트
      for (final style in availableStyles) {
        style.isUnlocked = unlockedStyleIds.contains(style.id);
      }

      _logEvent('BaldStyleService 초기화 완료 - 선택된 스타일: $_selectedStyleId');
    } catch (e) {
      _logEvent('BaldStyleService 초기화 실패: $e', isError: true);
      // 초기화 실패 시 기본값 사용
      _selectedStyleId = 'bald1';
      availableStyles.first.isUnlocked = true;
    }
  }

  /// 스타일 선택
  /// [styleId] 선택할 스타일의 ID
  Future<bool> selectStyle(String styleId) async {
    try {
      final style = availableStyles.firstWhere(
        (s) => s.id == styleId,
        orElse: () => throw Exception('스타일을 찾을 수 없습니다: $styleId'),
      );

      if (!style.isUnlocked) {
        _logEvent('잠긴 스타일 선택 시도: $styleId', isError: true);
        return false;
      }

      _selectedStyleId = styleId;

      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedStyleKey, styleId);

      _logEvent('스타일 선택됨: $styleId');
      return true;
    } catch (e) {
      _logEvent('스타일 선택 실패: $e', isError: true);
      return false;
    }
  }

  /// 카운트에 따른 스타일 해금 체크
  /// [currentCount] 현재 사용자의 카운트
  /// 반환: 새로 해금된 스타일 목록
  Future<List<BaldStyle>> checkAndUnlockStyles(int currentCount) async {
    final newlyUnlocked = <BaldStyle>[];

    try {
      for (final style in availableStyles) {
        if (!style.isUnlocked && currentCount >= style.unlockCount) {
          style.isUnlocked = true;
          newlyUnlocked.add(style);
          _logEvent('새 스타일 해금: ${style.id} (필요 카운트: ${style.unlockCount})');
        }
      }

      if (newlyUnlocked.isNotEmpty) {
        await _saveUnlockedStyles();
      }
    } catch (e) {
      _logEvent('스타일 해금 체크 실패: $e', isError: true);
    }

    return newlyUnlocked;
  }

  /// 특정 스타일의 해금 상태 확인
  bool isStyleUnlocked(String styleId) {
    final style = availableStyles.firstWhere(
      (s) => s.id == styleId,
      orElse: () => availableStyles.first,
    );
    return style.isUnlocked;
  }

  /// 현재 선택된 스타일의 플래시라이트 상태에 따른 이미지 경로 반환
  String getCurrentImagePath(bool isFlashlightOn) {
    final style = selectedStyle;
    return isFlashlightOn ? style.onImagePath : style.offImagePath;
  }

  /// 해금된 스타일 목록을 SharedPreferences에 저장
  Future<void> _saveUnlockedStyles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedIds = unlockedStyles.map((style) => style.id).toList();
      await prefs.setStringList(_unlockedStylesKey, unlockedIds);
    } catch (e) {
      _logEvent('해금된 스타일 저장 실패: $e', isError: true);
    }
  }

  /// 사용 가능한 스타일 목록 초기화
  List<BaldStyle> _initializeStyles() {
    return [
      BaldStyle(
        id: 'bald1',
        name: 'Basic Bald',
        offImagePath: 'assets/images/bald_styles/bald1_off.png',
        onImagePath: 'assets/images/bald_styles/bald1_on.png',
        unlockCount: 0, // 기본 해금
        isUnlocked: true,
      ),
      BaldStyle(
        id: 'bald2',
        name: 'Heihachi',
        offImagePath: 'assets/images/bald_styles/bald2_off.png',
        onImagePath: 'assets/images/bald_styles/bald2_on.png',
        unlockCount: 100,
      ),
      BaldStyle(
        id: 'bald3',
        name: 'Catholic Monk',
        offImagePath: 'assets/images/bald_styles/bald3_off.png',
        onImagePath: 'assets/images/bald_styles/bald3_on.png',
        unlockCount: 300,
      ),
    ];
  }

  /// 디버그 로깅
  void _logEvent(String message, {bool isError = false}) {
    if (isError) {
      developer.log(message, name: 'BaldStyleService', level: 1000);
    } else {
      developer.log(message, name: 'BaldStyleService');
    }
  }

  /// 서비스 정리
  void dispose() {
    _logEvent('BaldStyleService 정리');
  }
}
