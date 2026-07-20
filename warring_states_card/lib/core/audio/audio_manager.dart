/// Audio manager singleton for the Warring States card game.
/// Handles sound playback with web-safe, graceful degradation.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_config.dart';

/// ChangeNotifier for audio UI state management.
class AudioController extends ChangeNotifier {
  bool _isMuted = false;
  bool _isLoaded = false;
  final Set<String> _loadedSounds = {};

  bool get isMuted => _isMuted;
  bool get isLoaded => _isLoaded;
  bool get hasLoadedSound => _loadedSounds.isNotEmpty;

  /// Check if a specific sound is loaded
  bool isSoundLoaded(String assetPath) => _loadedSounds.contains(assetPath);

  /// Mark a sound as loaded
  void markSoundLoaded(String assetPath) {
    _loadedSounds.add(assetPath);
    notifyListeners();
  }

  /// Set muted state
  void setMuted(bool muted) {
    if (_isMuted != muted) {
      _isMuted = muted;
      notifyListeners();
    }
  }

  /// Toggle mute state
  void toggleMute() {
    setMuted(!_isMuted);
  }

  /// Mark audio system as initialized
  void setLoaded(bool loaded) {
    if (_isLoaded != loaded) {
      _isLoaded = loaded;
      notifyListeners();
    }
  }
}

/// Sound type to asset path mapping for quick lookup
const Map<SoundType, String> _soundPaths = {
  SoundType.playCard: '${AudioConfig.basePath}play_card.ogg',
  SoundType.attack: '${AudioConfig.basePath}attack.ogg',
  SoundType.damage: '${AudioConfig.basePath}damage.ogg',
  SoundType.heal: '${AudioConfig.basePath}heal.ogg',
  SoundType.death: '${AudioConfig.basePath}death.ogg',
  SoundType.endTurn: '${AudioConfig.basePath}end_turn.ogg',
  SoundType.victory: '${AudioConfig.basePath}victory.ogg',
  SoundType.defeat: '${AudioConfig.basePath}defeat.ogg',
  SoundType.manaCrystal: '${AudioConfig.basePath}mana_crystal.ogg',
  SoundType.buttonClick: '${AudioConfig.basePath}button_click.ogg',
  SoundType.cardSlide: '${AudioConfig.basePath}card_slide.ogg',
  SoundType.coin: '${AudioConfig.basePath}coin.ogg',
};

/// Audio manager singleton for game sounds.
/// 
/// Usage:
/// ```dart
/// // Initialize on first user interaction (button tap)
/// await AudioManager.instance.init();
///
/// // Play sounds
/// AudioManager.instance.playCard();
/// AudioManager.instance.attack();
///
/// // Control volume per type
/// AudioManager.instance.setVolume(SoundType.music, 0.5);
/// ```
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  /// Singleton access
  static AudioManager get I => instance;

  final AudioController _controller = AudioController();
  AudioController get controller => _controller;

  AudioPlayer? _player;
  AudioPlayer? _musicPlayer; // 独立 BGM 播放器
  final Map<SoundType, double> _volumes = {};
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isMusicPlaying = false;

  /// Get current muted state
  bool get isMuted => _isMuted;

  /// Get volume for a sound type
  double getVolume(SoundType type) {
    return _volumes[type] ?? AudioConfig.getConfig(type).defaultVolume;
  }

  /// Set volume for a specific sound type
  void setVolume(SoundType type, double volume) {
    _volumes[type] = volume.clamp(0.0, 1.0);
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    _controller.setMuted(_isMuted);
  }

  /// Set mute state explicitly
  void setMuted(bool muted) {
    _isMuted = muted;
    _controller.setMuted(_isMuted);
  }

  /// Initialize the audio manager.
  /// MUST be called on first user interaction (button tap) to unlock web audio.
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.stop);
      
      // Web requires user gesture - setting mode triggers unlock
      await _player!.setPlayerMode(PlayerMode.lowLatency);
      
      _isInitialized = true;
      _controller.setLoaded(true);
      
      debugPrint('[AudioManager] Initialized successfully');
    } catch (e) {
      debugPrint('[AudioManager] Init failed: $e');
      // Don't throw - allow graceful degradation
    }
  }

  /// Preload common sounds for better performance.
  /// Call after init() for best results.
  Future<void> preload() async {
    if (!_isInitialized || _isMuted) return;

    // Preload critical sounds
    final criticalSounds = [
      SoundType.playCard,
      SoundType.attack,
      SoundType.damage,
      SoundType.endTurn,
      SoundType.buttonClick,
    ];

    for (final type in criticalSounds) {
      await _preloadSound(type);
    }
  }

  /// Preload a single sound
  Future<void> _preloadSound(SoundType type) async {
    final path = _soundPaths[type];
    if (path == null) return;

    try {
      await AudioCache.instance.load(path);
      _controller.markSoundLoaded(path);
    } catch (e) {
      // Silently skip preload failures - sound may not exist
    }
  }

  /// Play a sound by type with error handling.
  Future<void> _playSound(SoundType type) async {
    if (!_isInitialized || _isMuted) return;

    final path = _soundPaths[type];
    if (path == null) {
      debugPrint('[AudioManager] No path for sound type: $type');
      return;
    }

    final volume = getVolume(type);

    try {
      await _player?.stop();
      await _player?.setVolume(volume);
      await _player?.play(AssetSource(path.replaceFirst('assets/', '')));
    } on PlatformException catch (e) {
      // Web audio restrictions - ignore silently
      if (e.code == 'AUDIOFOCUS' || 
          e.code == 'PLAYER_ERROR' ||
          e.message?.contains('audio') == true) {
        debugPrint('[AudioManager] Web audio restricted: ${e.message}');
      } else {
        debugPrint('[AudioManager] Play error: $e');
      }
    } catch (e) {
      debugPrint('[AudioManager] Play failed for $type: $e');
    }
  }

  /// Play card sound - playing a card from hand
  Future<void> playCard() => _playSound(SoundType.playCard);

  /// Play attack sound - minion or hero attack
  Future<void> attack() => _playSound(SoundType.attack);

  /// Play damage sound - taking damage
  Future<void> damage() => _playSound(SoundType.damage);

  /// Play heal sound - healing
  Future<void> heal() => _playSound(SoundType.heal);

  /// Play death sound - minion death
  Future<void> death() => _playSound(SoundType.death);

  /// Play end turn sound - end turn button press
  Future<void> endTurn() => _playSound(SoundType.endTurn);

  /// Play victory sound - game won
  Future<void> victory() => _playSound(SoundType.victory);

  /// Play defeat sound - game lost
  Future<void> defeat() => _playSound(SoundType.defeat);

  /// Play mana crystal sound - gaining mana
  Future<void> manaCrystal() => _playSound(SoundType.manaCrystal);

  /// Play button click sound - UI interaction
  Future<void> buttonClick() => _playSound(SoundType.buttonClick);

  /// Play card slide sound - card moving animation
  Future<void> cardSlide() => _playSound(SoundType.cardSlide);

  /// Play coin drop sound - rewards/trading
  Future<void> coin() => _playSound(SoundType.coin);

  /// Start background music with crossfade fallback
  Future<void> playBGM(String assetPath) async {
    if (!_isInitialized || _isMuted) return;
    try {
      _musicPlayer ??= AudioPlayer();
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.setVolume(0.3);
      await _musicPlayer!.play(AssetSource('sounds/$assetPath'));
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint('[AudioManager] BGM start failed: $e');
    }
  }

  /// Stop background music
  Future<void> stopBGM() async {
    if (_musicPlayer != null) {
      await _musicPlayer!.stop();
      _isMusicPlaying = false;
    }
  }

  /// Set BGM volume (0.0 to 1.0)
  void setBGMVolume(double volume) {
    _musicPlayer?.setVolume(volume.clamp(0.0, 0.5));
  }

  /// Dispose resources
  void dispose() {
    _player?.dispose();
    _player = null;
    _musicPlayer?.dispose();
    _musicPlayer = null;
    _isInitialized = false;
    _isMusicPlaying = false;
    _controller.setLoaded(false);
  }
}