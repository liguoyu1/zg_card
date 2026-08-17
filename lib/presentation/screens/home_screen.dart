import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../data/persistence/save_manager.dart';
import '../../data/card_image_service.dart';
import '../../data/xsolla_payment_service.dart';
import '../../data/support_service.dart';
import '../../shared/widgets/queued_asset_image.dart';
import '../../shared/widgets/ad_banner_slot.dart';
import '../../domain/models/card.dart' as domain;
import '../../domain/services/card_data_provider.dart';
import '../../domain/services/balance_sync_service.dart';
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

  /// App Store 链接（审核通过后填 https://apps.apple.com/app/idXXXXXX）
  static const String _iosStoreUrl = '';

  /// Android APK 直链（独立 dl 服务，按 ABI 拆分）
  static const List<({String file, String label})> _apkVariants = [
    (
      file:
          'https://dl-production-4a3d.up.railway.app/dl/app-arm64-v8a-release.apk',
      label: 'ARM64'
    ),
  ];

  /// 支持的语言（下拉框显示母语名）
  static const List<({String code, String label})> _languages = [
    (code: 'en', label: 'English'),
    (code: 'zh', label: '简体中文'),
    (code: 'zh_TW', label: '繁體中文'),
    (code: 'fr', label: 'Français'),
    (code: 'de', label: 'Deutsch'),
    (code: 'ja', label: '日本語'),
    (code: 'ru', label: 'Русский'),
    (code: 'es', label: 'Español'),
    (code: 'fil', label: 'Filipino'),
    (code: 'ms', label: 'Bahasa Melayu'),
    (code: 'th', label: 'ไทย'),
  ];

  /// 切换语言：生效并持久化
  Future<void> _changeLanguage(String code) async {
    await LocaleService.I.init(localeCode: code);
    await SharedPreferences.getInstance()
        .then((p) => p.setString('locale_code', code));
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Xsolla 支付返回：优先消费 URL 状态并立即跳回商店（不依赖登录/云同步，避免卡在主页）
    final xsollaStatus =
        kIsWeb ? XsollaPaymentService.consumeReturnStatus() : null;
    // 兜底：支付标记存在（status 偶发丢失）也回商店页
    final pending = await SaveManager.consumeXsollaPending();
    if ((xsollaStatus != null || pending) && mounted) {
      if (xsollaStatus != null)
        XsollaPaymentService.pendingReturnStatus = xsollaStatus;
      context.go('/shop/shop');
    }
    // 先用本地存档渲染，避免账号同步期间空白/初始状态停留
    var d = await SaveManager.loadPlayerData();
    if (mounted)
      setState(() {
        _cachedData = d;
        _loading = false;
      });
    // 恢复登录态并等待首次云端同步完成，同步后刷新为账号最新资产
    await ref.read(authProvider.notifier).loadSession();
    final auth = ref.read(authProvider);
    // 仅注册登录用户首次初始化赠送 20 张卡牌（游客不送，需注册登录后获得）
    if (auth?.email != null) {
      final existing = await SaveManager.loadPlayerData();
      if (existing == null || existing.unlockedCards.isEmpty) {
        await CardPool.seedStarterCards();
      }
    }
    await BalanceSyncService.waitForInitialSync();
    d = await SaveManager.loadPlayerData();
    if (mounted && d != null)
      setState(() {
        _cachedData = d;
      });
    if (d != null && d.firstRun) {
      final pd = d.copyWith(firstRun: false);
      await SaveManager.savePlayerData(pd);
      setState(() => _cachedData = pd);
    }
    _checkWeeklyTrial();
  }

  Future<void> _checkWeeklyTrial() async {
    // 游客不弹本周试用（需注册登录后获得）
    final auth = ref.read(authProvider);
    if (auth?.email == null) return;
    final data = await SaveManager.loadPlayerData();
    if (data == null) return;
    final week = CardPool.currentWeekNumber();
    if (data.lastTrialWeek == week) return;
    final trialIds = await CardPool.getWeeklyTrials();
    if (trialIds.isEmpty) return;
    final allCards = CardDataProvider.getAllCards();
    final cards = trialIds
        .map((id) => allCards.firstWhere(
              (c) => c.id == id,
              orElse: () => allCards.first,
            ))
        .toList()
      ..sort((a, b) {
        if (a.rarity.index != b.rarity.index)
          return a.rarity.index.compareTo(b.rarity.index);
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    await BalanceSyncService.refreshNow();
                    if (mounted) setState(() {});
                  },
                  color: AppTheme.goldAccent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Column(
                      children: [
                        if (ref.watch(authProvider)?.email == null)
                          _buildGuestHint(),
                        _buildMenuButton(
                            icon: Icons.shield_outlined,
                            label: LocaleService.I.t('home.btn_battle'),
                            color: AppTheme.healthRed,
                            onTap: () => context.push('/battle/hero-select')),
                        _buildMenuButton(
                            icon: Icons.sports_kabaddi,
                            label: LocaleService.I.t('home.pk'),
                            color: AppTheme.goldAccent,
                            onTap: () =>
                                context.push('/battle/hero-select?mode=pk')),
                        _buildMenuButton(
                            icon: Icons.explore_outlined,
                            label: LocaleService.I.t('home.btn_adventure'),
                            color: AppTheme.damageOrange,
                            onTap: () => context.push('/shop/adventure')),
                        // 游戏选择菜单下方：广告横幅（真实 Adsterra 横幅）
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
                          child: SizedBox(
                              height: 250,
                              width: double.infinity,
                              child: AdBannerSlot()),
                        ),
                        const SizedBox(height: 24),
                        // 下载 Android/iOS 的页面按钮仅 Web 端展示（Android/iOS 原生不提供）
                        if (kIsWeb) ...[
                          _buildDownloadSection(),
                          const SizedBox(height: 24),
                        ],
                        _buildVersionText(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 游客提示：注册登录后解锁新手 20 张卡牌与每周试用卡牌
  Widget _buildGuestHint() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.goldAccent.withAlpha(90), width: 1),
      ),
      child: Row(children: [
        Expanded(
            child: Text(LocaleService.I.t('home.guest_hint'),
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 12))),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () => context.push('/auth/login'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.goldAccent,
            side: BorderSide(color: AppTheme.goldAccent.withAlpha(120)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Text(LocaleService.I.t('home.guest_register'),
              style: const TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final auth = ref.watch(authProvider);
    final loggedIn = auth != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppTheme.borderGold.withAlpha(60)))),
      child: Row(children: [
        _buildSchoolEmblem(),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(LocaleService.I.t('home.title'),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 4)),
          Text(LocaleService.I.t('home.subtitle'),
              style: TextStyle(
                  fontSize: 10, color: AppTheme.textMuted, letterSpacing: 3)),
        ])),
        _buildUserMenu(loggedIn, auth),
      ]),
    );
  }

  Widget _buildUserMenu(bool loggedIn, AuthState? auth) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (v) async {
        switch (v) {
          case 'login':
            context.push('/auth/login');
            break;
          case 'sound':
            AudioManager.I.toggleMute();
            setState(() {});
            break;
          case 'transactions':
            if (loggedIn) {
              context.push('/shop/transactions');
            } else {
              // 未登录：提示先登录查看交易记录
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(LocaleService.I.t('home.login_first_transactions')),
                ));
              }
            }
            break;
          case 'support':
            if (auth != null) {
              await showSupportDialog(context, token: auth.token);
            } else {
              // 未登录：提示先登录再联系客服
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(LocaleService.I.t('home.login_first_support')),
                ));
              }
            }
            break;
          case 'skin':
            if (!context.mounted) break;
            // 皮肤：未登录提示先登录；已登录显示敬请期待
            if (!loggedIn) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(LocaleService.I.t('home.login_first_skin')),
              ));
              break;
            }
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.agedWood,
                title: Text(LocaleService.I.t('home.skin'),
                    style: const TextStyle(color: AppTheme.parchment)),
                content: Text(LocaleService.I.t('home.skin_coming_soon'),
                    style: const TextStyle(color: AppTheme.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(LocaleService.I.t('ok'),
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            );
            break;
          case 'lang_zh':
            await LocaleService.I.init(localeCode: 'zh');
            await SharedPreferences.getInstance()
                .then((p) => p.setString('locale_code', 'zh'));
            setState(() {});
            break;
          case 'lang_en':
            await LocaleService.I.init(localeCode: 'en');
            await SharedPreferences.getInstance()
                .then((p) => p.setString('locale_code', 'en'));
            setState(() {});
            break;
          case 'lang_zh_TW':
            await LocaleService.I.init(localeCode: 'zh_TW');
            await SharedPreferences.getInstance()
                .then((p) => p.setString('locale_code', 'zh_TW'));
            setState(() {});
            break;
          case 'legal':
            context.push('/legal');
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
          color:
              loggedIn ? AppTheme.goldAccent.withAlpha(60) : AppTheme.bgMedium,
          border: Border.all(
              color: loggedIn ? AppTheme.goldAccent : AppTheme.borderLight,
              width: 1.5),
        ),
        child: loggedIn
            ? Center(
                child: Text(
                  auth!.playerName.isNotEmpty
                      ? auth.playerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppTheme.goldAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              )
            : const Icon(Icons.person_outline,
                color: AppTheme.textMuted, size: 20),
      ),
      itemBuilder: (_) {
        return [
          if (loggedIn) ...[
            PopupMenuItem(
                value: 'info',
                enabled: false,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${auth!.playerName}',
                          style: const TextStyle(
                              color: AppTheme.goldAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(
                          'ID: ${auth.playerId.length > 8 ? auth.playerId.substring(0, 8) : auth.playerId}…',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 9)),
                    ])),
            const PopupMenuDivider(),
          ],
          PopupMenuItem(
              value: 'sound',
              child: ListTile(
                leading: Icon(
                    AudioManager.I.isMuted ? Icons.volume_off : Icons.volume_up,
                    color: AppTheme.parchment,
                    size: 20),
                title: Text(
                    LocaleService.I.t(AudioManager.I.isMuted
                        ? 'home.sound_off'
                        : 'home.sound_on'),
                    style: TextStyle(color: AppTheme.parchment)),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )),
          // 交易记录：仅登录可用，未登录点击提示登录
          PopupMenuItem(
              value: 'transactions',
              child: ListTile(
                leading: const Icon(Icons.receipt_long,
                    color: AppTheme.parchment, size: 20),
                title: Text(LocaleService.I.t('home.transactions'),
                    style: const TextStyle(color: AppTheme.parchment)),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )),
          PopupMenuItem(
              value: 'support',
              child: ListTile(
                leading: const Icon(Icons.support_agent,
                    color: AppTheme.parchment, size: 20),
                title: Text(LocaleService.I.t('home.contact_support'),
                    style: const TextStyle(color: AppTheme.parchment)),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )),
          // 皮肤：未登录提示登录；已登录显示敬请期待
          PopupMenuItem(
              value: 'skin',
              child: ListTile(
                leading: const Icon(Icons.checkroom,
                    color: AppTheme.parchment, size: 20),
                title: Text(LocaleService.I.t('home.skin'),
                    style: const TextStyle(color: AppTheme.parchment)),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )),
          PopupMenuItem<String>(
            enabled: false,
            child: Row(children: [
              const Icon(Icons.language, color: AppTheme.parchment, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: LocaleService.I.localeCode,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: AppTheme.agedWood,
                    style: const TextStyle(
                        color: AppTheme.parchment, fontSize: 13),
                    onChanged: (v) {
                      if (v != null && v != LocaleService.I.localeCode) {
                        _changeLanguage(v);
                      }
                    },
                    items: [
                      for (final l in _languages)
                        DropdownMenuItem(
                          value: l.code,
                          child: Text(l.label,
                              style: const TextStyle(
                                  color: AppTheme.parchment, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          // 法律法规与相关声明：所有用户可用
          PopupMenuItem(
              value: 'legal',
              child: ListTile(
                leading: const Icon(Icons.gavel,
                    color: AppTheme.parchment, size: 20),
                title: Text(LocaleService.I.t('home.legal'),
                    style: const TextStyle(color: AppTheme.parchment)),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )),
          const PopupMenuDivider(),
          if (loggedIn)
            PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading:
                      const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  title: Text(LocaleService.I.t('home.logout'),
                      style: const TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ))
          else
            PopupMenuItem(
                value: 'login',
                child: ListTile(
                    leading: const Icon(Icons.login, color: AppTheme.parchment),
                    title: Text(LocaleService.I.t('home.login'),
                        style: const TextStyle(color: AppTheme.parchment)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact)),
        ];
      },
    );
  }

  Widget _buildSchoolEmblem() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderGold, width: 1.5),
          gradient: const RadialGradient(
              colors: [Color(0x1EB8860B), Color(0xFF3D2B1F)])),
      child: const Center(
          child: Text('戰',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldAccent))),
    );
  }

  Widget _buildGoldDivider() {
    return Container(
        height: 2,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          Colors.transparent,
          AppTheme.borderGold.withAlpha(60),
          AppTheme.borderGold.withAlpha(120),
          AppTheme.borderGold.withAlpha(60),
          Colors.transparent,
        ])));
  }

  Widget _buildMenuButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return WMenuPlaque(
        icon: icon, label: label, accentColor: color, onTap: onTap);
  }

  Widget _buildDownloadSection() {
    final version = LocaleService.I.t('home.version');
    return Column(
      children: [
        WSectionTitle(
            label: LocaleService.I.t('home.download_title'),
            icon: Icons.phone_android),
        WMenuPlaque(
          icon: Icons.android,
          label: LocaleService.I.t('home.download_android'),
          subtitle: '${_apkVariants.first.label} · $version',
          accentColor: const Color(0xFF3DDC84),
          onTap: () => launchUrl(Uri.parse(_apkVariants.first.file),
              mode: LaunchMode.externalApplication),
        ),
        WMenuPlaque(
          icon: Icons.apple,
          label: LocaleService.I.t('home.download_ios'),
          subtitle: '${LocaleService.I.t('home.ios_reviewing')} · $version',
          accentColor: AppTheme.manaBlue,
          onTap: () {
            if (_iosStoreUrl.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(LocaleService.I.t('home.ios_reviewing')),
                    backgroundColor: AppTheme.goldAccent),
              );
            } else {
              launchUrl(Uri.parse(_iosStoreUrl),
                  mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }

  Widget _buildStarterBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.goldAccent.withAlpha(40),
              AppTheme.bgLight.withAlpha(200),
              AppTheme.goldAccent.withAlpha(20)
            ]),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppTheme.goldAccent.withAlpha(120), width: 1.5)),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.card_giftcard, color: AppTheme.goldBright, size: 32),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(LocaleService.I.t('home.starter_title'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                Text(LocaleService.I.t('home.starter_desc'),
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted)),
              ])),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final ok = await PurchaseService.I.purchase('starter_bundle');
              if (!context.mounted) return;
              if (ok.success)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(LocaleService.I.t('home.purchase_success')),
                    backgroundColor: AppTheme.healGreen));
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('\$0.99'),
          ),
        ]),
      ),
    );
  }

  Widget _buildVersionText() {
    return Text(LocaleService.I.t('home.version'),
        style:
            TextStyle(fontSize: 10, color: AppTheme.textMuted.withAlpha(120)));
  }
}

class _WeeklyTrialDialog extends StatelessWidget {
  const _WeeklyTrialDialog({required this.cards});
  final List<domain.Card> cards;

  static const _rc = {
    domain.Rarity.common: Color(0xFF9E9E9E),
    domain.Rarity.rare: Color(0xFF2196F3),
    domain.Rarity.epic: Color(0xFF9C27B0),
    domain.Rarity.legendary: Color(0xFFFF9800)
  };
  static final _rl = {
    domain.Rarity.common: LocaleService.I.t('card_library.rarity_common'),
    domain.Rarity.rare: LocaleService.I.t('card_library.rarity_rare'),
    domain.Rarity.epic: LocaleService.I.t('card_library.rarity_epic'),
    domain.Rarity.legendary: LocaleService.I.t('card_library.rarity_legendary')
  };

  @override
  Widget build(BuildContext context) {
    // 手机竖屏小屏下内容可能超高：限制最大高度并允许滚动，
    // 避免按钮被挤出屏幕外（不可见/不可点击）。
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(LocaleService.I.t('home.trial_weekly_title'),
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(LocaleService.I.t('home.trial_weekly_desc'),
                style: TextStyle(
                    color: Colors.white.withAlpha(180), fontSize: 12)),
            const SizedBox(height: 16),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cards.map((c) {
                  final rc = _rc[c.rarity]!;
                  final imgPath =
                      CardImageService.getImageByType(c.id, _typeEng(c.type));
                  return Container(
                    width: 84,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: rc.withAlpha(160), width: 1.5)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AspectRatio(
                          aspectRatio: 0.72,
                          child: imgPath.isNotEmpty
                              ? QueuedAssetImage(
                                  path: imgPath,
                                  placeholderColor: rc.withAlpha(60),
                                  placeholderBuilder: (_) =>
                                      _trialPlaceholder(c, rc))
                              : _trialPlaceholder(c, rc)),
                      Container(
                          padding: const EdgeInsets.all(4),
                          color: const Color(0xFF16213E),
                          child: Column(children: [
                            Text(c.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 2),
                            Text(
                                LocaleService.I.t('home.trial_cost', args: {
                                  'rarity': _rl[c.rarity] ?? '',
                                  'cost': '${c.cost}'
                                }),
                                style: TextStyle(color: rc, fontSize: 8)),
                          ])),
                    ]),
                  );
                }).toList()),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text(LocaleService.I.t('home.trial_accept'),
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black)),
                )),
          ]),
        ),
      ),
    );
  }

  /// 卡牌类型 → 英文（CardImageService.getImageByType 需要）
  String _typeEng(domain.CardType t) => switch (t) {
        domain.CardType.minion => 'minion',
        domain.CardType.spell => 'spell',
        domain.CardType.weapon => 'weapon',
      };

  /// 卡图缺失时的占位（稀有度色块 + 卡名首字）
  Widget _trialPlaceholder(domain.Card c, Color rc) => Container(
        color: rc.withAlpha(60),
        alignment: Alignment.center,
        child: Text(c.name.isNotEmpty ? c.name[0] : '?',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
      );
}
