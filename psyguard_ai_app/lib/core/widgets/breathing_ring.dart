import 'package:flutter/material.dart';

/// 首頁呼吸環動畫
///
/// 中央 Lumi 圓圈隨情緒起伏調整縮放頻率。
/// - 冷靜 (low risk) → 慢速呼吸 3 秒週期
/// - 留意 (medium risk) → 中速 2 秒
/// - 焦慮 (high risk) → 快速 1 秒
class BreathingRing extends StatefulWidget {
  const BreathingRing({
    super.key,
    required this.riskLevel,
    required this.child,
    this.minScale = 0.92,
    this.maxScale = 1.08,
    this.glowColor,
  });

  /// 'low', 'medium', 'high'
  final String riskLevel;
  final Widget child;
  final double minScale;
  final double maxScale;
  final Color? glowColor;

  @override
  State<BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<BreathingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant BreathingRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riskLevel != widget.riskLevel) {
      _controller.duration = _duration;
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  Duration get _duration => switch (widget.riskLevel) {
        'high' => const Duration(milliseconds: 800),
        'medium' => const Duration(milliseconds: 1600),
        _ => const Duration(milliseconds: 2800),
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// AnimatedBuilder helper
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
