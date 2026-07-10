import 'package:warring_states_card/data/cards/bingjia_fajia.dart';
import 'package:warring_states_card/data/cards/mojia_yinyangjia_zonghengjia.dart';
import 'package:warring_states_card/data/cards/neutral_cards.dart';
import 'package:warring_states_card/data/cards/rujia_daojia.dart';
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/l10n/locale_service.dart';

/// 按当前 locale 提供卡牌数据。
/// 简体中文：直接返回原始 const 数据。
/// 其他语言：从原始数据复制结构字段，文本字段从 LocaleService 读取。
class CardDataProvider {
  CardDataProvider._();

  static final List<Card> _allCards = () {
    return [
      ...bingjiaCards,
      ...fajiaCards,
      ...rujiaCards,
      ...daojiaCards,
      ...mojiaCards,
      ...yinyangjiaCards,
      ...zonghengjiaCards,
      ...neutralCards,
    ];
  }();

  /// 获取当前语言的所有卡牌
  static List<Card> getAllCards() {
    final lang = LocaleService.I.localeCode;
    if (lang == 'zh') return List.unmodifiable(_allCards);

    return _allCards.map((c) {
      final id = c.id;
      final name = _get('card.$id.name', c.name);
      final description = _get('card.$id.description', c.description);
      final flavor = _get('card.$id.flavor', c.flavor);
      return Card(
        id: id,
        name: name,
        type: c.type,
        cost: c.cost,
        attack: c.attack,
        health: c.health,
        maxHealth: c.maxHealth,
        description: description,
        keywords: c.keywords,
        owner: c.owner,
        rarity: c.rarity,
        flavor: flavor,
        imageAsset: c.imageAsset,
      );
    }).toList();
  }

  /// 按学派过滤
  static List<Card> getCardsByOwner(CardOwner owner) {
    return getAllCards().where((c) => c.owner == owner).toList();
  }

  static String _get(String key, String fallback) {
    final v = LocaleService.I.t(key);
    return v.startsWith('⚠') ? fallback : v;
  }
}
