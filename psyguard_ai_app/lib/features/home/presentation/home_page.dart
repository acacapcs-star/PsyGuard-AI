import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../ers/silence_detector.dart';
import '../../ers/cumulative_risk_engine.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/background_theme_service.dart';
import '../../../core/theme/mood_theme_service.dart';
import 'package:go_router/go_router.dart';

import '../../../core/risk_engine/risk_models.dart';
import '../../../core/risk_engine/risk_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/database_provider.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/widgets/app_brand_icon.dart';
import '../../../core/widgets/floating_app_brand.dart';
import '../../../core/widgets/mood_fall_overlay.dart';
import '../../../core/widgets/snow_cap.dart';
import '../../../core/widgets/paw_tap.dart';
import '../../../core/widgets/fish_pond.dart';
import '../../../core/widgets/penguin_nest.dart';
import '../../../core/widgets/beach_corner.dart';
import '../../../core/widgets/hongbao_layer.dart';
import '../../../core/widgets/micro_shake.dart';
import '../../../core/widgets/tooltip_bubble.dart';
import '../../../core/widgets/brand_loading_indicator.dart';
import '../../../core/security/local_settings_service.dart';
import '../../../l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDashboard {
  HomeDashboard({
    required this.todayCheckin,
    required this.todaySleep,
    required this.todayCheckinRisk,
    required this.latestRisk,
    required this.recentNotes,
  });

  final DailyCheckin? todayCheckin;
  final SleepLog? todaySleep;
  final RiskSnapshotResult? todayCheckinRisk;
  final RiskSnapshot? latestRisk;
  final List<String> recentNotes;
}

final homeDashboardProvider = FutureProvider<HomeDashboard>((ref) async {
  final db = ref.read(appDatabaseProvider);
  final riskEngine = ref.read(riskEngineProvider);
  final since = DateTime.now().subtract(const Duration(days: 3));
  final messages = await db.getMessagesSince(since);
  final checkins = await db.getCheckinsSince(since);
  final todayCheckin = await db.getTodayCheckin();
  final notes = <String>[
    ...messages.map((m) => m.content),
    ...checkins.where((c) => c.note != null).map((c) => c.note!),
  ];

  return HomeDashboard(
    todayCheckin: todayCheckin,
    todaySleep: await db.getTodaySleepLog(),
    todayCheckinRisk: todayCheckin == null
        ? null
        : riskEngine.evaluateCheckin(
            moodScore: todayCheckin.moodScore,
            stressScore: todayCheckin.stressScore,
            energyScore: todayCheckin.energyScore,
          ),
    latestRisk: await db.getLatestRiskSnapshot(),
    recentNotes: notes,
  );
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final theme = Theme.of(context);
    final copy = AppStrings.of(ref.watch(appLanguageControllerProvider));

    // Dynamic greeting
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? copy.goodMorning
        : (hour < 18 ? copy.goodAfternoon : copy.goodEvening);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: LumiTheme.background,
      ),
      child: Scaffold(
        backgroundColor: (() {
          final moodColor = ref.watch(moodThemeProvider).backgroundColor;
          if (moodColor.a != 0) return moodColor; // 有選氛圍（非「無」），優先使用
          return ref.watch(backgroundThemeProvider).backgroundColor; // 沒選氛圍，回到深淺模式
        })(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 76,
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: FloatingAppBrandIcon(size: 66),
          ),
        ),
        body: PawTapLayer(
          child: Stack(
          children: [
            // ☀️ 夏天全頁魚池（視覺層，墊在卡片後面）
            const Positioned.fill(child: FishVisualLayer()),
            // 原本的首頁內容
            Positioned.fill(
              child: dashboard.when(
                data: (data) => _HomeContent(
                  data: data,
                  greeting: greeting,
                  theme: theme,
                  copy: copy,
                ),
                loading: () =>
                    Center(child: BrandLoadingIndicator(message: copy.loading)),
                error: (error, stack) =>
                    Center(child: Text(copy.loadFailed(error))),
              ),
            ),
            // 氛圍飄落動畫圖層（IgnorePointer，不會擋到任何互動）
            Positioned.fill(
              child: MoodFallOverlay(
                controller: ref.watch(moodFallControllerProvider),
                effect: ref.watch(moodThemeProvider).fallEffect,
              ),
            ),
            // 🧧 過年紅包（點了開金額、灑金幣鈔票）
            const Positioned.fill(child: HongbaoLayer()),
            // ☀️ 魚與籃球的觸控層（只有魚/球位置攔截手指，其他全穿透）
            const Positioned.fill(child: FishTouchLayer()),
          ],
        ),
        ),
        drawer: _buildDrawer(context, copy),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppStrings copy) {
    final items = [
      ('/home', copy.navHome, Icons.home_rounded),
      ('/chat', copy.navChat, Icons.chat_bubble_rounded),
      ('/checkin', copy.navCheckin, Icons.edit_note_rounded),
      ('/sleep', copy.navSleep, Icons.bedtime_rounded),
      ('/trends', copy.navTrends, Icons.timeline_rounded),
      ('/tools', copy.navTools, Icons.style_rounded),
      ('/safety', copy.navSafety, Icons.health_and_safety_rounded),
      ('/export', copy.navExport, Icons.download_rounded),
      ('/settings', copy.navSettings, Icons.settings_rounded),
    ];

    return Drawer(
      backgroundColor: const Color(0xFFF9F9F8),
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBrandIcon(
                  size: 52,
                  radius: 16,
                  padding: 4,
                  backgroundColor: Color(0xFFF7FAF6),
                  borderColor: Color(0xFFE2E9E2),
                ),
                const SizedBox(height: 12),
                Text(
                  'lii',
                  style: GoogleFonts.varelaRound(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: LumiTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: items.map((item) {
                final currentRoute = GoRouterState.of(context).uri.toString();
                final isActive = currentRoute == item.$1;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isActive
                        ? LumiTheme.primary.withValues(alpha: 0.1)
                        : null,
                    leading: Icon(
                      item.$3,
                      color: isActive
                          ? LumiTheme.primary
                          : LumiTheme.textSecondary,
                    ),
                    title: Text(
                      item.$2,
                      style: GoogleFonts.nunitoSans(
                        color: isActive
                            ? LumiTheme.primary
                            : LumiTheme.textPrimary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(item.$1);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Home Content (StatefulWidget for animations) ────────────────────
class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.data,
    required this.greeting,
    required this.theme,
    required this.copy,
  });

  final HomeDashboard data;
  final String greeting;
  final ThemeData theme;
  final AppStrings copy;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  int _cumulativeCount = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await SilenceDetector().recordActivity();
    final count = await CumulativeRiskEngine().getRedCount();
    final alert = await SilenceDetector().checkSilence();
    if (mounted) {
      setState(() => _cumulativeCount = count);
      if (alert != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(alert.messageFor(widget.copy.isZhTw),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(widget.copy.isZhTw ? '我在' : "I'm here"),
                  ),
                ],
              ),
            ),
          );
        });
      }
    }
  }
  // Bold logic: check recent notes for negative keywords
  bool get _hasNegativeSignal {
    final notes = widget.data.recentNotes.join(' ');
    return LumiTheme.negativeKeywords.any((kw) => notes.contains(kw));
  }

  int get _riskScore =>
      widget.data.todayCheckinRisk?.riskScore ??
      widget.data.latestRisk?.riskScore ??
      20;
  String get _riskLevel =>
      widget.data.todayCheckinRisk?.riskLevelKey ??
      widget.data.latestRisk?.riskLevel ??
      'low';
  bool get _isHighRisk => _riskScore >= 70;
  IconData get _statusIcon => switch (_riskLevel) {
    'high' => Icons.sentiment_very_dissatisfied_rounded,
    'medium' => Icons.sentiment_neutral_rounded,
    _ => Icons.sentiment_very_satisfied_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final copy = widget.copy;
    final engine = CumulativeRiskEngine();
    final cumulativeColor = Color(int.parse(engine.colorForCount(_cumulativeCount).replaceAll('#', '0xFF')));
    final riskColor = _cumulativeCount > 0 ? cumulativeColor : LumiTheme.riskColor(_riskScore);
    final riskLabel = engine.labelForCount(_cumulativeCount, isZh: copy.isZhTw);

    final exploreCards = [
      _cardData(
        copy.navCheckin,
        copy.emotionalRelease,
        Icons.edit_note_rounded,
        const Color(0xFFD4A373),
        '/checkin',
        copy.isZhTw
            ? '把心裡的感受寫下來，讓自己慢慢看見、慢慢理解。'
            : 'Write down what you feel so you can see and understand it more gently.',
      ),
      _cardData(
        copy.trendsTitle,
        copy.healthDataTrends,
        Icons.favorite_rounded,
        const Color(0xFFE5989B),
        '/trends',
        copy.isZhTw
            ? '用溫柔的方式，看見你的變化，一步步找回自己的節奏。'
            : 'See your changes gently and find your rhythm step by step.',
      ),
      _cardData(
        copy.navChat,
        copy.supportiveChat,
        Icons.chat_bubble_outline_rounded,
        const Color(0xFF5B8C85),
        '/chat',
        copy.isZhTw
            ? '有些時候，你只需要被聽見，我會一直在，安靜陪著你。'
            : 'Sometimes you just need to be heard. I am here with you.',
      ),
      _cardData(
        copy.navSleep,
        copy.sleepStatus,
        Icons.bedtime_outlined,
        const Color(0xFF6D8299),
        '/sleep',
        copy.isZhTw
            ? '看見每晚的睡眠變化，慢慢找回適合自己的作息節奏。'
            : 'Track nightly sleep changes and rebuild a rhythm that fits you.',
      ),
      _cardData(
        copy.isZhTw ? '年度總覽' : 'Year Overview',
        copy.isZhTw ? '重點行事曆' : 'Key Calendar',
        Icons.calendar_month_rounded,
        const Color(0xFF0ABFBC),
        '/calendar-overview',
        copy.isZhTw
            ? '一眼看見全年重要事項，紅色緊急、黃色重要，一目了然。'
            : 'See all important items at a glance — red for urgent, yellow for important.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const SizedBox(height: 12),
        // ── Greeting ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.greeting,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: LumiTheme.textPrimary,
                ),
              ),
            ),
            const _SunMoonToggle(),
          ],
        ),
        Text(
          copy.peacefulDay,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: LumiTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        // ── Status Card + Sticky Note + Pet (PageView with arrows) ─────
        _SwipeableCards(
          riskColor: riskColor,
          riskLabel: riskLabel,
          todayStatus: copy.todayStatus,
          statusIcon: _statusIcon,
          theme: theme,
        ),
        const SizedBox(height: 32),

        if (_isHighRisk) ...[
          MicroShake(
            enabled: true,
            child: _InteractiveCard(
              title: copy.isZhTw ? '行政救援' : 'Emergency Support',
              subtitle: copy.emergencyCase,
              icon: Icons.emergency_rounded,
              color: const Color(0xFFD14343),
              route: '/safety',
              isBold: true,
              isFullWidth: true,
              tooltipTitle: copy.isZhTw ? '行政救援（案號）' : 'Emergency Support',
              tooltipDescription: copy.isZhTw
                  ? '緊急時刻，為你媒合校園與市府實體資源。'
                  : 'Connect with campus and city support resources in urgent moments.',
            ),
          ),
          const SizedBox(height: 32),
        ],

        // ── Explore Section ──────────────────────────
        Row(
          children: [
            Flexible(
              child: Text(
                copy.exploreSelf,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // ☀️🏖️ 夏天/暑假：四杯飲料選單（其他氛圍不顯示）
            // FittedBox：空間不夠時整排等比縮小，不會擠爆版面
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: DrinkBarStrip(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.55,
          children: [
            ...exploreCards.map((card) {
            final isBoldTarget =
                _hasNegativeSignal &&
                (card['route'] == '/chat' || card['route'] == '/tools');
            final isShakeTarget = _isHighRisk && (card['route'] == '/safety');

            return MicroShake(
              enabled: isShakeTarget,
              child: _InteractiveCard(
                title: card['title'] as String,
                subtitle: card['subtitle'] as String,
                icon: card['icon'] as IconData,
                color: card['color'] as Color,
                route: card['route'] as String,
                isBold: isBoldTarget,
                tooltipTitle: card['title'] as String,
                tooltipDescription: card['tooltip'] as String,
              ),
            );
          }),
            // 年度總覽旁的空位：雪系氛圍時企鵝來窩著
            const _CornerPenguin(),
          ],
        ),
        const SizedBox(height: 32),

        // 🐧 蛋滿 5 顆才展開的巢窩
        PenguinNestRow(isZh: copy.isZhTw),

        // ── More Functions ───────────────────────────
        Row(
          children: [
            Text(copy.moreFeatures, style: theme.textTheme.titleMedium),
            const Spacer(),
            // 🥤 你選的那杯飲料（還沒選就不顯示）
            const ChosenDrinkBadge(),
            // 🧧 過年：紅包固定在這裡（其他氛圍不顯示，和飲料吧不會同框）
            const HongbaoEnvelope(),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.55,
          children: [
            MicroShake(
              enabled: _isHighRisk,
              child: _InteractiveCard(
                title: copy.navTools,
                subtitle: copy.moodFirstAid,
                icon: Icons.medical_services_rounded,
                color: const Color(0xFF6B4C9A),
                route: '/tools',
                isBold: _hasNegativeSignal,
                tooltipTitle: copy.navTools,
                tooltipDescription: copy.isZhTw
                    ? '當你開始感到不安，我會陪你慢慢穩下來。'
                    : 'When you start to feel unsettled, these tools can help you steady yourself.',
              ),
            ),
            _InteractiveCard(
              title: copy.navExport,
              subtitle: copy.sevenDaySummary,
              icon: Icons.mark_email_read_rounded,
              color: const Color(0xFF667EEA),
              route: '/export',
              tooltipTitle: copy.navExport,
              tooltipDescription: copy.isZhTw
                  ? '把你的狀態整理成一份安心，需要時也能分享給專業的人。'
                  : 'Turn your records into a clear summary you can share with a professional.',
            ),
            _InteractiveCard(
              title: copy.isZhTw ? '🐧 Lumi 樂園' : '🐧 Lumi Park',
              subtitle: copy.isZhTw ? '和企鵝互動紓壓' : 'Play with Lumi',
              icon: Icons.pets_rounded,
              color: const Color(0xFF0ABFBC),
              route: '/penguin',
              tooltipTitle: copy.isZhTw ? 'Lumi 樂園' : 'Lumi Park',
              tooltipDescription: copy.isZhTw
                  ? '和Lumi互動、丟魚、摸摸，讓心情好一點。'
                  : 'Feed Lumi, pet Lumi, and feel a little better.',
            ),
            _InteractiveCard(
              title: copy.isZhTw ? '嘿，在嗎？' : 'Hey, Lumi?',
              subtitle: copy.isZhTw ? '聲控喚醒Lumi' : 'Voice wake Lumi',
              icon: Icons.mic_rounded,
              color: const Color(0xFF5B6EAE),
              route: '/voice',
              tooltipTitle: copy.isZhTw ? '聲控喚醒' : 'Voice Wake',
              tooltipDescription: copy.isZhTw
                  ? '說「嘿，在嗎？」喚醒Lumi陪你聊聊。'
                  : 'Say "Hey Lumi" to wake up your companion.',
            ),
          ],
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Map<String, dynamic> _cardData(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
    String tooltip,
  ) {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'color': color,
      'route': route,
      'tooltip': tooltip,
    };
  }
}

/// Interactive card with micro-zoom press effect, long-press tooltip,
/// and dynamic bold text.
class _InteractiveCard extends StatefulWidget {
  const _InteractiveCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.isBold = false,
    this.isFullWidth = false,
    this.tooltipTitle,
    this.tooltipDescription,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final bool isBold;
  final bool isFullWidth;
  final String? tooltipTitle;
  final String? tooltipDescription;

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color.withValues(alpha: 0.08);

    return SnowCap(
      // 雪系氛圍時，卡片頂端會積雪；按住雪堆用手溫融化它
      child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(widget.route);
      },
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        if (widget.tooltipTitle != null && widget.tooltipDescription != null) {
          showFeatureTooltip(
            context,
            title: widget.tooltipTitle!,
            description: widget.tooltipDescription!,
          );
        }
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  // 秋天氛圍時，小狐狸可能躲在這個 icon 口袋後面
                  FoxPocket(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon,
                          color: widget.color, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 15,
                        fontWeight: widget.isBold
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: LumiTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          color: LumiTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: LumiTheme.textLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class StickyNotePage extends StatefulWidget {
  final Color color;
  final Color borderColor;
  final String hintText;
  final String storageKey;
  const StickyNotePage({
    required this.color,
    required this.borderColor,
    required this.hintText,
    required this.storageKey,
  });
  @override
  State<StickyNotePage> createState() => StickyNotePageState();
}

class StickyNotePageState extends State<StickyNotePage> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(widget.storageKey) ?? '';
    if (mounted) setState(() => _ctrl.text = val);
  }

  Future<void> _save(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.storageKey, val);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: widget.borderColor),
              const SizedBox(width: 6),
              Text('✏️', style: TextStyle(fontSize: 12, color: widget.borderColor)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
                  onTap: () {},
              style: const TextStyle(fontSize: 13, height: 1.6),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: TextStyle(color: widget.borderColor.withOpacity(0.6), fontSize: 13),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableCards extends StatefulWidget {
  final Color riskColor;
  final String riskLabel;
  final String todayStatus;
  final IconData statusIcon;
  final ThemeData theme;

  const _SwipeableCards({
    required this.riskColor,
    required this.riskLabel,
    required this.todayStatus,
    required this.statusIcon,
    required this.theme,
  });

  @override
  State<_SwipeableCards> createState() => _SwipeableCardsState();
}

class _SwipeableCardsState extends State<_SwipeableCards> {
  final PageController _ctrl = PageController();
  int _page = 0;
  String _petName = '';
  String _petType = '';

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  Future<void> _loadPet() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _petName = prefs.getString('pet_name') ?? 'Lumi';
      _petType = prefs.getString('pet_type') ?? 'otter';
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = 4;
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              // 頁1：狀態卡片
              Consumer(
                builder: (context, ref, _) {
                  final isDark = ref.watch(backgroundThemeProvider).mode == BgMode.dark;
                  return Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: LumiTheme.softCard,
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: widget.riskColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(widget.statusIcon, color: widget.riskColor, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(widget.riskLabel,
                                    style: widget.theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: LumiTheme.textPrimary,
                                    )),
                                  const SizedBox(height: 4),
                                  Text(widget.todayStatus, style: widget.theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDark)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // 頁2：寵物卡片
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBDD7EE), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/${_petType}_happy.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) => Text(
                        _petType == 'otter' ? '🦦' : '🐹',
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_petName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C5282),
                          )),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0ABFBC).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _petType == 'otter' ? '🦦 水獺' : '🐹 豚鼠',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0ABFBC)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 頁3：桃紅便條紙
              StickyNotePage(
                color: const Color(0xFFFFE4EC),
                borderColor: const Color(0xFFFFB3C6),
                hintText: 'Jot anything down... 🌸',
                storageKey: 'sticky_pink',
              ),
              // 頁4：薄荷綠便條紙
              StickyNotePage(
                color: const Color(0xFFE4F9F0),
                borderColor: const Color(0xFF9FDEBD),
                hintText: 'Key priorities today... 🌿',
                storageKey: 'sticky_mint',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 頁面指示點 + 箭頭
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
              color: _page > 0 ? const Color(0xFF0ABFBC) : Colors.grey.shade300,
              onPressed: _page > 0 ? () => _ctrl.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ) : null,
            ),
            Row(
              children: List.generate(pages, (i) => Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page ? const Color(0xFF0ABFBC) : Colors.grey.shade300,
                ),
              )),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              color: _page < pages - 1 ? const Color(0xFF0ABFBC) : Colors.grey.shade300,
              onPressed: _page < pages - 1 ? () => _ctrl.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _SunMoonToggle extends ConsumerWidget {
  const _SunMoonToggle();

  void _showColorPicker(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final options = isDark
            ? [
                (BgColorChoice.navyDark, '深藍', const Color(0xFF0D1B2A)),
                (BgColorChoice.forestDark, '深墨綠', const Color(0xFF0D2818)),
              ]
            : [
                (BgColorChoice.blueLight, '淺藍', const Color(0xFFE3F2FD)),
                (BgColorChoice.greenLight, '淺綠', const Color(0xFFE8F5E9)),
              ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('選擇底色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: options.map((opt) {
                    return GestureDetector(
                      onTap: () {
                        ref.read(backgroundThemeProvider.notifier).setColor(opt.$1);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: opt.$3,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(opt.$2, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(backgroundThemeProvider);
    final isDark = themeState.mode == BgMode.dark;

    return GestureDetector(
      onTap: () => ref.read(backgroundThemeProvider.notifier).toggleMode(),
      onLongPress: () => _showColorPicker(context, ref, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isDark ? 0.25 : 1.0,
              child: const Icon(Icons.wb_sunny_rounded, size: 20, color: Color(0xFFF5A623)),
            ),
            const SizedBox(width: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isDark ? 1.0 : 0.25,
              child: const Icon(Icons.nightlight_round, size: 18, color: Color(0xFFC8E8FF)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 年度總覽旁的空位：雪系氛圍（冬/聖誕/寒假）時，工程師企鵝會來這裡窩著。
/// 點他會開心蹦跳一下；其他氛圍時維持原本的空位。
class _CornerPenguin extends ConsumerStatefulWidget {
  const _CornerPenguin();

  @override
  ConsumerState<_CornerPenguin> createState() => _CornerPenguinState();
}

class _CornerPenguinState extends ConsumerState<_CornerPenguin>
    with TickerProviderStateMixin {
  late final AnimationController _sway; // 平常微微搖晃
  late final AnimationController _bounce; // 點擊蹦跳
  // 🥚 蛋改由 penguinNest（core/widgets/penguin_nest.dart）統一管理，
  //    這樣巢窩那邊看得到同一份資料，也能存檔。

  @override
  void initState() {
    super.initState();
    penguinNest.addListener(_onNestChanged);
    penguinNest.load();
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    penguinNest.removeListener(_onNestChanged);
    _sway.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _onNestChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(moodThemeProvider);
    final effect = mood.fallEffect;
    if (mood == MoodTheme.christmas) {
      return const _OrnamentCatCorner(); // 🎄 掛飾裡的貓
    }
    if (mood == MoodTheme.winterBreak) {
      return const _SnowmanCorner(); // 🧣 一起堆雪人
    }
    if (mood == MoodTheme.newYear) {
      return const _NyDragonsCorner(); // 🧧 小龍賀歲
    }
    if (mood == MoodTheme.spring) {
      return const _EasterBunnyCorner(); // 🐰 復活節兔兔
    }
    if (mood == MoodTheme.summer) {
      return const SummerBeachCorner(); // ☀️ 海灘上的墨鏡貓與兔兔
    }
    if (mood == MoodTheme.summerBreak) {
      return const DrinkBarCorner(); // 🏖️ 排球男孩＋飲料吧
    }
    if (effect != FallEffectType.snow && effect != FallEffectType.leaves) {
      return const SizedBox.shrink(); // 沒有對應吉祥物的氛圍：維持空位
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _bounce.forward(from: 0);
        if (effect == FallEffectType.snow) {
          // ❄️ 企鵝生蛋！滿 5 顆會在「更多功能」上方展開巢窩開始孵化
          penguinNest.layEgg(-0.8 + math.Random().nextDouble() * 1.6);
        }
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([_sway, _bounce]),
        builder: (context, child) {
          final swayAngle = (_sway.value - 0.5) * 0.06; // 微微左右搖
          final jump = math.sin(_bounce.value * math.pi) * 12; // 蹦跳高度
          final squash = 1 + math.sin(_bounce.value * math.pi * 2) * 0.04;
          return Transform.translate(
            offset: Offset(0, -jump),
            child: Transform.rotate(
              angle: swayAngle,
              child: Transform.scale(scaleY: squash, child: child),
            ),
          );
        },
        child: effect == FallEffectType.snow
            // ❄️ 冬系：工程師企鵝（點他會生蛋）
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/mood_penguin.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('🐧', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  ),
                  // 🥚 生下來的蛋排在腳邊
                  if (penguinNest.stage == NestStage.filling)
                    for (int i = 0; i < penguinNest.eggs.length; i++)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment(penguinNest.eggs[i], 1.0),
                        child: Container(
                          width: 13,
                          height: 17,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF6),
                            borderRadius: const BorderRadius.all(
                                Radius.elliptical(7, 9)),
                            border: Border.all(
                                color: const Color(0xFFD8CDB8), width: 1),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            // 🍁 秋：燈下讀書狐狸
            : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/mood_fox_lamp.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🦊', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
      ),
    );
  }
}

/// 🎄 聖誕角落：掛飾裡的貓，像吊飾一樣輕輕搖擺，點他會叮一下。
class _OrnamentCatCorner extends StatefulWidget {
  const _OrnamentCatCorner();

  @override
  State<_OrnamentCatCorner> createState() => _OrnamentCatCornerState();
}

class _OrnamentCatCornerState extends State<_OrnamentCatCorner>
    with TickerProviderStateMixin {
  late final AnimationController _swing;
  late final AnimationController _jingle;

  @override
  void initState() {
    super.initState();
    _swing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _jingle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _swing.dispose();
    _jingle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 包一層 PawFreeZone：戳貓咪與貓貓球時不會出現貓掌
    return PawFreeZone(child: _buildOrnament());
  }

  Widget _buildOrnament() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _jingle.forward(from: 0); // 點貓或球，吊飾都會叮一下
      },
      child: Column(
        children: [
          // 貓貓球（加大版），只有吊飾在搖擺
          Expanded(
            flex: 11,
            child: ListenableBuilder(
              listenable: Listenable.merge([_swing, _jingle]),
              builder: (context, child) {
                final swing = (_swing.value - 0.5) * 0.16;
                final jingle = math.sin(_jingle.value * math.pi * 3) *
                    (1 - _jingle.value) *
                    0.2;
                return Transform.rotate(
                  angle: swing + jingle,
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: Transform.scale(
                scale: 1.50,
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/images/mood_ornament_cat.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🐱', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8), // 貓和毛球分開一點
          // 下面坐著橘貓，抬頭盯著貓貓球（放大並往下坐一點）
          Expanded(
            flex: 8,
            child: Transform.translate(
              // 數字越大貓咪越往下；超過 30 左右會畫出卡片外
              offset: const Offset(0, 28),
              child: Transform.scale(
                scale: 1.55,
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/images/mood_xmas_cat.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Text('🐈', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🧣 寒假角落：跟著下雪一起堆雪人。
/// 點球球下雪一次，雪人就長高一階（大雪球 → 身體＋頭 → 完成！）
/// 堆到第三階，貓咪會蹦出來跟完成的雪人合照。
class _SnowmanCorner extends ConsumerWidget {
  const _SnowmanCorner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(snowAccumulationProvider).clamp(0, 3);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: stage >= 3
          ? Padding(
              key: const ValueKey('snowman_done'),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/mood_snowman_cat.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('⛄', style: TextStyle(fontSize: 44)),
                ),
              ),
            )
          : stage == 0
              ? const Center(
                  key: ValueKey('snowman_hint'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⛄', style: TextStyle(fontSize: 28)),
                      SizedBox(height: 4),
                      Text(
                        '點球球下雪\n一起堆雪人',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : CustomPaint(
                  key: ValueKey('snowman_$stage'),
                  size: Size.infinite,
                  painter: _SnowmanPainter(stage: stage),
                ),
    );
  }
}

class _SnowmanPainter extends CustomPainter {
  _SnowmanPainter({required this.stage});

  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final base = size.height * 0.88;
    final body = Paint()..color = const Color(0xFFFAFDFF);
    final outline = Paint()
      ..color = const Color(0xFFBFD8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // 第一階：底部大雪球
    final r1 = size.shortestSide * 0.22;
    canvas.drawCircle(Offset(cx, base - r1), r1, body);
    canvas.drawCircle(Offset(cx, base - r1), r1, outline);

    if (stage >= 2) {
      // 第二階：身體 + 頭 + 眼睛
      final r2 = r1 * 0.72;
      final c2 = Offset(cx, base - r1 * 2 - r2 * 0.72);
      canvas.drawCircle(c2, r2, body);
      canvas.drawCircle(c2, r2, outline);
      final r3 = r1 * 0.5;
      final c3 = Offset(cx, c2.dy - r2 - r3 * 0.68);
      canvas.drawCircle(c3, r3, body);
      canvas.drawCircle(c3, r3, outline);
      final eye = Paint()..color = const Color(0xFF4A5A66);
      canvas.drawCircle(Offset(c3.dx - r3 * 0.35, c3.dy - r3 * 0.1), 1.6, eye);
      canvas.drawCircle(Offset(c3.dx + r3 * 0.35, c3.dy - r3 * 0.1), 1.6, eye);
    }
  }

  @override
  bool shouldRepaint(_SnowmanPainter old) => old.stage != stage;
}

/// 🧧 過年角落：小龍們賀歲，點一下會喜氣地晃一晃。
class _NyDragonsCorner extends StatefulWidget {
  const _NyDragonsCorner();

  @override
  State<_NyDragonsCorner> createState() => _NyDragonsCornerState();
}

class _NyDragonsCornerState extends State<_NyDragonsCorner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cheer;

  @override
  void initState() {
    super.initState();
    _cheer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _cheer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _cheer.forward(from: 0);
      },
      child: ListenableBuilder(
        listenable: _cheer,
        builder: (context, child) {
          final t = _cheer.value;
          final wob = math.sin(t * math.pi * 4) * (1 - t) * 0.05;
          final pop = 1 + math.sin(t * math.pi) * 0.05;
          return Transform.scale(
            scale: pop,
            child: Transform.rotate(angle: wob, child: child),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/mood_ny_dragons.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Text('🐉', style: TextStyle(fontSize: 44)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🌸 春天角落：復活節巧克力兔兔，點一下會開心地晃一晃。
class _EasterBunnyCorner extends StatefulWidget {
  const _EasterBunnyCorner();

  @override
  State<_EasterBunnyCorner> createState() => _EasterBunnyCornerState();
}

class _EasterBunnyCornerState extends State<_EasterBunnyCorner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hop;

  @override
  void initState() {
    super.initState();
    _hop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _hop.forward(from: 0);
      },
      child: ListenableBuilder(
        listenable: _hop,
        builder: (context, child) {
          final t = _hop.value;
          final wob = math.sin(t * math.pi * 4) * (1 - t) * 0.05;
          final hop = math.sin(t * math.pi) * 6; // 兔子式小跳
          return Transform.translate(
            offset: Offset(0, -hop),
            child: Transform.rotate(angle: wob, child: child),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/mood_easter_bunny.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Text('🐰', style: TextStyle(fontSize: 44)),
            ),
          ),
        ),
      ),
    );
  }
}
