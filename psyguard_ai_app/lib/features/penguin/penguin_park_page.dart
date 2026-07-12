import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'joke_data.dart';

class PenguinParkPage extends StatefulWidget {
  const PenguinParkPage({super.key});

  @override
  State<PenguinParkPage> createState() => _PenguinParkPageState();
}

class _PenguinParkPageState extends State<PenguinParkPage>
    with TickerProviderStateMixin {
  int _xp = 0;
  int _igloo = 1;
  String _outfit = 'happy';
  String _petType = 'otter';
  String _penguinState = 'happy';
  bool _showFish = false;
  String _selectedFish = 'fish_clown';
  final Random _random = Random();
  late AnimationController _penguinBounce;
  late Animation<double> _bounceAnim;

  final Map<String, int> _fishXP = {
    'fish_clown': 10,
    'fish_puffer': 15,
    'fish_yellow': 8,
    'fish_cartoon': 5,
    'jellyfish1': 20,
    'jellyfish2': 20,
  };

  final Map<String, String> _fishNames = {
    'fish_clown': '小丑魚 +10 XP',
    'fish_puffer': '河豚 +15 XP',
    'fish_yellow': '黃魚 +8 XP',
    'fish_cartoon': '普通魚 +5 XP',
    'jellyfish1': '水母 +20 XP ⭐',
    'jellyfish2': '彩虹水母 +20 XP ⭐',
  };

  String get _bgImage {
    if (_xp >= 50) return 'assets/images/coral_bg.jpeg';
    if (_xp >= 20) return 'assets/images/ocean_bg.jpeg';
    return '';
  }

  String get _iglooImage {
    if (_igloo >= 3) return 'assets/images/igloo3.jpeg';
    if (_igloo >= 2) return 'assets/images/igloo2.jpeg';
    return 'assets/images/igloo1.jpeg';
  }

  String get _penguinImage {
    if (_outfit == 'eating' || _outfit == 'love') {
      return _petType == 'capybara'
          ? 'assets/images/pet_capybara_bg.jpeg'
          : 'assets/images/pet_otter_bg.jpeg';
    }
    if (_outfit.startsWith('outfit')) {
      final num = _outfit.replaceAll('outfit', '');
      return _petType == 'capybara'
          ? 'assets/images/capy_outfit$num.jpeg'
          : 'assets/images/otter_outfit$num.jpeg';
    }
    return _petType == 'capybara'
        ? 'assets/images/pet_capybara.jpeg'
        : 'assets/images/pet_otter.jpeg';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _penguinBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _penguinBounce, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _penguinBounce.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _xp = prefs.getInt('penguin_xp') ?? 0;
      _igloo = prefs.getInt('igloo_level') ?? 1;
      _outfit = prefs.getString('penguin_outfit') ?? 'happy';
      _petType = prefs.getString('pet_type') ?? 'otter';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('penguin_xp', _xp);
    await prefs.setInt('igloo_level', _igloo);
    await prefs.setString('penguin_outfit', _outfit);
  }

  void _feedFish(String fish) {
    final xpGain = _fishXP[fish] ?? 5;
    setState(() {
      _xp += xpGain;
      _penguinState = 'eating';
      _outfit = 'eating';
      _showFish = false;
      if (_xp >= 300 && _igloo < 3) _igloo = 3;
      else if (_xp >= 150 && _igloo < 2) _igloo = 2;
    });
    _saveData();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _outfit = 'happy');
        _showJokeDialog();
      }
    });
  }

  void _petPenguin() {
    setState(() => _outfit = 'love');
    _xp += 5;
    _saveData();

    final quote = JokeData.inspirationalQuotes[
        _random.nextInt(JokeData.inspirationalQuotes.length)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF0F8FF),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐧 企鵝想跟你說...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(quote, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _outfit = 'happy');
              },
              child: const Text('謝謝企鵝 💙'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJokeDialog() {
    final joke = JokeData.jokes[_random.nextInt(JokeData.jokes.length)];
    bool _revealed = false;
    String _userInput = '';
    String _feedbackMsg = '';
    int _mode = 0; // 0=選擇 1=猜猜看 2=揭曉

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFF0F8FF),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐧 企鵝出題啦！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(joke['q']!, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 16),

                if (_mode == 0) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B8C85)),
                    onPressed: () => setModalState(() => _mode = 1),
                    child: const Text('🤔 猜猜看', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setModalState(() => _mode = 2),
                    child: const Text('😴 直接看答案'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      final lazy = JokeData.penguinLazyResponses[
                          _random.nextInt(JokeData.penguinLazyResponses.length)];
                      setModalState(() {
                        _feedbackMsg = lazy;
                        _mode = 2;
                      });
                      setState(() => _xp = (_xp - 1).clamp(0, 99999));
                      _saveData();
                    },
                    child: const Text('🦥 懶...:> (-1 XP)'),
                  ),
                ],

                if (_mode == 1) ...[
                  TextField(
                    decoration: const InputDecoration(hintText: '你的答案...'),
                    onChanged: (v) => _userInput = v,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B8C85)),
                    onPressed: () {
                      final correct = _userInput.trim().isNotEmpty &&
                          joke['a']!.contains(_userInput.trim());
                      final responses = correct
                          ? JokeData.penguinCorrectResponses
                          : JokeData.penguinWrongResponses;
                      setModalState(() {
                        _feedbackMsg = responses[_random.nextInt(responses.length)];
                        _mode = 2;
                      });
                      if (correct) {
                        setState(() => _xp += 5);
                        _saveData();
                      }
                    },
                    child: const Text('送出答案', style: TextStyle(color: Colors.white)),
                  ),
                ],

                if (_mode == 2) ...[
                  if (_feedbackMsg.isNotEmpty) ...[
                    Text(_feedbackMsg, style: const TextStyle(fontSize: 13, color: Color(0xFF5B8C85)), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('答案：${joke['a']}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('關閉'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOutfitPicker() {
    final isCapybara = _petType == 'capybara';
    final outfits = isCapybara ? [
      {'key': 'happy', 'name': '原味水豚', 'img': 'assets/images/pet_capybara.jpeg'},
      {'key': 'outfit1', 'name': '換裝一', 'img': 'assets/images/capy_outfit1.jpeg'},
      {'key': 'outfit2', 'name': '換裝二', 'img': 'assets/images/capy_outfit2.jpeg'},
      {'key': 'outfit3', 'name': '換裝三', 'img': 'assets/images/capy_outfit3.jpeg'},
      {'key': 'outfit4', 'name': '換裝四', 'img': 'assets/images/capy_outfit4.jpeg'},
    ] : [
      {'key': 'happy', 'name': '原味水獺', 'img': 'assets/images/pet_otter.jpeg'},
      {'key': 'outfit1', 'name': '換裝一', 'img': 'assets/images/otter_outfit1.jpeg'},
      {'key': 'outfit2', 'name': '換裝二', 'img': 'assets/images/otter_outfit2.jpeg'},
      {'key': 'outfit3', 'name': '換裝三', 'img': 'assets/images/otter_outfit3.jpeg'},
      {'key': 'outfit4', 'name': '換裝四', 'img': 'assets/images/otter_outfit4.jpeg'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A3558),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_petType == 'capybara' ? '👗 幫巴拉換衣服' : '👗 幫水獺換衣服',
          style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 300,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            children: outfits.map((o) => GestureDetector(
              onTap: () {
                setState(() => _outfit = o['key']!);
                _saveData();
                Navigator.pop(ctx);
              },
              child: Column(
                children: [
                  Image.asset(o['img']!, width: 60, height: 60, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                  Text(o['name']!, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                ],
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_petType == 'capybara' ? '🦫 巴拉說' : '🦦 水獺想說', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('⭐ $_xp XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: _bgImage.isNotEmpty
                ? Image.asset(_bgImage, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A6B9E)))
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1A6B9E), Color(0xFF0D3B5E)],
                      ),
                    ),
                  ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // igloo
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Image.asset(_iglooImage, width: 100, height: 100, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                ),

                // 企鵝
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _bounceAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _bounceAnim.value),
                            child: child,
                          ),
                          child: GestureDetector(
                            onTap: _petPenguin,
                            child: Image.asset(_penguinImage, width: 150, height: 150, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 100, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('點我摸摸 💙', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                // 底部按鈕
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      // 丟魚按鈕
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B8C85),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => setState(() => _showFish = !_showFish),
                        icon: const Text('🐟', style: TextStyle(fontSize: 20)),
                        label: const Text('丟魚給企鵝', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),

                      // 魚選擇
                      if (_showFish) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _fishXP.keys.map((fish) => GestureDetector(
                              onTap: () => _feedFish(fish),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  children: [
                                    Image.asset('assets/images/$fish.jpeg', width: 55, height: 55, fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.set_meal, size: 40, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(_fishNames[fish]!.split(' ').last,
                                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // 換衣服按鈕
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _showOutfitPicker,
                        icon: const Text('👗', style: TextStyle(fontSize: 16)),
                        label: const Text('換衣服', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
