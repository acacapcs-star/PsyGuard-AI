import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/local_settings_service.dart';
import '../../l10n/app_strings.dart';

class AppFrame extends ConsumerWidget {
  const AppFrame({
    super.key,
    required this.title,
    required this.child,
    required this.activeRoute,
    this.actions,
  });

  final String title;
  final Widget child;
  final String activeRoute;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = AppStrings.of(ref.watch(appLanguageControllerProvider));
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Lumi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ..._menuItems(context, copy),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  List<Widget> _menuItems(BuildContext context, AppStrings copy) {
    final items = [
      ('/home', copy.navHome),
      ('/chat', copy.navChat),
      ('/checkin', copy.navCheckin),
      ('/sleep', copy.navSleep),
      ('/trends', copy.navTrends),
      ('/tools', copy.navTools),
      ('/safety', copy.navSafety),
      ('/export', copy.navExport),
    ];

    return items.map((item) {
      final route = item.$1;
      return ListTile(
        selected: route == activeRoute,
        title: Text(item.$2),
        onTap: () {
          Navigator.of(context).pop();
          context.go(route);
        },
      );
    }).toList();
  }
}
