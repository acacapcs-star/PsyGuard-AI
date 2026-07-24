import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/mood_theme_service.dart';

/// 全頁觸碰輔助層：
/// 1. 點頁面任何地方 → 自動收起鍵盤（解決便條紙寫字欄關不掉的問題）
/// 2. 🎄 聖誕氛圍時 → 貓掌「啪」地拍在點的位置，縮回後留下掌印淡出
///    （鍵盤開啟時暫停貓掌，寫字不被打擾）
/// 用 Listener 純監聽，完全不攔截、不影響任何原有互動。
class PawTapLayer extends ConsumerStatefulWidget {
  const PawTapLayer({super.key, required this.child});

  final Widget child;

  /// PawFreeZone 用：本次點擊不出貓掌（例如點在貓咪本人身上）。
  static bool suppressNextPaw = false;

  @override
  ConsumerState<PawTapLayer> createState() => _PawTapLayerState();
}

class _PawHit {
  _PawHit({
    required this.pos,
    required this.asset,
    required this.rot,
    required this.born,
  });

  final Offset pos;
  final String asset;
  final double rot;
  final double born;
}

/// 包住任何區塊，讓「點這個區塊」不會觸發貓掌（例如戳貓咪本人時）。
class PawFreeZone extends StatelessWidget {
  const PawFreeZone({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => PawTapLayer.suppressNextPaw = true,
      child: child,
    );
  }
}

class _PawTapLayerState extends ConsumerState<PawTapLayer>
    with SingleTickerProviderStateMixin {
  static const List<String> _paws = [
    'assets/images/mood_paw_1.png',
    'assets/images/mood_paw_2.png',
    'assets/images/mood_paw_3.png',
  ];
  static const double _lifespan = 3.0;

  late final Ticker _ticker;
  final Stopwatch _clock = Stopwatch()..start();
  final math.Random _rng = math.Random();
  final List<_PawHit> _hits = [];
  double _now = 0;
  bool _pawsEnabled = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      _now = _clock.elapsedMicroseconds / 1e6;
      _hits.removeWhere((h) => _now - h.born > _lifespan);
      if (_hits.isEmpty) _ticker.stop();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    // 點任何地方都先收鍵盤（點進輸入框時，輸入框會自己重新取得焦點）
    FocusManager.instance.primaryFocus?.unfocus();
    final suppressed = PawTapLayer.suppressNextPaw;
    PawTapLayer.suppressNextPaw = false;
    if (!_pawsEnabled || suppressed) return;
    _hits.add(_PawHit(
      pos: e.localPosition,
      asset: _paws[_rng.nextInt(_paws.length)],
      rot: (_rng.nextDouble() - 0.5) * 0.7,
      born: _clock.elapsedMicroseconds / 1e6,
    ));
    while (_hits.length > 8) {
      _hits.removeAt(0);
    }
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    final christmas =
        ref.watch(moodThemeProvider) == MoodTheme.christmas;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    _pawsEnabled = christmas && !keyboardOpen; // 打字時不出貓掌

    return Listener(
      onPointerDown: _onPointerDown,
      child: Stack(
        children: [
          widget.child,
          if (_hits.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final h in _hits) ..._buildHit(h),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildHit(_PawHit h) {
    final t = _now - h.born;
    final widgets = <Widget>[];

    if (t > 0.18) {
      double printAlpha;
      if (t < 0.45) {
        printAlpha = (t - 0.18) / 0.27 * 0.85;
      } else if (t < _lifespan - 0.8) {
        printAlpha = 0.85;
      } else {
        printAlpha = 0.85 * (1 - (t - (_lifespan - 0.8)) / 0.8);
      }
      widgets.add(Positioned(
        left: h.pos.dx - 22,
        top: h.pos.dy - 20,
        child: Opacity(
          opacity: printAlpha.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: h.rot * 0.5,
            child: Image.asset(
              'assets/images/mood_paw_print.png',
              width: 44,
              errorBuilder: (_, __, ___) =>
                  const Text('🐾', style: TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ));
    }

    if (t < 0.78) {
      double scale;
      double lift = 0;
      if (t < 0.22) {
        scale = Curves.elasticOut.transform((t / 0.22).clamp(0.0, 1.0));
      } else if (t < 0.55) {
        scale = 1.0;
      } else {
        final rt = (t - 0.55) / 0.23;
        scale = 1 - rt;
        lift = rt * 14;
      }
      if (scale > 0.02) {
        widgets.add(Positioned(
          left: h.pos.dx - 34,
          top: h.pos.dy - 40 - lift,
          child: Transform.rotate(
            angle: h.rot,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                h.asset,
                width: 68,
                errorBuilder: (_, __, ___) =>
                    const Text('🐾', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}
