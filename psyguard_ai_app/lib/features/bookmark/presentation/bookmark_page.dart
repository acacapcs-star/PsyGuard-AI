// ═══════════════════════════════════════════════════════════
// lii - 我的書籤 Bookmarks 🚡（纜車山相簿版）
//
// 收藏頁 = 一座山 + 之字纜線，書籤變成纜車廂掛在線上。
// 山頂最新、山底最舊。可選外框、背景、署名。中英嚴格分開。
// 存在手機（SharedPreferences），關掉再開還在。
// ═══════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_strings.dart';
import '../../../core/security/local_settings_service.dart';

const _kBookmarksKey = 'bookmarks_v2';

const List<Color> _bgColors = [
  Color(0xFF7E8FE8),
  Color(0xFFF7A8B8),
  Color(0xFF6FCF97),
  Color(0xFFF2C94C),
  Color(0xFFB8A7E0),
  Color(0xFF56607F),
];

const List<String> _bgImages = [
  'assets/images/hope_night.jpg',
  'assets/images/hope_lonely.jpg',
  'assets/images/hope_tired.jpg',
  'assets/images/hope_cheer.jpg',
];

const List<List<String>> _frameNames = [
  ['圓角', 'Rounded'],
  ['白框', 'White'],
  ['拍立得', 'Polaroid'],
  ['貼紙', 'Sticker'],
  ['雙線', 'Double'],
];

class Bookmark {
  final String quote;
  final String author;
  final int colorIndex;
  final int imageIndex;
  final int frameIndex;

  const Bookmark({
    required this.quote,
    required this.author,
    required this.colorIndex,
    required this.imageIndex,
    required this.frameIndex,
  });

  Map<String, dynamic> toJson() => {
        'quote': quote,
        'author': author,
        'colorIndex': colorIndex,
        'imageIndex': imageIndex,
        'frameIndex': frameIndex,
      };

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        quote: j['quote'] as String? ?? '',
        author: j['author'] as String? ?? '',
        colorIndex: j['colorIndex'] as int? ?? 0,
        imageIndex: j['imageIndex'] as int? ?? -1,
        frameIndex: j['frameIndex'] as int? ?? 0,
      );
}

class BookmarkPage extends ConsumerStatefulWidget {
  const BookmarkPage({super.key});
  @override
  ConsumerState<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends ConsumerState<BookmarkPage> {
  List<Bookmark> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kBookmarksKey);
      if (raw != null && raw.isNotEmpty) {
        _items = (jsonDecode(raw) as List)
            .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kBookmarksKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  void _addBookmark(Bookmark b) {
    setState(() => _items.insert(0, b));
    _save();
  }

  void _delete(int index) {
    setState(() => _items.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppStrings.of(ref.watch(appLanguageControllerProvider));
    final zh = copy.isZhTw;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          zh ? '🚡 Pacer Lift' : '🚡 Pacer Lift',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3150)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7E8FE8),
        foregroundColor: Colors.white,
        onPressed: () => _openCreator(zh),
        icon: const Icon(Icons.add),
        label: Text(zh ? '新增' : 'Add'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _emptyState(zh)
              : _cableMountain(zh),
    );
  }

  Widget _emptyState(bool zh) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _MountainPainter()),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚡', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                zh ? '還沒有 Pacer' : 'No Pacers yet',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3150)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Text(
                  zh
                      ? '存下有人對你說過、想記得的話 🌙'
                      : 'Save the words someone said to you 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 纜車山 ──
  Widget _cableMountain(bool zh) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const cabinW = 132.0;
        const cabinH = 104.0;
        const rowH = 168.0;
        const topPad = 110.0;
        final n = _items.length;
        final totalH = topPad + n * rowH + 90.0;

        // 每個車廂的位置（山頂=最新=最上面）
        final cabins = <_CabinPos>[];
        for (var i = 0; i < n; i++) {
          final leftSide = i.isEven;
          final x = leftSide ? width * 0.08 : width * 0.92 - cabinW;
          final y = topPad + i * rowH;
          cabins.add(_CabinPos(
            index: i,
            rect: Rect.fromLTWH(x, y, cabinW, cabinH),
            anchor: Offset(x + cabinW / 2, y - 16), // 掛纜線的點
          ));
        }

        return SingleChildScrollView(
          child: SizedBox(
            width: width,
            height: totalH,
            child: Stack(
              children: [
                // 山 + 天空
                Positioned.fill(child: CustomPaint(painter: _MountainPainter())),
                // 纜線
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CablePainter(
                      anchors: cabins.map((c) => c.anchor).toList(),
                      cabins: cabins.map((c) => c.rect).toList(),
                    ),
                  ),
                ),
                // 車廂
                for (final c in cabins)
                  Positioned(
                    left: c.rect.left,
                    top: c.rect.top,
                    width: c.rect.width,
                    height: c.rect.height,
                    child: GestureDetector(
                      onTap: () => _viewBookmark(c.index, zh),
                      child: _cableCar(_items[c.index]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 一節纜車廂 ──
  Widget _cableCar(Bookmark b) {
    final useImage = b.imageIndex >= 0;
    final bg = useImage
        ? null
        : _bgColors[b.colorIndex.clamp(0, _bgColors.length - 1)];
    return Column(
      children: [
        // 車頂
        Container(
          width: 54,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF6C7BA6),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        // 車身
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: bg,
              image: useImage
                  ? DecorationImage(
                      image: AssetImage(
                          _bgImages[b.imageIndex.clamp(0, _bgImages.length - 1)]),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: useImage
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.5),
                        ],
                      )
                    : null,
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        b.quote,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  if (b.author.isNotEmpty)
                    Text(
                      '\u2014 ${b.author}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _viewBookmark(int i, bool zh) {
    final b = _items[i];
    final useImage = b.imageIndex >= 0;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 250,
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: useImage
                    ? null
                    : _bgColors[b.colorIndex.clamp(0, _bgColors.length - 1)],
                image: useImage
                    ? DecorationImage(
                        image: AssetImage(_bgImages[
                            b.imageIndex.clamp(0, _bgImages.length - 1)]),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black38, blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: useImage
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.5),
                          ],
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('\u275D',
                        style: TextStyle(
                            fontSize: 30, color: Colors.white, height: 1)),
                    Expanded(
                      child: Center(
                        child: Text(
                          b.quote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        b.author.isEmpty ? '' : '\u2014 ${b.author}',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _delete(i);
                  },
                  icon: const Icon(Icons.delete_outline, color: Color(0xFF2C3150)),
                  label: Text(zh ? '刪除' : 'Delete',
                      style: const TextStyle(color: Color(0xFF2C3150))),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(zh ? '關閉' : 'Close',
                      style: const TextStyle(color: Color(0xFF2C3150))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCreator(bool zh) {
    final quoteCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    int colorIndex = 0;
    int imageIndex = -1;
    int frameIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(zh ? '新增一個 Pacer 🔖' : 'Add a Pacer 🔖',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    // 預覽（一節纜車廂）
                    Center(
                      child: SizedBox(
                        width: 140,
                        height: 120,
                        child: _cableCar(Bookmark(
                          quote: quoteCtrl.text.isEmpty
                              ? (zh ? '他對你說的那句話…' : 'What they said…')
                              : quoteCtrl.text,
                          author: authorCtrl.text,
                          colorIndex: colorIndex,
                          imageIndex: imageIndex,
                          frameIndex: frameIndex,
                        )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: quoteCtrl,
                      maxLines: 3,
                      onChanged: (_) => setSheet(() {}),
                      decoration: InputDecoration(
                        labelText: zh ? '他說過的那句話' : 'The line they said',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: authorCtrl,
                      onChanged: (_) => setSheet(() {}),
                      decoration: InputDecoration(
                        labelText: zh ? '誰說的' : 'Who said it',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(zh ? '背景顏色' : 'Background color',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: List.generate(_bgColors.length, (i) {
                        final selected = imageIndex < 0 && colorIndex == i;
                        return GestureDetector(
                          onTap: () => setSheet(() {
                            colorIndex = i;
                            imageIndex = -1;
                          }),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _bgColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    selected ? Colors.black87 : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(zh ? '背景圖片' : 'Background image',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: List.generate(_bgImages.length, (i) {
                        final selected = imageIndex == i;
                        return GestureDetector(
                          onTap: () => setSheet(() => imageIndex = i),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: AssetImage(_bgImages[i]),
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF7E8FE8)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E8FE8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (quoteCtrl.text.trim().isEmpty) return;
                          _addBookmark(Bookmark(
                            quote: quoteCtrl.text.trim(),
                            author: authorCtrl.text.trim(),
                            colorIndex: colorIndex,
                            imageIndex: imageIndex,
                            frameIndex: frameIndex,
                          ));
                          Navigator.pop(ctx);
                        },
                        child: Text(zh ? '收好' : 'Keep it',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CabinPos {
  final int index;
  final Rect rect;
  final Offset anchor;
  const _CabinPos({required this.index, required this.rect, required this.anchor});
}

// ── 山 + 天空 ──
class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 天空 → 草地漸層
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCDE7F7), Color(0xFFE7F3E9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // 遠山（淡藍）鋪整條高度
    final far = Paint()..color = const Color(0xFFBFD3E8).withOpacity(0.55);
    for (double y = 60; y < h; y += 260) {
      final p = Path()
        ..moveTo(0, y + 120)
        ..lineTo(w * 0.30, y)
        ..lineTo(w * 0.60, y + 90)
        ..lineTo(w, y + 20)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(p, far);
    }

    // 雪頂（最上面的大山）
    final peak = Paint()..color = const Color(0xFFF6FAFF);
    final peakShadow = Paint()..color = const Color(0xFFD8E6F5);
    final peakPath = Path()
      ..moveTo(w * 0.5, 20)
      ..lineTo(w * 0.16, 150)
      ..lineTo(w * 0.84, 150)
      ..close();
    canvas.drawPath(peakPath, peakShadow);
    final peakPath2 = Path()
      ..moveTo(w * 0.5, 20)
      ..lineTo(w * 0.30, 150)
      ..lineTo(w * 0.60, 150)
      ..close();
    canvas.drawPath(peakPath2, peak);

    // 雲朵
    final cloud = Paint()..color = Colors.white.withOpacity(0.85);
    void drawCloud(double cx, double cy, double s) {
      canvas.drawCircle(Offset(cx, cy), 14 * s, cloud);
      canvas.drawCircle(Offset(cx + 16 * s, cy + 4 * s), 18 * s, cloud);
      canvas.drawCircle(Offset(cx + 36 * s, cy), 13 * s, cloud);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 2 * s, cy + 2 * s, 40 * s, 12 * s),
          Radius.circular(8 * s),
        ),
        cloud,
      );
    }

    for (double y = 200; y < h; y += 340) {
      drawCloud(w * 0.18, y, 0.9);
      drawCloud(w * 0.62, y + 150, 1.1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 之字纜線 ──
class _CablePainter extends CustomPainter {
  final List<Offset> anchors;
  final List<Rect> cabins;
  _CablePainter({required this.anchors, required this.cabins});

  @override
  void paint(Canvas canvas, Size size) {
    if (anchors.isEmpty) return;
    final line = Paint()
      ..color = const Color(0xFF6C7BA6)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    // 從畫面頂端下來，串連每個車廂，再往下延伸
    final path = Path()..moveTo(anchors.first.dx, 0);
    for (final a in anchors) {
      path.lineTo(a.dx, a.dy);
    }
    path.lineTo(anchors.last.dx, size.height);
    canvas.drawPath(path, line);

    // 每個掛點：小輪子 + 吊臂到車頂
    final wheel = Paint()..color = const Color(0xFF4E5A7E);
    final arm = Paint()
      ..color = const Color(0xFF6C7BA6)
      ..strokeWidth = 2.2;
    for (var i = 0; i < anchors.length; i++) {
      final a = anchors[i];
      final cabinTop = Offset(cabins[i].center.dx, cabins[i].top);
      canvas.drawLine(a, cabinTop, arm);
      canvas.drawCircle(a, 5, wheel);
      canvas.drawCircle(a, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _CablePainter old) =>
      old.anchors != anchors;
}
