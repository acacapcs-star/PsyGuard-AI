// 網頁版的存取代碼。
//
// ⚠️ 這是一道門，不是一把鎖。Flutter web build 是純前端，
//    key 就在 JS 檔裡，開 devtools 搜尋就找得到。
//    它擋得住：路人、被隨手轉貼的網址、搜尋引擎。
//    它擋不住：任何願意花五分鐘看原始碼的人。
//
// 要真正保護 key 只有一條路：後端代理，key 留在伺服器。
import 'package:shared_preferences/shared_preferences.dart';

class AccessGate {
  /// build 時用 --dart-define=ACCESS_CODE=xxx 傳入。
  /// 沒設定的話代表不上鎖（本機開發、手機版都走這條）。
  static const String _expected = String.fromEnvironment('ACCESS_CODE');

  static const _key = 'access_code_ok';
  static bool _unlocked = false;
  static bool _loaded = false;

  /// 沒設代碼 = 這個 build 不上鎖
  static bool get isGated => _expected.isNotEmpty;

  static bool get isUnlocked => !isGated || _unlocked;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _unlocked = p.getBool(_key) ?? false;
    _loaded = true;
  }

  /// 輸入代碼。對了就記住，下次開不用再輸入。
  static Future<bool> tryUnlock(String input) async {
    if (input.trim() != _expected) return false;
    _unlocked = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
    return true;
  }

  static Future<void> lock() async {
    _unlocked = false;
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
