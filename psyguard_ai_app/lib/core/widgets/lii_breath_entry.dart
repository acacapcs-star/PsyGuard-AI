// ═══════════════════════════════════════════════════════════
// lii · 呼吸入口
//
// 首頁角落的一顆小球，自己輕輕呼吸，點下去進入呼吸會話。
//
// 對應規則沿用你 risk_engine 裡本來就有的門檻，不另外發明：
//   ERS >= 70 → safety flow（序曲壓成 5 秒 + 求助入口）
//   ERS >= 40 → check-in（序曲縮到 60%）
//   其餘      → daily（完整序曲）
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../pacer/breath_plan.dart';
import 'lii_breath_page.dart';
import 'package:go_router/go_router.dart';
import 'lii_orb.dart';

/// 入口按鈕的位置。撞到你其他浮動元件的話改這裡就好。
const double kLiiEntryRight = 18;
const double kLiiEntryBottom = 96;
const double kLiiEntrySize = 54;

/// ERS 分數 → 用哪種模式出現。門檻跟 risk_engine 一致。
LiiBreathMode liiModeFromErs(int ers) {
  if (ers >= 70) return LiiBreathMode.safety;
  if (ers >= 40) return LiiBreathMode.checkIn;
  return LiiBreathMode.daily;
}

/// 心情 / 壓力 / 活力 → 用哪一組節奏（0–100）。
///
/// 低落和焦慮要分開，因為處理方式是相反的：
/// 焦慮用長吐氣壓交感神經；低落用長吐氣只會更往下沉，要等長節奏提振。
BreathMood liiMoodFromSignals({
  required int mood,
  required int stress,
  required int energy,
}) {
  if (mood <= 35 && energy <= 30) return BreathMood.low;
  if (stress >= 65) return BreathMood.anxious;
  if (mood <= 35) return BreathMood.low;
  return BreathMood.calm;
}

class LiiBreathButton extends StatefulWidget {
  /// 目前的 ERS（riskScore）。給 null 就當 daily。
  final int? ers;

  /// 目前的情緒訊號。給 null 就當 calm。
  final int? mood;
  final int? stress;
  final int? energy;

  /// safety flow 那顆「我現在想找人說話」按下去要做什麼
  final VoidCallback? onAskForHelp;

  const LiiBreathButton({
    super.key,
    this.ers,
    this.mood,
    this.stress,
    this.energy,
    this.onAskForHelp,
  });

  @override
  State<LiiBreathButton> createState() => _LiiBreathButtonState();
}

class _LiiBreathButtonState extends State<LiiBreathButton>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final SilentBreath _silent = SilentBreath();
  final OrbSplit _split = OrbSplit();
  double _b = 0;
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    _b = _silent.valueAt(now.inMicroseconds / 1e6);
    // 首頁常駐的東西不需要 60fps。8–12 秒一次的呼吸，30fps 完全看不出差別。
    _skip = (_skip + 1) % 2;
    if (_skip != 0) return;
    if (mounted) setState(() {});
  }

  void _open() {
    final mode = widget.ers == null
        ? LiiBreathMode.daily
        : liiModeFromErs(widget.ers!);
    final mood = (widget.mood == null ||
            widget.stress == null ||
            widget.energy == null)
        ? BreathMood.calm
        : liiMoodFromSignals(
            mood: widget.mood!,
            stress: widget.stress!,
            energy: widget.energy!,
          );
    showLiiBreath(
      context,
      mood: mood,
      mode: mode,
      onAskForHelp: widget.onAskForHelp,
    );
  }

  // CARD_PREVIEW 長按 → Pacer Lift（你原本就有的那個）
  void _openCard() => context.push('/bookmark');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '陪你呼吸',
      child: GestureDetector(
        onLongPress: _openCard,
        child: SizedBox(
        width: kLiiEntrySize,
        height: kLiiEntrySize,
        child: LiiOrb(
          breath: _b,
          split: _split,
          amplitude: 1,
          lunaGlow: 0.42,
          onTap: _open,
          ),
        ),
      ),
    );
  }
}
