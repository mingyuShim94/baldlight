import 'package:torch_light/torch_light.dart';

/// 플래시라이트 하드웨어 제어를 담당하는 서비스 클래스
///
/// 이 클래스는 다음 기능을 제공합니다:
/// - 플래시라이트 지원 여부 확인
/// - 플래시라이트 ON/OFF 제어
/// - 비지원 기기에 대한 예외 처리
/// - 안전한 권한 요청 및 에러 핸들링
class FlashlightService {
  static final FlashlightService _instance = FlashlightService._internal();
  factory FlashlightService() => _instance;
  FlashlightService._internal();

  bool _isFlashlightOn = false;
  bool? _isFlashlightAvailable;

  /// 현재 플래시라이트 상태를 반환
  bool get isFlashlightOn => _isFlashlightOn;

  /// 기기에서 플래시라이트 지원 여부를 확인
  ///
  /// Returns:
  ///   - true: 플래시라이트 지원
  ///   - false: 플래시라이트 미지원
  ///   - null: 확인 중 에러 발생
  Future<bool?> isFlashlightAvailable() async {
    if (_isFlashlightAvailable != null) {
      return _isFlashlightAvailable;
    }

    try {
      _isFlashlightAvailable = await TorchLight.isTorchAvailable();
      return _isFlashlightAvailable;
    } catch (e) {
      print('플래시라이트 지원 여부 확인 실패: $e');
      _isFlashlightAvailable = false;
      return false;
    }
  }

  /// 플래시라이트를 켭니다
  ///
  /// Returns:
  ///   - true: 성공적으로 켜짐
  ///   - false: 켜기 실패 (권한 없음, 하드웨어 미지원 등)
  ///
  /// Throws:
  ///   - FlashlightException: 플래시라이트 제어 중 에러 발생시
  Future<bool> turnOnFlashlight() async {
    try {
      // 먼저 플래시라이트 지원 여부 확인
      final isAvailable = await isFlashlightAvailable();
      if (isAvailable != true) {
        throw FlashlightNotSupportedException('이 기기에서는 플래시라이트를 지원하지 않습니다.');
      }

      // 이미 켜져 있는 경우 중복 요청 방지
      if (_isFlashlightOn) {
        return true;
      }

      await TorchLight.enableTorch();
      _isFlashlightOn = true;
      print('플래시라이트 켜짐');
      return true;
    } on EnableTorchNotAvailableException {
      throw FlashlightNotSupportedException('이 기기에서는 플래시라이트를 사용할 수 없습니다.');
    } on EnableTorchExistentUserException {
      throw FlashlightInUseException(
          '카메라가 다른 앱에서 사용 중입니다. 다른 앱을 종료 후 다시 시도해주세요.');
    } on EnableTorchException catch (e) {
      throw FlashlightException('플래시라이트를 켤 수 없습니다: ${e.toString()}');
    } catch (e) {
      print('플래시라이트 켜기 실패: $e');
      throw FlashlightException('알 수 없는 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 플래시라이트를 끕니다
  ///
  /// Returns:
  ///   - true: 성공적으로 꺼짐
  ///   - false: 끄기 실패
  ///
  /// Throws:
  ///   - FlashlightException: 플래시라이트 제어 중 에러 발생시
  Future<bool> turnOffFlashlight() async {
    try {
      // 이미 꺼져 있는 경우 중복 요청 방지
      if (!_isFlashlightOn) {
        return true;
      }

      await TorchLight.disableTorch();
      _isFlashlightOn = false;
      print('플래시라이트 꺼짐');
      return true;
    } on DisableTorchNotAvailableException {
      throw FlashlightNotSupportedException('이 기기에서는 플래시라이트를 사용할 수 없습니다.');
    } on DisableTorchExistentUserException {
      throw FlashlightInUseException('카메라가 다른 앱에서 사용 중입니다.');
    } on DisableTorchException catch (e) {
      throw FlashlightException('플래시라이트를 끌 수 없습니다: ${e.toString()}');
    } catch (e) {
      print('플래시라이트 끄기 실패: $e');
      _isFlashlightOn = false; // 에러 발생시 상태 초기화
      throw FlashlightException('알 수 없는 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 플래시라이트 상태를 토글합니다 (켜기/끄기 전환)
  ///
  /// Returns:
  ///   - true: 성공적으로 토글됨
  ///   - false: 토글 실패
  Future<bool> toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        return await turnOffFlashlight();
      } else {
        return await turnOnFlashlight();
      }
    } catch (e) {
      print('플래시라이트 토글 실패: $e');
      rethrow;
    }
  }

  /// 서비스 정리 (앱 종료시 호출)
  Future<void> dispose() async {
    try {
      if (_isFlashlightOn) {
        await turnOffFlashlight();
      }
    } catch (e) {
      print('FlashlightService dispose 중 에러: $e');
    }
  }
}

// ============================================================================
// Custom Exception Classes
// ============================================================================

/// 플래시라이트 관련 기본 예외 클래스
class FlashlightException implements Exception {
  final String message;
  const FlashlightException(this.message);

  @override
  String toString() => 'FlashlightException: $message';
}

/// 플래시라이트 미지원 기기 예외
class FlashlightNotSupportedException extends FlashlightException {
  const FlashlightNotSupportedException(super.message);

  @override
  String toString() => 'FlashlightNotSupportedException: $message';
}

/// 플래시라이트 사용 중 예외 (다른 앱에서 카메라 사용 중)
class FlashlightInUseException extends FlashlightException {
  const FlashlightInUseException(super.message);

  @override
  String toString() => 'FlashlightInUseException: $message';
}
