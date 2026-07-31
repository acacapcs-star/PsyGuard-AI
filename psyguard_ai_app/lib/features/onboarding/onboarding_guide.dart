// ═══════════════════════════════════════════════════════════
// lii - 開場引導（第一次打開 App，滑 4 張卡秒懂怎麼玩）
// 解決「新使用者不知道怎麼玩」。只跳一次，看過就記住。中英分開。
// ══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_strings.dart';
import '../../core/security/local_settings_service.dart';

const _kOnboardingKey = 'onboarding_v1_done';

Future<bool> onboardingDone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingKey) ?? false;
  } catch (_) {
    return true; // 出錯就當看l過，不擋使用者
  }
}

Future<void> _setDone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
  } catch (_) {}
}

Future<void> showOnboarding(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'onboarding',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, a1, a2) => Consumer(
      builder: (c, ref, _) {
        final zh =
            AppStrings.of(ref.watch(appLanguageControllerProvider)).isZhTw;
        return _OnboardingSheet(zh: zh);
      },
    ),
  );
}

class _Slide {
  final String emoji;
  final String titleZh;
  final String titleEn;
  final String bodyZh;
  final String bodyEn;
  const _Slide(
      this.emoji, this.titleZh, this.titleEn, this.bodyZh, this.bodyEn);
}

const List<_Slide> _slides = [
  _Slide(
    '🌙',
    'AI 陪你說話\n真人接住你',
    'Someone to talk to.\nSomeone to catch you.',
    '給台灣青少年的\n心理健康夥伴 🌙',
    'A mental-health companion\nbuilt for youth in Taiwan 🌙',
  ),
  _Slide(
    '💭',
    '記錄你的心情',
    'Track how you feel',
    '每天記一下心情和睡眠，\nlii 會陪你看見自己的變化。',
    'Log your mood and sleep each day,\nand watch your own patterns over time.',
  ),
  _Slide(
    '🚡',
    'Pacer Lift',
    'Pacer Lift',
    '把別人對你說過、想記得的話收成纜車；\n達成目標就在山上蓋一座觀景台 🏔️',
    'Save the kind words people said as cable cars,\nand build a deck for each goal you reach 🏔️',
  ),
  _Slide(
    '🎈',
    '換氛圍・養夥伴',
    'Moods & friends',
    '點上面的球球換季節氛圍\n（冬天企鵝會生蛋！），\n到 Luna 樂園跟水獺玩。',
    'Tap the floating ball to change the seasonal mood\n(penguins lay eggs in winter!),\nand play with your otter in Luna Park.',
  ),
];

class _OnboardingSheet extends StatefulWidget {
  final bool zh;
  const _OnboardingSheet({required this.zh});
  @override
  State<_OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<_OnboardingSheet> {
  final _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    _setDone();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final zh = widget.zh;
    final last = _page == _slides.length - 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: double.infinity,
            height: 470,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(zh ? '跳過' : 'Skip',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final s = _slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF7E8FE8),
                                    Color(0xFFB8A7E0)
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(s.emoji,
                                    style: const TextStyle(fontSize: 44)),
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(zh ? s.titleZh : s.titleEn,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2C3150))),
                            const SizedBox(height: 14),
                            Text(zh ? s.bodyZh : s.bodyEn,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.6,
                                    color: Colors.grey.shade700)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final on = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: on ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            on ? const Color(0xFF7E8FE8) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0ABFBC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (last) {
                          _finish();
                        } else {
                          _pc.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                        }
                      },
                      child: Text(
                          last
                              ? (zh ? '開始使用 🌙' : 'Get started 🌙')
                              : (zh ? '下一步' : 'Next'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
