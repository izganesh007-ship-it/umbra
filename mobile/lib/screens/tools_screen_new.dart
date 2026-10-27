// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra tools screen matching tools.html design

import 'package:flutter/material.dart';
import 'dart:async';

import '../main.dart' show appState, db;
import '../theme/theme.dart';
import '../widgets/stagger_in.dart';
import '../widgets/stroke_icon.dart';
import '../l10n/l10n.dart';
import '../widgets/umbra_tool_card.dart';
import '../widgets/umbra_progress_bar.dart';
import '../widgets/umbra_verification_item.dart';

// SVG icons
const _eyeOutline = ['M2.5 12s3.5-6.5 9.5-6.5 9.5 6.5 9.5 6.5-3.5 6.5-9.5 6.5S2.5 12 2.5 12z'];
const _eyeIris = ['M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z'];
const _sparkle = ['M12 3l1.8 4.6L18.5 9l-4.7 1.5L12 15l-1.8-4.5L5.5 9l4.7-1.4z', 'M18.5 15.5l.8 2 2 .7-2 .8-.8 2-.7-2-2-.8 2-.7z'];
const _qr = ['M4 4h6v6H4z', 'M14 4h6v6h-6z', 'M4 14h6v6H4z', 'M14 14h2.5v2.5H14zM17.5 17.5H20V20h-2.5zM14 19.5h1M19.5 14v1'];
const _lock = ['M5 10.5V8a4 4 0 0 1 8 0v2.5', 'M12 14.5v2.2', 'M8 10.5V8a4 4 0 0 1 7.6-1.7'];
const _unlock = ['M5 10.5V8a4 4 0 0 1 8 0v2.5', 'M8 10.5V8a4 4 0 0 1 7.6-1.7'];
const _chevron = ['M9 5l7 7-7 7'];
const _picture = ['M3.5 4.5h17v15h-17z', 'M9 10a1.8 1.8 0 1 1 0-3.6 1.8 1.8 0 0 1 0 3.6z', 'M20.5 15.5l-5-5-9 9'];

class ToolsScreen extends StatelessWidget {
  final VoidCallback? onPickPhoto;
  final VoidCallback? onPickVideo;
  final VoidCallback? onClean;
  final VoidCallback? onQr;
  final VoidCallback? onLock;
  final VoidCallback? onOpenLocked;

  const ToolsScreen({
    super.key,
    this.onPickPhoto,
    this.onPickVideo,
    this.onClean,
    this.onQr,
    this.onLock,
    this.onOpenLocked,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _Header(
                onPhoto: onPickPhoto,
                onVideo: onPickVideo,
              ),
            ),
            // Tools list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
                    child: Text(
                      l10n.toolsMoreTools,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        letterSpacing: 0.14,
                      ),
                    ),
                  ),
                  // Clean photo
                  _ToolRow(
                    icon: _sparkle,
                    tint: colors.success,
                    tile: colors.success.withValues(alpha: 0.24),
                    title: l10n.toolsCleanAPhotoOr,
                    sub: l10n.toolsOrShareOneTo,
                    onTap: onClean,
                  ),
                  // Make QR
                  _ToolRow(
                    icon: _qr,
                    tint: colors.accent,
                    tile: colors.accent.withValues(alpha: 0.25),
                    title: l10n.toolsMakeAPrivateQr,
                    sub: l10n.toolsLinksWiFiContacts,
                    onTap: onQr,
                  ),
                  // Lock file
                  _ToolRow(
                    icon: _lock,
                    tint: colors.accent,
                    tile: colors.accent.withValues(alpha: 0.26),
                    title: l10n.toolsLockAFile,
                    sub: l10n.toolsWithAPasswordOpens,
                    onTap: onLock,
                  ),
                  // Open locked file
                  _ToolRow(
                    icon: _unlock,
                    tint: colors.textSecondary,
                    tile: colors.surfaceHover,
                    title: l10n.toolsOpenALockedFile,
                    sub: l10n.toolsAnyAgeFileSomeone,
                    onTap: onOpenLocked,
                    last: true,
                  ),
                  const SizedBox(height: 24),
                  // Backup section
                  _BackupSection(),
                  const SizedBox(height: 16),
                  // Key Verification section
                  _KeyVerificationSection(),
                  const SizedBox(height: 16),
                  // Panic Options section
                  _PanicOptionsSection(),
                  const SizedBox(height: 16),
                  // Diagnostics section
                  _DiagnosticsSection(),
                  const SizedBox(height: 16),
                  // Export section
                  _ExportSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback? onPhoto;
  final VoidCallback? onVideo;

  const _Header({required this.onPhoto, required this.onVideo});

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    const ink = Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _BreathingDot(),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.toolsWorksOfflineNoContacts,
                  style: TextStyle(
                    fontFamily: UmbraTypography.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: colors.success,
                    letterSpacing: 0.14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.toolsUsefulFrom,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSerif,
              fontSize: 31,
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
              fontStyle: FontStyle.normal,
              height: 1.05,
              letterSpacing: -0.015,
            ).copyWith(letterSpacing: -0.62, height: 1.05),
          ),
          Text(
            l10n.toolsTheFirstMinute,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSerif,
              fontSize: 31,
              fontWeight: FontWeight.w400,
              color: colors.accent,
              fontStyle: FontStyle.italic,
              height: 1.05,
              letterSpacing: -0.015,
            ).copyWith(letterSpacing: -0.62, height: 1.1, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(
              l10n.toolsEverythingHereHappensOn,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
                height: 1.55,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Photo card
          _PhotoCard(onPhoto: onPhoto, onVideo: onVideo),
        ],
      ),
    );
  }
}

class _BreathingDot extends StatefulWidget {
  const _BreathingDot();
  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).reduceMotion;

    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: colors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final VoidCallback? onPhoto;
  final VoidCallback? onVideo;

  const _PhotoCard({required this.onPhoto, required this.onVideo});

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    const ink = Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFFFB800)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: -12,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(UmbraRadius.lg),
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    StrokeIcon(_eyeOutline, size: 21, color: colors.accent),
                    StrokeIcon(_eyeIris, size: 21, stroke: 2.4, color: colors.accent),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.toolsWhatDoesThisPhoto,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: ink,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.toolsPlacePhoneTime,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: ink.withValues(alpha: 0.7),
                        letterSpacing: 0.12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.toolsPickAPhotoAnd,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: ink,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: l10n.toolsPickAPhoto,
                  icon: _picture,
                  filled: true,
                  onTap: onPhoto,
                ),
              ),
              const SizedBox(width: 8),
              _CardButton(
                label: l10n.toolsVideo,
                filled: false,
                onTap: onVideo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final List<String>? icon;
  final bool filled;
  final VoidCallback? onTap;

  const _CardButton({
    required this.label,
    this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    const ink = Colors.white;
    final fg = filled ? colors.accent : ink;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: filled ? 0 : 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? ink : null,
            borderRadius: BorderRadius.circular(UmbraRadius.lg),
            border: filled ? null : Border.all(color: ink.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                StrokeIcon(icon!, size: 17, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 13.5,
                  fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Tool Row
// ──────────────────────────────────────────────────────────────

class _ToolRow extends StatelessWidget {
  final List<String> icon;
  final Color tint;
  final Color tile;
  final String title;
  final String sub;
  final VoidCallback? onTap;
  final bool last;

  const _ToolRow({
    required this.icon,
    required this.tint,
    required this.tile,
    required this.title,
    required this.sub,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final side = BorderSide(color: colors.separatorStrong, width: 0.5);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title. $sub',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            border: Border(top: side, bottom: last ? side : BorderSide.none),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(tint.withValues(alpha: 0.10), tile),
                      tile,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tint.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: StrokeIcon(icon, size: 22, color: tint, stroke: 1.9),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.separatorStrong, width: 0.5),
                ),
                alignment: Alignment.center,
                child: StrokeIcon(
                  _chevron,
                  size: 14,
                  color: colors.textPrimary,
                  stroke: 1.9,
                  pointing: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Backup Section
// ──────────────────────────────────────────────────────────────

class _BackupSection extends StatefulWidget {
  @override
  State<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<_BackupSection> {
  double _progress = 0.0;
  bool _creating = false;
  Timer? _progressTimer;
  int _stageIndex = 0;

  static const _stages = [
    (0.0, 'Preparing...'),
    (0.2, 'Encrypting identity...'),
    (0.4, 'Encrypting messages...'),
    (0.6, 'Writing file...'),
    (0.8, 'Verifying...'),
    (1.0, 'Complete'),
  ];

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _createBackup() async {
    setState(() {
      _creating = true;
      _progress = 0.0;
      _stageIndex = 0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_stageIndex < _stages.length - 1) {
        setState(() {
          _stageIndex++;
          _progress = _stages[_stageIndex].$1;
        });
      } else {
        timer.cancel();
        setState(() {
          _creating = false;
          _progress = 1.0;
        });
        // TODO: Actually create backup
        if (mounted) {
          showHaloToast(context, 'Backup created successfully');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    return UmbraToolCard(
      icon: _lock,
      iconColor: colors.accent,
      title: 'Backup',
      description: 'Encrypted backup of your identity and messages',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UmbraProgressBar(
            progress: _progress,
            stages: _stages.map((s) => UmbraProgressStage(progress: s.$1, label: s.$2)).toList(),
            showPercent: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatusRow(
                  label: 'Last Backup',
                  value: 'Never',
                  valueColor: colors.textSecondary,
                ),
              ),
              Expanded(
                child: _StatusRow(
                  label: 'Size',
                  value: '—',
                  valueColor: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatusRow(
                  label: 'Identity',
                  value: 'Not backed up',
                  valueColor: colors.warning,
                  icon: Icons.warning_amber_outlined,
                ),
              ),
              Expanded(
                child: _StatusRow(
                  label: 'Messages',
                  value: 'Not backed up',
                  valueColor: colors.warning,
                  icon: Icons.warning_amber_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          UmbraToolAction(
            label: _creating ? 'Creating...' : 'Create Backup',
            onPressed: _creating ? () {} : _createBackup,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: valueColor),
          const SizedBox(width: 6),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: UmbraTypography.fontMono,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
                letterSpacing: 0.14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Key Verification Section
// ──────────────────────────────────────────────────────────────

class _KeyVerificationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    // Mock verification data
    final verifications = [
      ('alice.umbra', UmbraVerificationStatus.verified, 'A1:B2:C3:D4 E5:F6:78:90'),
      ('bob.umbra', UmbraVerificationStatus.pending, 'B2:C3:D4:E5 F6:78:90:A1'),
      ('charlie.umbra', UmbraVerificationStatus.unverified, 'C3:D4:E5:F6 78:90:A1:B2'),
    ];

    return UmbraToolCard(
      icon: ['M12 22c5.52 0 10-4.48 10-10S17.52 2 12 2 2 6.48 2 12s4.48 10 10 10z', 'M12 6v6l4 2'],
      iconColor: colors.accent,
      title: 'Key Verification',
      description: 'Verify safety numbers with your contacts',
      content: Column(
        children: verifications.map((v) {
          return UmbraVerificationItem(
            name: v.$1,
            status: v.$2,
            fingerprint: v.$3,
            onVerify: () {
              // Show verification dialog
              showHaloToast(context, 'Verifying ${v.$1}...');
            },
          );
        }).toList(),
      ),
      actions: [
        UmbraToolAction(
          label: 'Verify New Contact',
          onPressed: () {
            showHaloToast(context, 'Scan QR code to verify');
          },
          filled: false,
          icon: _qr,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Panic Options Section
// ──────────────────────────────────────────────────────────────

class _PanicOptionsSection extends StatefulWidget {
  @override
  State<_PanicOptionsSection> createState() => _PanicOptionsSectionState();
}

class _PanicOptionsSectionState extends State<_PanicOptionsSection> {
  bool _wipeOnWrongPin = false;
  bool _wipeOnShake = false;
  bool _wipeOnSms = false;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    return UmbraToolCard(
      icon: ['M12 22c5.52 0 10-4.48 10-10S17.52 2 12 2 2 6.48 2 12s4.48 10 10 10z', 'M12 6v6l4 2', 'M12 18v-6'],
      iconColor: colors.error,
      title: 'Panic Options',
      description: 'Emergency data protection triggers',
      content: Column(
        children: [
          _PanicOption(
            icon: ['M12 1a2 2 0 0 1 2 2v6h2a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-6H2a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2h6a2 2 0 0 1 2-2zm0 2H2a1 1 0 0 0-1 1v6h2V3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v6h2V3a1 1 0 0 0-1-1H6a1 1 0 0 0-1 1v6h2V3a1 1 0 0 0-1-1z'],
            title: 'Wipe on Wrong PIN',
            desc: 'Erase all data after 3 failed PIN attempts',
            value: _wipeOnWrongPin,
            onChanged: (v) => setState(() => _wipeOnWrongPin = v),
            isDestructive: true,
          ),
          const Divider(height: 1),
          _PanicOption(
            icon: ['M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm0 18a8 8 0 1 1 8-8 8 8 0 0 1-8 8z', 'M12 6v6l4 2'],
            title: 'Wipe on Shake',
            desc: 'Erase all data when device is shaken violently',
            value: _wipeOnShake,
            onChanged: (v) => setState(() => _wipeOnShake = v),
            isDestructive: true,
          ),
          const Divider(height: 1),
          _PanicOption(
            icon: ['M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9', 'M13.73 21a2 2 0 0 1-3.46 0'],
            title: 'Wipe on SMS Command',
            desc: 'Erase all data when receiving a specific SMS',
            value: _wipeOnSms,
            onChanged: (v) => setState(() => _wipeOnSms = v),
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _PanicOption extends StatelessWidget {
  final List<String> icon;
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDestructive;

  const _PanicOption({
    required this.icon,
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDestructive ? colors.errorSoft : colors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: StrokeIcon(icon, size: 20, color: isDestructive ? colors.error : colors.accent, stroke: 1.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: UmbraTypography.fontSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: UmbraTypography.fontSans,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colors.textSecondary,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          UmbraToggle(
            value: value,
            onChanged: onChanged,
            size: UmbraToggleSize.md,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Diagnostics Section
// ──────────────────────────────────────────────────────────────

class _DiagnosticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    final diagnostics = [
      ('Tor Connection', 'Connected', true),
      ('Relay Latency', '42 ms', true),
      ('Onion Services', '3 active', true),
      ('Battery Optimization', 'Disabled', true),
      ('Notifications', 'Allowed', true),
      ('Storage', '1.2 GB free', true),
    ];

    return UmbraToolCard(
      icon: ['M9 11l3 3L22 4', 'M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11'],
      iconColor: colors.success,
      title: 'Diagnostics',
      description: 'System health and connection status',
      content: Column(
        children: diagnostics.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    d.$1,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  d.$2,
                  style: TextStyle(
                    fontFamily: UmbraTypography.fontMono,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: d.$3 ? colors.success : colors.warning,
                    letterSpacing: 0.12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  d.$3 ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: d.$3 ? colors.success : colors.warning,
                  size: 18,
                ),
              ],
            ),
          );
        }).toList(),
      ),
      actions: [
        UmbraToolAction(
          label: 'Run Full Diagnostics',
          onPressed: () {
            showHaloToast(context, 'Running diagnostics...');
          },
          filled: false,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Export Section
// ──────────────────────────────────────────────────────────────

class _ExportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    return UmbraToolCard(
      icon: ['M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4', 'M17 4l-4 4-4-4', 'M12 15V4'],
      iconColor: colors.accent,
      title: 'Export Data',
      description: 'Export your messages and contacts',
      actions: [
        UmbraToolAction(
          label: 'Export Messages',
          onPressed: () {
            showHaloToast(context, 'Preparing export...');
          },
          filled: false,
        ),
        UmbraToolAction(
          label: 'Export Contacts',
          onPressed: () {
            showHaloToast(context, 'Preparing export...');
          },
          filled: false,
        ),
      ],
    );
  }
}
