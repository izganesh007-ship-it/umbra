// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/stagger_in.dart';
import '../l10n/l10n.dart';

class WhyKryfoScreen extends StatelessWidget {
  const WhyKryfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          l10n.whyKryfoWhyKryfo,
          style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggerAll([
              Text(
                l10n.whyKryfoKryfoKreeFoGreek,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 22, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
              ),
              const SizedBox(height: 28),
              _principle(
                Icons.route_outlined,
                l10n.whyKryfoRoutedThroughTor,
                l10n.whyKryfoByDefaultEveryMessage,
              ),
              _principle(
                Icons.lock_outline,
                l10n.whyKryfoEndToEndEncrypted,
                l10n.whyKryfoMessagesAreSealedWith,
              ),
              _principle(
                Icons.cloud_off_outlined,
                l10n.whyKryfoNoServersHoldingYour,
                l10n.whyKryfoNoAccountNoPhone,
              ),
              _principle(
                Icons.visibility_off_outlined,
                l10n.whyKryfoNothingLeaks,
                l10n.whyKryfoNoReadReceiptsOr,
              ),
              _principle(
                Icons.verified_user_outlined,
                l10n.whyKryfoVerifyItIsReally,
                l10n.whyKryfoCompareASafetyNumber,
              ),
              const SizedBox(height: 32),
              Divider(
                color: colors.textTertiary.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.whyKryfoTheHonestPart,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 16, fontWeight: FontWeight.w400, color: colors.accent, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.whyKryfoKryfoIsPreAlpha,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

Widget _principle(IconData icon, String title, String body) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.accent),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.55, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
