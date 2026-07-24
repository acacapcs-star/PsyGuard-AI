import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🐧 企鵝孵蛋
///
/// 點首頁冬天角落的工程師企鵝 -> 生蛋（蛋先排在牠腳邊）
/// 滿 kNestSize 顆 -> 「更多功能」標題上方展開一排巢，蛋依序孵出小企鵝
/// 孵完再點企鵝 -> 重新開始下一窩
///
/// 想調大小改這幾個常數就好，不用重做圖。
const int kNestSize = 5;
const double kEggWidth = 40;
const double kEggHeight = 50;
const Duration kHatchGap = Duration(milliseconds: 430);

const String _kPrefEggs = 'penguin_nest_eggs';
const String _kPrefHatched = 'penguin_nest_hatched';
const String _kPrefStage = 'penguin_nest_stage';

enum NestStage {
  filling, // 還在生蛋
  hatching, // 孵化中
  done, // 全部孵完
}

class PenguinNestModel extends ChangeNotifier {
  final List<double> _eggs = []; // 蛋在企鵝腳邊的水平位置 -1..1
  int _hatched = 0;
  NestStage _stage = NestStage.filling;
  Timer? _timer;
  bool _loaded = false;

  List<double> get eggs => List.unmodifiable(_eggs);
  int get hatched => _hatched;
  NestStage get stage => _stage;

  /// 巢窩要不要出現：蛋滿了才展開
  bool get showRow => _eggs.length >= kNestSize;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList(_kPrefEggs) ?? const <String>[];
    _eggs
      ..clear()
      ..addAll(saved.map((e) => double.tryParse(e) ?? 0.0));

    _hatched = prefs.getInt(_kPrefHatched) ?? 0;

    final name = prefs.getString(_kPrefStage) ?? 'filling';
    _stage = NestStage.values.firstWhere(
      (e) => e.name == name,
      orElse: () => NestStage.filling,
    );

    // 上次關 App 時還沒孵完 -> 接著孵
    if (_stage == NestStage.hatching && _hatched < kNestSize) {
      _startHatching();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kPrefEggs, _eggs.map((e) => e.toStringAsFixed(3)).toList());
    await prefs.setInt(_kPrefHatched, _hatched);
    await prefs.setString(_kPrefStage, _stage.name);
  }

  /// 點企鵝：生一顆蛋。孵化中會忽略；孵完了則開新的一窩。
  void layEgg(double x) {
    if (_stage == NestStage.hatching) return;

    if (_stage == NestStage.done) {
      _eggs.clear();
      _hatched = 0;
      _stage = NestStage.filling;
    }

    if (_eggs.length < kNestSize) _eggs.add(x);

    if (_eggs.length >= kNestSize) {
      _stage = NestStage.hatching;
      _startHatching();
    }

    notifyListeners();
    _save();
  }

  void _startHatching() {
    _timer?.cancel();
    _timer = Timer.periodic(kHatchGap, (t) {
      if (_hatched >= kNestSize) {
        t.cancel();
        _stage = NestStage.done;
        notifyListeners();
        _save();
        return;
      }
      _hatched++;
      notifyListeners();
      _save();
    });
  }

  /// 全部清空（想加「重來」按鈕的話可以呼叫）
  void reset() {
    _timer?.cancel();
    _eggs.clear();
    _hatched = 0;
    _stage = NestStage.filling;
    notifyListeners();
    _save();
  }
}

/// 全域單例：首頁企鵝和巢窩共用同一份狀態
final PenguinNestModel penguinNest = PenguinNestModel();

/// 🪹 一整排的巢，放在「更多功能」標題上方。蛋沒滿之前完全不佔位。
class PenguinNestRow extends StatefulWidget {
  /// 語言由 home_page 的 copy.isZhTw 傳進來，跟 App 其他地方共用同一個來源
  final bool isZh;

  const PenguinNestRow({super.key, required this.isZh});

  @override
  State<PenguinNestRow> createState() => _PenguinNestRowState();
}

class _PenguinNestRowState extends State<PenguinNestRow> {
  @override
  void initState() {
    super.initState();
    penguinNest.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: penguinNest,
      builder: (context, _) {
        if (!penguinNest.showRow) return const SizedBox.shrink();

        final done = penguinNest.stage == NestStage.done;
        final zh = widget.isZh;
        final label = done
            ? (zh ? '🐧 孵出來了！再點企鵝生下一窩' : '🐧 They hatched! Tap the penguin for a new clutch')
            : (zh
                ? '🥚 蛋孵化中… (${penguinNest.hatched}/$kNestSize)'
                : '🥚 Hatching… (${penguinNest.hatched}/$kNestSize)');

        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  kNestSize,
                  (i) => _NestSlot(
                    index: i,
                    hatched: i < penguinNest.hatched,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 單一個巢：底下是巢，上面是蛋或孵出來的小企鵝
class _NestSlot extends StatelessWidget {
  final int index;
  final bool hatched;

  const _NestSlot({required this.index, required this.hatched});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: kEggHeight + 24,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 🪹 巢
          Container(
            width: 58,
            height: 20,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC0A070), Color(0xFF8A6A3E)],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.elliptical(29, 9),
                bottom: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          // 🥚 / 🐧
          Positioned(
            bottom: 11,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: hatched
                  ? Image.asset(
                      index.isEven
                          ? 'assets/images/mood_baby_penguin_1.png'
                          : 'assets/images/mood_baby_penguin_2.png',
                      key: ValueKey('baby-$index'),
                      width: kEggWidth + 8,
                      height: kEggHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        '🐧',
                        style: TextStyle(fontSize: 32),
                      ),
                    )
                  : Container(
                      key: ValueKey('egg-$index'),
                      width: kEggWidth,
                      height: kEggHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFDF6), Color(0xFFE8DAC0)],
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(kEggWidth / 2, kEggHeight / 2),
                        ),
                        border: Border.all(color: const Color(0xFFD8CDB8)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      // 蛋殼高光
                      child: Align(
                        alignment: const Alignment(-0.35, -0.45),
                        child: Container(
                          width: kEggWidth * 0.22,
                          height: kEggHeight * 0.18,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(
                                  kEggWidth * 0.11, kEggHeight * 0.09),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
