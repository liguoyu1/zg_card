import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/asset_style.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../data/persistence/save_manager.dart';
import '../../domain/models/card.dart' as domain;
import '../../domain/services/card_data_provider.dart';
import '../../domain/services/card_pool.dart';
import '../../domain/services/purchase_service.dart';
import '../../l10n/locale_service.dart';
import '../providers/auth_provider.dart';
import '../../domain/services/auth_service.dart' show AuthState;
import '../widgets/theme_widgets.dart';
import '../widgets/tutorial_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  PlayerData? _cachedData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 恢复登录态
    if (mounted) ref.read(authProvider.notifier).loadSession();
    final d = await SaveManager.loadPlayerData();
    if (mounted) setState(() { _cachedData = d; _loading = false; });
    if (d != null && d.firstRun) {
      final pd = d.copyWith(firstRun: false);
      await SaveManager.savePlayerData(pd);
      setState(() => _cachedData = pd);
    }
    _checkWeeklyTrial();
  }

  Future<void> _checkWeeklyTrial() async {
    final data = await SaveManager.loadPlayerData();
    if (data == null) return;
    final week = CardPool.currentWeekNumber();
    if (data.lastTrialWeek == week) return;
    final trialIds = await CardPool.getWeeklyTrials();
    if (trialIds.isEmpty) return;
    final allCards = CardDataProvider.getAllCards();
    final cards = trialIds.map((id) => allCards.firstWhere(
      (c) => c.id == id, orElse: () => allCards.first,
    )).toList()..sort((a, b) {
      if (a.rarity.index != b.rarity.index) return a.rarity.index.compareTo(b.rarity.index);
      return a.cost.compareTo(b.cost);
    });
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WeeklyTrialDialog(cards: cards),
    );
    final pd = await SaveManager.loadPlayerData();
    if (pd != null) {
      await SaveManager.savePlayerData(pd.copyWith(lastTrialWeek: week));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return Scaffold(
      body: WThemeBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildGoldDivider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Column(
                    children: [
                      _buildMenuButton(icon: Icons.shield_outlined, label: LocaleService.I.t('home.btn_battle'), color: AppTheme.healthRed,
                          onTap: () => context.push('/battle/hero-select')),
                      _buildMenuButton(icon: Icons.sports_kabaddi, label: LocaleService.I.t('home.pk'), color: AppTheme.goldAccent,
                          onTap: () => context.push('/battle/hero-select?mode=pk')),
                      _buildMenuButton(icon: Icons.explore_outlined, label: LocaleService.I.t('home.btn_adventure'), color: AppTheme.damageOrange,
                          onTap: () => context.push('/shop/adventure')),
                      const SizedBox(height: 24),
                      _buildVersionText(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final auth = ref.watch(authProvider);
    final loggedIn = auth != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderGold.withAlpha(60)))),
      child: Row(children: [
        _buildSchoolEmblem(),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(LocaleService.I.t('home.title'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 4)),
          Text(LocaleService.I.t('home.subtitle'), style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 3)),
        ])),
        _buildUserMenu(loggedIn, auth),
      ]),
    );
  }

  Widget _buildUserMenu(bool loggedIn, AuthState? auth) {
    final isChibi = AssetStyle.current == AssetStyle.chibiCute;
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (v) async {
        switch (v) {
          case 'login':
            context.push('/auth/login');
            break;
          case 'style':
            setState(() {
              AssetStyle.current = isChibi ? AssetStyle.fantasyRpg : AssetStyle.chibiCute;
            });
            break;
          case 'sound':
            AudioManager.I.toggleMute();
            setState(() {});
            break;
          case 'lang_zh':
            LocaleService.I.init(localeCode: 'zh');
            setState(() {});
            break;
          case 'lang_en':
            LocaleService.I.init(localeCode: 'en');
            setState(() {});
            break;
          case 'lang_zh_TW':
            LocaleService.I.init(localeCode: 'zh_TW');
            setState(() {});
            break;
          case 'logout':
            await ref.read(authProvider.notifier).logout();
            setState(() {});
            break;
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: loggedIn ? AppTheme.goldAccent.withAlpha(60) : AppTheme.bgMedium,
          border: Border.all(color: loggedIn ? AppTheme.goldAccent : AppTheme.borderLight, width: 1.5),
        ),
        child: loggedIn
            ? Center(
                child: Text(
                  auth!.playerName.isNotEmpty ? auth.playerName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            : const Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
      ),
      itemBuilder: (_) {
        if (!loggedIn) {
          return [
            PopupMenuItem(value: 'login', child: ListTile(leading: const Icon(Icons.login, color: AppTheme.parchment), title: Text(LocaleService.I.t('home.login'), style: const TextStyle(color: AppTheme.parchment)), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
          ];
        }
        return [
          PopupMenuItem(value: 'info', enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${auth!.playerName}', style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('ID: ${auth.playerId.length > 8 ? auth.playerId.substring(0, 8) : auth.playerId}…', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
          ])),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'style', child: ListTile(
            leading: Icon(isChibi ? Icons.auto_awesome : Icons.auto_fix_high, color: AppTheme.parchment, size: 20),
            title: Text(LocaleService.I.t(isChibi ? 'home.style_toggle_real' : 'home.style_toggle_q'), style: TextStyle(color: AppTheme.parchment)),
            contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
          )),
          PopupMenuItem(value: 'sound', child: ListTile(
            leading: Icon(AudioManager.I.isMuted ? Icons.volume_off : Icons.volume_up, color: AppTheme.parchment, size: 20),
            title: Text(LocaleService.I.t(AudioManager.I.isMuted ? 'home.sound_off' : 'home.sound_on'), style: TextStyle(color: AppTheme.parchment)),
            contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
          )),
          PopupMenuItem(value: 'lang_zh', child: ListTile(
            leading: const Icon(Icons.language, color: AppTheme.parchment, size: 20),
            title: Text(LocaleService.I.t('home.lang_zh'), style: const TextStyle(color: AppTheme.parchment)),
            contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
          )),
          PopupMenuItem(value: 'lang_en', child: ListTile(
            leading: const Icon(Icons.language, color: AppTheme.parchment, size: 20),
            title: Text(LocaleService.I.t('home.lang_en'), style: const TextStyle(color: AppTheme.parchment)),
            contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
          )),
          PopupMenuItem(value: 'lang_zh_TW', child: ListTile(
            leading: const Icon(Icons.language, color: AppTheme.parchment, size: 20),
            title: Text(LocaleService.I.t('home.lang_zh_TW'), style: const TextStyle(color: AppTheme.parchment)),
            contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
          )),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'logout', child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: Text(LocaleService.I.t('home.logout'), style: const TextStyle(color: Colors.redAccent)),
            contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
          )),
        ];
      },
    );
  }

  Widget _buildSchoolEmblem() {
    return Container(width: 40, height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.borderGold, width: 1.5),
        gradient: const RadialGradient(colors: [Color(0x1EB8860B), Color(0xFF3D2B1F)])),
      child: const Center(child: Text('戰', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.goldAccent))),
    );
  }

  Widget _buildStyleToggle() {
    final isChibi = AssetStyle.current == AssetStyle.chibiCute;
    return GestureDetector(
      onTap: () => setState(() { AssetStyle.current = isChibi ? AssetStyle.fantasyRpg : AssetStyle.chibiCute; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.bgMedium.withAlpha(150), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.borderLight.withAlpha(80))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isChibi ? Icons.auto_awesome : Icons.auto_fix_high, size: 16, color: AppTheme.goldAccent),
          const SizedBox(width: 4),
          Text(isChibi ? LocaleService.I.t('home.style_toggle_q') : LocaleService.I.t('home.style_toggle_real'), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildGoldDivider() {
    return Container(height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [
      Colors.transparent, AppTheme.borderGold.withAlpha(60), AppTheme.borderGold.withAlpha(120),
      AppTheme.borderGold.withAlpha(60), Colors.transparent,
    ])));
  }

  Widget _buildMenuButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return WMenuPlaque(icon: icon, label: label, accentColor: color, onTap: onTap);
  }

  Widget _buildStarterBanner() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.goldAccent.withAlpha(40), AppTheme.bgLight.withAlpha(200), AppTheme.goldAccent.withAlpha(20)]),
            borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.goldAccent.withAlpha(120), width: 1.5)),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.card_giftcard, color: AppTheme.goldBright, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(LocaleService.I.t('home.starter_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            Text(LocaleService.I.t('home.starter_desc'), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ])),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async { final ok = await PurchaseService.I.purchase('starter_bundle'); if (!context.mounted) return;
              if (ok.success) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleService.I.t('home.purchase_success')), backgroundColor: AppTheme.healGreen));
              setState(() {}); },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('\$0.99'),
          ),
        ]),
      ),
    );
  }

  Widget _buildVersionText() {
    return Text(LocaleService.I.t('home.version'), style: TextStyle(fontSize: 10, color: AppTheme.textMuted.withAlpha(120)));
  }
}

class _WeeklyTrialDialog extends StatelessWidget {
  const _WeeklyTrialDialog({required this.cards});
  final List<domain.Card> cards;

  static const _rc = {domain.Rarity.common: Color(0xFF9E9E9E), domain.Rarity.rare: Color(0xFF2196F3), domain.Rarity.epic: Color(0xFF9C27B0), domain.Rarity.legendary: Color(0xFFFF9800)};
  static final _rl = {domain.Rarity.common: LocaleService.I.t('card_library.rarity_common'), domain.Rarity.rare: LocaleService.I.t('card_library.rarity_rare'), domain.Rarity.epic: LocaleService.I.t('card_library.rarity_epic'), domain.Rarity.legendary: LocaleService.I.t('card_library.rarity_legendary')};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(LocaleService.I.t('home.trial_weekly_title'), style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(LocaleService.I.t('home.trial_weekly_desc'), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: cards.map((c) {
          final rc = _rc[c.rarity]!;
          return Container(width: 80, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF16213E), borderRadius: BorderRadius.circular(8), border: Border.all(color: rc.withAlpha(120), width: 1.5)),
            child: Column(children: [
              Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('${_rl[c.rarity]} · ${c.cost}费', style: TextStyle(color: rc, fontSize: 9)),
              const SizedBox(height: 2),
              Text(_typeName(c.type), style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 8)),
            ]),
          );
        }).toList()),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), padding: const EdgeInsets.symmetric(vertical: 12)),
          child: Text(LocaleService.I.t('home.trial_accept'), style: const TextStyle(fontSize: 16, color: Colors.black)),
        )),
      ])),
    );
  }

  String _typeName(domain.CardType t) => switch (t) {
    domain.CardType.minion => LocaleService.I.t('card_library.type_minion'), domain.CardType.spell => LocaleService.I.t('card_library.type_spell'), domain.CardType.weapon => LocaleService.I.t('card_library.type_weapon'),
  };
}