// ═══════════════════════════════════════════════════════════
// PsyGuard AI - 年齡族群與研究基準線 📊
//
// 提供兩件事：
//   1. 使用者的年齡層（存 SharedPreferences）
//   2. 對比基準線：
//        個人 -> 由呼叫端傳入自己的歷史平均
//        團體 -> 這裡的研究常模（依年齡層不同）
//
// ⚠️ 團體基準線目前是「研究常模估計值」，不是真實使用者資料。
//    UI 上一定要標注「基於研究常模」。
//
// 🔌 後端接口已預留：GroupNorms.fetch() 現在回傳本地常模，
//    未來要接匿名資料庫時，只要把這個函式改成打 API 即可，
//    呼叫端完全不用動。
// ═══════════════════════════════════════════════════════════

import 'package:shared_preferences/shared_preferences.dart';

/// 年齡層。心理常模通常這樣分。
enum AgeBand {
  under13,
  age13to15,
  age16to18,
  over18;

  String labelFor(bool isZh) {
    switch (this) {
      case AgeBand.under13:
        return isZh ? '12 歲以下' : 'Under 13';
      case AgeBand.age13to15:
        return isZh ? '13–15 歲' : 'Age 13–15';
      case AgeBand.age16to18:
        return isZh ? '16–18 歲' : 'Age 16–18';
      case AgeBand.over18:
        return isZh ? '18 歲以上' : 'Over 18';
    }
  }
}

const String _kAgeBandKey = 'user_age_band';

class AgeBandStore {
  static Future<AgeBand?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kAgeBandKey);
    if (name == null) return null;
    for (final b in AgeBand.values) {
      if (b.name == name) return b;
    }
    return null;
  }

  static Future<void> set(AgeBand band) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAgeBandKey, band.name);
  }

  static Future<bool> isSet() async => (await get()) != null;
}

/// 一組三個指標的基準值（同齡人的典型水準）
class GroupNorm {
  final double mood; // 0-100
  final double sleepHours; // 0-12
  final double riskScore; // 0-100，越低越好
  final int count; // 真實匿名樣本數（本地估計值為 0）

  const GroupNorm({
    required this.mood,
    required this.sleepHours,
    required this.riskScore,
    this.count = 0,
  });

  factory GroupNorm.fromJson(Map<String, dynamic> j) => GroupNorm(
        mood: (j['mood'] as num).toDouble(),
        sleepHours: (j['sleepHours'] as num).toDouble(),
        riskScore: (j['riskScore'] as num).toDouble(),
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

/// 研究常模。
///
/// 數值依據公開的青少年心理健康研究「量級」設定（例如青少年
/// 平均睡眠不足、年紀越大壓力越高的普遍趨勢），作為相對參考，
/// 不代表任何特定個人或真實使用者資料。
class GroupNorms {
  static const Map<AgeBand, GroupNorm> _local = {
    AgeBand.under13: GroupNorm(mood: 72, sleepHours: 9.0, riskScore: 30),
    AgeBand.age13to15: GroupNorm(mood: 66, sleepHours: 7.5, riskScore: 40),
    AgeBand.age16to18: GroupNorm(mood: 61, sleepHours: 6.8, riskScore: 47),
    AgeBand.over18: GroupNorm(mood: 64, sleepHours: 7.0, riskScore: 44),
  };

  /// 🔌 後端接口。現在回傳本地常模，未來改成打 API：
  ///
  ///   final res = await http.get(Uri.parse('$base/norms/${band.name}'));
  ///   return GroupNorm.fromJson(jsonDecode(res.body));
  ///
  /// 呼叫端已經是 await，所以之後換掉不影響任何其他程式碼。
  static Future<GroupNorm> fetch(AgeBand band) async {
    return _local[band] ?? _local[AgeBand.age16to18]!;
  }

  /// 顯示同齡比較（peers）的最低樣本數。
  /// 低於這個數字就不顯示 —— 同時顧到統計效度與隱私：
  /// 人數太少的平均沒有意義，也可能被反推出是誰。
  static const int minSampleSize = 15;

  /// 目前這組常模是否有足夠的真實同齡樣本可以顯示。
  static bool hasEnoughSample(GroupNorm norm) => norm.count >= minSampleSize;

  /// 後端聚合：把某年齡層「所有匿名使用者」的數值加總後取平均（total / n）。
  /// 這一定要在伺服器端做（本機看不到其他人的資料，不能自己湊人數）。
  /// 不足 minSampleSize 人時回傳 null，代表暫時不顯示 peers。
  static GroupNorm? aggregate(List<GroupNorm> samples) {
    final n = samples.length;
    if (n < minSampleSize) return null;
    double mood = 0, sleep = 0, risk = 0;
    for (final s in samples) {
      mood += s.mood;
      sleep += s.sleepHours;
      risk += s.riskScore;
    }
    return GroupNorm(
      mood: mood / n,
      sleepHours: sleep / n,
      riskScore: risk / n,
      count: n,
    );
  }
}
