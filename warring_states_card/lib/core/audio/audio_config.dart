/// Audio configuration for the Warring States card game.
/// Contains sound file paths and default volume settings.
library;

import 'package:equatable/equatable.dart';

/// Sound effect types available in the game.
enum SoundType {
  /// Playing a card
  playCard,
  /// Minion or hero attack
  attack,
  /// Taking damage
  damage,
  /// Healing
  heal,
  /// Minion death
  death,
  /// End turn button press
  endTurn,
  /// Victory sound
  victory,
  /// Defeat sound
  defeat,
  /// Mana crystal gained
  manaCrystal,
  /// Button click sound
  buttonClick,
  /// Card sliding/swooshing
  cardSlide,
  /// Coin drop sound
  coin,
}

/// Configuration for a single sound effect.
class SoundConfig extends Equatable {
  /// Path to the sound file relative to assets/sounds/
  final String assetPath;

  /// Default volume for this sound (0.0 to 1.0)
  final double defaultVolume;

  const SoundConfig({
    required this.assetPath,
    this.defaultVolume = 1.0,
  });

  @override
  List<Object?> get props => [assetPath, defaultVolume];
}

/// Audio configuration containing all sound definitions.
class AudioConfig {
  AudioConfig._();

  /// Base path for sound assets
  static const String basePath = 'assets/sounds/';

  /// Map of sound type to its configuration
  static final Map<SoundType, SoundConfig> sounds = {
    SoundType.playCard: SoundConfig(
      assetPath: '${basePath}play_card.ogg',
      defaultVolume: 0.8,
    ),
    SoundType.attack: SoundConfig(
      assetPath: '${basePath}attack.ogg',
      defaultVolume: 0.9,
    ),
    SoundType.damage: SoundConfig(
      assetPath: '${basePath}damage.ogg',
      defaultVolume: 1.0,
    ),
    SoundType.heal: SoundConfig(
      assetPath: '${basePath}heal.ogg',
      defaultVolume: 0.7,
    ),
    SoundType.death: SoundConfig(
      assetPath: '${basePath}death.ogg',
      defaultVolume: 0.85,
    ),
    SoundType.endTurn: SoundConfig(
      assetPath: '${basePath}end_turn.ogg',
      defaultVolume: 0.6,
    ),
    SoundType.victory: SoundConfig(
      assetPath: '${basePath}victory.ogg',
      defaultVolume: 1.0,
    ),
    SoundType.defeat: SoundConfig(
      assetPath: '${basePath}defeat.ogg',
      defaultVolume: 0.9,
    ),
    SoundType.manaCrystal: SoundConfig(
      assetPath: '${basePath}mana_crystal.ogg',
      defaultVolume: 0.5,
    ),
    SoundType.buttonClick: SoundConfig(
      assetPath: '${basePath}button_click.ogg',
      defaultVolume: 0.4,
    ),
    SoundType.cardSlide: SoundConfig(
      assetPath: '${basePath}card_slide.ogg',
      defaultVolume: 0.6,
    ),
    SoundType.coin: SoundConfig(
      assetPath: '${basePath}coin.ogg',
      defaultVolume: 0.7,
    ),
  };

  /// Get configuration for a sound type
  static SoundConfig getConfig(SoundType type) {
    return sounds[type] ??
        SoundConfig(assetPath: '${basePath}default.mp3', defaultVolume: 0.7);
  }
}