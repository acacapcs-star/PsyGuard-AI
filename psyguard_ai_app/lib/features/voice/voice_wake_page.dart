import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_language.dart';
import '../../core/security/local_settings_service.dart';
import 'voice_wake_service.dart';

class VoiceWakePage extends ConsumerStatefulWidget {
  const VoiceWakePage({super.key});

  @override
  ConsumerState<VoiceWakePage> createState() => _VoiceWakePageState();
}

class _VoiceWakePageState extends ConsumerState<VoiceWakePage>
    with SingleTickerProviderStateMixin {
  final VoiceWakeService _service = VoiceWakeService();
  bool _isListening = false;
  bool _isNoteMode = false;
  String _statusText = '';
  bool _statusInitialized = false;
  String _spokenText = '';
  String _apiKey = '';

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
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    const storage = FlutterSecureStorage();
    _apiKey = (await storage.read(key: 'ai_api_key'))?.trim() ?? '';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _organizeAndSaveToNote(String text) async {
    if (text.isEmpty) return;
    final isZh = ref.read(appLanguageControllerProvider) == AppLanguage.zhTw;
    if (_apiKey.isEmpty) {
      setState(() => _statusText = isZh ? 'API Key 未設定，請先到設定頁面填入' : 'API Key not set - please add it in Settings');
      return;
    }
    setState(() => _statusText = isZh ? '正在整理筆記...' : 'Organizing your notes...');

    try {
      final languageInstruction = isZh
          ? 'Write every bullet point in Traditional Chinese, regardless of what language the input is in.'
          : 'Write every bullet point in English, regardless of what language the input is in.';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Extract key action items and important points from the user speech. '
                  'Return ONLY a JSON array of strings, each being a concise bullet point. '
                  '$languageInstruction Max 5 items. '
                  'Example: ["買菜", "明天打電話給醫生", "週五前交報告"]'
            },
            {'role': 'user', 'content': text}
          ],
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['choices'][0]['message']['content'] as String;
        final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();
        final List bullets = jsonDecode(clean);

        final now = DateTime.now();
        DateTime targetDate = now;
        final lowerText = text.toLowerCase();
        if (lowerText.contains('明天') || lowerText.contains('tomorrow') || lowerText.contains('tmr')) {
          targetDate = now.add(const Duration(days: 1));
        } else if (lowerText.contains('後天') || lowerText.contains('day after tomorrow')) {
          targetDate = now.add(const Duration(days: 2));
        } else if (lowerText.contains('下週') || lowerText.contains('下周') || lowerText.contains('next week')) {
          targetDate = now.add(const Duration(days: 7));
        }

        final prefs = await SharedPreferences.getInstance();
        final targetKey = 'note_${targetDate.year}_${targetDate.month}_${targetDate.day}';
        final existing = prefs.getString(targetKey);
        final List items =
            existing != null ? (jsonDecode(existing) as List) : [];

        items.add({
          'text': isZh ? '🎤 語音筆記' : '🎤 Voice Note',
          'type': 0,
          'checked': false,
          'priority': 12,
        });
        for (final bullet in bullets) {
          items.add({
            'text': '☐ \$bullet',
            'type': 2,
            'checked': false,
            'priority': 4,
          });
        }

        await prefs.setString(targetKey, jsonEncode(items));

        final daysUntil = targetDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        if (daysUntil > 0) {
          final todayKey = 'note_\${now.year}_\${now.month}_\${now.day}';
          final todayRaw = prefs.getString(todayKey);
          final List todayItems = todayRaw != null ? (jsonDecode(todayRaw) as List) : [];
          final countdown = isZh
              ? (daysUntil == 1 ? '明天' : '還有 \$daysUntil 天')
              : (daysUntil == 1 ? 'Tomorrow' : 'In \$daysUntil days');
          final firstBullet = bullets.isNotEmpty ? bullets.first.toString() : '';
          todayItems.add({
            'text': '⏰ \$countdown：\$firstBullet',
            'type': 2,
            'checked': false,
            'priority': 6,
          });
          await prefs.setString(todayKey, jsonEncode(todayItems));
        }
        setState(
          () => _statusText = isZh
              ? '✅ 已整理 ${bullets.length} 條筆記到今日 Diary！'
              : '✅ Organized ${bullets.length} notes into today\'s Diary!',
        );
      } else {
        setState(() => _statusText = isZh ? '整理失敗 (${response.statusCode})，請重試' : 'Failed (${response.statusCode}), please try again');
      }
    } catch (e) {
      setState(() => _statusText = isZh ? '整理失敗，請重試' : 'Failed to organize, please try again');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _service.stopListening();
      setState(() {
        _isListening = false;
        if (!_isNoteMode) _statusText = '點擊麥克風說「嘿，在嗎？」';
      });
    } else {
      setState(() {
        _isListening = true;
        _spokenText = '';
        _statusText = _isNoteMode ? '我在聽，說完點停止...' : '我在聽...';
      });
      final isZh = ref.read(appLanguageControllerProvider) == AppLanguage.zhTw;
      await _service.startListening(
        isZh: isZh,
        onWakeWordDetected: (text) {
          if (!_isNoteMode) {
            setState(() {
              _statusText = isZh
                  ? 'Lumi：嘿！我在這裡陪你 💙'
                  : "Lumi: Hey! I'm here for you 💙";
              _isListening = false;
            });
          }
        },
        onResult: (text) {
          setState(() {
            _spokenText = text;
            _statusText = _isNoteMode
                ? (isZh ? '說完了，點「整理成筆記」👆' : 'Done! Tap "Organize Notes" 👆')
                : (isZh ? '聽到了：$text' : 'Heard: $text');
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = ref.watch(appLanguageControllerProvider) == AppLanguage.zhTw;
    if (!_statusInitialized) {
      _statusText = isZh ? '點擊麥克風說「嘿，在嗎？」' : 'Tap the mic and say "Hey Lumi"';
      _statusInitialized = true;
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0D3B5E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(isZh ? '嘿，在嗎？' : 'Hey Lumi', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _isNoteMode = !_isNoteMode;
              _statusText = _isNoteMode
                  ? (isZh ? '說話後自動整理成筆記 📝' : 'Speak and auto-organize into notes 📝')
                  : (isZh ? '點擊麥克風說「嘿，在嗎？」' : 'Tap the mic and say "Hey Lumi"');
              _spokenText = '';
            }),
            child: Text(
              _isNoteMode
                  ? (isZh ? '🎙 筆記模式' : '🎙 Note Mode')
                  : (isZh ? '💬 喚醒模式' : '💬 Wake Mode'),
              style: const TextStyle(color: Color(0xFF0ABFBC)),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_isNoteMode && _spokenText.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _spokenText,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _organizeAndSaveToNote(_spokenText),
                icon: const Icon(Icons.auto_fix_high),
                label: Text(isZh ? '整理成筆記' : 'Organize Notes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0ABFBC),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 24),
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
                              color: const Color(0xFF0ABFBC)
                                  .withValues(alpha: 0.5),
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
              _isListening
                  ? (isZh ? '點擊停止' : 'Tap to stop')
                  : (isZh ? '點擊開始聆聽' : 'Tap to start listening'),
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
