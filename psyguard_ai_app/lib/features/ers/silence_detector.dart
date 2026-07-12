import 'package:shared_preferences/shared_preferences.dart';

class SilenceDetector {
  static const _lastActiveKey = 'silence_last_active';
  static const _silenceAlertedKey = 'silence_alerted_date';

  Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_lastActiveKey, today);
  }

  Future<int> getSilenceDays() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getString(_lastActiveKey);
    if (lastActive == null) return 0;
    final last = DateTime.parse(lastActive);
    return DateTime.now().difference(last).inDays;
  }

  Future<SilenceAlert?> checkSilence() async {
    final days = await getSilenceDays();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final alerted = prefs.getString(_silenceAlertedKey);
    if (alerted == today) return null;
    if (days >= 7) {
      await prefs.setString(_silenceAlertedKey, today);
      return SilenceAlert(days: days, level: SilenceLevel.critical);
    }
    if (days >= 3) {
      await prefs.setString(_silenceAlertedKey, today);
      return SilenceAlert(days: days, level: SilenceLevel.warning);
    }
    return null;
  }
}

enum SilenceLevel { warning, critical }

class SilenceAlert {
  final int days;
  final SilenceLevel level;
  const SilenceAlert({required this.days, required this.level});
  String get message => level == SilenceLevel.critical
      ? 'LUNA 已經 $days 天沒有見到你了。你還好嗎？🤍'
      : '已經 $days 天了，想跟 LUNA 說說話嗎？';
}
