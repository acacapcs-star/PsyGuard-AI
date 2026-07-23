import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/mood_theme_service.dart';
import 'mood_fall_overlay.dart';

/// 全域積雪計數：每點一次球球下雪就 +1。
/// 每個 SnowCap 各自記住「自己被融化時的計數」，
/// 厚度 = (目前計數 - 融化時計數)，夾在 0~3 級之間。
class SnowAccumulationController extends StateNotifier<int> {
  SnowAccumulationController() : super(0);

  void addSnow() => state = state + 1;
}

final snowAccumulationProvider =
    StateNotifierProvider<SnowAccumulationController, int>(
  (ref) => SnowAccumulationController(),
);

/// 包住任何卡片/區塊，就會在它頂端的平整區域積雪。
/// - 只在雪系氛圍（冬/聖誕/寒假）且有積雪計數時出現
/// - 按住雪堆不放：手的溫度會慢慢把雪融成半透明的水（中途放開會重新凍回去）
/// - 完全融化後：水珠停留片刻、往下垂幾滴，然後蒸發消失
class SnowCap extends ConsumerStatefulWidget {
  const SnowCap({super.key, required this.child, this.cornerInset = 18});

  final Widget child;

  /// 左右兩端內縮距離，避開卡片圓角。
  final double cornerInset;

  @override
  ConsumerState<SnowCap> createState() => _SnowCapState();
}

class _SnowCapState extends ConsumerState<SnowCap>
    with TickerProviderStateMixin {
  late final AnimationController _melt; // 0→1：雪 → 半透明的水
  late final AnimationController _fade; // 0→1：水蒸發消失
  late final int _seed; // 讓每張卡片的雪堆形狀固定但彼此不同
  int _meltedAtCount = 0;
  bool _evaporating = false;

  @override
  void initState() {
    super.initState();
    _seed = math.Random().nextInt(1 << 31);
    _melt = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      reverseDuration: const Duration(milliseconds: 500),
    )..addStatusListener(_onMeltStatus);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener(_onFadeStatus);
  }

  @override
  void dispose() {
    _melt.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _onMeltStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    HapticFeedback.mediumImpact(); // 融化完成的小回饋
    _evaporating = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _evaporating) _fade.forward();
    });
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    setState(() {
      _meltedAtCount = ref.read(snowAccumulationProvider); // 這張卡片乾淨了
      _evaporating = false;
      _melt.reset();
      _fade.reset();
    });
  }

  void _maybeRefreeze() {
    // 手放開時如果還沒完全融化 → 慢慢凍回去
    if (!_evaporating && _melt.status != AnimationStatus.completed) {
      _melt.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snowy =
        ref.watch(moodThemeProvider).fallEffect == FallEffectType.snow;
    final count = ref.watch(snowAccumulationProvider);
    final level = (count - _meltedAtCount).clamp(0, 3);

    if (!snowy || level == 0) return widget.child;

    final thickness = 6.0 + level * 3.0; // 1~3 級：9 / 12 / 15px
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: -thickness * 0.45,
          left: 0,
          right: 0,
          height: thickness + 10,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (_) {
              if (!_evaporating) _melt.forward();
            },
            onLongPressEnd: (_) => _maybeRefreeze(),
            onLongPressCancel: _maybeRefreeze,
            child: AnimatedBuilder(
              animation: Listenable.merge([_melt, _fade]),
              builder: (context, _) => Opacity(
                opacity: 1 - _fade.value,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SnowCapPainter(
                    thickness: thickness,
                    meltT: _melt.value,
                    inset: widget.cornerInset,
                    seed: _seed,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SnowCapPainter extends CustomPainter {
  _SnowCapPainter({
    required this.thickness,
    required this.meltT,
    required this.inset,
    required this.seed,
  });

  final double thickness;
  final double meltT; // 0 = 雪，1 = 完全變成水
  final double inset;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 4; // 雪堆底線（貼在卡片上緣）
    final hEff = thickness * (1 - meltT * 0.55); // 融化時整體壓扁
    final left = inset;
    final right = size.width - inset;
    if (right - left < 20) return;

    // 雪白 → 半透明水藍
    final fillColor = Color.lerp(
      const Color(0xFFFDFEFF),
      const Color(0x8C86C9F2),
      meltT,
    )!;
    final fill = Paint()..color = fillColor;

    // 底座 + 一連串大小不一的圓弧，畫出蓬鬆雪堆
    final path = Path()
      ..addRRect(RRect.fromLTRBR(
        left,
        baseline - hEff * 0.5,
        right,
        baseline,
        Radius.circular(hEff * 0.4),
      ));
    final rng = math.Random(seed); // 固定 seed → 形狀固定不閃爍
    double x = left + 10;
    while (x < right - 10) {
      final r = hEff * 0.42 + rng.nextDouble() * hEff * 0.45;
      path.addOval(Rect.fromCircle(
        center: Offset(x, baseline - hEff * 0.48),
        radius: r,
      ));
      x += r * 1.3 + 5;
    }
    canvas.drawPath(path, fill);

    // 雪的底部淡藍陰影線（增加立體感，融化時漸漸消失）
    if (meltT < 0.6) {
      final line = Paint()
        ..color =
            const Color(0xFFB8D6EA).withValues(alpha: (0.6 - meltT).clamp(0.0, 1.0))
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(left + 3, baseline), Offset(right - 3, baseline), line);
    }

    // 融化後期：幾滴半透明水珠往下垂
    if (meltT > 0.55) {
      final dt = ((meltT - 0.55) / 0.45).clamp(0.0, 1.0);
      final drop = Paint()
        ..color = Color(0x9973B9E8).withValues(alpha: 0.6 * dt);
      final dropRng = math.Random(seed + 7);
      for (int i = 0; i < 3; i++) {
        final dx = left + 14 + dropRng.nextDouble() * (right - left - 28);
        final dy = baseline + dt * (4 + dropRng.nextDouble() * 5);
        canvas.drawCircle(Offset(dx, dy), 1.8 + dropRng.nextDouble(), drop);
      }
    }
  }

  @override
  bool shouldRepaint(_SnowCapPainter old) =>
      old.meltT != meltT || old.thickness != thickness;
}
