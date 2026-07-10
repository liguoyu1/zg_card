import 'package:warring_states_card/domain/models/hero.dart' as hero;
import 'package:warring_states_card/domain/models/mission_context.dart';
import 'package:warring_states_card/domain/services/services.dart';

/// Args container for passing GameScreen params through GoRouter's `extra`.
class GameScreenArgs {

  const GameScreenArgs({
    required this.playerId,
    required this.playerHero,
    this.difficulty = AIDifficulty.normal,
    this.missionContext,
    this.runHp,
    this.opponentHero,
    this.isOnline = false,
  });
  final String playerId;
  final hero.Hero playerHero;
  final AIDifficulty difficulty;
  final MissionContext? missionContext;
  final int? runHp;
  final hero.Hero? opponentHero;
  final bool isOnline;
}
