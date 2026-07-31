// 頁面使用追蹤 — 記錄每頁被打開幾次 + 停留幾秒（全部存本機，不上傳）
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageTracker {
  static const _kOpens = 'usage_opens_v1';
  static const _kSecs = 'usage_secs_v1';
  static const _kDates = 'usage_dates_v1';
  static Map<String, int> opens = {};
  static Map<String, int> secs = {};
  static Set<String> dates = {};
  static bool _loaded = false;
  static String? _curName;
  static DateTime? _curStart;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    opens = _decode(p.getString(_kOpens));
    secs = _decode(p.getString(_kSecs));
    dates = (p.getStringList(_kDates) ?? <String>[]).toSet();
    _loaded = true;
  }

  static Map<String, int> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kOpens, jsonEncode(opens));
    await p.setString(_kSecs, jsonEncode(secs));
    await p.setStringList(_kDates, dates.toList());
  }

  static Future<void> _ensure() async {
    if (!_loaded) await load();
  }

  static void _flush() {
    if (_curName != null && _curStart != null) {
      final d = DateTime.now().difference(_curStart!).inSeconds;
      if (d > 0) secs[_curName!] = (secs[_curName!] ?? 0) + d;
    }
    _curName = null;
    _curStart = null;
  }

  static Future<void> enter(String name) async {
    await _ensure();
    _flush();
    final n = name.isEmpty ? 'unknown' : name;
    opens[n] = (opens[n] ?? 0) + 1;
    dates.add(_dayKey(DateTime.now()));
    _curName = n;
    _curStart = DateTime.now();
    await _save();
  }

  static Future<void> leave() async {
    await _ensure();
    _flush();
    await _save();
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<int> streakDays() async {
    await _ensure();
    int streak = 0;
    var d = DateTime.now();
    while (dates.contains(_dayKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static Future<double> consistency7() async {
    await _ensure();
    int c = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      if (dates.contains(_dayKey(now.subtract(Duration(days: i))))) c++;
    }
    return c / 7.0;
  }

  static Future<void> reset() async {
    opens = {};
    secs = {};
    dates = {};
    _curName = null;
    _curStart = null;
    _loaded = true;
    await _save();
  }
}

class UsageObserver extends NavigatorObserver {
  String _n(Route<dynamic>? r) => r?.settings.name ?? 'unknown';
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    UsageTracker.enter(_n(route));
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    UsageTracker.enter(_n(previousRoute));
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    UsageTracker.enter(_n(newRoute));
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
