import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceWakeService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isAvailable = false;

  // 🔧 修正「重複 prompt」的問題：同一句話在講的過程中，
  // onResult 會連續觸發好幾次「部分結果」，如果每次都判斷喚醒詞，
  // 會導致 _respond() 被重複呼叫好幾次。這個旗標確保同一次聆聽，
  // 喚醒詞只會真正觸發一次，直到重新開始聆聽才會重置。
  bool _wakeWordTriggered = false;

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
    bool isZh = true,
  }) async {
    if (!_isAvailable) return;
    _isListening = true;
    _wakeWordTriggered = false;
    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        final hasWakeWord = wakeWords.any((w) => text.contains(w.toLowerCase()));
        if (hasWakeWord && !_wakeWordTriggered) {
          _wakeWordTriggered = true;
          onWakeWordDetected(text);
          _respond(locale: isZh ? 'zh-TW' : 'en-US');
        } else if (result.finalResult && !hasWakeWord) {
          onResult(text);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: isZh ? 'zh_TW' : 'en_US',
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    _wakeWordTriggered = false;
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
