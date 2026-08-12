import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/balance_service.dart';
import '../../data/persistence/save_manager.dart';
import '../../l10n/locale_service.dart';
import '../providers/auth_provider.dart';

/// 交易记录 — 服务端流水 + 本地事件流（钻石充值/购买卡牌武将/兑换）合并展示；
/// 最近 3 天默认，可切换近 1 月 / 全部历史
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  int _days = 3; // 3=近3天 30=近1月 0=全部

  @override
  void initState() {
    super.initState();
    // 登录态变化后自动刷新（如支付跳回、登录恢复完成）
    ref.listenManual(authProvider, (_, __) => _load());
    _load();
  }

  Future<void> _load() async {
    // 支付/登录返回后冷启动：等待登录态恢复（至多 3s），避免误显示"暂无交易记录"
    var auth = ref.read(authProvider);
    for (var i = 0; i < 10 && auth == null; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      auth = ref.read(authProvider);
    }
    if (auth == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final list =
        await BalanceService.getTransactions(auth.playerId, days: _days);
    final events = await SaveManager.loadEvents();
    if (!mounted) return;
    setState(() {
      _txns = mergeTransactionRows(list, events, _days);
      _loading = false;
    });
  }

  String _typeLabel(Map<String, dynamic> t) {
    final detail = t['detail'] as String?;
    if (detail != null && detail.isNotEmpty) return detail;
    switch (t['type']) {
      case 'earn_gems':
        return LocaleService.I.t('txn.earn_gems');
      case 'spend_gems':
        return LocaleService.I.t('txn.spend_gems');
      case 'earn_gold':
        return LocaleService.I.t('txn.earn_gold');
      case 'spend_gold':
        return LocaleService.I.t('txn.spend_gold');
      case 'exchange':
        return LocaleService.I.t('txn.exchange');
      case 'gem_purchase':
        return LocaleService.I.t('txn.gem_purchase');
      case 'card_purchase':
        return LocaleService.I.t('txn.card_purchase');
      case 'hero_purchase':
        return LocaleService.I.t('txn.hero_purchase');
      default:
        return t['type']?.toString() ?? '-';
    }
  }

  String _fmtTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
          title: Text(LocaleService.I.t('txn.title'),
              style: const TextStyle(color: AppTheme.parchment)),
          backgroundColor: AppTheme.agedWood,
          foregroundColor: AppTheme.parchment),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _txns.isEmpty
              ? Center(
                  child: Text(LocaleService.I.t('txn.empty'),
                      style: const TextStyle(color: AppTheme.textMuted)))
              : Column(children: [
                  Expanded(
                      child: RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.goldAccent,
                          child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _txns.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (_, i) {
                      final t = _txns[i];
                      final amount = (t['amount'] as num?)?.toInt();
                      final currency = t['currency'] == 'gold'
                          ? LocaleService.I.t('common.gold')
                          : LocaleService.I.t('common.gem');
                      final sign =
                          amount == null ? '' : (amount >= 0 ? '+' : '');
                      final balance = t['balanceAfter'];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(
                            amount == null || amount >= 0
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                            color: amount == null || amount >= 0
                                ? AppTheme.goldAccent
                                : AppTheme.textMuted),
                        title: Text(_typeLabel(t),
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 14)),
                        subtitle: Text(
                            '${_fmtTime(t['createdAt']?.toString() ?? '')}'
                            '${balance != null ? ' · ${LocaleService.I.t('txn.balance')} $balance' : ''}',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                        trailing: Text(
                            amount == null
                                ? LocaleService.I.t('txn.pending')
                                : '$sign$amount $currency',
                            style: TextStyle(
                                color: amount == null || amount >= 0
                                    ? AppTheme.goldAccent
                                    : AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      );
                    },
                  ))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Row(children: [
                      Expanded(
                          child: _periodButton(
                              3, LocaleService.I.t('txn.period_3'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _periodButton(
                              30, LocaleService.I.t('txn.period_30'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _periodButton(
                              0, LocaleService.I.t('txn.period_all'))),
                    ]),
                  ),
                ]),
    );
  }

  Widget _periodButton(int days, String label) {
    final active = _days == days;
    return OutlinedButton(
      onPressed: () {
        if (_days == days) return;
        setState(() {
          _days = days;
          _loading = true;
        });
        _load();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? AppTheme.goldAccent : AppTheme.textSecondary,
        side: BorderSide(
            color: active ? AppTheme.goldAccent : AppTheme.borderLight),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

/// 服务端流水与本地事件流合并：同一天同类型同金额视为同一笔（服务端优先），
/// 避免同一笔支付/兑换在两端各记一次
List<Map<String, dynamic>> mergeTransactionRows(
    List<Map<String, dynamic>> server,
    List<Map<String, dynamic>> events,
    int days) {
  final since = days > 0 ? DateTime.now().subtract(Duration(days: days)) : null;
  final rows = List<Map<String, dynamic>>.from(server);
  final serverKeys = <String>{
    for (final t in server)
      '${t['type']}|${t['amount']}|${(t['createdAt']?.toString().length ?? 0) >= 10 ? t['createdAt'].toString().substring(0, 10) : ''}',
  };
  // 已到账的充值事件（同渠道同商品，用于抑制"已发起待入账"的 opened 事件）
  final creditedKeys = <String>{};
  for (final e in events) {
    final data = (e['data'] as Map?) ?? const {};
    if (e['type'] == 'gem_purchase' && data['status'] == 'credited') {
      creditedKeys.add('${data['channel']}');
    }
  }

  bool sameDayServer(String type, Object? amount, String? at,
      {bool abs = false}) {
    final day = (at ?? '').length >= 10 ? at!.substring(0, 10) : '';
    final a = amount is num ? (abs ? amount.abs() : amount).toString() : '';
    for (final k in serverKeys) {
      final parts = k.split('|');
      if (parts.length != 3 || parts[2] != day) continue;
      if (parts[0] != type) continue;
      if (a.isNotEmpty) {
        final ka = abs
            ? (int.tryParse(parts[1])?.abs().toString() ?? parts[1])
            : parts[1];
        if (ka != a) continue;
      }
      return true;
    }
    return false;
  }

  for (final e in events) {
    final at = e['at']?.toString() ?? '';
    final dt = DateTime.tryParse(at);
    if (dt == null || (since != null && dt.isBefore(since))) continue;
    final data = (e['data'] as Map?) ?? const {};
    final type = e['type']?.toString() ?? '';
    final cost = (data['cost'] as num?)?.toInt();
    Map<String, dynamic>? row;
    String? conflictType;
    Object? conflictAmount;

    switch (type) {
      case 'gem_purchase':
        final gems = (data['gems'] as num?)?.toInt();
        final channel = data['channel']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';
        if (status == 'opened' && creditedKeys.contains(channel)) {
          continue;
        }
        if (gems != null && sameDayServer('earn_gems', gems, at)) {
          continue; // 服务端已入账（webhook 记 earn_gems），不重复展示
        }
        row = {
          'type': 'gem_purchase',
          'amount': gems,
          'currency': 'gem',
          'createdAt': at,
          'balanceAfter': null,
          'detail': channel == 'xsolla'
              ? 'Xsolla'
              : (channel == 'iap' ? 'Apple IAP' : null),
        };
        break;
      case 'gold_exchange':
        final cost = (data['gemsCost'] as num?)?.toInt();
        final gold = (data['gold'] as num?)?.toInt();
        if (cost != null &&
            gold != null &&
            (sameDayServer('spend_gems', -cost, at) ||
                sameDayServer('earn_gold', gold, at))) {
          continue; // 服务端已记录兑换流水
        }
        row = {
          'type': 'exchange',
          'amount': gold,
          'currency': 'gold',
          'createdAt': at,
          'balanceAfter': null,
          'detail': null,
        };
        break;
      case 'card_purchase':
        conflictType = 'spend_gold';
        conflictAmount = cost == null ? null : -cost;
        row = {
          'type': 'card_purchase',
          'amount': cost == null ? null : -cost,
          'currency': 'gold',
          'createdAt': at,
          'balanceAfter': null,
          'detail': data['cardId']?.toString(),
        };
        break;
      case 'hero_purchase':
        conflictType = 'spend_gold';
        conflictAmount = cost == null ? null : -cost;
        row = {
          'type': 'hero_purchase',
          'amount': cost == null ? null : -cost,
          'currency': 'gold',
          'createdAt': at,
          'balanceAfter': null,
          'detail': data['heroId']?.toString(),
        };
        break;
      default:
        continue;
    }
    if (conflictType != null &&
        sameDayServer(conflictType, conflictAmount, at, abs: true)) {
      continue; // 服务端已记录该笔扣款
    }
    rows.add(row);
  }
  rows.sort((a, b) {
    final x = a['createdAt']?.toString() ?? '';
    final y = b['createdAt']?.toString() ?? '';
    return y.compareTo(x);
  });
  return rows;
}
