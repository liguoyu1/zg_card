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
import '../../domain/services/balance_sync_service.dart';
import '../../domain/services/purchase_service.dart';
import '../../data/xsolla_payment_service.dart';
import '../../data/support_service.dart';
import '../../l10n/locale_service.dart';
import '../providers/auth_provider.dart';

/// 商店 — 钻石/金币/英雄/卡牌直购（不含随机抽卡/宝箱）
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  PlayerData? _data;
  bool _loading = true;
  bool _heroShopExpanded = true;
  bool _goldExpanded = true;
  String _heroShopCache = '';

  @override
  void initState() {
    super.initState();
    _load(syncFirst: true);
    dataVersionNotifier.addListener(_load);
    PurchaseService.I.ensureReady().then((_) { if (mounted) setState(() {}); });
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleXsollaReturn());
  }

  /// Xsolla 支付跳回：弹窗展示结果 + 轮询服务端补钻
  Future<void> _handleXsollaReturn() async {
    final status = XsollaPaymentService.takeReturnStatus();
    if (status == null || !mounted) return;
    // 先强制云端同步：以服务端到账为准判定结果（Xsolla 的 status 参数偶发与真实结果不一致）
    await _load(syncFirst: true);
    if (!mounted) return;
    final preGems = await SaveManager.consumeXsollaPreGems();
    // 以服务端权威余额为准（直接查 /balance/get，不经存档同步链路）
    var auth = ref.read(authProvider);
    for (var i = 0; i < 10 && auth == null; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      auth = ref.read(authProvider);
    }
    var gained = preGems != null && (_data?.gems ?? 0) > preGems;
    if (!gained && auth != null && preGems != null) {
      final b = await BalanceService.getBalance(auth.playerId);
      gained = b != null && b.gems > preGems;
    }
    // 异步结算订单（待入账）跳回时 status 可能非 successful 但最终会到账：
    // 弹窗只分"成功/处理中"，不再用 status 判定失败，避免误报"未完成"
    final st = status.toLowerCase();
    final ok = st.contains('success') || gained;
    final pending = !ok;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ok
            ? LocaleService.I.t('shop.xsolla_success')
            : pending
                ? LocaleService.I.t('shop.xsolla_pending')
                : LocaleService.I.t('shop.xsolla_failed')),
        content: Text(ok
            ? LocaleService.I.t('shop.xsolla_success_desc')
            : pending
                ? LocaleService.I.t('shop.xsolla_pending_desc')
                : LocaleService.I.t('shop.xsolla_failed_desc')),
        actions: [
          if (!ok) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAfterSalesPage();
              },
              child: Text(LocaleService.I.t('shop.after_sales'), style: const TextStyle(color: AppTheme.healthRed)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                final auth = ref.read(authProvider);
                if (auth != null) {
                  showSupportDialog(context, token: auth.token, category: 'payment');
                }
              },
              child: Text(LocaleService.I.t('home.contact_support')),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.I.t('ok')),
          ),
        ],
      ),
    );
    // 弹窗后后台轮询：结算完成后自动提示「购买成功 +X 钻」并刷新余额（服务端为准）
    if (auth != null) await _pollXsollaBalance(auth.playerId);
  }

  Future<void> _load({bool syncFirst = false}) async {
    if (syncFirst) await BalanceSyncService.refreshNow(); // 在线：等云端同步完成后渲染
    final d = await SaveManager.loadPlayerData();
    _heroShopCache = 'hs_${_cycleKey(8)}';
    if (mounted) setState(() { _data = d; _loading = false; });
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

  // ===== 单卡直购（服务端事务：扣款+入档，返回权威状态） =====
  void _buySingleCard(cm.Card card) async {
    final price = _cardPrice(card);
    final res = await _purchase('card', card.id, price);
    if (res == null) return;
    await SaveManager.addEvent({
      'type': 'card_purchase',
      'data': {'cardId': card.id, 'cost': price, 'currency': 'gold'},
    });
    _snack(res.error ?? LocaleService.I.t('shop.purchase_success_name', args: {'name': card.name}));
    await _refresh();
  }

  int _cardPrice(cm.Card c) {
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
        if (_data != null && !resp.alreadyProcessed) {
          _data = _data!.copyWith(gems: _data!.gems + resp.gained);
          await SaveManager.savePlayerData(_data!);
        }
        bumpDataVersion();
        await _refresh();
        _snack(LocaleService.I.t('shop.restore_success', args: {'gems': '${resp.gained}'}));
      } else {
        _snack('${LocaleService.I.t('shop.restore_verify_failed')}（${resp?.error ?? '?'}）');
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
      // 记录"支付进行中"标记：跳回后无论 status 是否携带都返回商店页（原页面）
      await SaveManager.markXsollaPending(true);
      // 记录支付前钻石数：跳回后以服务端到账为准判定弹窗结果（status 参数不可靠）
      await SaveManager.markXsollaPreGems(_data?.gems ?? 0);
      final ok = await XsollaPaymentService.I.purchase(auth.playerId, auth.token, sku: sku);
      if (ok) {
        await SaveManager.addEvent({
          'type': 'gem_purchase',
          'data': {'productId': sku, 'channel': 'xsolla', 'status': 'opened'},
        });
        _snack(LocaleService.I.t('shop.payment_opened'));
        await _pollXsollaBalance(auth.playerId);
        return;
      }

      // Android：Xsolla 失败 → 降级 Google IAP
      if (!kIsWeb) await _buyIAP(ga);
    } catch (_) { _snack(LocaleService.I.t('shop.buy_failed_generic')); }
  }

  /// Web 支付完成后轮询服务端余额，把已到账部分补进本地（服务端 > 本地才补）
  /// 轮询服务端余额补差；返回是否补到钻石
  Future<bool> _pollXsollaBalance(String playerId) async {
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 2500));
      final b = await BalanceService.getBalance(playerId);
      final d = _data;
      if (b == null || d == null) continue;
      final gemDiff = b.gems - d.gems;
      final goldDiff = b.gold - d.gold;
      if (gemDiff > 0 || goldDiff > 0) {
        _data = d.copyWith(
          gems: d.gems + (gemDiff > 0 ? gemDiff : 0),
          gold: d.gold + (goldDiff > 0 ? goldDiff : 0),
        );
        await SaveManager.savePlayerData(_data!);
        if (gemDiff > 0) {
          await SaveManager.addEvent({
            'type': 'gem_purchase',
            'data': {'gems': gemDiff, 'channel': 'xsolla', 'status': 'credited'},
          });
        }
        bumpDataVersion();
        await _refresh();
        if (gemDiff > 0) {
          _snack(LocaleService.I.t('shop.buy_success_gems', args: {'gems': '$gemDiff'}));
        }
        return true;
      }
    }
    await _refresh();
    return false;
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
    if (auth == null) { _snack(LocaleService.I.t('shop.please_login')); return; }
    final resp = await BalanceService.verifyIAPReceipt(
      playerId: auth.playerId,
      token: auth.token,
      receipt: result.receipt!,
      productId: result.productId!,
      transactionId: result.transactionId,
    );
    if (resp != null && resp.success) {
      if (_data != null && !resp.alreadyProcessed) {
        _data = _data!.copyWith(gems: _data!.gems + resp.gained);
        await SaveManager.savePlayerData(_data!);
        await SaveManager.addEvent({
          'type': 'gem_purchase',
          'data': {'productId': result.productId, 'gems': resp.gained, 'channel': 'iap'},
        });
      }
      bumpDataVersion();
      await _refresh();
      _snack(LocaleService.I.t('shop.buy_success_gems', args: {'gems': '${resp.gained}'}));
    } else {
      _snack('${LocaleService.I.t('shop.buy_failed_verify')}（${resp?.error ?? '?'}）');
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
  // iOS 走 IAP 用基础赠送；Web/Android 走 Xsolla 追加活动赠予 +20%（服务端 GEM_SKU_MAP 同值）
  static int _gemBonus(int ga) {
    const bonus = {60: 0, 300: 50, 600: 150, 1500: 500, 3000: 1500};
    var b = bonus[ga] ?? 0;
    if (!kIsWeb && Platform.isIOS) return b;
    const xsollaExtra = {60: 12, 300: 70, 600: 150, 1500: 400, 3000: 900};
    return b + (xsollaExtra[ga] ?? 0);
  }

  Widget _gemCard(int diamonds, double usd, String? bonus) {
    final bonusActual = _gemBonus(diamonds);
    final total = diamonds + bonusActual;
    // 方案A：优先 StoreKit 本地化价格（用户地区真实货币/售价，如中国区 ¥8.00），加载失败回退美元定价
    final local = PurchaseService.I.products.where((p) => p.id == _gemProductId(diamonds)).firstOrNull;
    final price = (local != null && local.price.isNotEmpty) ? local.price : '\$${usd.toStringAsFixed(2)}';
    final raw = local?.rawPrice ?? usd;
    final eff = raw > 0 ? (total / raw).round() : 0;
    final cur = price.replaceAll(RegExp(r'[\d.,]+'), '').trim();
    final subtitle = bonusActual > 0
        ? LocaleService.I.t('shop.gem_subtitle_bonus', args: {'price': price, 'eff': '$eff', 'bonus': '$bonusActual', 'cur': cur})
        : LocaleService.I.t('shop.gem_subtitle', args: {'price': price, 'eff': '$eff', 'cur': cur});
    final title = bonusActual > 0
        ? LocaleService.I.t('shop.gem_title_bonus', args: {'base': '$diamonds', 'bonus': '$bonusActual'})
        : LocaleService.I.t('shop.gem_title', args: {'base': '$diamonds'});
    return _card(Icons.diamond, title, subtitle,
        Text(price, style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        () => _buyGem(diamonds));
  }

  // 钻石→金币：10:1（服务端单事务：扣钻石+发金币）
  Future<void> _buyGoldExchange(int gemsCost, int goldReward) async {
    if (!await _requireLogin()) return;
    final auth = ref.read(authProvider);
    if (auth == null) return;
    if (_data == null || _data!.gems < gemsCost) {
      _snack(LocaleService.I.t('shop.gems_insufficient_short'));
      return;
    }
    final res = await BalanceService.exchangeGemsToGold(
      auth.playerId, auth.token, gemsCost: gemsCost, goldReward: goldReward,
    );
    if (res == null) { _snack(LocaleService.I.t('shop.exchange_failed')); return; }
    if (!res.ok) {
      _snack(res.error ?? LocaleService.I.t('shop.exchange_failed'));
      // 失败时用服务端余额回读校准（可能并发冲突，提示重试）
      await _refresh();
      return;
    }
    _data = _data!.copyWith(gems: res.gems, gold: res.gold);
    await SaveManager.savePlayerData(_data!);
    await SaveManager.addEvent({
      'type': 'gold_exchange',
      'data': {'gemsCost': gemsCost, 'gold': goldReward},
    });
    bumpDataVersion(); await _refresh();
    _snack(LocaleService.I.t('shop.exchange_success', args: {'gold': '$goldReward'}));
  }

  void _buyHero(String hid, int cost) async {
    if (_data!.unlockedHeroes.contains(hid)) return;
    final res = await _purchase('hero', hid, cost);
    if (res == null) return;
    await SaveManager.addEvent({
      'type': 'hero_purchase',
      'data': {'heroId': hid, 'cost': cost, 'currency': 'gold'},
    });
    _snack(res.error ?? LocaleService.I.t('shop.buy_success'));
    await _refresh();
  }

  /// 统一购买入口：服务端事务处理当前这笔购买，成功后用返回的权威状态落存本地
  Future<({String? error})?> _purchase(String kind, String assetId, int cost) async {
    if (!await _requireLogin()) return (error: null);
    final auth = ref.read(authProvider);
    if (auth == null) return (error: null);
    if (_data == null || _data!.gold < cost) {
      _snack(LocaleService.I.t('shop.gold_insufficient_short'));
      return (error: null);
    }
    final res = await BalanceService.purchasePlayerAsset(
      auth.playerId, auth.token,
      kind: kind, assetId: assetId, cost: cost,
    );
    if (res == null) { _snack(LocaleService.I.t('shop.op_failed')); return (error: null); }
    if (!res.ok) {
      _snack(res.error ?? LocaleService.I.t('shop.op_failed'));
      return (error: res.error);
    }
    // 服务端返回的余额与解锁列表为权威状态
    await SaveManager.savePlayerData(_data!.copyWith(
      gold: res.gold,
      unlockedCards: kind == 'card' ? res.unlockedCards : _data!.unlockedCards,
      unlockedHeroes: kind == 'hero' ? res.unlockedHeroes : _data!.unlockedHeroes,
    ));
    bumpDataVersion();
    return (error: null);
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


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: Text(LocaleService.I.t('shop.title_bar'), style: const TextStyle(color: AppTheme.parchment)),
          backgroundColor: AppTheme.agedWood, foregroundColor: AppTheme.parchment),
      body: RefreshIndicator(
        onRefresh: () => _load(syncFirst: true),
        color: AppTheme.goldAccent,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BalanceBar(gold: _data?.gold ?? 0, gems: _data?.gems ?? 0),
          const SizedBox(height: 16),

          // === 卡牌直购 ===
          _sec(LocaleService.I.t('shop.card_shop')),
          ..._buildCardShop(),
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
          const SizedBox(height: 16),

          // === 金币 ===
          _foldable(LocaleService.I.t('shop.gold_title'), _goldExpanded, (v) => setState(() => _goldExpanded = v), LocaleService.I.t('shop.gold_exchange')),
          if (_goldExpanded) ...[
            _card(Icons.monetization_on, LocaleService.I.t('shop.gold_amount', args: {'amount': '1000'}), LocaleService.I.t('shop.gems_exchange', args: {'gems': '100'}), const Text('100💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldExchange(100, 1000)),
            const SizedBox(height: 4),
            _card(Icons.monetization_on, LocaleService.I.t('shop.gold_amount', args: {'amount': '5000'}), LocaleService.I.t('shop.gems_exchange', args: {'gems': '500'}), const Text('500💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldExchange(500, 5000)),
            const SizedBox(height: 4),
            _card(Icons.monetization_on, LocaleService.I.t('shop.gold_amount', args: {'amount': '10000'}), LocaleService.I.t('shop.gems_exchange', args: {'gems': '1000'}), const Text('1000💎', style: TextStyle(color: AppTheme.manaBlue, fontSize: 16, fontWeight: FontWeight.bold)), () => _buyGoldExchange(1000, 10000)),
          ],
          const SizedBox(height: 16),

          // === 英雄商店（可折叠，每8h刷新） ===
          _foldable(LocaleService.I.t('shop.hero_shop'), _heroShopExpanded, (v) => setState(() => _heroShopExpanded = v),
              LocaleService.I.t('shop.hero_shop_refresh', args: {'code': '${_heroShopCache.hashCode % 100}'})),
          if (_heroShopExpanded) ..._heroShop(),
          const SizedBox(height: 16),

          // === 恢复购买记录（置底） ===
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _restorePurchases,
              icon: const Icon(Icons.restore, size: 16),
              label: Text(LocaleService.I.t('shop.restore_purchases')),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      )),
      ),
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
    final rng = Random(_heroShopCache.hashCode != 0 ? _heroShopCache.hashCode : DateTime.now().millisecondsSinceEpoch);
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
