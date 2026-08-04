// 水晶收集：只能靠呼吸取得。
// 不是課金也不是隨機抽 —— 每一顆都對應一件他真的做過的事。
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/luna_orb.dart';

class CrystalRule {
  final GlassTone tone;
  final int sessions;
  final int streak;
  const CrystalRule(this.tone, {this.sessions = 0, this.streak = 0});

  String get requirement {
    if (sessions > 0) return '完成 $sessions 次呼吸';
    if (streak > 0) return '連續 $streak 天';
    return '一開始就有';
  }

  String get requirementEn {
    if (sessions > 0) return 'Complete $sessions sessions';
    if (streak > 0) return '$streak-day streak';
    return 'Yours from the start';
  }

  String requirementFor(bool zh) => zh ? requirement : requirementEn;
}

const List<CrystalRule> kCrystalRules = [
  CrystalRule(GlassTone.ice),
  CrystalRule(GlassTone.sea, sessions: 3),
  CrystalRule(GlassTone.amethyst, sessions: 7),
  CrystalRule(GlassTone.amber, sessions: 14),
  CrystalRule(GlassTone.moss, streak: 3),
  CrystalRule(GlassTone.dawn, streak: 7),
];

class CrystalStore {
  static const _kSessions = 'crystal_sessions';
  static const _kStreak = 'crystal_streak';
  static const _kLastDay = 'crystal_last_day';

  static int sessions = 0;
  static int streak = 0;
  static String lastDay = '';
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    sessions = p.getInt(_kSessions) ?? 0;
    streak = p.getInt(_kStreak) ?? 0;
    lastDay = p.getString(_kLastDay) ?? '';
    _loaded = true;
  }

  static String _day(DateTime n) => '${n.year}-${n.month}-${n.day}';

  static Future<List<GlassTone>> recordSession() async {
    await ensureLoaded();
    final before = unlocked().toSet();

    sessions += 1;
    final today = _day(DateTime.now());
    if (lastDay != today) {
      final y = _day(DateTime.now().subtract(const Duration(days: 1)));
      streak = (lastDay == y) ? streak + 1 : 1;
      lastDay = today;
    }

    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSessions, sessions);
    await p.setInt(_kStreak, streak);
    await p.setString(_kLastDay, lastDay);

    return unlocked().where((t) => !before.contains(t)).toList();
  }

  static bool isUnlocked(GlassTone t) {
    return true; // DEMO 全解鎖
    final r = kCrystalRules.firstWhere((e) => e.tone == t);
    if (r.sessions > 0) return sessions >= r.sessions;
    if (r.streak > 0) return streak >= r.streak;
    return true;
  }

  static List<GlassTone> unlocked() =>
      kCrystalRules.map((e) => e.tone).where(isUnlocked).toList();

  static String? nextHint({bool zh = true}) {
    for (final r in kCrystalRules) {
      if (isUnlocked(r.tone)) continue;
      if (r.sessions > 0) {
        return zh
            ? '再 ${r.sessions - sessions} 次呼吸 → ${r.tone.label}'
            : '${r.sessions - sessions} more to unlock ${r.tone.labelEn}';
      }
      return zh
          ? '連續 ${r.streak} 天 → ${r.tone.label}（現在 $streak 天）'
          : '${r.streak}-day streak for ${r.tone.labelEn} (now $streak)';
    }
    return null;
  }
}
