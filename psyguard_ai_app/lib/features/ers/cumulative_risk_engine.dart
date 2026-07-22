import 'package:shared_preferences/shared_preferences.dart';

class CumulativeRiskEngine {
  static const _redCountKey = 'cumulative_red_count';
  static const _greenStreakKey = 'green_streak_count';
  static const _lastUpdateKey = 'cumulative_last_update';

  static const List<String> riskColors = [
    '#E8F5E9', '#A5D6A7', '#80CBC4', '#4DB6AC',
    '#81D4FA', '#29B6F6', '#9FA8DA', '#7986CB',
    '#9C27B0', '#E91E63', '#F44336', '#4E342E',
  ];

  static const List<String> riskLabels = [
    '狀態良好', '待觀察', '輕微警示', '需留意',
    '請多關注自己', '建議找人聊聊', '持續關注中', '積極介入',
    '高度警戒', '緊急', '危機狀態', '需立即協助',
  ];

  static const List<String> riskLabelsEn = [
    'Doing okay', 'Worth watching', 'Mild alert', 'Needs attention',
    'Please look after yourself', 'Consider talking to someone', 'Ongoing concern', 'Active intervention',
    'High alert', 'Urgent', 'Crisis state', 'Needs immediate help',
  ];

  Future<int> getRedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_redCountKey) ?? 0;
  }

  Future<void> recordERS(String ersLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastUpdate = prefs.getString(_lastUpdateKey) ?? '';
    if (lastUpdate == today) return;
    await prefs.setString(_lastUpdateKey, today);
    int redCount = prefs.getInt(_redCountKey) ?? 0;
    int greenStreak = prefs.getInt(_greenStreakKey) ?? 0;
    if (ersLevel == 'red') {
      redCount++;
      greenStreak = 0;
    } else if (ersLevel == 'green') {
      greenStreak++;
      if (greenStreak >= 3) {
        redCount = redCount > 0 ? redCount - 1 : 0;
        greenStreak = 0;
      }
    } else {
      greenStreak = 0;
    }
    await prefs.setInt(_redCountKey, redCount);
    await prefs.setInt(_greenStreakKey, greenStreak);
  }

  String colorForCount(int count) {
    final index = count < 0 ? 0 : (count >= riskColors.length ? riskColors.length - 1 : count);
    return riskColors[index];
  }

  String labelForCount(int count, {bool isZh = true}) {
    final list = isZh ? riskLabels : riskLabelsEn;
    final index = count < 0 ? 0 : (count >= list.length ? list.length - 1 : count);
    return list[index];
  }

  bool shouldShowButtons(int count) => count >= 4;
}
