import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 사운드 효과 관리 서비스
///
/// 게임의 모든 사운드 효과를 관리합니다:
/// - 타격 효과음
/// - 해금 효과음
/// - 배경음악 (추후 추가 예정)
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  late AudioPlayer _audioPlayer;
  late AudioPlayer _painAudioPlayer; // 추가 오디오 플레이어 (동시 재생용)
  bool _isInitialized = false;
  bool _isSoundEnabled = true;
  double _volume = 0.8;

  // 사운드 파일 경로
  static const String _tapSoundPath = 'sounds/tap_sound.mp3';
  static const String _painSoundPath = 'sounds/pain_sound.mp3';
  static const String _unlockSoundPath = 'sounds/unlock_sound.mp3';
  static const String _feverSoundPath = 'sounds/fever_sound.mp3';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSoundEnabled => _isSoundEnabled;
  double get volume => _volume;

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();
      _painAudioPlayer = AudioPlayer();
      await _audioPlayer.setVolume(_volume);
      await _painAudioPlayer.setVolume(_volume);
      _isInitialized = true;

      if (kDebugMode) {
        print('SoundService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SoundService: $e');
      }
      _isInitialized = false;
    }
  }

  /// 타격 효과음 재생
  Future<void> playTapSound() async {
    if (!_isInitialized || !_isSoundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource(_tapSoundPath));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing tap sound (sound file may not exist): $e');
      }
      // 사운드 파일이 없어도 앱이 중단되지 않도록 처리
    }
  }

  /// 타격 효과음 + 10% 확률로 아픔 사운드 동시 재생
  Future<void> playTapSoundWithChance() async {
    if (!_isInitialized || !_isSoundEnabled) return;

    try {
      // 항상 tap_sound 재생
      await _audioPlayer.play(AssetSource(_tapSoundPath));

      // 10% 확률로 pain_sound 동시 재생
      final random = Random();
      if (random.nextInt(100) < 10) {
        await _painAudioPlayer.play(AssetSource(_painSoundPath));
        if (kDebugMode) {
          print('Pain sound triggered! (10% chance)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error playing tap sound with chance (sound file may not exist): $e');
      }
      // 사운드 파일이 없어도 앱이 중단되지 않도록 처리
    }
  }

  /// 아픔 효과음 재생
  Future<void> playPainSound() async {
    if (!_isInitialized || !_isSoundEnabled) return;

    try {
      await _painAudioPlayer.play(AssetSource(_painSoundPath));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing pain sound (sound file may not exist): $e');
      }
      // 사운드 파일이 없어도 앱이 중단되지 않도록 처리
    }
  }

  /// 해금 효과음 재생
  Future<void> playUnlockSound() async {
    if (!_isInitialized || !_isSoundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource(_unlockSoundPath));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing unlock sound (sound file may not exist): $e');
      }
      // 사운드 파일이 없어도 앱이 중단되지 않도록 처리
    }
  }

  /// 피버타임 효과음 재생
  Future<void> playFeverSound() async {
    if (!_isInitialized || !_isSoundEnabled) return;

    try {
      await _audioPlayer.play(AssetSource(_feverSoundPath));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing fever sound (sound file may not exist): $e');
      }
      // 사운드 파일이 없어도 앱이 중단되지 않도록 처리
    }
  }

  /// 사운드 ON/OFF 설정
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
  }

  /// 볼륨 설정
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _audioPlayer.setVolume(_volume);
      await _painAudioPlayer.setVolume(_volume);
    }
  }

  /// 모든 사운드 정지
  Future<void> stopAllSounds() async {
    if (_isInitialized) {
      await _audioPlayer.stop();
      await _painAudioPlayer.stop();
    }
  }

  /// 서비스 정리
  Future<void> dispose() async {
    if (_isInitialized) {
      await _audioPlayer.dispose();
      await _painAudioPlayer.dispose();
      _isInitialized = false;
    }
  }
}
