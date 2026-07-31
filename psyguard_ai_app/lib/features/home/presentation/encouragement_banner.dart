import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_language.dart';
import '../../../core/security/local_settings_service.dart';

/// 主頁每日鼓勵語 — 依最近的 ERS 狀態（green/yellow/red）顯示不同的話。
/// 讀本機已存的 last_ers_level，不呼叫 AI，零成本、離線可用。
class EncouragementBanner extends ConsumerStatefulWidget {
  const EncouragementBanner({super.key});

  @override
  ConsumerState<EncouragementBanner> createState() =>
      _EncouragementBannerState();
}

class _EncouragementBannerState extends ConsumerState<EncouragementBanner> {
  String _level = 'green';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lv = prefs.getString('last_ers_level') ?? 'green';
    if (mounted) {
      setState(() {
        _level = lv;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final zh = ref.watch(appLanguageControllerProvider) == AppLanguage.zhTw;
    final day = DateTime.now().day;

    Color bg;
    Color fg;
    IconData icon;
    List<String> msgsZh;
    List<String> msgsEn;

    switch (_level) {
      case 'red':
        bg = const Color(0xFFFDECEC);
        fg = const Color(0xFFC0453F);
        icon = Icons.favorite_rounded;
        msgsZh = [
          '這陣子真的辛苦了。你不需要一個人扛，需要時記得找信任的人聊聊 🫂',
          '看得出你最近很累。先照顧好自己，慢一點沒關係 🫂',
        ];
        msgsEn = [
          "It's been really hard lately. You don't have to carry it alone \u2014 reach out to someone you trust \ud83e\udd7c",
          'You seem worn out lately. Care for yourself first \u2014 slow is okay \ud83e\udd7c',
        ];
        break;
      case 'yellow':
        bg = const Color(0xFFFDF6E3);
        fg = const Color(0xFFB07D18);
        icon = Icons.wb_sunny_rounded;
        msgsZh = [
          '最近好像有點起伏，慢慢來就好，我一直在 💙',
          '有點小波動很正常，一步一步來就好 💙',
        ];
        msgsEn = [
          "A few ups and downs lately \u2014 take it slow, I'm here \ud83d\udc99",
          'Small waves are normal \u2014 one step at a time \ud83d\udc99',
        ];
        break;
      default:
        bg = const Color(0xFFE6F7F6);
        fg = const Color(0xFF0A8F8C);
        icon = Icons.auto_awesome_rounded;
        msgsZh = [
          '你最近狀態很穩，繼續保持這份對自己的溫柔 ✨',
          '最近的你很平穩，為自己驕傲一下吧 ✨',
        ];
        msgsEn = [
          "You've been steady lately \u2014 keep being kind to yourself \u2728",
          "You've been in a good place \u2014 be proud of that \u2728",
        ];
    }

    final msg = zh ? msgsZh[day % msgsZh.length] : msgsEn[day % msgsEn.length];

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                  color: fg, fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
