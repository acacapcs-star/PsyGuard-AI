import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  int _skin = 0;
  String _petType = 'penguin';
  String _petName = 'Lumi';
  bool _showFish = false;
  String _message = '';

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  final _random = Random();
  Map<String, dynamic>? _currentJoke;
  bool _jokeAnswerShown = false;

  static const _skinLabels = ['原味', '二號', '三號', '四號', '五號'];

  String _animalImage(String type, int skin) {
    final s = skin + 1;
    switch (type) {
      case 'otter':    return 'assets/images/otter_s$s.jpeg';
      case 'capybara': return 'assets/images/capy_s$s.jpeg';
      default:         return 'assets/images/penguin_s$s.jpeg';
    }
  }

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _xp      = prefs.getInt('lumi_xp')    ?? 0;
      _skin    = prefs.getInt('lumi_skin')   ?? 0;
      _petType = prefs.getString('pet_type') ?? 'penguin';
      print('DEBUG pet_type: \$_petType');
      _petName = prefs.getString('pet_name') ?? 'Lumi';
    });
  }

  Future<void> _saveXp()   async => (await SharedPreferences.getInstance()).setInt('lumi_xp', _xp);
  Future<void> _saveSkin() async => (await SharedPreferences.getInstance()).setInt('lumi_skin', _skin);

  void _bounce() {
    _bounceCtrl.forward().then((_) => _bounceCtrl.reverse());
  }

  void _feedFish() {
    setState(() {
      _showFish = true;
      _xp += 5;
      _message = '$_petName 開心地吃掉了魚！+5 XP 🐟';
    });
    _bounce();
    _saveXp();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFish = false);
    });
  }

  void _pet() {
    setState(() {
      _xp += 2;
      _message = '$_petName 好開心被摸摸！+2 XP 💙';
    });
    _bounce();
    _saveXp();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _message = '');
    });
  }

  void _newJoke() {
    setState(() {
      _currentJoke = JokeData.jokes[_random.nextInt(JokeData.jokes.length)];
      _jokeAnswerShown = false;
      _message = '';
    });
  }

  void _showAnswer() {
    setState(() {
      _jokeAnswerShown = true;
      _xp += 1;
      _message = JokeData.penguinLazyResponses[
          _random.nextInt(JokeData.penguinLazyResponses.length)];
    });
    _saveXp();
  }

  void _showCostumePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('幫 $_petName 換造型 👗',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final selected = _skin == i;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _skin = i;
                      _xp += 1;
                      _message = '換上造型 ${i + 1}！+1 XP ✨';
                    });
                    _saveSkin();
                    _saveXp();
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF0ABFBC)
                                : Colors.grey.shade300,
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            _animalImage(_petType, i),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.pets, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_skinLabels[i],
                          style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? const Color(0xFF0ABFBC)
                                  : Colors.grey)),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3B5E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text('$_petName 的樂園 🏝',
            style: const TextStyle(color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0ABFBC).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0ABFBC)),
            ),
            child: Text('⭐ $_xp XP',
                style: const TextStyle(
                    color: Color(0xFF0ABFBC), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 主角動物 ───────────────────────────────────────
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTap: _pet,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: _bounceAnim,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D3B5E),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            _animalImage(_petType, _skin),
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text(
                                '🐧', style: TextStyle(fontSize: 100)),
                          ),
                        ),
                      ),
                      if (_showFish)
                        const Positioned(
                          top: 10, right: 10,
                          child: Text('🐟', style: TextStyle(fontSize: 40)),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 訊息 ───────────────────────────────────────────
            if (_message.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center),
              ),

            // ── 笑話 ───────────────────────────────────────────
            if (_currentJoke != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('🐧 ${_currentJoke!['q']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center),
                    if (_jokeAnswerShown) ...[
                      const SizedBox(height: 6),
                      Text('答案：${_currentJoke!['a']}',
                          style: const TextStyle(
                              color: Color(0xFF0ABFBC),
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ] else
                      TextButton(
                        onPressed: _showAnswer,
                        child: const Text('直接看答案 😅',
                            style: TextStyle(color: Color(0xFF0ABFBC))),
                      ),
                  ],
                ),
              ),

            // ── 按鈕 ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionBtn(icon: '🐟', label: '丟魚', onTap: _feedFish),
                  _ActionBtn(icon: '😂', label: '出題', onTap: _newJoke),
                  _ActionBtn(icon: '👗', label: '換造型', onTap: _showCostumePicker),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('點擊 $_petName 可以摸摸牠 💙',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
