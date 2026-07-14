import 'dart:math';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/card_image_service.dart' show CardImageService;
import '../../data/balance_service.dart';
import '../../data/data_version.dart';
import '../../data/persistence/save_manager.dart';
import '../../domain/models/card.dart' as cm;
import '../../domain/services/card_data_provider.dart';
import '../../domain/services/hero_data_provider.dart';
import '../../domain/services/purchase_service.dart';
import '../../data/xsolla_payment_service.dart';
import '../providers/auth_provider.dart';

/// 商店 — 金币/钻石/卡包/单卡/英雄/每日特惠
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  PlayerData? _data;
  bool _loading = true;
  bool _dailyDealBought = false;
  // 折叠状态
  bool _cardShopExpanded = true;
  bool _heroShopExpanded = true;
  bool _goldExpanded = true;
  // 缓存刷新
  String _cardShopCache = '';
  String _heroShopCache = '';

  @override
  void initState() { super.initState(); _load(); dataVersionNotifier.addListener(_load); }

  Future<void> _load() async {
    final d = await SaveManager.loadPlayerData();
    final tk = 'ddeal_${DateTime.now().month}_${DateTime.now().day}';
    // 刷新种子：卡牌商店每2h，英雄商店每8h
    _cardShopCache = 'cs_${_cycleKey(2)}';
    _heroShopCache = 'hs_${_cycleKey(8)}';
    if (mounted) setState(() { _data = d; _dailyDealBought = d?.stats[tk] != null; _loading = false; });
  }

  @override
  void dispose() { super.dispose(); dataVersionNotifier.removeListener(_load); }

  /// 刷新周期 key：当前时间 / hours 取整
  String _cycleKey(int hours) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return (ms ~/ (hours * 3600000)).toString();
  }

  Future<void> _refresh() async {
    final d = await SaveManager.loadPlayerData();
    if (mounted) setState(() => _data = d);
  }

  Future<bool> _spendGold(int a) async {
    if (!await _requireLogin()) return false;
    if (_data == null || _data!.gold < a) { _snack('金币不足'); return false; }
    final odID = ref.read(authProvider)?.playerId ?? '';
    final ok = await BalanceService.spendGold(odID, a, detail: '消费$a金币');
    if (!ok) { _snack('操作失败'); return false; }
    bumpDataVersion(); await _refresh(); return true;
  }

  Future<bool> _spendGems(int a) async {
    if (!await _requireLogin()) return false;
    if (_data == null || _data!.gems < a) { _snack('钻石不足'); return false; }
    final odID = ref.read(authProvider)?.playerId ?? '';
    final ok = await BalanceService.spendGems(odID, a, detail: '消费$a钻石');
    if (!ok) { _snack('操作失败'); return false; }
    bumpDataVersion(); await _refresh(); return true;
  }

  void _snack(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }

  /// 检查登录状态，未登录则弹窗引导登录
  Future<bool> _requireLogin() async {
    if (ref.read(authProvider) != null) return true;
    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: const Text('需要登录', style: TextStyle(color: AppTheme.parchment)),
        content: const Text('购买前需要先登录/注册', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent),
            child: const Text('登录/注册', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      context.push('/auth/login');
    }
    return false;
  }

  // ===== 卡包 =====
  Future<void> _buyPackNormal() async {
    if (!await _spendGold(500)) return;
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
    // 普通卡包：最多3张，全是普通
    final commons = all.where((c) => c.rarity == cm.Rarity.common && !owned.contains(c.id)).toList()..shuffle();
    final picks = <cm.Card>[];
    picks.addAll(commons.take(min(3, commons.length)));
    if (picks.isEmpty) { picks.addAll((all..shuffle()).take(3)); }
    _finishPack(picks, '普通卡包', _data!.gold);
  }

  Future<void> _buyPackRare() async {
    if (!await _spendGold(1000)) return;
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
    // 稀有卡包：最多4张，稀有最多50%（2张），其余普通
    final rares = all.where((c) => c.rarity == cm.Rarity.rare && !owned.contains(c.id)).toList()..shuffle();
    final commons = all.where((c) => c.rarity == cm.Rarity.common && !owned.contains(c.id)).toList()..shuffle();
    final picks = <cm.Card>[];
    final rareCount = min(Random().nextInt(3) + 1, rares.length); // 1-2张稀有
    picks.addAll(rares.take(rareCount));
    final commonCount = min(4 - rareCount, commons.length);
    picks.addAll(commons.take(commonCount));
    if (picks.isEmpty) { picks.addAll((all..shuffle()).take(4)); }
    _finishPack(picks, '稀有卡包', _data!.gold);
  }

  Future<void> _buyPackEpic() async {
    if (!await _spendGold(2000)) return;
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
    // 史诗卡包：最多4张，史诗50%概率1张+随机金币20-100
    final epics = all.where((c) => c.rarity == cm.Rarity.epic && !owned.contains(c.id)).toList()..shuffle();
    final rares = all.where((c) => c.rarity == cm.Rarity.rare && !owned.contains(c.id)).toList()..shuffle();
    final commons = all.where((c) => c.rarity == cm.Rarity.common && !owned.contains(c.id)).toList()..shuffle();
    final picks = <cm.Card>[];
    if (Random().nextBool() && epics.isNotEmpty) picks.add(epics.first);
    final rareCount = min(3 - picks.length, rares.length);
    picks.addAll(rares.take(rareCount));
    final commonCount = min(4 - picks.length, commons.length);
    picks.addAll(commons.take(commonCount));
    if (picks.isEmpty) { picks.addAll((all..shuffle()).take(4)); }
    final bonusGold = 20 + Random().nextInt(81); // 20-100
    _finishPack(picks, '史诗卡包', _data!.gold, bonusGold: bonusGold);
  }

  Future<void> _buyPackLegendary() async {
    if (!await _spendGold(5000)) return;
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
    final rng = Random();
    // 传说卡包：3-5张，传说5%最多1，史诗30%最多1，稀有+普通若干
    final legends = all.where((c) => c.rarity == cm.Rarity.legendary && !owned.contains(c.id)).toList()..shuffle();
    final epics = all.where((c) => c.rarity == cm.Rarity.epic && !owned.contains(c.id)).toList()..shuffle();
    final rares = all.where((c) => c.rarity == cm.Rarity.rare && !owned.contains(c.id)).toList()..shuffle();
    final commons = all.where((c) => c.rarity == cm.Rarity.common && !owned.contains(c.id)).toList()..shuffle();
    final picks = <cm.Card>[];
    final total = rng.nextInt(3) + 3; // 3-5张
    if (rng.nextDouble() < 0.05 && legends.isNotEmpty) picks.add(legends.first);
    if (rng.nextDouble() < 0.30 && epics.isNotEmpty && picks.where((c) => c.rarity == cm.Rarity.epic).isEmpty) picks.add(epics.first);
    final remaining = total - picks.length;
    final rareCount = min(remaining > 1 ? rng.nextInt(remaining) + 1 : remaining, rares.length);
    picks.addAll(rares.take(rareCount));
    final commonCount = min(total - picks.length, commons.length);
    picks.addAll(commons.take(commonCount));
    if (picks.length < total || picks.isEmpty) {
      final fill = (all..shuffle()).where((c) => !picks.contains(c)).take(total - picks.length).toList();
      picks.addAll(fill);
    }
    final bonusGold = 500 + rng.nextInt(1001); // 500-1500
    _finishPack(picks, '传说卡包', _data!.gold, bonusGold: bonusGold);
  }

  void _finishPack(List<cm.Card> picks, String label, int currentGold, {int bonusGold = 0}) async {
    final ids = [..._data!.unlockedCards, ...picks.map((c) => c.id)];
    final pd = _data!.copyWith(unlockedCards: ids, gold: currentGold);
    SaveManager.savePlayerData(pd);
    if (bonusGold > 0) {
      final odID = ref.read(authProvider)?.playerId ?? '';
      if (odID.isNotEmpty) {
        await BalanceService.addGold(odID, bonusGold, detail: '$label奖励金币');
      }
    }
    bumpDataVersion();
    _refresh();
    if (!mounted) return;
    _showPackResult(picks, bonusGold > 0 ? '$label (+$bonusGold💰)' : label);
  }

  void _showPackResult(List<cm.Card> picks, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.goldAccent.withAlpha(80)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: const TextStyle(color: AppTheme.goldAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...picks.map((c) {
              final imgPath = CardImageService.getImageByType(c.id, _typeEng(c));
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _rc(c.rarity).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _rc(c.rarity).withAlpha(60)),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(width: 36, height: 48,
                      child: imgPath.isNotEmpty
                          ? Image.asset(imgPath, fit: BoxFit.cover, alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => _imgPlaceholder(c))
                          : _imgPlaceholder(c),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(_rn(c.rarity), style: TextStyle(color: _rc(c.rarity), fontSize: 11)),
                  ])),
                ]),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent),
                child: const Text('好的', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _imgPlaceholder(cm.Card c) => Container(
    color: _rc(c.rarity).withAlpha(80),
    child: Center(child: Text(c.name[0], style: TextStyle(color: _rc(c.rarity), fontSize: 16))),
  );

  void _buySingleCard(cm.Card card) async {
    final price = _cardPrice(card);
    if (!await _spendGold(price)) return;
    final ids = [..._data!.unlockedCards, card.id];
    await SaveManager.savePlayerData(_data!.copyWith(unlockedCards: ids));
    bumpDataVersion();
    _snack('购买成功！获得 ${card.name}');
    await _refresh();
  }

  int _cardPrice(cm.Card c) {
    // 保底100，按稀有度+属性
    int base;
    switch (c.rarity) {
      case cm.Rarity.common: base = 100;
      case cm.Rarity.rare: base = 300;
      case cm.Rarity.epic: base = 800;
      case cm.Rarity.legendary: base = 2000;
    }
    if (c.isMinion && c.attack >= 5) base += 200;
    if (c.isMinion && c.health >= 6) base += 200;
    if (c.keywords.isNotEmpty) base += (c.keywords.length * 150);
    return base;
  }

  StreamSubscription<String>? _restoreSub;

  /// 监听恢复购买事件（重装后恢复已购买的钻石）
  void _initRestoreListener() {
    _restoreSub?.cancel();
    _restoreSub = PurchaseService.I.restoredStream.listen((productId) async {
      const gemMap = {'gem_60': 60, 'gem_300': 300, 'gem_600': 600, 'gem_1500': 1500, 'gem_3000': 3000};
      final ga = gemMap[productId];
      if (ga == null) return;
      final total = ga + _gemBonus(ga);
      final odID = ref.read(authProvider)?.playerId ?? '';
      if (odID.isNotEmpty) {
        await BalanceService.addGems(odID, total, detail: '恢复购买');
      }
      _snack('恢复购买成功！获得 $total 钻石');
    });
  }

  void _buyGem(int ga) async {
    try {
      if (!await _requireLogin()) return;
      final auth = ref.read(authProvider);
      if (auth == null) { _snack('请先登录'); return; }
      final sku = _gemProductId(ga);
      final bonus = _gemBonus(ga);
      final total = ga + bonus;

      // 尝试 Xsolla → 失败自动降级到旧 IAP
      final xsollaOk = await XsollaPaymentService.I.purchase(auth.playerId, auth.token, sku: sku);
      if (xsollaOk) {
        _snack('支付页面已打开，完成支付后请返回刷新');
        await Future.delayed(const Duration(seconds: 3));
        await _refresh();
        return;
      }

      // 降级：旧 IAP (Apple/Google)
      _initRestoreListener();
      final pid = _gemProductId(ga);
      final ok = await PurchaseService.I.purchase(pid);
      if (!ok) { _snack('购买失败'); return; }
      final odID = auth.playerId;
      final result = await BalanceService.addGems(odID, total, detail: '购买${ga}钻石');
      if (result) {
        bumpDataVersion();
        await _refresh();
        _snack('购买成功！获得 $total 钻石');
      } else {
        _snack('购买成功但同步失败，请重试');
      }
    } catch (_) { _snack('购买失败'); }
  }

  Future<void> _restorePurchases() async {
    _initRestoreListener();
    final ok = await PurchaseService.I.restorePurchases();
    if (ok) {
      _snack('正在恢复购买...');
      await Future.delayed(const Duration(seconds: 2));
      await _refresh();
    } else {
      _snack('没有可恢复的购买记录');
    }
  }

  String _gemProductId(int ga) {
    const map = {60: 'gem_60', 300: 'gem_300', 600: 'gem_600', 1500: 'gem_1500', 3000: 'gem_3000'};
    return map[ga] ?? 'gem_60';
  }

  // ─── 赠送配置：修改此处即可调整各档位赠送额，不影响 SKU 映射 ───
  static int _gemBonus(int ga) {
    const bonus = {60: 0, 300: 50, 600: 150, 1500: 500, 3000: 1500};
    return bonus[ga] ?? 0;
  }

  Widget _gemCard(int diamonds, double usd, String? bonus) {
    final bonusActual = _gemBonus(diamonds);
    final total = diamonds + bonusActual;
    final eff = usd > 0 ? (total / usd).round() : 0;
    final subtitle = bonusActual > 0
        ? '\$${usd.toStringAsFixed(2)} ($eff💎/\$) · 送${bonusActual}颗'
        : '\$${usd.toStringAsFixed(2)} ($eff💎/\$)';
    final title = bonusActual > 0
        ? '${diamonds}+${bonusActual}钻石'
        : '${diamonds}钻石';
    return _card(Icons.diamond, title, subtitle,
        Text('\$${usd.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        () => _buyGem(diamonds));
  }

  // 钻石→金币：10:1
  Future<void> _buyGoldBundle(int gemsCost, int goldReward) async {
    if (!await _requireLogin()) return;
    final odID = ref.read(authProvider)?.playerId ?? '';
    if (!await _spendGems(gemsCost)) return;
    final ok = await BalanceService.addGold(odID, goldReward, detail: '兑换$goldReward金币');
    if (ok) { _snack('兑换成功！获得 $goldReward💰'); } else { _snack('兑换失败'); }
    bumpDataVersion(); await _refresh();
  }

  // ===== 每日特惠 =====
  void _buyDailyDeal() async {
    if (_dailyDealBought) return;
    final deals = [
      ('普通卡包', 350, 5),
      ('稀有卡包', 700, 3),
      ('史诗卡包', 1400, 2),
      ('传说卡包', 3500, 1),
    ];
    final deal = deals[DateTime.now().day % deals.length];
    final cost = deal.$2;
    if (_data == null || _data!.gold < cost) { _snack('金币不足'); return; }
    // 扣费+开包（不经过 _buyPack 的 _spendGold，避免双重扣费）
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
    var pool = all.where((c) => !owned.contains(c.id)).toList()..shuffle();
    if (pool.isEmpty) pool = (all..shuffle()).toList();
    final picks = pool.take(deal.$3).toList();
    await SaveManager.savePlayerData(_data!.copyWith(gold: _data!.gold - cost,
        unlockedCards: [..._data!.unlockedCards, ...picks.map((c) => c.id)]));
    bumpDataVersion();
    await _refresh();
    final tk = 'ddeal_${DateTime.now().month}_${DateTime.now().day}';
    final ns = Map<String, int>.from(_data!.stats);
    ns[tk] = 1;
    await SaveManager.savePlayerData(_data!.copyWith(stats: ns));
    bumpDataVersion();
    setState(() => _dailyDealBought = true);
    await _refresh();
    if (!mounted) return;
    _showPackResult(picks, '🔥 每日特惠 · ${deal.$1}');
  }

  void _buyHero(String hid, int cost) async {
    if (_data!.unlockedHeroes.contains(hid)) return;
    if (_data!.gold >= cost) {
      await SaveManager.savePlayerData(_data!.copyWith(gold: _data!.gold - cost,
          unlockedHeroes: [..._data!.unlockedHeroes, hid]));
      bumpDataVersion();
    } else { _snack('金币不足'); return; }
    await _refresh(); _snack('购买成功！');
  }

  int _heroPrice(String hid) {
    // 英雄远贵于卡牌（卡牌最贵传说2000，英雄基础3000起）
    const p = {'H_B001': 8000, 'H_B002': 12000, 'H_B003': 20000, 'H_F001': 10000,
      'H_F002': 12000, 'H_F003': 18000, 'H_R001': 8000, 'H_R002': 12000, 'H_R003': 20000,
      'H_D001': 8000, 'H_D002': 12000, 'H_D003': 18000, 'H_M001': 10000, 'H_M002': 12000,
      'H_M003': 18000, 'H_Y001': 12000, 'H_Y002': 18000, 'H_Y003': 20000,
      'H_Z001': 10000, 'H_Z002': 12000, 'H_Z003': 25000};
    return p[hid] ?? 12000;
  }

  String _dealLabel() {
    final deals = ['普通卡包 · 7折', '稀有卡包 · 7折', '史诗卡包 · 7折', '传说卡包 · 7折'];
    return deals[DateTime.now().day % deals.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('商店', style: TextStyle(color: AppTheme.parchment)),
          backgroundColor: AppTheme.agedWood, foregroundColor: AppTheme.parchment),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BalanceBar(gold: _data?.gold ?? 0, gems: _data?.gems ?? 0),
          const SizedBox(height: 16),

          // 每日特惠
          _sec('每日特惠'),
          _card(Icons.card_giftcard, _dealLabel(), '每日限购1份',
              _dailyDealBought ? const Text('已购买', style: TextStyle(color: AppTheme.healGreen, fontSize: 13))
                  : const Text('🔥', style: TextStyle(color: AppTheme.healthRed, fontSize: 18)),
              _dailyDealBought ? null : _buyDailyDeal),
          const SizedBox(height: 16),

          // === 卡牌商店（可折叠，每2h刷新） ===
          _foldable('卡牌商店', _cardShopExpanded, (v) => setState(() => _cardShopExpanded = v),
              '每2小时刷新 · ${_cardShopCache.hashCode % 100}'),
          if (_cardShopExpanded) ...[
            _card(Icons.card_giftcard, '普通卡包', '最多3张普通卡', const Text('500💰', style: TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackNormal),
            _card(Icons.card_giftcard, '稀有卡包', '最多4张·稀有50%概率1-2张', const Text('1000💰', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackRare),
            _card(Icons.card_giftcard, '史诗卡包', '4张·史诗50%·附赠20-100💰', const Text('2000💰', style: TextStyle(color: Colors.purple, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackEpic),
            _card(Icons.card_giftcard, '传说卡包', '1-5张·传说5%·附赠500-1500💰', const Text('5000💰', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackLegendary),
            ..._buildCardShop(),
          ],
          const SizedBox(height: 16),

          // === 钻石 ===
          _sec('钻石'),
          _gemCard(60, 0.99, null),
          const SizedBox(height: 6),
          _gemCard(300, 4.99, null),
          const SizedBox(height: 6),
          _gemCard(600, 9.99, null),
          const SizedBox(height: 6),
          _gemCard(1500, 19.99, null),
          const SizedBox(height: 6),
          _gemCard(3000, 29.99, null),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _restorePurchases,
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('恢复购买记录'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          // === 金币 ===
          _foldable('金币', _goldExpanded, (v) => setState(() => _goldExpanded = v), '100💎=1000💰'),
          if (_goldExpanded) ...[
            _card(Icons.monetization_on, '1000金币', '100💎兑换', const Text('100💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldBundle(100, 1000)),
            const SizedBox(height: 4),
            _card(Icons.monetization_on, '5000金币', '500💎兑换', const Text('500💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldBundle(500, 5000)),
            const SizedBox(height: 4),
            _card(Icons.monetization_on, '10000金币', '1000💎兑换', const Text('1000💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldBundle(1000, 10000)),
          ],
          const SizedBox(height: 16),

          // === 英雄商店（可折叠，每8h刷新） ===
          _foldable('英雄商店', _heroShopExpanded, (v) => setState(() => _heroShopExpanded = v),
              '每8小时刷新 · ${_heroShopCache.hashCode % 100}'),
          if (_heroShopExpanded) ..._heroShop(),
          const SizedBox(height: 16),

          Center(child: TextButton(
            onPressed: () async { await PurchaseService.I.restorePurchases(); _snack('已恢复购买记录'); },
            child: const Text('恢复购买', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          )),
        ],
      )),
    );
  }

  Widget _sec(String t) => Text(t, style: const TextStyle(
      color: AppTheme.goldAccent, fontSize: 15, fontWeight: FontWeight.bold));

  Widget _foldable(String t, bool expanded, ValueChanged<bool> onToggle, String subtitle) {
    return GestureDetector(
      onTap: () => onToggle(!expanded),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text(t, style: const TextStyle(color: AppTheme.goldAccent, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const Spacer(),
          Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.goldAccent),
        ]),
      ),
    );
  }

  Widget _card(IconData ic, String t, String sub, Widget trail, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(13),
          decoration: AppTheme.panelDecoration(), margin: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(ic, color: AppTheme.goldAccent, size: 24), const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ])),
            trail,
          ])),
    );
  }

  // ===== 卡牌商店：每2h刷新 =====
  List<Widget> _buildCardShop() {
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data?.unlockedCards ?? []);
    final rng = Random(_cardShopCache.hashCode);
    final pool = all.where((c) => c.rarity != cm.Rarity.common).toList()..shuffle(rng);
    if (pool.isEmpty) return [const Padding(padding: EdgeInsets.all(8), child: Text('暂无推荐', style: TextStyle(color: AppTheme.textMuted)))];
    return pool.take(6).map((c) {
      final price = _cardPrice(c);
      final imgPath = CardImageService.getImageByType(c.id, _typeEng(c));
      final isOwned = owned.contains(c.id);
      final borderColor = _rc(c.rarity);
      return GestureDetector(
        onTap: isOwned ? null : () => _buySingleCard(c),
        child: Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: AppTheme.cardBack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isOwned ? borderColor.withAlpha(80) : borderColor.withAlpha(200), width: isOwned ? 1.5 : 2),
          ),
          child: Opacity(
            opacity: isOwned ? 0.5 : 1.0,
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(width: 36, height: 48,
                  child: imgPath.isNotEmpty
                      ? Image.asset(imgPath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: borderColor.withAlpha(80),
                              child: Center(child: Text(c.name[0], style: TextStyle(color: borderColor, fontSize: 16)))))
                      : Container(color: borderColor.withAlpha(80),
                          child: Center(child: Text(c.name[0], style: TextStyle(color: borderColor, fontSize: 16)))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: TextStyle(color: isOwned ? AppTheme.textMuted : AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${_rn(c.rarity)} · ${_ownerName(c.owner)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ])),
              if (isOwned)
                const Text('已拥有', style: TextStyle(color: AppTheme.textMuted, fontSize: 11))
              else
                Text('$price💰', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
    }).toList();
  }

  String _typeEng(cm.Card c) => switch (c.type) {
    cm.CardType.minion => 'minion', cm.CardType.spell => 'spell', cm.CardType.weapon => 'weapon',
  };

  String _ownerName(cm.CardOwner o) => switch (o) {
    cm.CardOwner.bingjia => '兵家', cm.CardOwner.fajia => '法家',
    cm.CardOwner.rujia => '儒家', cm.CardOwner.daojia => '道家',
    cm.CardOwner.mojia => '墨家', cm.CardOwner.yinyangjia => '阴阳家',
    cm.CardOwner.zonghengjia => '纵横家', cm.CardOwner.neutral => '中立',
  };

  // ===== 英雄商店：每8h刷新 =====
  List<Widget> _heroShop() {
    final all = HeroDataProvider.getAllHeroes();
    final owned = Set<String>.from(_data?.unlockedHeroes ?? []);
    final rng = Random(_heroShopCache.hashCode);
    final pool = all.toList()..shuffle(rng); // 不再过滤已拥有，保留展示
    if (pool.isEmpty) return [const Padding(padding: EdgeInsets.all(8), child: Text('英雄已全部解锁', style: TextStyle(color: AppTheme.textMuted)))];
    return pool.take(4).map((h) {
      final p = _heroPrice(h.id);
      final heroImg = CardImageService.getHeroImageAsset(h.id);
      final isOwned = owned.contains(h.id);
      return GestureDetector(
        onTap: isOwned ? null : () => _buyHero(h.id, p),
        child: Opacity(
          opacity: isOwned ? 0.5 : 1.0,
          child: Container(padding: const EdgeInsets.all(11), margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardBack, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isOwned ? AppTheme.textMuted.withAlpha(80) : AppTheme.goldAccent.withAlpha(150), width: 1.5),
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(width: 36, height: 36,
                    child: heroImg.isNotEmpty
                        ? Image.asset(heroImg, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(color: AppTheme.goldAccent.withAlpha(40),
                                child: Center(child: Text(h.name[0], style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16)))))
                        : Container(color: AppTheme.goldAccent.withAlpha(40),
                            child: Center(child: Text(h.name[0], style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16)))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.name, style: TextStyle(color: isOwned ? AppTheme.textMuted : AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${h.className} · ${h.kingdom}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ])),
                if (isOwned)
                  const Text('已拥有', style: TextStyle(color: AppTheme.textMuted, fontSize: 11))
                else
                  Text('$p💰', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              ])),
        ),
      );
    }).toList();
  }

  Color _rc(cm.Rarity r) => switch (r) {
    cm.Rarity.common => Colors.grey, cm.Rarity.rare => Colors.blue,
    cm.Rarity.epic => Colors.purple, cm.Rarity.legendary => Colors.orange,
  };
  String _rn(cm.Rarity r) => switch (r) {
    cm.Rarity.common => '普通', cm.Rarity.rare => '稀有',
    cm.Rarity.epic => '史诗', cm.Rarity.legendary => '传说',
  };
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.gold, required this.gems});
  final int gold; final int gems;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.cardBack, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGold.withAlpha(80))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Row(children: [
          const Icon(Icons.monetization_on, color: AppTheme.goldAccent, size: 22),
          const SizedBox(width: 6),
          Text('$gold', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        Row(children: [
          const Icon(Icons.diamond, color: AppTheme.manaBlue, size: 22),
          const SizedBox(width: 6),
          Text('$gems', style: const TextStyle(color: AppTheme.manaBlue, fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}