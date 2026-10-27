// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import '../l10n/l10n.dart';

// shown when boot() throws. the fault is usually local, so the tor splash
// would point at the wrong thing.
class BootFailedScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const BootFailedScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.bootFailedKryfoCouldNotStart,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 22, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.bootFailedThisIsAFault,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.4, letterSpacing: 0),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.separator),
                ),
                child: SelectableText(
                  error,
                  style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: error)),
                    child: Text(
                      l10n.commonCopy,
                      style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentOn,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UmbraRadius.radius3xl),
                      ),
                    ),
                    child: Text(
                      l10n.commonTryAgain,
                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.accentOn, height: 1.5, letterSpacing: 0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
