import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 情緒壓力幾何化 (Geometric Stress Mapping)
///
/// - 低風險 (0-30): 圓形中空 — 圓潤、無害、輕盈放鬆
/// - 中風險 (31-60): 正方形半填充 — 框架、壓力堆積
/// - 高風險 (61-100): 三角形全實心 — 尖銳警示、需立即介入
class GeometricStressIndicator extends StatelessWidget {
  const GeometricStressIndicator({
    super.key,
    required this.riskScore,
    this.size = 48,
    this.showLabel = true,
  });

  final int riskScore;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final level = _riskLevel;
    final color = LumiTheme.riskColor(riskScore);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _GeometricPainter(
            level: level,
            color: color,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  int get _riskLevel {
    if (riskScore <= 30) return 0; // low
    if (riskScore <= 60) return 1; // medium
    return 2; // high
  }

  String get _label {
    if (riskScore <= 30) return '穩定';
    if (riskScore <= 60) return '留意';
    return '警戒';
  }
}

class _GeometricPainter extends CustomPainter {
  _GeometricPainter({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    switch (level) {
      case 0:
        // Circle, hollow (stroke only)
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(center, radius, paint);
      case 1:
        // Square, semi-filled (50% opacity fill + stroke)
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 1.6,
          height: radius * 1.6,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        // Fill at 50% opacity
        final fillPaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, fillPaint);
        // Stroke
        final strokePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawRRect(rrect, strokePaint);
      case 2:
        // Triangle, fully filled
        final path = Path();
        final triangleRadius = radius * 1.1;
        // Point up triangle
        path.moveTo(
          center.dx,
          center.dy - triangleRadius,
        );
        path.lineTo(
          center.dx + triangleRadius * cos(pi / 6),
          center.dy + triangleRadius * sin(pi / 6),
        );
        path.lineTo(
          center.dx - triangleRadius * cos(pi / 6),
          center.dy + triangleRadius * sin(pi / 6),
        );
        path.close();

        final fillPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GeometricPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}
