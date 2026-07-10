import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'voice_wake_service.dart';

class VoiceWakePage extends StatefulWidget {
  const VoiceWakePage({super.key});

  @override
  State<VoiceWakePage> createState() => _VoiceWakePageState();
}

class _VoiceWakePageState extends State<VoiceWakePage>
    with SingleTickerProviderStateMixin {
  final VoiceWakeService _service = VoiceWakeService();
  bool _isListening = false;
  String _statusText = '點擊麥克風說「嘿，在嗎？」';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _service.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _service.stopListening();
      setState(() {
        _isListening = false;
        _statusText = '點擊麥克風說「嘿，在嗎？」';
      });
    } else {
      setState(() {
        _isListening = true;
        _statusText = '我在聽...';
      });
      await _service.startListening(
        onWakeWordDetected: (text) {
          setState(() => _statusText = '我在！有什麼我可以幫你的嗎？ 💙');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/chat');
          });
        },
        onResult: (text) {
          setState(() => _statusText = '聽到了：$text');
        },
      );
    }
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
        title: const Text('嘿，在嗎？', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lumi企鵝圖
            Image.asset(
              'assets/images/penguin_happy.png',
              width: 150,
              height: 150,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.pets,
                size: 100,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),

            // 狀態文字
            Text(
              _statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // 麥克風按鈕
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? const Color(0xFF0ABFBC)
                        : Colors.white24,
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0ABFBC).withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isListening ? '點擊停止' : '點擊開始聆聽',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
