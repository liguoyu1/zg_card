import 'package:warring_states_card/data/heroes/heroes_data.dart' as raw;
import 'package:warring_states_card/domain/models/models.dart';
import 'package:warring_states_card/l10n/locale_service.dart';

class HeroDataProvider {
  HeroDataProvider._();

  static List<Hero> getAllHeroes() {
    final lang = LocaleService.I.localeCode;
    if (lang == 'zh') return raw.getAllHeroes();
    return raw.getAllHeroes().map(_localize).toList();
  }

  static List<Hero> getHeroesByClass(String className) {
    final lang = LocaleService.I.localeCode;
    if (lang == 'zh') return raw.getHeroesByClass(className);
    return raw.getHeroesByClass(className).map(_localize).toList();
  }

  static Hero _localize(Hero h) {
    final id = h.id;
    return Hero(
      id: id,
      name: _g('hero.$id.name', h.name),
      className: h.className,
      kingdom: h.kingdom,
      health: h.health,
      heroPowerName: _g('hero.$id.powerName', h.heroPowerName),
      heroPowerDescription: _g('hero.$id.powerDescription', h.heroPowerDescription),
      skillType: h.skillType,
      artAsset: h.artAsset,
      flavor: _g('hero.$id.flavor', h.flavor),
    );
  }

  static String _g(String key, String fb) {
    final v = LocaleService.I.t(key);
    return v.startsWith('⚠') ? fb : v;
  }
}
