// ═══════════════════════════════════════════════════════════
// 潮聲
//
// 用 Dart 即時合成，不用音檔 —— 零素材、零授權問題，
// 而且不用打包好幾 MB 的 mp3 進 app。
//
// 三層疊起來才像「拍打」而不是白噪音在變大變小：
//   swell 低頻湧起 → crash 在吸氣頂點碎掉 → foam 嘶嘶退去
//
// 音量跟著呼吸走：吸氣時漲、吐氣時退。
// 預設關閉 —— 他可能在課堂上、公車上、或家人睡著的旁邊打開，
// 聲音會暴露他正在做這件事。
// ═══════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

class TideSound {
  static const int _rate = 22050;
  static const int _seconds = 12; // 一段夠長，循環時聽不出接縫

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _on = false;

  bool get isOn => _on;

  /// 產生一段 12 秒的潮聲。中間有三次完整的湧起與退去，
  /// 週期彼此不整除，所以循環播放時聽不出重複。
  Uint8List _buildWav() {
    final n = _rate * _seconds;
    final samples = Int16List(n);
    final rnd = math.Random(7); // 固定種子，每次啟動聽起來一樣

    // 粉紅噪音（比白噪音溫和，接近真實的水聲）
    var pink = 0.0;
    // 低通濾波器的狀態
    var lp = 0.0;
    // 高通（嘶聲）的狀態
    var hpPrev = 0.0, hpOut = 0.0;

    for (var i = 0; i < n; i++) {
      final t = i / _rate;

      // 三個不整除的週期疊起來 = 不規則但有節奏的浪
      final wave = 0.5 +
          0.30 * math.sin(2 * math.pi * t / 7.0) +
          0.14 * math.sin(2 * math.pi * t / 4.3 + 1.1) +
          0.06 * math.sin(2 * math.pi * t / 2.9 + 2.3);
      final env = wave.clamp(0.0, 1.0);

      final white = rnd.nextDouble() * 2 - 1;
      pink = (pink + 0.02 * white) / 1.02;

      // swell：低通，浪頭越高截止頻率越開
      final cut = 0.02 + 0.10 * env;
      lp += cut * (pink * 3.2 - lp);
      final swell = lp * (0.25 + 0.75 * env);

      // foam：高通的嘶聲，只在浪頭最高的那一段出現
      hpOut = 0.92 * (hpOut + pink - hpPrev);
      hpPrev = pink;
      final crest = ((env - 0.72) / 0.28).clamp(0.0, 1.0);
      final foam = hpOut * 0.35 * crest * crest;

      var v = (swell + foam) * 0.55;
      // 頭尾淡入淡出，接回開頭時不會有一聲「噗」
      const fade = _rate; // 1 秒
      if (i < fade) v *= i / fade;
      if (i > n - fade) v *= (n - i) / fade;

      samples[i] = (v.clamp(-1.0, 1.0) * 32767).round();
    }

    return _wrapWav(samples);
  }

  /// 加上 44 bytes 的 WAV 檔頭
  Uint8List _wrapWav(Int16List samples) {
    final dataBytes = samples.lengthInBytes;
    final out = BytesBuilder();
    void str(String s) => out.add(s.codeUnits);
    void u32(int v) => out.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
    void u16(int v) => out.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

    str('RIFF');
    u32(36 + dataBytes);
    str('WAVE');
    str('fmt ');
    u32(16); // PCM
    u16(1); // 格式：PCM
    u16(1); // 單聲道
    u32(_rate);
    u32(_rate * 2); // byte rate
    u16(2); // block align
    u16(16); // bits per sample
    str('data');
    u32(dataBytes);
    out.add(samples.buffer.asUint8List());
    return out.toBytes();
  }

  Future<void> _prepare() async {
    if (_ready) return;
    await _player.setAudioSource(
      _WavSource(_buildWav()),
    );
    await _player.setLoopMode(LoopMode.one);
    _ready = true;
  }

  Future<void> enable() async {
    await _prepare();
    _on = true;
    await _player.play();
  }

  Future<void> disable() async {
    _on = false;
    await _player.pause();
  }

  /// 呼吸值 0..1。吸氣時漲、吐氣時退。
  /// [scale] 給 safety flow 用 —— 一個已經被淹沒的人不需要更多刺激。
  Future<void> update(double breath, {double scale = 1.0}) async {
    if (!_on) return;
    final v = (0.25 + 0.55 * breath) * scale;
    await _player.setVolume(v.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// 把記憶體裡的 bytes 當成音源餵給 just_audio
class _WavSource extends StreamAudioSource {
  final Uint8List _bytes;
  _WavSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
