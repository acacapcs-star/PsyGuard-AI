import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceWakeService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isAvailable = false;

  static const List<String> wakeWords = ['嘿在嗎', '嘿，在嗎', '在嗎', 'hey psyguard', 'hey lumi'];

  Future<void> initialize() async {
    _isAvailable = await _speech.initialize();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<void> startListening({
    required Function(String) onWakeWordDetected,
    required Function(String) onResult,
  }) async {
    if (!_isAvailable) return;
    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        final hasWakeWord = wakeWords.any((w) => text.contains(w.toLowerCase()));
        if (hasWakeWord) {
          onWakeWordDetected(text);
          _respond();
        } else if (result.finalResult) {
          onResult(text);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'zh_TW',
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  Future<void> _respond({String locale = 'zh-TW'}) async {
    if (locale.startsWith('en')) {
      await _tts.setLanguage('en-US');
      await _tts.speak("Hey! I'm Lumi. I'm here for you.");
    } else {
      await _tts.setLanguage('zh-TW');
      await _tts.speak('嘿！我是Lumi，我在這裡陪你。');
    }
  }

  Future<void> dispose() async {
    await _speech.stop();
    await _tts.stop();
  }
}
