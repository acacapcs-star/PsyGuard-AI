import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/security/local_settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_icon.dart';
import '../../../l10n/app_strings.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(ref.watch(appLanguageControllerProvider));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              // Logo / Brand
              const AppBrandIcon(
                size: 88,
                radius: 28,
                padding: 8,
                backgroundColor: Color(0xFFF6F8F5),
                borderColor: Color(0xFFE2E9E2),
              ),
              const SizedBox(height: 32),
              Text(
                strings.appName,
                style: GoogleFonts.nunitoSans(
                  color: LumiTheme.textPrimary,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.welcomeTagline,
                style: GoogleFonts.nunitoSans(
                  color: LumiTheme.textSecondary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 2),

              // Disclaimer (Minimal)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: LumiTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: LumiTheme.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          strings.disclaimerTitle,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: LumiTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.disclaimerBody,
                      style: GoogleFonts.nunitoSans(
                        color: LumiTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // CTA Button (Primary Color)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(localSettingsServiceProvider)
                        .setWelcomeSeen();
                    ref.invalidate(welcomeSeenProvider);
                    if (!context.mounted) return;
                    final hasConsent = await ref.read(
                      consentAcceptedProvider.future,
                    );
                    if (!context.mounted) return;
                    context.go(hasConsent ? '/home' : '/consent');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumiTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.nunitoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(strings.getStarted),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
