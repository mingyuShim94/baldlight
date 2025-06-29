import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 사운드 효과 관리 서비스
///
/// 게임의 모든 사운드 효과를 관리합니다:
/// - 타격 효과음
/// - 아픔 효과음 (hurt1~hurt7 랜덤 재생)
/// - 해금 효과음
/// - 배경음악 (추후 추가 예정)
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  late AudioPlayer _audioPlayer;
  late AudioPlayer _hurtAudioPlayer; // hurt sound 전용 오디오 플레이어 (동시 재생용)
  bool _isInitialized = false;
  bool _isSoundEnabled = true;
  double _volume = 0.8;

  // 사운드 파일 경로
  static const String _tapSoundPath = 'sounds/tap_sound.mp3';
  static const String _unlockSoundPath = 'sounds/unlock_sound.mp3';
  static const String _feverSoundPath = 'sounds/fever_sound.mp3';

  // hurt sound 파일 경로들
  static const List<String> _hurtSoundPaths = [
    'sounds/hurt_sounds/hurt1.mp3',
    'sounds/hurt_sounds/hurt2.mp3',
    'sounds/hurt_sounds/hurt3.mp3',
    'sounds/hurt_sounds/hurt4.mp3',
    'sounds/hurt_sounds/hurt5.mp3',
    'sounds/hurt_sounds/hurt6.mp3',
    'sounds/hurt_sounds/hurt7.mp3',
  ];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSoundEnabled => _isSoundEnabled;
  double get volume => _volume;

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();
      _hurtAudioPlayer = AudioPlayer();
      await _audioPlayer.setVolume(_volume);
      await _hurtAudioPlayer.setVolume(_volume);
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

  /// 타격 효과음 + 랜덤 hurt sound 동시 재생
  Future<void> playTapSoundWithChance() async {
    if (kDebugMode) {
      print(
          'playTapSoundWithChance called - initialized: $_isInitialized, soundEnabled: $_isSoundEnabled');
    }

    if (!_isInitialized || !_isSoundEnabled) return;

    try {
      // 항상 tap_sound 재생
      if (kDebugMode) {
        print('Playing tap sound: $_tapSoundPath');
      }
      await _audioPlayer.play(AssetSource(_tapSoundPath));

      // 항상 랜덤 hurt sound 동시 재생
      if (kDebugMode) {
        print('About to play random hurt sound...');
      }
      await _playRandomHurtSound();
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error playing tap sound with hurt sound (sound file may not exist): $e');
      }
      // 사운드 파일이 없어도 앱이 중단되지 않도록 처리
    }
  }

  /// 랜덤 hurt sound 재생
  Future<void> _playRandomHurtSound() async {
    if (!_isInitialized || !_isSoundEnabled) {
      if (kDebugMode) {
        print(
            '_playRandomHurtSound skipped - initialized: $_isInitialized, soundEnabled: $_isSoundEnabled');
      }
      return;
    }

    try {
      final random = Random();
      final selectedIndex = random.nextInt(_hurtSoundPaths.length);
      final selectedHurtSound = _hurtSoundPaths[selectedIndex];

      if (kDebugMode) {
        print(
            'Selected hurt sound: $selectedHurtSound (index: $selectedIndex)');
        print('_hurtAudioPlayer state before play: ${_hurtAudioPlayer.state}');
      }

      await _hurtAudioPlayer.play(AssetSource(selectedHurtSound));

      if (kDebugMode) {
        print(
            'Random hurt sound triggered: ${selectedHurtSound.split('/').last}');
        print('_hurtAudioPlayer state after play: ${_hurtAudioPlayer.state}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing random hurt sound: $e');
        print('Error type: ${e.runtimeType}');
        if (e is Exception) {
          print('Exception details: $e');
        }
      }
      // 사운드 파일이 없어도 앱이 중단되지 않도록 처리
    }
  }

  /// 특정 hurt sound 재생 (직접 호출용)
  Future<void> playHurtSound([int? hurtIndex]) async {
    if (!_isInitialized || !_isSoundEnabled) return;

    try {
      String selectedHurtSound;

      if (hurtIndex != null &&
          hurtIndex >= 0 &&
          hurtIndex < _hurtSoundPaths.length) {
        // 특정 인덱스의 hurt sound 재생
        selectedHurtSound = _hurtSoundPaths[hurtIndex];
      } else {
        // 랜덤 hurt sound 재생
        final random = Random();
        final selectedIndex = random.nextInt(_hurtSoundPaths.length);
        selectedHurtSound = _hurtSoundPaths[selectedIndex];
      }

      await _hurtAudioPlayer.play(AssetSource(selectedHurtSound));

      if (kDebugMode) {
        print('Hurt sound played: ${selectedHurtSound.split('/').last}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing hurt sound (sound file may not exist): $e');
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
      await _hurtAudioPlayer.setVolume(_volume);
    }
  }

  /// 모든 사운드 정지
  Future<void> stopAllSounds() async {
    if (_isInitialized) {
      await _audioPlayer.stop();
      await _hurtAudioPlayer.stop();
    }
  }

  /// 서비스 정리
  Future<void> dispose() async {
    if (_isInitialized) {
      await _audioPlayer.dispose();
      await _hurtAudioPlayer.dispose();
      _isInitialized = false;
    }
  }
}
