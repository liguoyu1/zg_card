// 从现有 Dart 源码提取所有用户可见字符串并生成 zh.json
// 运行: dart tool/generate_l10n_json.dart
// 说明: 使用源码级正则提取，不依赖 Flutter 运行时

import 'dart:convert';
import 'dart:io';

void main() {
  final gen = L10nGenerator();
  gen.run();
}

class L10nGenerator {
  final Map<String, dynamic> _json = {};
  int _count = 0, _cards = 0, _heroes = 0, _missions = 0;

  static final _rootDir =
      '${(Directory.current.path.endsWith('tool') ? '${Directory.current.path}/..' : Directory.current.path)}';

  void run() {
    _extractCards('$_rootDir/lib/data/cards/bingjia_fajia.dart');
    _extractCards('$_rootDir/lib/data/cards/rujia_daojia.dart');
    _extractCards('$_rootDir/lib/data/cards/mojia_yinyangjia_zonghengjia.dart');
    _extractCards('$_rootDir/lib/data/cards/neutral_cards.dart');
    _extractHeroes('$_rootDir/lib/data/heroes/heroes_data.dart');
    _extractMissions('$_rootDir/lib/domain/services/adventure_manager.dart');
    _addUiStrings();

    final path = '$_rootDir/assets/l10n/zh.json';
    File(path).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(_json) + '\n');

    print('✅ $path 已生成');
    print('   共 $_count 条 | 卡牌 $_cards 张 | 英雄 $_heroes 位 | 任务 $_missions 个');
  }

  String _val(String s) => s.replaceAll("\\'", "'").replaceAll("\\\\", "\\");

  void _extractCards(String path) {
    if (!File(path).existsSync()) return;
    final txt = File(path).readAsStringSync();
    final re = RegExp(
        r"Card\([^)]*?id\s*:\s*'([^']+)'[^)]*?name\s*:\s*'([^']*)'[^)]*?description\s*:\s*'([^']*)'[^)]*?flavor\s*:\s*'([^']*)'",
        dotAll: true);
    var n = 0;
    for (final m in re.allMatches(txt)) {
      final id = m.group(1)!;
      _json['card.$id.name'] = _val(m.group(2)!);
      _json['card.$id.description'] = _val(m.group(3)!);
      _json['card.$id.flavor'] = _val(m.group(4)!);
      _count += 3;
      n++;
    }
    _cards += n;
    print('  $path: $n cards');
  }

  void _extractHeroes(String path) {
    if (!File(path).existsSync()) return;
    final txt = File(path).readAsStringSync();
    final re = RegExp(
        r"Hero\([^)]*?id\s*:\s*'([^']+)'[^)]*?name\s*:\s*'([^']*)'[^)]*?heroPowerName\s*:\s*'([^']*)'[^)]*?heroPowerDescription\s*:\s*'([^']*)'[^)]*?flavor\s*:\s*'([^']*)'",
        dotAll: true);
    var n = 0;
    for (final m in re.allMatches(txt)) {
      final id = m.group(1)!;
      _json['hero.$id.name'] = _val(m.group(2)!);
      _json['hero.$id.powerName'] = _val(m.group(3)!);
      _json['hero.$id.powerDescription'] = _val(m.group(4)!);
      _json['hero.$id.flavor'] = _val(m.group(5)!);
      _count += 4;
      n++;
    }
    _heroes += n;
    print('  $path: $n heroes');
  }

  void _extractMissions(String path) {
    if (!File(path).existsSync()) return;
    final txt = File(path).readAsStringSync();
    var re = RegExp(
        r"AdventureChapter\([^)]*?id\s*:\s*'([^']+)'[^)]*?name\s*:\s*'([^']*)'[^)]*?description\s*:\s*'([^']*)'",
        dotAll: true);
    for (final m in re.allMatches(txt)) {
      _json['chapter.${m.group(1)}.name'] = _val(m.group(2)!);
      _json['chapter.${m.group(1)}.description'] = _val(m.group(3)!);
      _count += 2;
    }
    re = RegExp(
        r"AdventureMission\([^)]*?id\s*:\s*'([^']+)'[^)]*?name\s*:\s*'([^']*)'[^)]*?description\s*:\s*'([^']*)'",
        dotAll: true);
    var n = 0;
    for (final m in re.allMatches(txt)) {
      _json['mission.${m.group(1)}.name'] = _val(m.group(2)!);
      _json['mission.${m.group(1)}.description'] = _val(m.group(3)!);
      _count += 2;
      n++;
    }
    _missions += n;
    print('  $path: $n missions + chapters');
  }

  void _addUiStrings() {
    final ui = <String, String>{
      // Home
      'home.title': '战国卡牌',
      'home.subtitle': 'Warring States Card',
      'home.btn_battle': '开始对战',
      'home.btn_training': '训练模式',
      'home.btn_adventure': '冒险模式',
      'home.btn_pack': '开包',
      'home.btn_collection': '收藏',
      'home.btn_leaderboard': '排行榜',
      'home.version': 'v1.0.0',
      'home.language': '语言',
      'home.lang_zh': '简体中文',
      'home.lang_zh_TW': '繁體中文',
      'home.lang_en': 'English',
      'home.remove_ads': '移除广告',
      'home.buy_gold': '购买金币',
      // Adventure
      'adventure.title': '冒险模式',
      'adventure.progress': '总进度',
      'adventure.boss': 'BOSS',
      'adventure.error_no_enemy': '找不到敌人英雄: {heroId}',
      'difficulty.easy': '简单',
      'difficulty.normal': '普通',
      'difficulty.hard': '困难',
      'difficulty.extreme': '极难',
      // Pack
      'pack.title': '开包',
      'pack.pack_name': '战国卡包',
      'pack.btn_open': '开包 (50💰)',
      'pack.btn_open_ad': '看广告免费开包 >',
      'pack.gold_insufficient': '金币不足！完成冒险关卡获得金币',
      'pack.opened_cards': '开出卡牌',
      'pack.btn_again': '再来一包',
      'pack.gold_price': '50💰/包',
      // Collection
      'collection.title': '收藏',
      'collection.empty': '还没有卡牌，去开包吧！',
      'collection.close': '关闭',
      'owner.bingjia': '兵',
      'owner.fajia': '法',
      'owner.rujia': '儒',
      'owner.daojia': '道',
      'owner.mojia': '墨',
      'owner.yinyangjia': '阴阳',
      'owner.zonghengjia': '纵横',
      'owner.neutral': '中',
      // Game
      'game.victory': '胜利',
      'game.defeat': '失败',
      'game.end_turn': '结束回合',
      'game.your_turn': '你的回合',
      'game.opponent_turn': '对手回合',
      'game.hand': '手牌',
      'game.battlefield': '战场',
      'game.mana': '法力水晶',
      'game.hero_power': '英雄技能',
      'game.btn_return': '返回主菜单',
      'game.btn_rematch': '再来一局',
      'game.ad_revive': '看广告复活',
      'game.ad_gold_bonus': '双倍金币',
      // Leaderboard
      'leaderboard.title': '排行榜',
      'leaderboard.coming_soon': '排行榜即将上线',
      'leaderboard.hint': '在冒险模式中通关获取积分',
      // Hero Select
      'hero_select.title': '选择英雄',
      'hero_select.hero_power': '英雄技能',
      // IAP
      'iap.title': '商店',
      'iap.remove_ads': '移除广告',
      'iap.remove_ads_desc': '永久移除所有广告',
      'iap.gold_small': '100 金币',
      'iap.gold_small_desc': '小包金币',
      'iap.gold_medium': '500 金币',
      'iap.gold_medium_desc': '中包金币',
      'iap.gold_large': '1200 金币',
      'iap.gold_large_desc': '大包金币',
      'iap.purchase_success': '购买成功！',
      'iap.purchase_failed': '购买失败，请重试',
      // Ad
      'ad.watch_reward': '观看广告获得奖励',
      'ad.loading': '广告加载中...',
      'ad.error': '广告加载失败',
      // Common
      'common.cancel': '取消',
      'common.confirm': '确认',
      'common.back': '返回',
      'common.loading': '加载中...',
    };
    for (final e in ui.entries) {
      _json[e.key] = e.value;
      _count++;
    }
    print('  UI strings: ${ui.length}');
  }
}
