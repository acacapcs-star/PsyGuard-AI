// ═══════════════════════════════════════════════════════════
// PsyGuard AI - 語音特徵擷取 🎤📊
//
// ERS 的「串流一：語言訊號」原本是從壓力滑桿推算出來的假數據，
// 等於壓力被重複計算兩次，三串流實際上只有兩個獨立訊號。
// 這個檔案把它換成真的。
//
//   語速      字數 ÷ 說話秒數 × 60
//   負面詞密度 命中的負面詞 ÷ 總詞數
//   停頓頻率   說話中間的空檔次數 ÷ 分鐘
//
// ⚠️ 限制要說清楚：
//   手機語音辨識的結果會受環境音、口音、網路延遲影響，
//   算出來的語速和停頓是「粗估」，不是實驗室等級的聲學分析。
//   它適合當作趨勢參考（今天比平常慢很多），
//   不適合當成單次的診斷依據。
// ═══════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 一次說話所擷取到的特徵
class SpeechMetrics {
  /// 字/分鐘（中文算字，英文算詞）
  final double speechRate;

  /// 0~1
  final double negativeWordRatio;

  /// 次/分鐘
  final double pauseFrequency;

  /// 這次說了多久（秒）
  final double durationSec;

  /// 什麼時候錄的
  final DateTime recordedAt;

  const SpeechMetrics({
    required this.speechRate,
    required this.negativeWordRatio,
    required this.pauseFrequency,
    required this.durationSec,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'rate': speechRate,
        'neg': negativeWordRatio,
        'pause': pauseFrequency,
        'dur': durationSec,
        'at': recordedAt.toIso8601String(),
      };

  static SpeechMetrics fromJson(Map<String, dynamic> j) => SpeechMetrics(
        speechRate: (j['rate'] as num).toDouble(),
        negativeWordRatio: (j['neg'] as num).toDouble(),
        pauseFrequency: (j['pause'] as num).toDouble(),
        durationSec: (j['dur'] as num).toDouble(),
        recordedAt: DateTime.parse(j['at'] as String),
      );
}

/// 負面詞表。中英各一份，跟 risk_engine 的高風險詞刻意分開 ——
/// 這裡要抓的是「情緒色彩」而不是「危機訊號」，門檻低很多。
const List<String> _negativeZh = [
  '累', '痛', '壓力', '焦慮', '害怕', '難過', '煩', '討厭',
  '孤單', '寂寞', '失望', '生氣', '委屈', '無助', '沒用',
  '糟', '爛', '不想', '不行', '不會', '沒辦法', '撐不住',
  '哭', '睡不著', '緊張', '擔心', '後悔', '對不起', '算了',
];

const List<String> _negativeEn = [
  'tired', 'exhausted', 'pain', 'hurt', 'stress', 'stressed',
  'anxious', 'anxiety', 'afraid', 'scared', 'sad', 'upset',
  'annoyed', 'hate', 'lonely', 'alone', 'disappointed', 'angry',
  'helpless', 'useless', 'awful', 'terrible', 'worst', 'cant',
  "can't", 'wont', "won't", 'never', 'sorry', 'regret',
  'worried', 'worry', 'nervous', 'crying', 'cry', 'insomnia',
];

/// 中間空檔超過這個長度才算一次停頓
const Duration _kPauseThreshold = Duration(milliseconds: 1200);

/// 太短的錄音算不出有意義的數字
const double _kMinDurationSec = 3.0;

/// 收集一次說話過程中的事件，結束時算出特徵。
///
/// 用法：
///   final c = SpeechMetricsCollector()..start();
///   // 每次辨識有更新就餵進去（包含中途的部分結果）
///   c.onEvent(recognizedText);
///   // 說完
///   await c.finish(finalText, isZh: true);
class SpeechMetricsCollector {
  DateTime? _startedAt;
  DateTime? _lastEventAt;
  int _lastLength = 0;
  int _pauseCount = 0;

  void start() {
    _startedAt = DateTime.now();
    _lastEventAt = _startedAt;
    _lastLength = 0;
    _pauseCount = 0;
  }

  /// 每次辨識結果更新時呼叫（部分結果也要）
  void onEvent(String text) {
    final now = DateTime.now();
    _startedAt ??= now;
    final last = _lastEventAt ?? now;

    // 字數沒增加、又隔了一段時間 -> 這中間是停頓
    if (text.length <= _lastLength && now.difference(last) >= _kPauseThreshold) {
      _pauseCount++;
    }

    if (text.length > _lastLength) _lastLength = text.length;
    _lastEventAt = now;
  }

  /// 說完之後算出特徵並存起來。
  /// 錄太短或沒內容會回傳 null，也不會覆蓋掉上一次的紀錄。
  Future<SpeechMetrics?> finish(String finalText, {required bool isZh}) async {
    final started = _startedAt;
    if (started == null) return null;

    final durationSec =
        DateTime.now().difference(started).inMilliseconds / 1000.0;
    if (durationSec < _kMinDurationSec) return null;
    if (finalText.trim().isEmpty) return null;

    final tokens = _tokenize(finalText, isZh);
    if (tokens.isEmpty) return null;

    final lowered = finalText.toLowerCase();
    final table = isZh ? _negativeZh : _negativeEn;
    var negHits = 0;
    for (final w in table) {
      if (lowered.contains(w)) negHits++;
    }

    final minutes = durationSec / 60.0;
    final metrics = SpeechMetrics(
      speechRate: (tokens.length / minutes).clamp(0.0, 600.0),
      negativeWordRatio: (negHits / tokens.length * 4).clamp(0.0, 1.0),
      pauseFrequency: (_pauseCount / minutes).clamp(0.0, 60.0),
      durationSec: durationSec,
      recordedAt: DateTime.now(),
    );

    await SpeechMetricsStore.save(metrics);
    return metrics;
  }

  /// 中文按字算，英文按詞算
  static List<String> _tokenize(String text, bool isZh) {
    if (isZh) {
      return text
          .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '')
          .split('')
          .where((c) => c.isNotEmpty)
          .toList();
    }
    return text
        .toLowerCase()
        .split(RegExp(r"[^a-z']+"))
        .where((w) => w.isNotEmpty)
        .toList();
  }
}

/// 存放最近一次的語音特徵，供 check-in 計算 ERS 時取用
class SpeechMetricsStore {
  static const _key = 'speech_metrics_latest';

  /// 超過這個時間就當作過期，不再用來算 ERS
  static const Duration maxAge = Duration(days: 7);

  static Future<void> save(SpeechMetrics m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(m.toJson()));
  }

  /// 拿最近一次的特徵。沒有或太舊就回 null，呼叫端要自己準備退路。
  static Future<SpeechMetrics?> latest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final m = SpeechMetrics.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(m.recordedAt) > maxAge) return null;
      return m;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
