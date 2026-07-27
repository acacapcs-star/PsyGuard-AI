import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferenc
cd ~/Desktop/app使用介面/PsyGuard_Mine/psyguard_ai_app
mkdir -p lib/core/settings
cat > lib/core/settings/font_scale_provider.dart << 'DARTEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全 App 字體縮放（0.9 小 / 1.0 標準 / 1.15 大 / 1.3 特大），存在手機。
class FontScaleController extends StateNotifier<double> {
  FontScaleController() : super(1.0) {
    _load();
  }
  static const _key = 'font_scale';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(_key);
      if (v != null) state = v;
    } catch (_) {}
  }

  Future<void> set(double v) async {
    state = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, v);
    } catch (_) {}
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleController, double>(
  (ref) => FontScaleController(),
);
