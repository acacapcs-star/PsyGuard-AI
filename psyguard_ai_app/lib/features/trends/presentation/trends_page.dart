import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/ai_chat_repository.dart';
import '../../../core/security/local_settings_service.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/database_provider.dart';
import '../../../core/widgets/geometric_stress_indicator.dart';
import '../../../core/widgets/brand_loading_indicator.dart';
import '../../../l10n/app_strings.dart';

class TrendBundle {
  TrendBundle({
    required this.checkins,
    required this.sleepLogs,
    required this.risks,
  });

  final List<DailyCheckin> checkins;
  final List<SleepLog> sleepLogs;
  final List<RiskSnapshot> risks;
}

final trendRangeProvider = StateProvider<int>((ref) => 30);

final trendBundleProvider = FutureProvider<TrendBundle>((ref) async {
  final range = ref.watch(trendRangeProvider);
  final db = ref.read(appDatabaseProvider);
  final since = DateTime.now().subtract(Duration(days: range - 1));

  final checkins = await db.getCheckinsSince(since);
  final sleepLogs = await db.getSleepLogsSince(since);
  final allRisks = await db.select(db.riskSnapshots).get();
  final risks = allRisks.where((item) => !item.date.isBefore(since)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return TrendBundle(checkins: checkins, sleepLogs: sleepLogs, risks: risks);
});

class TrendsPage extends ConsumerWidget {
  const TrendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(trendRangeProvider);
    final data = ref.watch(trendBundleProvider);
    final theme = Theme.of(context);
    final copy = AppStrings.of(ref.watch(appLanguageControllerProvider));

    return Scaffold(
      backgroundColor: LumiTheme.background,
      appBar: AppBar(
        title: Text(copy.trendsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: copy.analysisHistory,
            onPressed: () => context.push('/ai_history'),
          ),
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF6B4C9A),
            ),
            tooltip: copy.aiTrendAnalysis,
            onPressed: () => _showAiAnalysisDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final days in [7, 14, 30, 90])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        key: ValueKey('range_$days'),
                        label: Text(
                          days == 90 ? copy.threeMonths : copy.days(days),
                        ),
                        selected: range == days,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(trendRangeProvider.notifier).state = days;
                          }
                        },
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: range == days
                              ? Colors.white
                              : LumiTheme.textSecondary,
                          fontWeight: range == days
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        backgroundColor: LumiTheme.surface,
                        selectedColor: LumiTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: range == days
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: data.when(
              data: (bundle) {
                try {
                  // 取得最新風險分數用於圖標變色
                  final latestRiskScore = bundle.risks.isNotEmpty
                      ? bundle.risks.last.riskScore
                      : 20;
                  final riskIconColor = LumiTheme.riskColor(
                    latestRiskScore,
                  );

                  if (bundle.checkins.isEmpty &&
                      bundle.sleepLogs.isEmpty &&
                      bundle.risks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Icon(
                                Icons.timeline_rounded,
                                size: 48,
                                color: LumiTheme.primary.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              copy.noTrendData,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: LumiTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              copy.noTrendDataBody,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: LumiTheme.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.push('/checkin'),
                                    child: Text(copy.doCheckin),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/sleep'),
                                    child: Text(copy.recordSleep),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      // 案號浮水印
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Text(
                                copy.emergencyCase,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black.withValues(alpha: 0.03),
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: [
                          _chartCard(
                            context,
                            title: copy.moodPercentage,
                            icon: Icons.sentiment_satisfied_alt_rounded,
                            color: const Color(0xFF667EEA),
                            spots: _toSpots(
                              bundle.checkins
                                  .map((e) => e.moodScore.toDouble())
                                  .toList(),
                            ),
                            minY: 0,
                            maxY: 100,
                            formatYLabel: _formatPercentAxis,
                          ),
                          const SizedBox(height: 16),
                          _chartCard(
                            context,
                            title: copy.sleepHoursLabel,
                            icon: Icons.bedtime_rounded,
                            color: const Color(0xFFA18CD1),
                            spots: _toSpots(
                              bundle.sleepLogs
                                  .map((e) => e.sleepHours)
                                  .toList(),
                            ),
                            minY: 0,
                            maxY: 12,
                          ),
                          const SizedBox(height: 16),
                          // 風險分數卡 + 幾何壓力指示器
                          _chartCard(
                            context,
                            title: copy.riskScore,
                            icon: Icons.shield_rounded,
                            color: riskIconColor,
                            spots: _toSpots(
                              bundle.risks
                                  .map((e) => e.riskScore.toDouble())
                                  .toList(),
                            ),
                            minY: 0,
                            maxY: 100,
                            trailing: GeometricStressIndicator(
                              riskScore: latestRiskScore,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } catch (e) {
                  return Center(
                    child: Text(
                      copy.chartLoadError(e),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
              },
              loading: () => Center(
                child: BrandLoadingIndicator(message: copy.loadingTrendData),
              ),
              error: (error, stack) => Center(
                child: Text(
                  copy.loadFailed(error),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
    String Function(double value)? formatYLabel,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: LumiTheme.softCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: LumiTheme.textPrimary,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: true),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        (formatYLabel ?? _formatDefaultAxis)(value),
                        style: TextStyle(
                          fontSize: 11,
                          color: LumiTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? const [FlSpot(0, 0)] : spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: color,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _toSpots(List<double> values) {
    if (values.isEmpty) return const [FlSpot(0, 0)];
    return values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }

  String _formatDefaultAxis(double value) => value.toInt().toString();

  String _formatPercentAxis(double value) => '${value.toInt()}%';

  Future<void> _showAiAnalysisDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final copy = AppStrings.of(ref.read(appLanguageControllerProvider));
    final range = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(copy.chooseAiRange),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 30),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text(copy.lastMonth, style: const TextStyle(fontSize: 16)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 90),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text(
              copy.lastThreeMonths,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 365),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text(copy.lastYear, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (range == null) return;
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final db = ref.read(appDatabaseProvider);
      final since = DateTime.now().subtract(Duration(days: range));

      // 1. Fetch Data
      final checkins = await db.getCheckinsSince(since);
      final sleepLogs = await db.getSleepLogsSince(since);
      final allRisks = await db.select(db.riskSnapshots).get();
      final risks = allRisks
          .where((item) => !item.date.isBefore(since))
          .toList();

      // 2. Format Data for AI
      final moodSummary = checkins
          .map(
            (e) => copy.isZhTw
                ? '${e.date.toString().substring(0, 10)}:心情${e.moodScore}%'
                : '${e.date.toString().substring(0, 10)}: mood ${e.moodScore}%',
          )
          .join('\n');
      final sleepSummary = sleepLogs
          .map(
            (e) => copy.isZhTw
                ? '${e.date.toString().substring(0, 10)}:睡眠${e.sleepHours}hr'
                : '${e.date.toString().substring(0, 10)}: sleep ${e.sleepHours}hr',
          )
          .join('\n');
      final riskSummary = risks
          .map(
            (e) => copy.isZhTw
                ? '${e.date.toString().substring(0, 10)}:風險${e.riskScore}'
                : '${e.date.toString().substring(0, 10)}: risk ${e.riskScore}',
          )
          .join('\n');

      final inputData = copy.isZhTw
          ? '''
時間範圍：近 $range 天
-- 心情紀錄 --
$moodSummary
-- 睡眠紀錄 --
$sleepSummary
-- 風險分數 --
$riskSummary
'''
          : '''
Time range: last $range days
-- Mood Records --
$moodSummary
-- Sleep Records --
$sleepSummary
-- Risk Scores --
$riskSummary
''';

      // 3. Call AI
      final aiRepo = ref.read(aiChatRepositoryProvider);
      final report = await aiRepo.generateReport(analysisData: inputData);

      // 4. Save to DB
      await db.saveAiReport(rangeDays: range, content: report);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // 5. Navigate to Report Page (Top Level Route)
      context.push('/ai_report', extra: report);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.analysisFailed(e))));
    }
  }
}
