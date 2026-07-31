import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
