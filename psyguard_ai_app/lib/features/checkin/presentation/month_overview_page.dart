import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_language.dart';
import '../../../core/security/local_settings_service.dart';
import '../../../core/theme/background_theme_service.dart';

class MonthOverviewPage extends ConsumerStatefulWidget {
  const MonthOverviewPage({super.key});

  @override
  ConsumerState<MonthOverviewPage> createState() => _MonthOverviewPageState();
}

class _WeekSummary {
  final List<Map<String, dynamic>> redItems = [];
  final List<Map<String, dynamic>> yellowItems = [];
}

class _MonthOverviewPageState extends ConsumerState<MonthOverviewPage> {
  bool _loading = true;
  Map<int, List<_WeekSummary>> _monthData = {};

  @override
  void initState() {
    super.initState();
    _loadAllMonths();
  }

  Future<void> _loadAllMonths() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final year = now.year;

    final Map<int, List<_WeekSummary>> result = {};

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final weeks = <_WeekSummary>[];
      _WeekSummary current = _WeekSummary();

      for (int day = 1; day <= daysInMonth; day++) {
        final key = 'note_${year}_${month}_$day';
        final raw = prefs.getString(key);
        if (raw != null) {
          try {
            final List items = jsonDecode(raw);
            for (final item in items) {
              final priority = item['priority'] as int? ?? 12;
              final entry = {
                'text': item['text']?.toString() ?? '',
                'date': '$month/$day',
              };
              if (priority <= 4) {
                current.redItems.add(entry);
              } else if (priority <= 9) {
                current.yellowItems.add(entry);
              }
            }
          } catch (_) {
            // 忽略解析失敗的資料，不讓單一天的壞資料擋住整個月曆
          }
        }

        if (day % 7 == 0 || day == daysInMonth) {
          weeks.add(current);
          current = _WeekSummary();
        }
      }

      result[month] = weeks;
    }

    if (mounted) {
      setState(() {
        _monthData = result;
        _loading = false;
      });
    }
  }

  void _showWeekDetail(bool isZh, int month, int weekIndex, _WeekSummary week) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isZh ? '$month月 第${weekIndex + 1}週' : 'Month $month, Week ${weekIndex + 1}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (week.redItems.isEmpty && week.yellowItems.isEmpty)
                    Text(isZh ? '這週沒有重要事項' : 'No important items this week', style: TextStyle(color: Colors.grey.shade500)),
                  ...week.redItems.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${e['date']}：${e['text']}', style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                  ...week.yellowItems.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${e['date']}：${e['text']}', style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotsRow(List items, Color color) {
    if (items.isEmpty) return const SizedBox(height: 14);
    return Wrap(
      spacing: 4,
      children: List.generate(
        items.length > 8 ? 8 : items.length,
        (i) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  static const _monthNamesZh = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
  static const _monthNamesEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    final isZh = ref.watch(appLanguageControllerProvider) == AppLanguage.zhTw;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2C5282)),
          onPressed: () => context.go('/home'),
        ),
        title: Text(isZh ? '年度重點總覽' : 'Year Overview', style: const TextStyle(color: Color(0xFF2C5282))),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 12,
              itemBuilder: (context, idx) {
                final month = idx + 1;
                final weeks = _monthData[month] ?? [];
                final monthName = isZh ? _monthNamesZh[idx] : _monthNamesEn[idx];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0ABFBC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          monthName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...weeks.asMap().entries.map((entry) {
                        final weekIdx = entry.key;
                        final week = entry.value;
                        final hasAny = week.redItems.isNotEmpty || week.yellowItems.isNotEmpty;
                        final themeColor = ref.watch(backgroundThemeProvider).backgroundColor;
                        final isEven = weekIdx % 2 == 0;
                        final stripeColor = isEven
                            ? Colors.white
                            : Color.alphaBlend(themeColor.withValues(alpha: 0.18), Colors.white);
                        return GestureDetector(
                          onTap: hasAny ? () => _showWeekDetail(isZh, month, weekIdx, week) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: stripeColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: isEven
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    isZh ? '第${weekIdx + 1}週' : 'W${weekIdx + 1}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDotsRow(week.redItems, Colors.red),
                                      const SizedBox(height: 4),
                                      _buildDotsRow(week.yellowItems, Colors.amber),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
