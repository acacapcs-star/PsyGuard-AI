import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 8 種氛圍主題
enum MoodTheme {
  none,       // 無（預設，不顯示任何氛圍效果）
  christmas,  // 聖誕節
  newYear,    // 過年
  spring,     // 春
  summer,     // 夏
  autumn,     // 秋
  winter,     // 冬
  winterBreak, // 寒假
  summerBreak, // 暑假
}

extension MoodThemeLabel on MoodTheme {
  // 每種氛圍對應的底色，優先權高於深淺模式（選了氛圍就不看深淺模式的顏色）
  Color get backgroundColor {
    switch (this) {
      case MoodTheme.none:
        return const Color(0x00000000); // 透明，代表「不覆蓋，交給深淺模式決定」
      case MoodTheme.christmas:
        return const Color(0xFFFFFBF5); // 極淺米白底，聖誕氛圍
      case MoodTheme.newYear:
        return const Color(0xFFFFF3F3); // 極淺粉紅底，過年氛圍
      case MoodTheme.spring:
        return const Color(0xFFFCE4EC); // 粉嫩底，春天氛圍
      case MoodTheme.summer:
        return const Color(0xFFE0F7FA); // 明亮淺藍，夏天氛圍
      case MoodTheme.autumn:
        return const Color(0xFFFBE9E0); // 橘棕暖調，秋天氛圍
      case MoodTheme.winter:
        return const Color(0xFFE8F0F7); // 冷藍白，冬天氛圍
      case MoodTheme.winterBreak:
        return const Color(0xFFF3E9E0); // 暖米色，寒假氛圍（比冬天暖一點）
      case MoodTheme.summerBreak:
        return const Color(0xFFFFF3D6); // 活潑亮黃，暑假氛圍
    }
  }

  String labelZh() {
    switch (this) {
      case MoodTheme.none: return '無氛圍';
      case MoodTheme.christmas: return '🎄 聖誕節';
      case MoodTheme.newYear: return '🧧 過年';
      case MoodTheme.spring: return '🌸 春';
      case MoodTheme.summer: return '☀️ 夏';
      case MoodTheme.autumn: return '🍁 秋';
      case MoodTheme.winter: return '❄️ 冬';
      case MoodTheme.winterBreak: return '🧣 寒假';
      case MoodTheme.summerBreak: return '🏖️ 暑假';
    }
  }

  String labelEn() {
    switch (this) {
      case MoodTheme.none: return 'No mood';
      case MoodTheme.christmas: return '🎄 Christmas';
      case MoodTheme.newYear: return '🧧 New Year';
      case MoodTheme.spring: return '🌸 Spring';
      case MoodTheme.summer: return '☀️ Summer';
      case MoodTheme.autumn: return '🍁 Autumn';
      case MoodTheme.winter: return '❄️ Winter';
      case MoodTheme.winterBreak: return '🧣 Winter Break';
      case MoodTheme.summerBreak: return '🏖️ Summer Break';
    }
  }

  String get storageValue => name;

  static MoodTheme fromStorageValue(String? value) {
    return MoodTheme.values.firstWhere(
      (m) => m.name == value,
      orElse: () => MoodTheme.none,
    );
  }
}

class MoodThemeController extends StateNotifier<MoodTheme> {
  static const _key = 'mood_theme';

  MoodThemeController() : super(MoodTheme.none) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    state = MoodThemeLabel.fromStorageValue(stored);
  }

  Future<void> setMood(MoodTheme mood) async {
    state = mood;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mood.storageValue);
  }
}

final moodThemeProvider = StateNotifierProvider<MoodThemeController, MoodTheme>(
  (ref) => MoodThemeController(),
);
