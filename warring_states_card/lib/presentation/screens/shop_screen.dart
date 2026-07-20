import 'dart:math';
import 'dart:io' show Platform;

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../l10n/locale_service.dart';
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
    if (_data == null || _data!.gold < a) { _snack(LocaleService.I.t('shop.gold_insufficient_short')); return false; }
    final odID = ref.read(authProvider)?.playerId ?? '';
    final ok = await BalanceService.spendGold(odID, a, detail: '消费$a金币');
    if (!ok) { _snack(LocaleService.I.t('shop.op_failed')); return false; }
    bumpDataVersion(); await _refresh(); return true;
  }

  Future<bool> _spendGems(int a) async {
    if (!await _requireLogin()) return false;
    if (_data == null || _data!.gems < a) { _snack(LocaleService.I.t('shop.gems_insufficient_short')); return false; }
    final odID = ref.read(authProvider)?.playerId ?? '';
    final ok = await BalanceService.spendGems(odID, a, detail: '消费$a钻石');
    if (!ok) { _snack(LocaleService.I.t('shop.op_failed')); return false; }
    bumpDataVersion(); await _refresh(); return true;
  }

  void _snack(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }

  /// 检查登录状态，未登录则弹窗引导登录
  Future<bool> _requireLogin() async {
    if (ref.read(authProvider) != null) return true;
    return _promptAccount(LocaleService.I.t('shop.need_login_title'), LocaleService.I.t('shop.need_login_desc'));
  }

  /// 游客禁止购买；仅注册且带有效邮箱的账号可支付
  Future<bool> _requirePaidAccount() async {
    final auth = ref.read(authProvider);
    if (auth?.email?.isNotEmpty == true) return true;
    return _promptAccount(LocaleService.I.t('shop.need_account_title'), LocaleService.I.t('shop.need_account_desc'));
  }

  Future<bool> _promptAccount(String title, String message) async {
    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.agedWood,
        title: Text(title, style: const TextStyle(color: AppTheme.parchment)),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocaleService.I.t('shop.cancel'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent),
            child: Text(LocaleService.I.t('shop.login_register'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (go == true && mounted) context.push('/auth/login');
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
    _finishPack(picks, LocaleService.I.t('shop.pack_normal'), _data!.gold);
  }

  Future<void> _buyPackRare() async {
    if (!await _spendGold(1000)) return;
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
    final rares = all.where((c) => c.rarity == cm.Rarity.rare && !owned.contains(c.id)).toList()..shuffle();
    final commons = all.where((c) => c.rarity == cm.Rarity.common && !owned.contains(c.id)).toList()..shuffle();
    final picks = <cm.Card>[];
    final rareCount = min(Random().nextInt(3) + 1, rares.length); // 1-2张稀有
    picks.addAll(rares.take(rareCount));
    final commonCount = min(4 - rareCount, commons.length);
    picks.addAll(commons.take(commonCount));
    if (picks.isEmpty) { picks.addAll((all..shuffle()).take(4)); }
    _finishPack(picks, LocaleService.I.t('shop.pack_rare'), _data!.gold);
  }

  Future<void> _buyPackEpic() async {
    if (!await _spendGold(2000)) return;
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
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
    final bonusGold = 20 + Random().nextInt(81);
    _finishPack(picks, LocaleService.I.t('shop.pack_epic'), _data!.gold, bonusGold: bonusGold);
  }

  Future<void> _buyPackLegendary() async {
    if (!await _spendGold(5000)) return;
    final all = CardDataProvider.getAllCards();
    final owned = Set<String>.from(_data!.unlockedCards);
    final rng = Random();
    final legends = all.where((c) => c.rarity == cm.Rarity.legendary && !owned.contains(c.id)).toList()..shuffle();
    final epics = all.where((c) => c.rarity == cm.Rarity.epic && !owned.contains(c.id)).toList()..shuffle();
    final rares = all.where((c) => c.rarity == cm.Rarity.rare && !owned.contains(c.id)).toList()..shuffle();
    final commons = all.where((c) => c.rarity == cm.Rarity.common && !owned.contains(c.id)).toList()..shuffle();
    final picks = <cm.Card>[];
    final total = rng.nextInt(3) + 3;
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
    final bonusGold = 500 + rng.nextInt(1001);
    _finishPack(picks, LocaleService.I.t('shop.pack_legendary'), _data!.gold, bonusGold: bonusGold);
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
                child: Text(LocaleService.I.t('shop.good'), style: const TextStyle(color: Colors.white)),
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
    _snack(LocaleService.I.t('shop.purchase_success_name', args: {'name': card.name}));
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

  StreamSubscription<PurchaseResult>? _restoreSub;

  /// 监听恢复购买事件 — 上传 receipt 到后端验证，不等价加分
  void _initRestoreListener() {
    _restoreSub?.cancel();
    _restoreSub = PurchaseService.I.restoredStream.listen((result) async {
      if (!result.success) {
        _snack(result.error ?? LocaleService.I.t('shop.restore_failed'));
        return;
      }
      final auth = ref.read(authProvider);
      if (auth == null || result.productId == null || result.receipt == null) {
        _snack(LocaleService.I.t('shop.restore_failed_desc'));
        return;
      }
      final resp = await BalanceService.verifyIAPReceipt(
        playerId: auth.playerId,
        token: auth.token,
        receipt: result.receipt!,
        productId: result.productId!,
        transactionId: result.transactionId,
      );
      if (resp != null && resp.success) {
        bumpDataVersion();
        await _refresh();
        _snack(LocaleService.I.t('shop.restore_success', args: {'gems': '${resp.gems}'}));
      } else {
        _snack(LocaleService.I.t('shop.restore_verify_failed'));
      }
    });
  }

  /// iOS → Apple IAP（合规）；Web → Xsolla；Android → Xsolla 优先，降级 IAP
  void _buyGem(int ga) async {
    try {
      if (!await _requirePaidAccount()) return;
      final auth = ref.read(authProvider);
      if (auth == null) { _snack(LocaleService.I.t('shop.please_login')); return; }
      // iOS：强制 Apple IAP
      if (!kIsWeb && Platform.isIOS) {
        await _buyIAP(ga);
        return;
      }

      // Web / Android：Xsolla
      final sku = _gemProductId(ga);
      final ok = await XsollaPaymentService.I.purchase(auth.playerId, auth.token, sku: sku);
      if (ok) {
        _snack('支付页面已打开，完成支付后请刷新');
        await Future.delayed(const Duration(seconds: 3));
        await _refresh();
        return;
      }

      // Android：Xsolla 失败 → 降级 Google IAP
      if (!kIsWeb) await _buyIAP(ga);
    } catch (_) { _snack(LocaleService.I.t('shop.buy_failed_generic')); }
  }

  Future<void> _buyIAP(int ga) async {
    final pid = _gemProductId(ga);
    final result = await PurchaseService.I.purchase(pid);
    if (!result.success) {
      _snack(result.error ?? LocaleService.I.t('shop.buy_failed_generic'));
      return;
    }
    if (result.receipt == null || result.productId == null) {
      _snack(LocaleService.I.t('shop.buy_failed_receipt'));
      return;
    }
    final auth = ref.read(authProvider);
    if (auth == null) { _snack('请先注册并登录'); return; }
    final resp = await BalanceService.verifyIAPReceipt(
      playerId: auth.playerId,
      token: auth.token,
      receipt: result.receipt!,
      productId: result.productId!,
      transactionId: result.transactionId,
    );
    if (resp != null && resp.success) {
      bumpDataVersion();
      await _refresh();
      _snack(LocaleService.I.t('shop.buy_success_gems', args: {'gems': '${resp.gems}'}));
    } else {
      _snack(LocaleService.I.t('shop.buy_failed_verify'));
    }
  }

  Future<void> _restorePurchases() async {
    _initRestoreListener();
    final ok = await PurchaseService.I.restorePurchases();
    if (ok) {
      _snack(LocaleService.I.t('shop.restoring'));
    } else {
      _snack(LocaleService.I.t('shop.restore_retry'));
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
    if (ok) { _snack(LocaleService.I.t('shop.exchange_success', args: {'gold': '$goldReward'})); } else { _snack(LocaleService.I.t('shop.exchange_failed')); }
    bumpDataVersion(); await _refresh();
  }

  // ===== 每日特惠 =====
  void _buyDailyDeal() async {
    if (_dailyDealBought) return;
    final deals = [
      (LocaleService.I.t('shop.daily_deal_pack_normal'), 350, 5),
      (LocaleService.I.t('shop.daily_deal_pack_rare'), 700, 3),
      (LocaleService.I.t('shop.daily_deal_pack_epic'), 1400, 2),
      (LocaleService.I.t('shop.daily_deal_pack_legendary'), 3500, 1),
    ];
    final deal = deals[DateTime.now().day % deals.length];
    final cost = deal.$2;
    if (_data == null || _data!.gold < cost) { _snack(LocaleService.I.t('shop.gold_insufficient_short')); return; }
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
    _showPackResult(picks, '🔥 ${LocaleService.I.t('shop.daily_deal_title')} · ${deal.$1}');
  }

  void _buyHero(String hid, int cost) async {
    if (_data!.unlockedHeroes.contains(hid)) return;
    if (_data!.gold >= cost) {
      await SaveManager.savePlayerData(_data!.copyWith(gold: _data!.gold - cost,
          unlockedHeroes: [..._data!.unlockedHeroes, hid]));
      bumpDataVersion();
    } else { _snack(LocaleService.I.t('shop.gold_insufficient_short')); return; }
    await _refresh(); _snack(LocaleService.I.t('shop.buy_success'));
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
    final labels = [LocaleService.I.t('shop.daily_deal_pack_normal'), LocaleService.I.t('shop.daily_deal_pack_rare'), LocaleService.I.t('shop.daily_deal_pack_epic'), LocaleService.I.t('shop.daily_deal_pack_legendary')];
    return LocaleService.I.t('shop.daily_deal_label', args: {'pack': labels[DateTime.now().day % labels.length]});
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
          _sec(LocaleService.I.t('shop.daily_deal_title')),
          _card(Icons.card_giftcard, _dealLabel(), LocaleService.I.t('shop.daily_deal_item'),
              _dailyDealBought ? Text(LocaleService.I.t('shop.bought'), style: const TextStyle(color: AppTheme.healGreen, fontSize: 13))
                  : const Text('🔥', style: TextStyle(color: AppTheme.healthRed, fontSize: 18)),
              _dailyDealBought ? null : _buyDailyDeal),
          const SizedBox(height: 16),

          // === 卡牌商店（可折叠，每2h刷新） ===
          _foldable(LocaleService.I.t('shop.card_shop'), _cardShopExpanded, (v) => setState(() => _cardShopExpanded = v),
              LocaleService.I.t('shop.card_shop_refresh', args: {'code': '${_cardShopCache.hashCode % 100}'})),
          if (_cardShopExpanded) ...[
            _card(Icons.card_giftcard, LocaleService.I.t('shop.pack_normal'), LocaleService.I.t('shop.pack_normal_short'), const Text('500💰', style: TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackNormal),
            _card(Icons.card_giftcard, LocaleService.I.t('shop.pack_rare'), LocaleService.I.t('shop.pack_rare_short'), const Text('1000💰', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackRare),
            _card(Icons.card_giftcard, LocaleService.I.t('shop.pack_epic'), LocaleService.I.t('shop.pack_epic_short'), const Text('2000💰', style: TextStyle(color: Colors.purple, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackEpic),
            _card(Icons.card_giftcard, LocaleService.I.t('shop.pack_legendary'), LocaleService.I.t('shop.pack_legendary_short'), const Text('5000💰', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)), _buyPackLegendary),
            ..._buildCardShop(),
          ],
          const SizedBox(height: 16),

          // === 钻石 ===
          _sec(LocaleService.I.t('shop.gems_title')),
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
              label: Text(LocaleService.I.t('shop.restore_purchases')),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          // === 金币 ===
          _foldable(LocaleService.I.t('shop.gold_title'), _goldExpanded, (v) => setState(() => _goldExpanded = v), LocaleService.I.t('shop.gold_exchange')),
          if (_goldExpanded) ...[
            _card(Icons.monetization_on, '1000金币', '100💎兑换', const Text('100💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldBundle(100, 1000)),
            const SizedBox(height: 4),
            _card(Icons.monetization_on, '5000金币', '500💎兑换', const Text('500💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldBundle(500, 5000)),
            const SizedBox(height: 4),
            _card(Icons.monetization_on, '10000金币', '1000💎兑换', const Text('1000💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldBundle(1000, 10000)),
          ],
          const SizedBox(height: 16),

          // === 英雄商店（可折叠，每8h刷新） ===
          _foldable(LocaleService.I.t('shop.hero_shop'), _heroShopExpanded, (v) => setState(() => _heroShopExpanded = v),
              LocaleService.I.t('shop.hero_shop_refresh', args: {'code': '${_heroShopCache.hashCode % 100}'})),
          if (_heroShopExpanded) ..._heroShop(),
          const SizedBox(height: 16),

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
    if (pool.isEmpty) return [Padding(padding: const EdgeInsets.all(8), child: Text(LocaleService.I.t('shop.no_recommend'), style: const TextStyle(color: AppTheme.textMuted)))];
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
                Text(LocaleService.I.t('shop.owned_tag'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))
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
    cm.CardOwner.bingjia => LocaleService.I.t('owner.bingjia'), cm.CardOwner.fajia => LocaleService.I.t('owner.fajia'),
    cm.CardOwner.rujia => LocaleService.I.t('owner.rujia'), cm.CardOwner.daojia => LocaleService.I.t('owner.daojia'),
    cm.CardOwner.mojia => LocaleService.I.t('owner.mojia'), cm.CardOwner.yinyangjia => LocaleService.I.t('owner.yinyangjia'),
    cm.CardOwner.zonghengjia => LocaleService.I.t('owner.zonghengjia'), cm.CardOwner.neutral => LocaleService.I.t('owner.neutral'),
  };

  // ===== 英雄商店：每8h刷新 =====
  List<Widget> _heroShop() {
    final all = HeroDataProvider.getAllHeroes();
    final owned = Set<String>.from(_data?.unlockedHeroes ?? []);
    final rng = Random(_heroShopCache.hashCode);
    final pool = all.toList()..shuffle(rng); // 不再过滤已拥有，保留展示
    if (pool.isEmpty) return [Padding(padding: const EdgeInsets.all(8), child: Text(LocaleService.I.t('shop.all_unlocked'), style: const TextStyle(color: AppTheme.textMuted)))];
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
                  Text(LocaleService.I.t('shop.owned_tag'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))
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
    cm.Rarity.common => LocaleService.I.t('card_library.rarity_common'), cm.Rarity.rare => LocaleService.I.t('card_library.rarity_rare'),
    cm.Rarity.epic => LocaleService.I.t('card_library.rarity_epic'), cm.Rarity.legendary => LocaleService.I.t('card_library.rarity_legendary'),
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