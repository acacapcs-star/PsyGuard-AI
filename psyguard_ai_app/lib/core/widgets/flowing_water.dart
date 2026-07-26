// ═══════════════════════════════════════════════════════════
// PsyGuard AI / Luna Pacer - 流動的水背景 🌊✨
//
// 多層光帶交融流動，像水面的光影緩緩晃動、彼此穿插，連成一片
// 流動的水。柔和、有質感、有深度。加一抹金光。
//
// 配色跟著 App 亮暗模式 + mood 走：
//   亮模式 → 深色調流水（在亮底上看得見）
//   暗模式 → 亮色調流水（在深底上發光）
//   永遠帶一抹金光點綴。
//
// 鋪滿整頁、墊在最底層、不蓋任何功能。
//   Stack(children:[ const Positioned.fill(child: FlowingLight()), ...])
// ═══════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/mood_theme_service.dart';
import '../theme/background_theme_service.dart';

class _Pal {
  final Color bg1; // 背景漸層上
  final Color bg2; // 背景漸層下
  final Color flow1; // 流水色 A
  final Color flow2; // 流水色 B
  final Color gold; // 金光
  const _Pal(this.bg1, this.bg2, this.flow1, this.flow2, this.gold);
}

// 依 mood 取一個「基底色」（沿用 App 既有的 mood 背景色感）
Color _moodBase(MoodTheme m) {
  switch (m) {
    case MoodTheme.none: return const Color(0xFF2E4A8A);
    case MoodTheme.christmas: return const Color(0xFF2E7D52);
    case MoodTheme.newYear: return const Color(0xFFC0392B);
    case MoodTheme.spring: return const Color(0xFFE39CB8);
    case MoodTheme.summer: return const Color(0xFF2FA8C4);
    case MoodTheme.autumn: return const Color(0xFFCB7A3A);
    case MoodTheme.winter: return const Color(0xFF6E9BBE);
    case MoodTheme.winterBreak: return const Color(0xFF9C8Fb0);
    case MoodTheme.summerBreak: return const Color(0xFFDCA838);
  }
}

Color _lighten(Color c, double amt) {
  return Color.lerp(c, Colors.white, amt)!;
}

Color _darken(Color c, double amt) {
  return Color.lerp(c, Colors.black, amt)!;
}

_Pal _paletteFor(MoodTheme mood, bool isDark) {
  final base = _moodBase(mood);
  const gold = Color(0xFFF5C542);
  if (isDark) {
    // 暗模式：深底 + 亮色流水
    return _Pal(
      _darken(base, 0.72),
      const Color(0xFF060A14),
      _lighten(base, 0.15),
      _lighten(base, 0.40),
      gold,
    );
  } else {
    // 亮模式：亮底 + 深色流水
    return _Pal(
      _lighten(base, 0.78),
      _lighten(base, 0.55),
      _darken(base, 0.10),
      base,
      _darken(gold, 0.15),
    );
  }
}

class FlowingLight extends ConsumerStatefulWidget {
  const FlowingLight({super.key});
  @override
  ConsumerState<FlowingLight> createState() => _FlowingLightState();
}

class _FlowingLightState extends ConsumerState<FlowingLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(vsync: this, duration: const Duration(seconds: 24))
      ..repeat();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(moodThemeProvider);
    final isDark = ref.watch(backgroundThemeProvider).mode == BgMode.dark;
    final pal = _paletteFor(mood, isDark);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) => CustomPaint(
        painter: _WaterPainter(t: _t.value * math.pi * 2, p: pal, dark: isDark),
        size: Size.infinite,
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({required this.t, required this.p, required this.dark});
  final double t;
  final _Pal p;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // 背景漸層
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bg1, p.bg2],
        ).createShader(rect),
    );

    // 多層流動光帶 —— 每層是一條填滿到底的平滑曲線，半透明疊加交融
    final layers = <List<double>>[
      // baseY, amp, waveLen, speed, alpha, colorPick(0=flow1,1=flow2,2=gold)
      [0.30, 0.05, 0.85, 0.55, 0.16, 1],
      [0.42, 0.07, 1.05, 0.40, 0.18, 0],
      [0.54, 0.06, 0.75, 0.70, 0.14, 2], // 金光帶
      [0.64, 0.08, 1.15, 0.32, 0.20, 1],
      [0.74, 0.065, 0.90, 0.60, 0.16, 0],
      [0.84, 0.05, 0.70, 0.48, 0.14, 1],
    ];

    for (final L in layers) {
      final baseY = L[0] * h;
      final amp = L[1] * h;
      final wl = L[2] * w;
      final spd = L[3];
      final alpha = L[4];
      final pick = L[5].toInt();
      final color = pick == 0 ? p.flow1 : (pick == 1 ? p.flow2 : p.gold);

      final path = Path()..moveTo(0, baseY);
      for (double x = 0; x <= w; x += 6) {
        final y = baseY +
            math.sin((x / wl) * 2 * math.pi + t * spd) * amp +
            math.sin((x / (wl * 0.45)) * 2 * math.pi + t * spd * 1.6) * amp * 0.35;
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..blendMode = dark ? BlendMode.plus : BlendMode.srcOver,
      );

      // 頂緣柔光高光線
      final hl = Path();
      bool first = true;
      for (double x = 0; x <= w; x += 6) {
        final y = baseY +
            math.sin((x / wl) * 2 * math.pi + t * spd) * amp +
            math.sin((x / (wl * 0.45)) * 2 * math.pi + t * spd * 1.6) * amp * 0.35;
        if (first) {
          hl.moveTo(x, y);
          first = false;
        } else {
          hl.lineTo(x, y);
        }
      }
      canvas.drawPath(
        hl,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = (pick == 2 ? p.gold : Color.lerp(color, Colors.white, 0.5)!)
              .withValues(alpha: dark ? 0.30 : 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // 上方一層很淡的金光暈染（質感）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.gold.withValues(alpha: dark ? 0.10 : 0.06),
            p.gold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.4))
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) => true;
}
