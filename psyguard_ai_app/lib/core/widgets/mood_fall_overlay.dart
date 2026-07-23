import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/mood_theme_service.dart';

/// 氛圍飄落效果控制器。
/// 在任何地方（例如點擊飄浮 lii 球球時）呼叫 [play]，
/// 頁面上的 [MoodFallOverlay] 就會播放「一次」對應氛圍的飄落動畫。
class MoodFallController extends ChangeNotifier {
  int _playCount = 0;
  int get playCount => _playCount;

  /// 觸發一次飄落動畫（動畫播放中重複呼叫會重新開始）。
  void play() {
    _playCount++;
    notifyListeners();
  }
}

/// 飄落效果種類。
/// 之後其他氛圍（春/夏/秋/過年/寒暑假）各自新增一個值 + 對應的繪製邏輯即可。
enum FallEffectType {
  none,
  snow, // ❄️ 冬 / 聖誕節 / 寒假：雪花飄落（使用者提供的 6 張雪花圖 + 小雪點）
}

/// 單顆粒子的參數（出生時隨機決定，之後不再改變）。
class _FallParticle {
  _FallParticle({
    required this.x,
    required this.delay,
    required this.duration,
    required this.size,
    required this.swayAmp,
    required this.swaySpeed,
    required this.swayPhase,
    required this.spinSpeed,
    required this.spinPhase,
    required this.imageIndex,
    required this.isFlake,
    required this.opacity,
  });

  final double x; // 0~1 相對水平位置
  final double delay; // 出生延遲（秒），讓粒子分批落下
  final double duration; // 從畫面頂端落到底部所需秒數
  final double size; // 尺寸（邏輯像素；圖片粒子代表目標寬度）
  final double swayAmp; // 左右飄移幅度
  final double swaySpeed; // 左右飄移速度
  final double swayPhase; // 飄移相位（讓每顆節奏不同）
  final double spinSpeed; // 自轉速度
  final double spinPhase; // 自轉起始角度
  final int imageIndex; // >=0 表示用第幾張雪花圖；-1 表示不用圖片
  final bool isFlake; // 圖片載入失敗時的備援：true = 程式畫六角雪花
  final double opacity; // 基礎透明度
}

/// 疊加在頁面上的一次性飄落動畫圖層。
/// 整個圖層被 IgnorePointer 包住，不會擋到任何點擊互動；
/// 沒有動畫在跑的時候是空白 widget，幾乎零成本。
class MoodFallOverlay extends StatefulWidget {
  const MoodFallOverlay({
    super.key,
    required this.controller,
    required this.effect,
    this.particleCount = 55,
    this.snowColor = const Color(0xFF5EC1E0), // Frozen 冰藍：小雪點與光暈用色
  });

  final MoodFallController controller;
  final FallEffectType effect;
  final int particleCount;
  final Color snowColor;

  @override
  State<MoodFallOverlay> createState() => _MoodFallOverlayState();
}

class _MoodFallOverlayState extends State<MoodFallOverlay>
    with SingleTickerProviderStateMixin {
  /// 使用者提供、已去背縮小的 6 張雪花圖。
  static const List<String> _snowAssets = [
    // 只用水晶系雪花，呈現半透明 crystalization 質感
    'assets/images/mood_snow_2.png', // 粉紫水晶
    'assets/images/mood_snow_5.png', // 發光水晶
    'assets/images/mood_snow_6.png', // 冰晶星芒（Frozen 風）
  ];

  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final List<_FallParticle> _particles = [];
  double _elapsed = 0; // 這一輪動畫已經過的秒數
  double _totalDuration = 0; // 這一輪動畫的總長度
  int _seenPlayCount = 0;

  List<ui.Image>? _snowImages;
  Future<List<ui.Image>>? _snowImagesFuture;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _seenPlayCount = widget.controller.playCount;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant MoodFallOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _seenPlayCount = widget.controller.playCount;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    final imgs = _snowImages;
    if (imgs != null) {
      for (final img in imgs) {
        img.dispose();
      }
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.playCount == _seenPlayCount) return;
    _seenPlayCount = widget.controller.playCount;
    _startOnce();
  }

  /// 載入 6 張雪花圖（只載入一次，之後重複使用）。
  /// 任一張載入失敗就退回「程式畫雪花」模式，不會讓 App 掛掉。
  Future<void> _ensureSnowImagesLoaded() async {
    _snowImagesFuture ??= _loadSnowImages();
    _snowImages = await _snowImagesFuture!;
  }

  Future<List<ui.Image>> _loadSnowImages() async {
    final list = <ui.Image>[];
    try {
      for (final asset in _snowAssets) {
        final data = await rootBundle.load(asset);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        list.add(frame.image);
      }
      return list;
    } catch (_) {
      // 圖片缺失（例如 assets 沒放好）→ 回傳空清單，改用程式畫的雪花
      for (final img in list) {
        img.dispose();
      }
      return const [];
    }
  }

  /// 依目前的 effect 產生一批粒子並開始播放。
  Future<void> _startOnce() async {
    if (widget.effect == FallEffectType.none) return; // 該氛圍還沒有效果

    switch (widget.effect) {
      case FallEffectType.snow:
        await _ensureSnowImagesLoaded();
        if (!mounted) return;
        _particles.clear();
        _spawnSnow();
        break;
      case FallEffectType.none:
        return;
    }

    _totalDuration = 0;
    for (final p in _particles) {
      final end = p.delay + p.duration;
      if (end > _totalDuration) _totalDuration = end;
    }
    _totalDuration += 0.3; // 收尾緩衝

    _ticker.stop();
    _elapsed = 0;
    if (_particles.isNotEmpty) {
      _ticker.start();
      setState(() {});
    }
  }

  void _spawnSnow() {
    final images = _snowImages ?? const <ui.Image>[];
    final hasImages = images.isNotEmpty;

    for (int i = 0; i < widget.particleCount; i++) {
      // 65% 用使用者的雪花圖，其餘是小雪點；圖片載入失敗時改為程式畫雪花
      final useImage = hasImages && _rng.nextDouble() < 0.65;
      final paintedFlake = !useImage && !hasImages && _rng.nextDouble() < 0.4;

      final double size;
      if (useImage) {
        size = 26 + _rng.nextDouble() * 30; // 圖片雪花：26~56px 寬
      } else if (paintedFlake) {
        size = 7 + _rng.nextDouble() * 9;
      } else {
        size = 2.5 + _rng.nextDouble() * 3.5; // 小雪點
      }

      _particles.add(_FallParticle(
        x: _rng.nextDouble(),
        delay: _rng.nextDouble() * 6.4, // 6.4 秒內分批出生（間距拉開兩倍）
        duration: 7.0 + _rng.nextDouble() * 6.0, // 7~13 秒落地（慢兩倍）
        size: size,
        swayAmp: 12 + _rng.nextDouble() * 26,
        swaySpeed: 0.6 + _rng.nextDouble() * 1.2,
        swayPhase: _rng.nextDouble() * math.pi * 2,
        spinSpeed: useImage
            ? (_rng.nextDouble() - 0.5) * 1.6 // 圖片轉慢一點比較優雅
            : (_rng.nextDouble() - 0.5) * 2.4,
        spinPhase: _rng.nextDouble() * math.pi * 2,
        imageIndex: useImage ? _rng.nextInt(images.length) : -1,
        isFlake: paintedFlake,
        opacity: 0.4 + _rng.nextDouble() * 0.25, // 半透明冰晶感
      ));
    }
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    if (t >= _totalDuration) {
      _ticker.stop();
      setState(() {
        _particles.clear();
        _elapsed = 0;
      });
      return;
    }
    setState(() => _elapsed = t);
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _SnowPainter(
            particles: _particles,
            images: _snowImages ?? const [],
            elapsed: _elapsed,
            color: widget.snowColor,
          ),
        ),
      ),
    );
  }
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({
    required this.particles,
    required this.images,
    required this.elapsed,
    required this.color,
  });

  final List<_FallParticle> particles;
  final List<ui.Image> images;
  final double elapsed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final imagePaint = Paint()..filterQuality = FilterQuality.medium;
    final haloPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (final p in particles) {
      final local = elapsed - p.delay;
      if (local < 0) continue; // 還沒出生
      final t = local / p.duration;
      if (t > 1) continue; // 已經落地

      // 垂直位置：從畫面上方落到下方（圖片粒子留多一點緩衝）
      final margin = p.imageIndex >= 0 ? p.size : 40.0;
      final y = -margin + (size.height + margin * 2) * t;
      // 水平位置：基準點 + 正弦左右飄
      final x = p.x * size.width +
          math.sin(local * p.swaySpeed * math.pi + p.swayPhase) * p.swayAmp;

      // 淡入（前 8%）與淡出（最後 15%）
      double alpha = p.opacity;
      if (t < 0.08) alpha *= t / 0.08;
      if (t > 0.85) alpha *= (1 - t) / 0.15;
      alpha = alpha.clamp(0.0, 1.0);

      if (p.imageIndex >= 0 && p.imageIndex < images.length) {
        final img = images[p.imageIndex];
        // 淡淡的深色光暈墊底，讓淺色雪花圖在淺色背景上也看得見
        haloPaint.color = color.withValues(alpha: alpha * 0.14);
        canvas.drawCircle(Offset(x, y), p.size * 0.42, haloPaint);

        final scale = p.size / img.width;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(p.spinPhase + local * p.spinSpeed);
        canvas.scale(scale);
        imagePaint.color = Colors.white.withValues(alpha: alpha);
        canvas.drawImage(
          img,
          Offset(-img.width / 2, -img.height / 2),
          imagePaint,
        );
        canvas.restore();
      } else if (p.isFlake) {
        stroke
          ..color = color.withValues(alpha: alpha)
          ..strokeWidth = p.size * 0.14;
        _drawFlake(canvas, Offset(x, y), p.size,
            p.spinPhase + local * p.spinSpeed, stroke);
      } else {
        fill.color = color.withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), p.size, fill);
      }
    }
  }

  /// 備援用：程式畫的六角雪花（六根主枝 + 每根主枝上兩對小分枝）。
  void _drawFlake(
      Canvas canvas, Offset center, double r, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final tip = dir * r;
      canvas.drawLine(Offset.zero, tip, paint);
      for (final frac in const [0.55, 0.8]) {
        final base = dir * (r * frac);
        final branchLen = r * (frac == 0.55 ? 0.30 : 0.22);
        for (final side in const [1.0, -1.0]) {
          final branchAngle = angle + side * math.pi / 5;
          final end = base +
              Offset(math.cos(branchAngle), math.sin(branchAngle)) * branchLen;
          canvas.drawLine(base, end, paint);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SnowPainter old) =>
      old.elapsed != elapsed || old.particles != particles;
}

/// 全 App 共用的飄落動畫控制器。
/// 球球（floating_app_brand.dart）點擊時呼叫 play()，
/// 首頁（home_page.dart）的 MoodFallOverlay 監聽同一個 controller 播放動畫。
final moodFallControllerProvider = Provider<MoodFallController>((ref) {
  final controller = MoodFallController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// 每種氛圍對應哪一種飄落效果。
/// 之後新氛圍效果做好了，就在這裡把 none 換成對應的 FallEffectType。
extension MoodFallEffect on MoodTheme {
  FallEffectType get fallEffect {
    switch (this) {
      case MoodTheme.winter: // ❄️ 冬
      case MoodTheme.christmas: // 🎄 聖誕節
      case MoodTheme.winterBreak: // 🧣 寒假
        return FallEffectType.snow;
      case MoodTheme.none:
      case MoodTheme.newYear: // 🧧 過年（效果待定）
      case MoodTheme.spring: // 🌸 春（溪水+森林，之後做）
      case MoodTheme.summer: // ☀️ 夏（水花+芒果+飲品，之後做）
      case MoodTheme.autumn: // 🍁 秋（楓葉+山脈，之後做）
      case MoodTheme.summerBreak: // 🏖️ 暑假（效果待定）
        return FallEffectType.none;
    }
  }
}
