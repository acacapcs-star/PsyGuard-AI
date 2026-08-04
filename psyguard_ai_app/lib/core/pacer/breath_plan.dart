// ═══════════════════════════════════════════════════════════
// lii · 呼吸序曲 — 純邏輯層
//
// 這個檔案不 import flutter，只吃 dart:math。
// 好處：壞掉的時候可以單獨測，不用開模擬器。
//
// 核心概念是「序曲」：不能把一個正在焦慮的人直接丟進 4-7-8。
// 他現在一分鐘呼吸 18 次，開場就要他停 7 秒等於憋不過去，
// 只會更慌然後關掉 app。所以要從他現在的速度起步，再慢慢拉慢。
// ═══════════════════════════════════════════════════════════

import 'dart:math' as math;

enum BreathMood { anxious, low, calm }

enum BreathStage { overture, ramp, main, outro }

enum BreathSegment { inhale, holdTop, exhale, holdBottom }

/// 一個呼吸循環的四段秒數。
class BreathPattern {
  final double inhale;
  final double holdTop;
  final double exhale;
  final double holdBottom;

  const BreathPattern(this.inhale, this.holdTop, this.exhale, this.holdBottom);

  double get total => inhale + holdTop + exhale + holdBottom;

  static BreathPattern lerp(BreathPattern a, BreathPattern b, double t) {
    return BreathPattern(
      a.inhale + (b.inhale - a.inhale) * t,
      a.holdTop + (b.holdTop - a.holdTop) * t,
      a.exhale + (b.exhale - a.exhale) * t,
      a.holdBottom + (b.holdBottom - a.holdBottom) * t,
    );
  }

  /// 給畫面顯示用：4.0 · 7.0 · 8.0（0 的段落不顯示）
  String get label {
    final parts = <String>[];
    for (final v in [inhale, holdTop, exhale, holdBottom]) {
      if (v > 0.05) parts.add(v.toStringAsFixed(1));
    }
    return parts.join('  ·  ');
  }
}

/// 每種心情一組節奏。
class MoodRecipe {
  final BreathPattern start;
  final BreathPattern target;
  final double overtureSeconds;
  final int rampCycles;
  final int mainCycles;

  const MoodRecipe({
    required this.start,
    required this.target,
    required this.overtureSeconds,
    required this.rampCycles,
    required this.mainCycles,
  });
}

/// 低落刻意不給長吐氣 —— 長吐氣是鎮定用的，低落時會更往下沉。
/// 焦慮才用 4-7-8，而且要被帶到，不是一開場就要求。
const Map<BreathMood, MoodRecipe> kMoodRecipes = <BreathMood, MoodRecipe>{
  BreathMood.anxious: MoodRecipe(
    start: BreathPattern(4, 2, 4, 0),
    target: BreathPattern(4, 7, 8, 0),
    overtureSeconds: 20,
    rampCycles: 5,
    mainCycles: 4,
  ),
  BreathMood.low: MoodRecipe(
    start: BreathPattern(3, 0, 3, 0),
    target: BreathPattern(4, 0, 4, 0),
    overtureSeconds: 8,
    rampCycles: 3,
    mainCycles: 5,
  ),
  BreathMood.calm: MoodRecipe(
    start: BreathPattern(4, 2, 4, 2),
    target: BreathPattern(4, 4, 4, 4),
    overtureSeconds: 10,
    rampCycles: 3,
    mainCycles: 4,
  ),
};

class BreathCycle {
  final BreathPattern pattern;
  final BreathStage stage;
  final double startsAt;

  const BreathCycle(this.pattern, this.stage, this.startsAt);
}

/// 某一個瞬間的狀態。畫面只要拿這個就能畫。
class BreathTick {
  /// 0 = 吐盡，1 = 吸滿。畫面所有東西都從這個值推出來。
  final double value;
  final BreathSegment segment;
  final BreathStage stage;
  final BreathPattern pattern;

  /// 在目前這個階段裡走到幾成（序曲和尾聲會用到）
  final double stageProgress;
  final bool finished;

  const BreathTick({
    required this.value,
    required this.segment,
    required this.stage,
    required this.pattern,
    required this.stageProgress,
    required this.finished,
  });

  /// 水火交融：只吃呼吸值的最高 28%。
  /// 因為「停」的時候 value 停在 1，所以它會自然停在最亮 —— 不用另外寫狀態機。
  /// 4-7-8 最難撐的就是那 7 秒，讓那 7 秒是最美的一刻，人才有理由留在裡面。
  double get meet {
    final u = (value - 0.72) / 0.28;
    if (u <= 0) return 0;
    return math.pow(u, 1.4).toDouble();
  }

  /// 呼吸幅度：序曲裡先很小，主段才長出來
  double get amplitude {
    switch (stage) {
      case BreathStage.overture:
        final late = ((stageProgress - 0.65) / 0.35).clamp(0.0, 1.0);
        return 0.35 + 0.65 * late;
      case BreathStage.outro:
        return 1.5 * (1 - stageProgress * 0.7);
      case BreathStage.ramp:
      case BreathStage.main:
        return 1.5;
    }
  }

  // ── 序曲的四層：Luna 先亮 → 你亮起來 → 星星醒 → 才一起呼吸 ──
  bool get showLuna => true;

  bool get showYou =>
      stage != BreathStage.overture || stageProgress > 0.16;

  bool get showStars {
    if (stage == BreathStage.overture) return stageProgress > 0.42;
    if (stage == BreathStage.outro) return stageProgress < 0.6;
    return true;
  }

  /// 吸／停／吐 的文字提示。序曲不給 —— 那段的意思是「你先看著就好」。
  bool get showCue =>
      stage == BreathStage.ramp || stage == BreathStage.main;

  String get cueText {
    switch (segment) {
      case BreathSegment.inhale:
        return 'Inhale';
      case BreathSegment.exhale:
        return 'Exhale';
      case BreathSegment.holdTop:
      case BreathSegment.holdBottom:
        return 'Hold';
    }
  }
}

class BreathPlan {
  final List<BreathCycle> cycles;
  final double overtureSeconds;
  final double totalSeconds;

  BreathPlan._(this.cycles, this.overtureSeconds, this.totalSeconds);

  /// [overtureScale] 由 ERS 決定：越高越短，一個 ERS 78 的人不會坐著看 20 秒。
  /// [hardOvertureSeconds] 給 safety flow 用，直接壓成固定秒數。
  factory BreathPlan.build({
    required BreathMood mood,
    double overtureScale = 1.0,
    double? hardOvertureSeconds,
  }) {
    final r = kMoodRecipes[mood]!;
    final ovt = hardOvertureSeconds ?? (r.overtureSeconds * overtureScale);

    final list = <BreathCycle>[];
    var t = 0.0;

    final one = r.start.total;
    while (t < ovt) {
      list.add(BreathCycle(r.start, BreathStage.overture, t));
      t += one;
    }
    if (list.isEmpty) {
      list.add(BreathCycle(r.start, BreathStage.overture, t));
      t += one;
    }

    for (var i = 1; i <= r.rampCycles; i++) {
      final p = BreathPattern.lerp(r.start, r.target, i / r.rampCycles);
      list.add(BreathCycle(p, BreathStage.ramp, t));
      t += p.total;
    }
    for (var i = 0; i < r.mainCycles; i++) {
      list.add(BreathCycle(r.target, BreathStage.main, t));
      t += r.target.total;
    }
    list.add(BreathCycle(r.target, BreathStage.outro, t));
    t += r.target.total;

    return BreathPlan._(List.unmodifiable(list), ovt, t);
  }

  static double _easeSine(double u) => (1 - math.cos(math.pi * u)) / 2;

  /// 從開始算起第 [elapsed] 秒的狀態。
  BreathTick at(double elapsed) {
    if (elapsed < 0) elapsed = 0;

    var c = cycles.last;
    for (final x in cycles) {
      if (elapsed < x.startsAt + x.pattern.total) {
        c = x;
        break;
      }
    }

    final u = elapsed - c.startsAt;
    final p = c.pattern;

    double v;
    BreathSegment seg;
    if (u < p.inhale) {
      v = _easeSine(u / p.inhale);
      seg = BreathSegment.inhale;
    } else if (u < p.inhale + p.holdTop) {
      v = 1;
      seg = BreathSegment.holdTop;
    } else if (u < p.inhale + p.holdTop + p.exhale) {
      v = 1 - _easeSine((u - p.inhale - p.holdTop) / p.exhale);
      seg = BreathSegment.exhale;
    } else {
      v = 0;
      seg = BreathSegment.holdBottom;
    }

    double sp;
    if (c.stage == BreathStage.overture) {
      sp = (elapsed / overtureSeconds).clamp(0.0, 1.0);
    } else if (c.stage == BreathStage.outro) {
      sp = (u / p.total).clamp(0.0, 1.0);
    } else {
      sp = 1;
    }

    return BreathTick(
      value: v.clamp(0.0, 1.0),
      segment: seg,
      stage: c.stage,
      pattern: p,
      stageProgress: sp,
      finished: elapsed >= totalSeconds,
    );
  }
}

/// 靜陪模式：不規則的人類呼吸節奏（8–12 秒），不引導。
/// 這個模式的價值就在「不引導」，套上序曲會毀掉它。
class SilentBreath {
  final math.Random _r;
  double _inhale = 0, _exhale = 0, _hold = 0;
  double _phaseStart = 0;
  int _phase = 0;

  SilentBreath([int? seed]) : _r = math.Random(seed) {
    _roll();
  }

  void _roll() {
    final t = 8 + _r.nextDouble() * 4;
    _inhale = t * 0.38;
    _exhale = t * 0.48;
    _hold = t * 0.14;
  }

  double valueAt(double now) {
    final el = now - _phaseStart;
    if (_phase == 0) {
      final p = (el / _inhale).clamp(0.0, 1.0);
      if (p >= 1) {
        _phase = 1;
        _phaseStart = now;
      }
      return p * p;
    } else if (_phase == 1) {
      final p = (el / _exhale).clamp(0.0, 1.0);
      if (p >= 1) {
        _phase = 2;
        _phaseStart = now;
      }
      final q = 1 - p;
      return q * (2 - q);
    } else {
      if (el >= _hold) {
        _phase = 0;
        _phaseStart = now;
        _roll();
      }
      return 0;
    }
  }
}
