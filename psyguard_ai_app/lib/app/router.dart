
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/security/local_settings_service.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/checkin/presentation/checkin_history_page.dart';
import '../features/checkin/presentation/checkin_page.dart';
import '../features/export/presentation/export_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/safety/presentation/safety_page.dart';
import '../features/sleep/presentation/sleep_history_page.dart';
import '../features/sleep/presentation/sleep_page.dart';
import '../features/tools_library/presentation/tools_page.dart';
import '../features/trends/presentation/trends_page.dart';
import '../features/trends/presentation/ai_report_page.dart';
import '../features/trends/presentation/ai_report_history_page.dart';
import '../features/tools_library/presentation/tool_history_page.dart';
import '../features/welcome/presentation/welcome_page.dart';
import '../features/welcome/presentation/consent_page.dart';
import '../features/voice/voice_wake_page.dart';
import '../features/penguin/penguin_park_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) async { return null; },
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/consent',
        name: 'consent',
        builder: (context, state) => const ConsentPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const HomePage()),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const ChatPage()),
      ),
      GoRoute(
        path: '/checkin',
        name: 'checkin',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const CheckinPage()),
        routes: [
          GoRoute(
            path: 'history',
            name: 'checkin_history',
            pageBuilder: (context, state) =>
                _buildPageWithSlide(context, state, const CheckinHistoryPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/sleep',
        name: 'sleep',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const SleepPage()),
        routes: [
          GoRoute(
            path: 'history',
            name: 'sleep_history',
            pageBuilder: (context, state) =>
                _buildPageWithSlide(context, state, const SleepHistoryPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/trends',
        name: 'trends',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const TrendsPage()),
      ),
      GoRoute(
        path: '/ai_report',
        name: 'ai_report',
        pageBuilder: (context, state) {
          final report = state.extra as String;
          return _buildPageWithSlide(
            context,
            state,
            AiReportPage(reportContent: report),
          );
        },
      ),
      GoRoute(
        path: '/ai_history',
        name: 'ai_history',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const AiReportHistoryPage()),
      ),
      GoRoute(
        path: '/tools',
        name: 'tools',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const ToolsPage()),
      ),
      GoRoute(
        path: '/tools/history',
        name: 'tool_history',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const ToolHistoryPage()),
      ),
      GoRoute(
        path: '/safety',
        name: 'safety',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const SafetyPage()),
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const ExportPage()),
      ),
      GoRoute(
        path: '/voice',
        name: 'voice',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const VoiceWakePage()),
      ),
      GoRoute(
        path: '/penguin',
        name: 'penguin',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const PenguinParkPage()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _buildPageWithSlide(context, state, const SettingsPage()),
      ),
    ],
  );
});

CustomTransitionPage _buildPageWithSlide(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Enter from Right
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
