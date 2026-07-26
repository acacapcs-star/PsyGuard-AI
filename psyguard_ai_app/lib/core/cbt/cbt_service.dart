// ═══════════════════════════════════════════════════════════
// PsyGuard AI / lii - CBT 思考教練 🧠💭
//
// 認知行為療法（CBT）核心：辨識「認知扭曲」，引導重構。
// 人的痛苦常來自扭曲的想法，不是事情本身。這個服務用 AI 辨識
// 使用者話語中的認知扭曲，溫柔指出，並引導換個角度想。
//
// 6 種常見認知扭曲（青少年最常見）：
//   all-or-nothing        非黑即白
//   overgeneralization    過度類化
//   jumping-to-conclusions 妄下結論
//   emotional-reasoning   情緒化推理
//   catastrophizing       災難化
//   labeling              貼標籤
//
// 英文優先（demo 用），中英雙語。AI 沒設定時有 fallback 保底。
// ═══════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/ai_api_client.dart';
import '../network/ai_chat_repository.dart';
import '../network/app_config_controller.dart';
import '../config/app_config.dart';

/// 認知扭曲類型
enum Distortion {
  allOrNothing,
  overgeneralization,
  jumpingToConclusions,
  emotionalReasoning,
  catastrophizing,
  labeling,
  none; // 沒偵測到明顯扭曲

  String labelFor(bool isZh) {
    switch (this) {
      case Distortion.allOrNothing:
        return isZh ? '非黑即白' : 'All-or-nothing thinking';
      case Distortion.overgeneralization:
        return isZh ? '過度類化' : 'Overgeneralization';
      case Distortion.jumpingToConclusions:
        return isZh ? '妄下結論' : 'Jumping to conclusions';
      case Distortion.emotionalReasoning:
        return isZh ? '情緒化推理' : 'Emotional reasoning';
      case Distortion.catastrophizing:
        return isZh ? '災難化' : 'Catastrophizing';
      case Distortion.labeling:
        return isZh ? '貼標籤' : 'Labeling';
      case Distortion.none:
        return isZh ? '沒有明顯的思考陷阱' : 'No clear thinking trap';
    }
  }

  static Distortion fromKey(String key) {
    switch (key.toLowerCase().replaceAll('_', '-').trim()) {
      case 'all-or-nothing':
      case 'allornothing':
        return Distortion.allOrNothing;
      case 'overgeneralization':
        return Distortion.overgeneralization;
      case 'jumping-to-conclusions':
      case 'jumpingtoconclusions':
        return Distortion.jumpingToConclusions;
      case 'emotional-reasoning':
      case 'emotionalreasoning':
        return Distortion.emotionalReasoning;
      case 'catastrophizing':
        return Distortion.catastrophizing;
      case 'labeling':
        return Distortion.labeling;
      default:
        return Distortion.none;
    }
  }
}

/// CBT 分析結果
class CbtAnalysis {
  final Distortion distortion;
  final String gentleReframe; // 溫柔指出 + 重構引導
  final List<String> questions; // 蘇格拉底式問句（引導自己想）

  const CbtAnalysis({
    required this.distortion,
    required this.gentleReframe,
    required this.questions,
  });
}

class CbtService {
  CbtService(this._client, this._config);

  final AiApiClient _client;
  final AppConfig _config;

  static const String _systemMarker = 'CBT_THOUGHT_COACH';

  /// 分析使用者的想法，辨識認知扭曲並給引導
  Future<CbtAnalysis> analyzeThought({
    required String userText,
    required bool isZh,
  }) async {
    // AI 沒設定 -> 用 fallback（demo 保底）
    if (!_config.isConfigured) {
      return _fallback(userText, isZh);
    }

    try {
      final lang = isZh ? 'Traditional Chinese' : 'English';
      final system =
          '$_systemMarker\n'
          'You are a warm, supportive CBT (Cognitive Behavioral Therapy) coach '
          'for teenagers. Analyze the user\'s statement and identify ONE cognitive '
          'distortion from this list: all-or-nothing, overgeneralization, '
          'jumping-to-conclusions, emotional-reasoning, catastrophizing, labeling. '
          'If none clearly applies, use "none".\n'
          'Respond ONLY with a JSON object, no markdown, in this exact shape:\n'
          '{"distortion":"<key>","reframe":"<one warm sentence gently naming the '
          'pattern and offering a kinder view>","questions":["<socratic q1>","<q2>"]}\n'
          'Write reframe and questions in $lang. Keep them short, kind, teen-friendly. '
          'Never diagnose. Never mention self-harm methods.';

      final content = await _client.createChatCompletion(
        model: _config.model,
        messages: [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': userText},
        ],
      );

      return _parse(content, isZh, userText);
    } catch (_) {
      return _fallback(userText, isZh);
    }
  }

  CbtAnalysis _parse(String raw, bool isZh, String userText) {
    try {
      // 去掉可能的 markdown fence
      var s = raw.trim();
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start >= 0 && end > start) {
        s = s.substring(start, end + 1);
      }
      final map = jsonDecode(s) as Map<String, dynamic>;
      final dist = Distortion.fromKey((map['distortion'] ?? 'none').toString());
      final reframe = (map['reframe'] ?? '').toString().trim();
      final qs = (map['questions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (reframe.isEmpty) return _fallback(userText, isZh);
      return CbtAnalysis(
        distortion: dist,
        gentleReframe: reframe,
        questions: qs.isEmpty ? _defaultQuestions(dist, isZh) : qs,
      );
    } catch (_) {
      return _fallback(userText, isZh);
    }
  }

  /// AI 沒設定或失敗時的 fallback：關鍵字粗略辨識 + 預設引導
  CbtAnalysis _fallback(String userText, bool isZh) {
    final t = userText.toLowerCase();
    Distortion d = Distortion.none;

    // 粗略關鍵字（中英）
    if (RegExp(r'never|always|everything|nothing|從來|永遠|всё|都不|全部').hasMatch(t) ||
        t.contains('都')) {
      d = Distortion.overgeneralization;
    }
    if (RegExp(r'useless|failure|loser|stupid|worthless|沒用|失敗|魯蛇|廢').hasMatch(t)) {
      d = Distortion.labeling;
    }
    if (RegExp(r'disaster|ruined|terrible|end of|完蛋|毀了|糟透|世界末日').hasMatch(t)) {
      d = Distortion.catastrophizing;
    }
    if (RegExp(r'i feel.*so i|because i feel|覺得.*所以').hasMatch(t)) {
      d = Distortion.emotionalReasoning;
    }

    return CbtAnalysis(
      distortion: d,
      gentleReframe: _defaultReframe(d, isZh),
      questions: _defaultQuestions(d, isZh),
    );
  }

  String _defaultReframe(Distortion d, bool isZh) {
    switch (d) {
      case Distortion.labeling:
        return isZh
            ? '我聽到你用一個很重的詞形容自己。一次的結果，不能定義整個你 💙'
            : 'I hear you putting a heavy label on yourself. One outcome doesn\'t define all of who you are 💙';
      case Distortion.catastrophizing:
        return isZh
            ? '現在感覺像天要塌了。我們一起看看，最可能發生的其實是什麼？'
            : 'It feels like everything is falling apart right now. Let\'s look together — what\'s the most likely outcome, really?';
      case Distortion.overgeneralization:
        return isZh
            ? '「總是」「從來」這些字，常常比事實更重。這次之外，有沒有不一樣的時候？'
            : 'Words like "always" and "never" often weigh more than the facts. Besides this time, was there ever a moment that went differently?';
      case Distortion.emotionalReasoning:
        return isZh
            ? '感覺很真實，但感覺不等於事實。你覺得糟，不代表你就是糟的 💙'
            : 'The feeling is real — but a feeling isn\'t a fact. Feeling bad doesn\'t mean you are bad 💙';
      case Distortion.allOrNothing:
        return isZh
            ? '好像只有「全好」或「全壞」兩種。中間其實有很多灰色地帶，對吧？'
            : 'It sounds like only "all good" or "all bad" fit. There\'s usually a lot of grey in between, right?';
      case Distortion.jumpingToConclusions:
        return isZh
            ? '我們好像先跳到了結論。有沒有其他可能的解釋呢？'
            : 'We may have jumped to a conclusion. Could there be another explanation?';
      case Distortion.none:
        return isZh
            ? '謝謝你願意說出來。我們一起慢慢整理這個想法，好嗎？'
            : 'Thank you for sharing that. Let\'s gently sort through this thought together, okay?';
    }
  }

  List<String> _defaultQuestions(Distortion d, bool isZh) {
    if (isZh) {
      return [
        '這個想法，有什麼證據支持？又有什麼證據反對？',
        '如果是好朋友這樣說自己，你會怎麼回應他？',
      ];
    }
    return [
      'What evidence supports this thought? What evidence goes against it?',
      'If a close friend said this about themselves, what would you tell them?',
    ];
  }
}

final cbtServiceProvider = Provider<CbtService>((ref) {
  return CbtService(
    ref.watch(aiApiClientProvider),
    ref.watch(appConfigProvider),
  );
});
