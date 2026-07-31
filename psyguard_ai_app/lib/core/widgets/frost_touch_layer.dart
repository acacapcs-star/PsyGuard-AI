import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// ❄️ 冰霜觸碰層 — 手碰到哪就從那裡結晶擴散（像 Frozen）。
/// 用 translucent 只觀察觸碰、不消費手勢，所以不會擋按鈕/拖曳。
class FrostTouchLayer extends StatefulWidget {
  const FrostTouchLayer({super.key});
  @override
  State<FrostTouchLayer> createState() => _FrostTouchLayerState();
}

class _Crystal {
  double x, y, ang, len, grown;
  int depth;
  double life, maxlife, seed;
  _Crystal(this.x, this.y, this.ang, this.len, this.depth, this.life,
      this.maxlife, this.seed)
      : grown = 0;
}

class _Halo {
  double x, y, r, max, a;
  _Halo(this.x, this.y, this.max)
      : r = 0,
        a = 1;
}

class _FrostTouchLayerState extends State<FrostTouchLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rnd = Random();
  final List<_Crystal> _crystals = [];
  final List<_Halo> _halos = [];
  Offset? _last;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  double _r(double a, double b) => a + _rnd.nextDouble() * (b - a);

  void _spawn(Offset p) {
    if (_crystals.length > 1800) return;
    const arms = 6;
    final base = _r(34, 60);
    for (int i = 0; i < arms; i++) {
      final a = (pi * 2 / arms) * i + _r(-0.12, 0.12);
      _crystals.add(
          _Crystal(p.dx, p.dy, a, base, 0, _r(150, 220), 220, _rnd.nextDouble()));
    }
    _halos.add(_Halo(p.dx, p.dy, _r(26, 40)));
  }

  void _tick(Duration d) {
    if (_crystals.isEmpty && _halos.isEmpty) return;
    for (int i = _halos.length - 1; i >= 0; i--) {
      final h = _halos[i];
      h.r += (h.max - h.r) * 0.18;
      h.a *= 0.94;
      if (h.a < 0.03) _halos.removeAt(i);
    }
    final add = <_Crystal>[];
    for (int i = _crystals.length - 1; i >= 0; i--) {
      final c = _crystals[i];
      if (c.grown < 1) {
        final ng = min(1.0, c.grown + 0.09);
        if (c.depth < 2 &&
            _rnd.nextDouble() < 0.5 &&
            _crystals.length + add.length < 1800) {
          final tx = c.x + cos(c.ang) * c.len * ng;
          final ty = c.y + sin(c.ang) * c.len * ng;
          final bl = c.len * _r(0.3, 0.5);
          final off = (_rnd.nextBool() ? 1 : -1) * _r(0.5, 0.8);
          add.add(_Crystal(tx, ty, c.ang + off, bl, c.depth + 1, c.life * 0.7,
              c.maxlife, _rnd.nextDouble()));
          add.add(_Crystal(tx, ty, c.ang - off, bl, c.depth + 1, c.life * 0.7,
              c.maxlife, _rnd.nextDouble()));
        }
        c.grown = ng;
      }
      c.life -= 1;
      if (c.life <= 0) _crystals.removeAt(i);
    }
    _crystals.addAll(add);
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _last = e.localPosition;
        _spawn(e.localPosition);
      },
      onPointerMove: (e) {
        final p = e.localPosition;
        _last ??= p;
        if ((p - _last!).distance > 26) {
          _spawn(p);
          _last = p;
        }
      },
      onPointerUp: (e) => _last = null,
      onPointerCancel: (e) => _last = null,
      child: CustomPaint(
        painter: _FrostPainter(_crystals, _halos),
        size: Size.infinite,
      ),
    );
  }
}

class _FrostPainter extends CustomPainter {
  final List<_Crystal> crystals;
  final List<_Halo> halos;
  _FrostPainter(this.crystals, this.halos);

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in halos) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(220, 240, 255, 0.5 * h.a),
          const Color.fromRGBO(160, 210, 255, 0),
        ]).createShader(
            Rect.fromCircle(center: Offset(h.x, h.y), radius: h.r + 8));
      canvas.drawCircle(Offset(h.x, h.y), h.r + 8, paint);
    }
    for (final c in crystals) {
      final alpha = (c.life / c.maxlife).clamp(0.0, 1.0);
      final tx = c.x + cos(c.ang) * c.len * c.grown;
      final ty = c.y + sin(c.ang) * c.len * c.grown;
      final paint = Paint()
        ..color = Color.fromRGBO(200 + (c.seed * 40).toInt(),
            228 + (c.seed * 20).toInt(), 255, 0.85 * alpha)
        ..strokeWidth = max(0.6, 2.2 - c.depth * 0.7)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(c.x, c.y), Offset(tx, ty), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrostPainter old) => true;
}
