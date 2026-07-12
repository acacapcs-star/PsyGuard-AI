import 'note_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/risk_engine/risk_models.dart';
import '../../../core/risk_engine/risk_provider.dart';
import '../../../core/security/local_settings_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../l10n/app_strings.dart';
import '../../ers/ers_engine.dart';
import '../../ers/ers_models.dart';
import '../../ers/ers_percentile_widget.dart';

class CheckinPage extends ConsumerStatefulWidget {
  const CheckinPage({super.key});

  @override
  ConsumerState<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends ConsumerState<CheckinPage> {
  double _mood = 50;
  double _stress = 50;
  double _energy = 50;
  final TextEditingController _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final copy = AppStrings.of(ref.read(appLanguageControllerProvider));
    if (_noteController.text.length > 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.noteTooLong)));
      return;
    }
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final mood = _mood.round();
      final stress = _stress.round();
      final energy = _energy.round();

      await ref
          .read(appDatabaseProvider)
          .upsertDailyCheckin(
            date: now,
            mood: mood,
            stress: stress,
            energy: energy,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );

      final risk = await ref
          .read(riskEvaluationServiceProvider)
          .evaluateAndPersistCheckin(
            date: now,
            mood: mood,
            stress: stress,
            energy: energy,
          );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(copy.savedRisk(risk.riskLevelKey.toUpperCase())),
        ),
      );

      // ERS分析
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final ersEngine = ERSEngine();
      // 讀取真實睡眠數據（行為串流）
      final db = ref.read(appDatabaseProvider);
      final yesterday = now.subtract(const Duration(days: 1));
      final sleepLogs = await db.getSleepLogsSince(yesterday);
      final realSleepHours = sleepLogs.isNotEmpty
          ? sleepLogs.last.sleepHours
          : 3.0;

      // 語言串流根據心理負荷感推算
      final inferredSpeechRate = stress > 70 ? 130.0 : stress > 50 ? 200.0 : 300.0;
      final inferredNegRatio = stress / 100.0 * 0.8;
      final inferredPauseFreq = stress > 70 ? 8.0 : stress > 50 ? 5.0 : 2.0;
      final ersResult = ersEngine.calculate(
        ERSInput(
          speechRate: inferredSpeechRate,
          negativeWordRatio: inferredNegRatio,
          pauseFrequency: inferredPauseFreq,
          moodScore: mood.toDouble(),
          stressScore: stress.toDouble(),
          energyScore: energy.toDouble(),
          sleepDuration: realSleepHours,
          appUsageStreak: mood < 30 ? 1.0 : mood < 50 ? 3.0 : 7.0,
          checkInConsistency: mood < 30 ? 0.2 : mood < 50 ? 0.5 : 0.8,
        ),
        const PersonalBaseline(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_ers_score', ersResult.adjustedERS);
      await prefs.setString('last_ers_level', ersResult.riskLevel);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('今日心理狀態分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ERSPercentileWidget(ersResult: ersResult, ageGroup: '高中'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (risk.riskLevel == RiskLevel.high || ersResult.riskLevel == 'red') {
                    context.go('/safety');
                  } else {
                    context.go('/home');
                  }
                },
                child: Text(ersResult.riskLevel == 'red' ? '⚠️ 前往求助資源' : '了解了'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.saveFailed(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppStrings.of(ref.watch(appLanguageControllerProvider));
    return Scaffold(
      backgroundColor: LumiTheme.background,
      appBar: AppBar(
        title: Text(copy.checkinTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            color: LumiTheme.textPrimary,
            onPressed: () => context.push('/checkin/history'),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildSliderSection(
            title: copy.mood,
            value: _mood,
            icon: _moodEmoji(_mood.round()),
            color: const Color(0xFF667EEA),
            minAssistiveLabel: copy.veryBad,
            maxAssistiveLabel: copy.veryGood,
            onChanged: (v) => setState(() => _mood = v),
          ),
          const SizedBox(height: 16),
          _buildSliderSection(
            title: copy.stress,
            value: _stress,
            icon: _stressEmoji(_stress.round()),
            color: const Color(0xFFF5576C),
            minAssistiveLabel: copy.veryBad,
            maxAssistiveLabel: copy.veryGood,
            onChanged: (v) => setState(() => _stress = v),
          ),
          const SizedBox(height: 16),
          _buildSliderSection(
            title: copy.energy,
            value: _energy,
            icon: _energyEmoji(_energy.round()),
            color: const Color(0xFF43E97B),
            minAssistiveLabel: copy.veryBad,
            maxAssistiveLabel: copy.veryGood,
            onChanged: (v) => setState(() => _energy = v),
          ),
          const SizedBox(height: 24),
          // Note section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: LumiTheme.softCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: LumiTheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      copy.todayNote,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: LumiTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotePage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0ABFBC).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '開啟獨立今日筆記本',
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold, 
                                  color: Color(0xFF2C5282),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '支援待辦勾選、列點與輕重緩急顏色標記',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0ABFBC)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(copy.completeCheckin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    String? minAssistiveLabel,
    String? maxAssistiveLabel,
    required ValueChanged<double> onChanged,
  }) {
    final percent = value.round().clamp(0, 100);
    final copy = AppStrings.of(ref.watch(appLanguageControllerProvider));
    final moodLabel = title == copy.mood
        ? _moodDescriptor(percent, copy)
        : title == copy.stress
            ? _stressDescriptor(percent, copy)
            : title == copy.energy
                ? _energyDescriptor(percent, copy)
                : null;

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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: LumiTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (moodLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      moodLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LumiTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(value: value, min: 0, max: 100, onChanged: onChanged),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEndpointLabel(
                  score: '0%',
                  assistiveLabel: minAssistiveLabel,
                  alignEnd: false,
                ),
                _buildEndpointLabel(
                  score: '100%',
                  assistiveLabel: maxAssistiveLabel,
                  alignEnd: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointLabel({
    required String score,
    String? assistiveLabel,
    required bool alignEnd,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          score,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: LumiTheme.textSecondary,
          ),
        ),
        if (assistiveLabel != null)
          Text(
            assistiveLabel,
            style: const TextStyle(
              fontSize: 10,
              color: LumiTheme.textLight,
            ),
          ),
      ],
    );
  }

  String _moodDescriptor(int value, AppStrings copy) {
    if (value <= 20) return copy.veryBad;
    if (value <= 40) return copy.bad;
    if (value <= 60) return copy.okay;
    if (value <= 80) return copy.good;
    return copy.veryGood;
  }

  String _stressDescriptor(int value, AppStrings copy) {
    if (value <= 20) return copy.veryGood;
    if (value <= 40) return copy.good;
    if (value <= 60) return copy.okay;
    if (value <= 80) return copy.bad;
    return copy.veryBad;
  }

  String _energyDescriptor(int value, AppStrings copy) {
    if (value <= 20) return copy.veryBad;
    if (value <= 40) return copy.bad;
    if (value <= 60) return copy.okay;
    if (value <= 80) return copy.good;
    return copy.veryGood;
  }

  // ── 滑桿表情連動 (Slider Emoji Linkage) ─────────────────────────
  IconData _moodEmoji(int value) {
    if (value <= 20) return Icons.sentiment_very_dissatisfied_rounded;
    if (value <= 40) return Icons.sentiment_dissatisfied_rounded;
    if (value <= 60) return Icons.sentiment_neutral_rounded;
    if (value <= 80) return Icons.sentiment_satisfied_rounded;
    return Icons.sentiment_very_satisfied_rounded;
  }

  IconData _stressEmoji(int value) {
    if (value <= 25) return Icons.spa_rounded;
    if (value <= 50) return Icons.psychology_rounded;
    if (value <= 75) return Icons.psychology_alt_rounded;
    return Icons.warning_amber_rounded;
  }

  IconData _energyEmoji(int value) {
    if (value <= 25) return Icons.battery_1_bar_rounded;
    if (value <= 50) return Icons.battery_3_bar_rounded;
    if (value <= 75) return Icons.battery_5_bar_rounded;
    return Icons.battery_full_rounded;
  }
}
