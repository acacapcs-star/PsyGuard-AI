// ═══════════════════════════════════════════════════════════
// PsyGuard AI - 秘密日記的鎖 🔒
//
// 兩本日記：
//   📖 公開日記  直接打開就能寫（現有的 note_page）
//   🔒 秘密日記  要 Touch ID 或密碼才打得開
//
// 金鑰結構（同一把 AES 金鑰，三種方式取得）
//   1. App 密碼 → PBKDF2 推導 → 解開包住金鑰的信封
//   2. Touch ID → 從 Keychain 直接取出
//   3. 復原碼   → 密碼忘記時的救命繩
//
// ⚠️ 三條路全失效 = 秘密日記救不回來。這是設計本質。
//
// 想關掉加密只改 kEncryptContent = false（不建議，那樣硬碟裡是明文）
// ═══════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:shared_preferences/shared_preferences.dart';

/// 內容要不要真的加密。false = 只上鎖，硬碟裡是明文。
const bool kEncryptContent = true;

const _kWrappedByPassword = 'secret_key_by_password';
const _kWrappedByRecovery = 'secret_key_by_recovery';
const _kSaltPassword = 'secret_salt_password';
const _kSaltRecovery = 'secret_salt_recovery';
const _kSetupDone = 'secret_setup_done';
const _kKeyInKeychain = 'secret_diary_key';

/// 新設定的密碼用這個次數。Chrome 上是編譯成 JS 單執行緒跑的，
/// 12 萬次會凍住畫面好幾秒，3 萬次快 4 倍、體感順很多。
const int _pbkdf2Iterations = 30000;

/// 舊資料沒記次數，一律當作 12 萬（不然舊密碼會解不開）
const int _legacyIterations = 120000;

const _kIterations = 'secret_kdf_iters';
const _kAutoLockPolicy = 'secret_autolock_policy';

/// 什麼時候把金鑰從記憶體清掉
enum AutoLockPolicy {
  /// 一離開秘密頁面就鎖（最安全，但每次進去都要解）
  onLeave,

  /// 離開 2 分鐘後才鎖
  after2min,

  /// App 關掉才鎖（同一次使用只解一次）
  onAppClose,
}

extension AutoLockPolicyLabel on AutoLockPolicy {
  String labelFor(bool isZh) {
    switch (this) {
      case AutoLockPolicy.onLeave:
        return isZh ? '離開就鎖' : 'Lock on leaving';
      case AutoLockPolicy.after2min:
        return isZh ? '離開 2 分鐘後鎖' : 'Lock after 2 minutes';
      case AutoLockPolicy.onAppClose:
        return isZh ? '關掉 App 才鎖' : 'Lock when the app closes';
    }
  }

  String hintFor(bool isZh) {
    switch (this) {
      case AutoLockPolicy.onLeave:
        return isZh ? '最安全，但每次進去都要重新解鎖' : 'Safest, but you unlock every time';
      case AutoLockPolicy.after2min:
        return isZh ? '短暫離開不用重解，折衷選擇' : 'No re-unlock for short trips away';
      case AutoLockPolicy.onAppClose:
        return isZh ? '最方便，但別人拿到你開著的 App 就看得到' : 'Most convenient, least private';
    }
  }
}

enum LockFailure { wrongPassword, notSetUp, biometricUnavailable }

class LockException implements Exception {
  final LockFailure reason;
  const LockException(this.reason);
  @override
  String toString() => 'LockException($reason)';
}

class SecretDiaryLock {
  SecretDiaryLock._({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// 全 App 共用同一把鎖，這樣日記和日曆之間來回不用重複解鎖。
  /// 什麼時候鎖回去由 AutoLockPolicy 決定。
  static final SecretDiaryLock instance = SecretDiaryLock._();

  final FlutterSecureStorage _storage;

  /// 解鎖後暫存在記憶體
  Uint8List? _key;

  Timer? _pendingLock;
  AutoLockPolicy _policy = AutoLockPolicy.onLeave;
  bool _policyLoaded = false;

  bool get isUnlocked => _key != null;

  AutoLockPolicy get policy => _policy;

  void lock() {
    _pendingLock?.cancel();
    _pendingLock = null;
    _key = null;
  }

  // ══════════════════════════════════════════════════════
  // 自動上鎖
  // ══════════════════════════════════════════════════════

  Future<AutoLockPolicy> loadPolicy() async {
    if (_policyLoaded) return _policy;
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kAutoLockPolicy);
    _policy = AutoLockPolicy.values.firstWhere(
      (p) => p.name == name,
      orElse: () => AutoLockPolicy.onLeave,
    );
    _policyLoaded = true;
    return _policy;
  }

  Future<void> setPolicy(AutoLockPolicy p) async {
    _policy = p;
    _policyLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAutoLockPolicy, p.name);
    // 換成比較嚴格的政策時，馬上生效
    if (p == AutoLockPolicy.onLeave) _pendingLock?.cancel();
  }

  /// 進入秘密頁面時呼叫，取消還在倒數的上鎖
  void cancelPendingLock() {
    _pendingLock?.cancel();
    _pendingLock = null;
  }

  /// 離開秘密頁面時呼叫，依照政策決定要不要鎖
  void scheduleLock() {
    _pendingLock?.cancel();
    _pendingLock = null;
    switch (_policy) {
      case AutoLockPolicy.onLeave:
        lock();
        break;
      case AutoLockPolicy.after2min:
        _pendingLock = Timer(const Duration(minutes: 2), lock);
        break;
      case AutoLockPolicy.onAppClose:
        break; // 什麼都不做，App 結束時記憶體自然清掉
    }
  }

  // ══════════════════════════════════════════════════════
  // 設定
  // ══════════════════════════════════════════════════════

  Future<bool> isSetUp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSetupDone) ?? false;
  }

  /// 第一次設定秘密日記。回傳復原碼，請讓使用者抄下來。
  /// 設定完直接就是解鎖狀態。
  Future<String> setUp({required String password}) async {
    final prefs = await SharedPreferences.getInstance();

    final key = _randomBytes(32);
    final recoveryCode = _generateRecoveryCode();

    final saltP = _randomBytes(16);
    final saltR = _randomBytes(16);

    await prefs.setString(
        _kWrappedByPassword, _aesEncrypt(_deriveKey(password, saltP), key));
    await prefs.setString(_kWrappedByRecovery,
        _aesEncrypt(_deriveKey(_normalize(recoveryCode), saltR), key));
    await prefs.setString(_kSaltPassword, base64Encode(saltP));
    await prefs.setString(_kSaltRecovery, base64Encode(saltR));
    await prefs.setInt(_kIterations, _pbkdf2Iterations);
    await prefs.setInt(_kIterations, _pbkdf2Iterations);
    await prefs.setBool(_kSetupDone, true);
    await loadPolicy();

    await _storage.write(key: _kKeyInKeychain, value: base64Encode(key));

    _key = key;
    return recoveryCode;
  }

  /// 改密碼。必須先解鎖。
  Future<void> changePassword(String newPassword) async {
    final key = _key;
    if (key == null) throw const LockException(LockFailure.notSetUp);
    final prefs = await SharedPreferences.getInstance();
    final salt = _randomBytes(16);
    await prefs.setString(
        _kWrappedByPassword, _aesEncrypt(_deriveKey(newPassword, salt), key));
    await prefs.setString(_kSaltPassword, base64Encode(salt));
    await prefs.setInt(_kIterations, _pbkdf2Iterations);
  }

  // ══════════════════════════════════════════════════════
  // 解鎖（三選一）
  // ══════════════════════════════════════════════════════

  Future<void> unlockWithPassword(String password) =>
      _unwrap(password, _kSaltPassword, _kWrappedByPassword);

  Future<void> unlockWithRecoveryCode(String code) =>
      _unwrap(_normalize(code), _kSaltRecovery, _kWrappedByRecovery);

  /// ⚠️ 呼叫前，UI 必須先用 local_auth 驗證通過。
  ///    這個方法只負責從 Keychain 取金鑰，本身不做生物辨識。
  Future<void> unlockWithBiometricResult() async {
    final stored = await _storage.read(key: _kKeyInKeychain);
    if (stored == null) {
      throw const LockException(LockFailure.biometricUnavailable);
    }
    _key = base64Decode(stored);
    await loadPolicy();
  }

  Future<void> _unwrap(String secret, String saltKey, String wrappedKey) async {
    final prefs = await SharedPreferences.getInstance();
    final saltStr = prefs.getString(saltKey);
    final wrapped = prefs.getString(wrappedKey);
    if (saltStr == null || wrapped == null) {
      throw const LockException(LockFailure.notSetUp);
    }
    final iters = prefs.getInt(_kIterations) ?? _legacyIterations;
    try {
      _key =
          _aesDecrypt(_deriveKey(secret, base64Decode(saltStr), iters), wrapped);
    } catch (_) {
      // GCM 驗證失敗 = 密碼或復原碼錯誤
      throw const LockException(LockFailure.wrongPassword);
    }
    await loadPolicy();
  }

  // ══════════════════════════════════════════════════════
  // 內容加解密
  // ══════════════════════════════════════════════════════

  /// 秘密日記寫入前呼叫。必須先解鎖。
  String encryptContent(String plain) {
    if (!kEncryptContent) return plain;
    final key = _key;
    if (key == null) throw const LockException(LockFailure.notSetUp);
    return 'v1:${_aesEncrypt(key, Uint8List.fromList(utf8.encode(plain)))}';
  }

  /// 秘密日記讀出後呼叫。必須先解鎖。
  /// 遇到還沒加密的舊資料會原樣回傳，不會炸掉。
  String decryptContent(String stored) {
    if (!stored.startsWith('v1:')) return stored; // 明文或搬過來的舊資料
    final key = _key;
    if (key == null) throw const LockException(LockFailure.notSetUp);
    return utf8.decode(_aesDecrypt(key, stored.substring(3)));
  }

  // ══════════════════════════════════════════════════════
  // 自我測試 —— 接上真實日記前先跑
  // ══════════════════════════════════════════════════════

  /// ⚠️ 會覆蓋現有金鑰，只能在還沒存過秘密日記時跑！
  static Future<Map<String, bool>> selfTest() async {
    final r = <String, bool>{};
    final lock = SecretDiaryLock.instance;
    const sample = '秘密日記 secret entry 🔒 中英混合';

    try {
      final recovery = await lock.setUp(password: 'test-pw-1234');
      r['設定金鑰'] = true;
      r['設定完是解鎖狀態'] = lock.isUnlocked;

      final blob = lock.encryptContent(sample);
      r['加密後不等於原文'] = blob != sample;
      r['密文不含原文'] = !blob.contains('秘密日記');
      r['解回來一樣'] = lock.decryptContent(blob) == sample;

      lock.lock();
      r['鎖上後 isUnlocked=false'] = !lock.isUnlocked;
      try {
        lock.decryptContent(blob);
        r['鎖上時讀不到'] = false;
      } catch (_) {
        r['鎖上時讀不到'] = true;
      }

      await lock.unlockWithPassword('test-pw-1234');
      r['密碼解鎖'] = lock.decryptContent(blob) == sample;

      lock.lock();
      try {
        await lock.unlockWithPassword('wrong');
        r['錯誤密碼被擋'] = false;
      } on LockException catch (e) {
        r['錯誤密碼被擋'] = e.reason == LockFailure.wrongPassword;
      }

      lock.lock();
      await lock.unlockWithRecoveryCode(recovery);
      r['復原碼解鎖'] = lock.decryptContent(blob) == sample;

      lock.lock();
      await lock.unlockWithBiometricResult();
      r['Keychain 解鎖'] = lock.decryptContent(blob) == sample;

      // 復原碼加空白、小寫也要能用
      lock.lock();
      await lock.unlockWithRecoveryCode(recovery.toLowerCase() + '  ');
      r['復原碼容錯（大小寫空白）'] = lock.isUnlocked;

      // 上鎖政策
      await lock.setPolicy(AutoLockPolicy.session);
      lock.onLeaveSecretArea();
      r['session 模式離開不鎖'] = lock.isStillUnlocked;

      await lock.setPolicy(AutoLockPolicy.immediate);
      lock.onLeaveSecretArea();
      r['immediate 模式離開就鎖'] = !lock.isStillUnlocked;
    } catch (e) {
      r['發生例外：$e'] = false;
    }

    return r;
  }

  // ══════════════════════════════════════════════════════
  // 內部工具
  // ══════════════════════════════════════════════════════

  static final Random _rng = Random.secure();

  static Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));

  /// 24 碼，每 4 碼一組，去掉容易看錯的 I O 0 1
  static String _generateRecoveryCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buf = StringBuffer();
    for (var i = 0; i < 24; i++) {
      if (i > 0 && i % 4 == 0) buf.write('-');
      buf.write(alphabet[_rng.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }

  static String _normalize(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[^A-Z2-9]'), '');

  static Uint8List _deriveKey(String secret, Uint8List salt, [int? iterations]) {
    final d = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, iterations ?? _pbkdf2Iterations, 32));
    return d.process(Uint8List.fromList(utf8.encode(secret)));
  }

  /// 格式：base64(iv):base64(密文含驗證碼)
  static String _aesEncrypt(Uint8List key, Uint8List plain) {
    final iv = enc.IV(_randomBytes(12));
    final e = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
    return '${base64Encode(iv.bytes)}:${e.encryptBytes(plain, iv: iv).base64}';
  }

  static Uint8List _aesDecrypt(Uint8List key, String payload) {
    final parts = payload.split(':');
    if (parts.length != 2) throw const FormatException('密文格式錯誤');
    final iv = enc.IV(base64Decode(parts[0]));
    final e = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
    return Uint8List.fromList(
      e.decryptBytes(enc.Encrypted.fromBase64(parts[1]), iv: iv),
    );
  }
}
