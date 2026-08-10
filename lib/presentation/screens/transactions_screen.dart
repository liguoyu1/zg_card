import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/balance_service.dart';
import '../../domain/services/balance_sync_service.dart';
import '../../l10n/locale_service.dart';
import '../providers/auth_provider.dart';

/// 交易记录 — 最近 3 天默认展示，可扩展查询近 1 个月
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  int _days = 3;

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
    if (auth == null) { if (mounted) setState(() => _loading = false); return; }
    final list = await BalanceService.getTransactions(auth.playerId, days: _days);
    if (!mounted) return;
    setState(() { _txns = list; _loading = false; });
  }

  String _typeLabel(Map<String, dynamic> t) {
    final detail = t['detail'] as String?;
    if (detail != null && detail.isNotEmpty) return detail;
    switch (t['type']) {
      case 'earn_gems': return LocaleService.I.t('txn.earn_gems');
      case 'spend_gems': return LocaleService.I.t('txn.spend_gems');
      case 'earn_gold': return LocaleService.I.t('txn.earn_gold');
      case 'spend_gold': return LocaleService.I.t('txn.spend_gold');
      case 'exchange': return LocaleService.I.t('txn.exchange');
      default: return t['type']?.toString() ?? '-';
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
        title: Text(LocaleService.I.t('txn.title'), style: const TextStyle(color: AppTheme.parchment)),
        backgroundColor: AppTheme.agedWood, foregroundColor: AppTheme.parchment),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _txns.isEmpty
              ? Center(child: Text(LocaleService.I.t('txn.empty'),
                  style: const TextStyle(color: AppTheme.textMuted)))
              : Column(children: [
                  Expanded(child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _txns.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (_, i) {
                      final t = _txns[i];
                      final amount = (t['amount'] as num?)?.toInt() ?? 0;
                      final currency = t['currency'] == 'gold'
                          ? LocaleService.I.t('common.gold')
                          : LocaleService.I.t('common.gem');
                      final sign = amount >= 0 ? '+' : '';
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: Icon(amount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: amount >= 0 ? AppTheme.goldAccent : AppTheme.textMuted),
                        title: Text(_typeLabel(t), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                        subtitle: Text('${_fmtTime(t['createdAt']?.toString() ?? '')} · ${LocaleService.I.t('txn.balance')} ${t['balanceAfter']}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        trailing: Text('$sign$amount $currency',
                            style: TextStyle(color: amount >= 0 ? AppTheme.goldAccent : AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                      );
                    },
                  )),
                  if (_days < 30)
                    Padding(padding: const EdgeInsets.all(8),
                      child: SizedBox(width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () { setState(() { _days = 30; _loading = true; }); _load(); },
                          child: Text(LocaleService.I.t('txn.show_month')),
                        ))),
                ]),
    );
  }
}
