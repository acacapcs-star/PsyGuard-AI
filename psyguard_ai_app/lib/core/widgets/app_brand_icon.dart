import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBrandIcon extends StatefulWidget {
  const AppBrandIcon({
    super.key,
    this.size = 72,
    this.radius = 18,
    this.padding = 6,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE8ECE8),
  });

  final double size;
  final double radius;
  final double padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  State<AppBrandIcon> createState() => _AppBrandIconState();
}

class _AppBrandIconState extends State<AppBrandIcon> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final innerSize = widget.size;
    // 圓形版 SVG（viewBox 160x160）：Luna 黃點在 (83,28)，你的藍白點在 (109,28)
    const lunaFrac = Offset(83 / 160, 36 / 160);
    const youFrac = Offset(109 / 160, 36 / 160);

    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      child: ClipOval(
        child: SizedBox(
          width: innerSize,
          height: innerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                'assets/lii_logo.svg',
                width: innerSize,
                height: innerSize,
                fit: BoxFit.cover,
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    children: [
                      _buildRipple(innerSize, lunaFrac, const Color(0xFFFFD166), 0.0),
                      _buildRipple(innerSize, youFrac, const Color(0xFFC8E8FF), 0.5),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 漣漪效果：圓圈由小放大、由清晰變透明，兩個點用相位差交錯，看起來更自然
  Widget _buildRipple(double innerSize, Offset fracCenter, Color color, double phaseOffset) {
    final t = (_controller.value + phaseOffset) % 1.0;
    final scale = 0.3 + t * 1.4;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.55;

    final baseDot = innerSize * 0.14;
    final dotSize = baseDot * scale;
    final centerX = fracCenter.dx * innerSize;
    final centerY = fracCenter.dy * innerSize;

    return Positioned(
      left: centerX - dotSize / 2,
      top: centerY - dotSize / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}
