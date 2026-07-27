import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/local_settings_service.dart';
import '../core/theme/app_theme.dart';
import '../core/settings/font_scale_provider.dart';
import 'router.dart';

class LumiApp extends ConsumerWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final language = ref.watch(appLanguageControllerProvider);
    final fontScale = ref.watch(fontScaleProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: LumiTheme.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp.router(
        title: 'lii',
        debugShowCheckedModeBanner: false,
        theme: LumiTheme.lightTheme,
        routerConfig: router,
        // ⌨️ 全域點空白收鍵盤（修 CBT／筆記本／聊天等鍵盤關不掉）
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(fontScale)),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        ),
        locale: language.locale,
        supportedLocales: const [Locale('en'), Locale('zh', 'TW')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
