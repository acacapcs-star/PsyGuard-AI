// 從任何地方掛一台纜車到 Pacer Lift。
// ⚠️ key 必須跟 bookmark_page.dart 的 _kBookmarksKey 一致。
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'breath_plan.dart';

class BookmarkQuickAdd {
  static const String _key = 'bookmarks_v2';

  static Future<void> add({
    required String quote,
    String author = 'Luna',
    int colorIndex = 0,
    int imageIndex = -1,
    int toneIndex = 0,
  }) async {
    if (quote.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    List<dynamic> list = [];
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        list = jsonDecode(raw) as List;
      } catch (_) {
        list = [];
      }
    }

    list.insert(0, <String, dynamic>{
      'quote': quote,
      'author': author,
      'colorIndex': colorIndex,
      'imageIndex': imageIndex,
      'frameIndex': 0,
      'darkY': 0.72,
      'darkRange': 0.35,
      'customImagePath': '',
      'tone': toneIndex,
    });

    await prefs.setString(_key, jsonEncode(list));
  }

  static const Map<BreathMood, List<List<String>>> _quotes = {
    BreathMood.anxious: [
      ['現在這一刻，沒有事情正在發生。你是安全的。', 'Luna'],
      ['心跳快不代表有危險，它只是跑得比你快一點。', '班導'],
      ['不用把整天想完，先想接下來十分鐘就好。', '班導'],
      ['你剛剛把呼吸放慢了。你做得到的事，比你以為的多。', 'Luna'],
    ],
    BreathMood.low: [
      ['你今天什麼都沒做也沒關係，你有在呼吸。', 'Luna'],
      ['不用馬上好起來。慢慢來，我等你。', 'Luna'],
      ['撐到現在的人是你，這件事不小。', '班導'],
      ['暗的時候不用假裝亮，我陪你待著就好。', 'Luna'],
    ],
    BreathMood.calm: [
      ['這樣就很好，不用再多做什麼。', 'Luna'],
      ['你今天有好好照顧自己。', '班導'],
      ['安靜的時候，也值得被記下來。', 'Luna'],
      ['記得花時間呼吸。', '班導'],
    ],
  };

  static final math.Random _rng = math.Random();

  static Future<String> addFromBreath(BreathMood mood) async {
    final list = _quotes[mood]!;
    final pick = list[_rng.nextInt(list.length)];
    await add(quote: pick[0], author: pick[1]);
    return pick[0];
  }
}
