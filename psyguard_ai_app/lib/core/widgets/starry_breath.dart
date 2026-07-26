// ═══════════════════════════════════════════════════════════
// PsyGuard AI / Luna Pacer - 星夜呼吸陪伴 🌌
//
// 靈感：梵谷《星夜》。深夜藍底，金黃與橙色的光同時發光，
//       光線傾瀉而下、由深轉淡，像星塵灑落散佈，整體緩緩漩渦流動。
//       三條圓角膠囊（lii 符號）安靜地浮在光河上。
//
// 「靜默但緩慢的海浪」——不搶眼，但一直在。這是 Luna Pacer 的
// 靈魂符號：Always there. Never loud.
//
// 純 CustomPaint 動畫，無外部圖片、無 shader，手機上穩定運行。
// ═══════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 呼吸節奏（對應企劃書三模式）
enum BreathMode {
  calm, // 靜陪 8 秒
  guide, // 呼吸引導 5 秒
  anxious, // 焦慮 4 秒
}

extension BreathModeInfo on BreathMode {
  Duration get cycle {
    switch (this) {
      case BreathMode.calm:
        return const Duration(seconds: 8);
      case BreathMode.guide:
        return const Duration(seconds: 5);
      case BreathMode.anxious:
        return const Duration(seconds: 4);
    }
  }

  String labelFor(bool isZh) {
    switch (this) {
      case BreathMode.calm:
        return isZh ? '靜陪' : 'Presence';
      case BreathMode.guide:
        return isZh ? '呼吸引導' : 'Breathe';
      case BreathMode.anxious:
        return isZh ? '安撫' : 'Soothe';
    }
  }
}

class StarryBreath extends StatefulWidget {
  const StarryBreath({
    super.key,
    this.height = 220,
    this.isZh = true,
    this.tappableToSwitchMode = true,
  });

  final double height;
  final bool isZh;

  /// 點一下切換呼吸節奏（靜陪→引導→安撫）
  final bool tappableToSwitchMode;

  @override
  State<StarryBreath> createState() => _StarryBreathState();
}

class _StarryBreathState extends State<StarryBreath>
    with TickerProviderStateMixin {
  late final AnimationController _flow; // 漩渦流動（一直轉）
  late AnimationController _breath; // 呼吸脈動（膠囊漲縮）
  BreathMode _mode = BreathMode.calm;

  @override
  void initState() {
    super.initState();
    // 漩渦流動：很長的循環，永遠緩緩轉
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _breath = AnimationController(vsync: this, duration: _mode.cycle)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flow.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _cycleMode() {
    setState(() {
      _mode = BreathMode.values[(_mode.index + 1) % BreathMode.values.length];
      _breath.dispose();
      _breath = AnimationController(vsync: this, duration: _mode.cycle)
        ..repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.tappableToSwitchMode ? _cycleMode : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: Listenable.merge([_flow, _breath]),
            builder: (context, _) {
              // 呼吸曲線：0（吐盡）→ 1（吸滿），用 easeInOut 更自然
              final breath = Curves.easeInOut.transform(_breath.value);
              return Stack(
                children: [
                  // 星夜光河
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _StarryNightPainter(
                        flow: _flow.value,
                        breath: breath,
                      ),
                    ),
                  ),
                  // 三條膠囊（lii 符號）
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CapsulesPainter(breath: breath),
                    ),
                  ),
                  // 模式標籤（右下角，很淡）
                  if (widget.tappableToSwitchMode)
                    Positioned(
                      right: 14,
                      bottom: 10,
                      child: Text(
                        _mode.labelFor(widget.isZh),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 星夜光河：深夜藍底 + 金橙漩渦 + 傾瀉光暈 + 灑落星塵
class _StarryNightPainter extends CustomPainter {
  _StarryNightPainter({required this.flow, required this.breath});

  final double flow; // 0..1 一直增加（漩渦轉動）
  final double breath; // 0..1 呼吸

  // Luna 星夜配色
  static const _deep = Color(0xFF0A1330); // 最深夜藍
  static const _mid = Color(0xFF16295C); // 中夜藍
  static const _glowGold = Color(0xFFF5C542); // 星光金
  static const _glowAmber = Color(0xFFE8913A); // 傘橙

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // 1. 底：由上而下深轉淡的夜藍（光線傾瀉的基調）
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_mid, _deep],
        ).createShader(rect),
    );

    final t = flow * math.pi * 2;

    // 2. 漩渦：幾個緩緩旋轉的金橙光暈，位置用正弦漂移
    final swirls = [
      _Swirl(0.24, 0.34, 0.42, _glowGold, 0.0),
      _Swirl(0.68, 0.28, 0.36, _glowAmber, 2.1),
      _Swirl(0.50, 0.60, 0.50, _glowGold, 4.0),
      _Swirl(0.82, 0.66, 0.30, _glowAmber, 1.2),
    ];

    for (final s in swirls) {
      final cx = (s.x + math.sin(t + s.phase) * 0.05) * w;
      final cy = (s.y + math.cos(t * 0.8 + s.phase) * 0.04) * h;
      final radius = s.r * w * (0.9 + breath * 0.25); // 呼吸時光暈漲縮
      final glowStrength = 0.28 + breath * 0.22;

      // 光暈本體（徑向漸層，中心亮、邊緣化開）
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              s.color.withValues(alpha: glowStrength),
              s.color.withValues(alpha: glowStrength * 0.4),
              s.color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: radius))
          ..blendMode = BlendMode.plus, // 疊加發光
      );

      // 漩渦紋：繞著光暈中心畫幾圈螺旋，做出梵谷的筆觸捲動
      _paintSwirlStrokes(canvas, Offset(cx, cy), radius * 0.8, t + s.phase,
          s.color, glowStrength);
    }

    // 3. 星塵：散佈的小光點，明滅閃爍
    final rnd = math.Random(7);
    for (int i = 0; i < 46; i++) {
      final sx = rnd.nextDouble() * w;
      final sy = rnd.nextDouble() * h;
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 1.5 + i * 1.3));
      final r = 0.6 + rnd.nextDouble() * 1.6;
      canvas.drawCircle(
        Offset(sx, sy),
        r,
        Paint()
          ..color = _glowGold.withValues(alpha: twinkle * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  /// 螺旋筆觸：繞中心一圈圈，做出星夜的漩渦感
  void _paintSwirlStrokes(Canvas canvas, Offset center, double maxR,
      double phase, Color color, double strength) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;

    for (int arc = 0; arc < 3; arc++) {
      final path = Path();
      final startA = phase + arc * 2.1;
      final baseR = maxR * (0.35 + arc * 0.22);
      bool first = true;
      for (double a = 0; a < math.pi * 1.6; a += 0.18) {
        // 半徑隨角度緩增 → 螺旋
        final rr = baseR + a * maxR * 0.06;
        final px = center.dx + math.cos(startA + a) * rr;
        final py = center.dy + math.sin(startA + a) * rr;
        if (first) {
          path.moveTo(px, py);
          first = false;
        } else {
          path.lineTo(px, py);
        }
      }
      paint.color = color.withValues(alpha: strength * 0.30);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarryNightPainter old) =>
      old.flow != flow || old.breath != breath;
}

class _Swirl {
  final double x, y, r, phase;
  final Color color;
  const _Swirl(this.x, this.y, this.r, this.color, this.phase);
}

/// 三條圓角膠囊 —— lii 的符號，浮在光河上，隨呼吸漲縮
class _CapsulesPainter extends CustomPainter {
  _CapsulesPainter({required this.breath});
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 三條膠囊：中間高、兩側略低，像呼吸的聲波
    final heights = [0.30, 0.46, 0.30];
    final gap = w * 0.08;
    final capW = w * 0.075;
    final positions = [cx - gap, cx, cx + gap];

    for (int i = 0; i < 3; i++) {
      final baseH = h * heights[i];
      // 呼吸：吸滿時膠囊變長、發光變強
      final capH = baseH * (0.82 + breath * 0.36);
      final glow = 0.5 + breath * 0.5;

      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(positions[i], cy),
          width: capW,
          height: capH,
        ),
        Radius.circular(capW / 2),
      );

      // 外發光
      canvas.drawRRect(
        r,
        Paint()
          ..color = const Color(0xFFFDF6E3).withValues(alpha: glow * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // 膠囊本體（米白微漸層）
      canvas.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.95),
              const Color(0xFFEDE4CF).withValues(alpha: 0.88),
            ],
          ).createShader(r.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CapsulesPainter old) => old.breath != breath;
}
