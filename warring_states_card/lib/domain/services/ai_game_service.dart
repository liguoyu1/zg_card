import 'package:warring_states_card/domain/models/models.dart';

import 'ai_controller.dart' show AIDifficulty;

class AIGameService {

  AIGameService({this.difficulty = AIDifficulty.normal});
  final AIDifficulty difficulty;

  List<Card> getPlayableCards(GameState state, String playerId) {
    final player = state.getCurrentPlayer(playerId);
    return player.hand.where((c) => c.cost <= player.mana).toList();
  }

  int getCardValue(Card card) {
    int value = card.attack + card.health + card.cost;
    if (card.keywords.contains(Keyword.battlecry)) value += 2;
    if (card.keywords.contains(Keyword.deathrattle)) value += 2;
    if (card.keywords.contains(Keyword.charge)) value += 2;
    return value;
  }

  String? selectOptimalTarget(List<Card> targets) {
    if (targets.isEmpty) return null;
    final tauntTargets = targets.where((c) => c.keywords.contains(Keyword.taunt));
    if (tauntTargets.isNotEmpty) return tauntTargets.first.id;
    for (final target in targets) {
      if (target.keywords.contains(Keyword.poisonous)) return target.id;
      if (target.attack >= 5) return target.id;
    }
    return targets.first.id;
  }

  String? selectRandomTarget(List<Card> targets) {
    if (targets.isEmpty) return null;
    return targets[DateTime.now().microsecond % targets.length].id;
  }

  List<Card> getAIPlayOrder(GameState state, String aiPlayerId) {
    final playableCards = getPlayableCards(state, aiPlayerId);
    switch (difficulty) {
      case AIDifficulty.simple:
        playableCards.shuffle();
        return playableCards;
      case AIDifficulty.normal:
        playableCards.sort((a, b) => b.cost.compareTo(a.cost));
        return playableCards;
      case AIDifficulty.hard:
        playableCards.sort((a, b) => getCardValue(b).compareTo(getCardValue(a)));
        return playableCards;
      case AIDifficulty.abyss:
        playableCards.sort((a, b) => _getOptimalPlayOrder(b).compareTo(_getOptimalPlayOrder(a)));
        return playableCards;
    }
  }

  int _getOptimalPlayOrder(Card card) {
    int priority = card.cost * 10;
    if (card.keywords.contains(Keyword.battlecry)) priority += 5;
    if (card.keywords.contains(Keyword.deathrattle)) priority += 3;
    return priority;
  }
}