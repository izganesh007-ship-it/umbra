// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra verification item for key verification screen

import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'umbra_avatar.dart';

/// Verification status for a contact
enum UmbraVerificationStatus {
  verified,
  pending,
  unverified,
  mismatch,
}

/// A verification item showing contact avatar, name, status, and action
class UmbraVerificationItem extends StatelessWidget {
  const UmbraVerificationItem({
    super.key,
    required this.name,
    required this.status,
    this.avatarSeed,
    this.fingerprint,
    this.onTap,
    this.onVerify,
    this.showAction = true,
  });

  final String name;
  final UmbraVerificationStatus status;
  final String? avatarSeed;
  final String? fingerprint;
  final VoidCallback? onTap;
  final VoidCallback? onVerify;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final (statusColor, statusLabel, statusIcon) = switch (status) {
      UmbraVerificationStatus.verified => (
          colors.success,
          'Verified',
          Icons.check_circle_rounded,
        ),
      UmbraVerificationStatus.pending => (
          colors.warning,
          'Pending',
          Icons.schedule_rounded,
        ),
      UmbraVerificationStatus.unverified => (
          colors.textTertiary,
          'Unverified',
          Icons.help_outline_rounded,
        ),
      UmbraVerificationStatus.mismatch => (
          colors.error,
          'Mismatch',
          Icons.error_outline_rounded,
        ),
    };

    return Semantics(
      button: onTap != null,
      label: '$name. $statusLabel',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.separatorStrong,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              UmbraAvatar(
                seed: avatarSeed ?? name,
                size: UmbraAvatarSize.lg,
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    if (fingerprint != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 12,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fingerprint!,
                            style: TextStyle(
                              fontFamily: UmbraTypography.fontMono,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.textTertiary,
                              letterSpacing: 0.12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                        letterSpacing: 0.12,
                      ),
                    ),
                  ],
                ),
              ),
              // Action button
              if (showAction && onVerify != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onVerify,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(UmbraRadius.md),
                      border: Border.all(color: colors.accent.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Text(
                      status == UmbraVerificationStatus.verified ? 'Verified' : 'Verify',
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                        letterSpacing: 0.12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Key verification card with QR code and fingerprint comparison
class UmbraKeyVerificationCard extends StatelessWidget {
  const UmbraKeyVerificationCard({
    super.key,
    required this.localName,
    required this.remoteName,
    this.localAvatarSeed,
    this.remoteAvatarSeed,
    required this.localFingerprint,
    required this.remoteFingerprint,
    this.onScanRemote,
    this.onShowLocalQR,
    this.onMarkVerified,
    this.isVerified = false,
  });

  final String localName;
  final String remoteName;
  final String? localAvatarSeed;
  final String? remoteAvatarSeed;
  final String localFingerprint;
  final String remoteFingerprint;
  final VoidCallback? onScanRemote;
  final VoidCallback? onShowLocalQR;
  final VoidCallback? onMarkVerified;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final match = localFingerprint == remoteFingerprint;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(UmbraRadius.xl),
        border: Border.all(
          color: match ? colors.success.withValues(alpha: 0.4) : colors.separator,
          width: match ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: match ? colors.successSoft : colors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  match ? Icons.verified_rounded : Icons.security_rounded,
                  color: match ? colors.success : colors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match ? 'Keys Match' : 'Keys Do Not Match',
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSerif,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: match ? colors.success : colors.error,
                        fontStyle: FontStyle.italic,
                        height: 1.05,
                        letterSpacing: -0.015,
                      ),
                    ),
                    Text(
                      'Compare the fingerprints below with your contact',
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
            ],
          ),
          const SizedBox(height: 24),
          // Fingerprint comparison
          Row(
            children: [
              // Local
              Expanded(
                child: _FingerprintColumn(
                  label: 'You ($localName)',
                  fingerprint: localFingerprint,
                  avatarSeed: localAvatarSeed,
                  isLocal: true,
                  onShowQR: onShowLocalQR,
                ),
              ),
              const SizedBox(width: 16),
              // Match indicator
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      match ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: match ? colors.success : colors.error,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match ? 'MATCH' : 'MISMATCH',
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: match ? colors.success : colors.error,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Remote
              Expanded(
                child: _FingerprintColumn(
                  label: remoteName,
                  fingerprint: remoteFingerprint,
                  avatarSeed: remoteAvatarSeed,
                  isLocal: false,
                  onScanQR: onScanRemote,
                ),
              ),
            ],
          ),
          if (!isVerified && match) ...[
            const SizedBox(height: 24),
            // Mark verified button
            SizedBox(
              width: double.infinity,
              child: UmbraToolAction(
                label: 'Mark as Verified',
                onPressed: onMarkVerified!,
                filled: true,
                icon: ['M5 13l4 4L19 7'],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FingerprintColumn extends StatelessWidget {
  const _FingerprintColumn({
    required this.label,
    required this.fingerprint,
    this.avatarSeed,
    required this.isLocal,
    this.onShowQR,
    this.onScanQR,
  });

  final String label;
  final String fingerprint;
  final String? avatarSeed;
  final bool isLocal;
  final VoidCallback? onShowQR;
  final VoidCallback? onScanQR;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UmbraAvatar(
              seed: avatarSeed ?? label,
              size: UmbraAvatarSize.md,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(UmbraRadius.lg),
            border: Border.all(color: colors.separator, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fingerprint in groups of 4
              ..._fingerprintGroups(fingerprint).map((group) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    group,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontMono,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }),
              if (isLocal && onShowQR != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onShowQR,
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2_outlined, size: 16, color: colors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Show my QR code',
                        style: TextStyle(
                          fontFamily: UmbraTypography.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.accent,
                          letterSpacing: 0.12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!isLocal && onScanQR != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onScanQR,
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner_outlined, size: 16, color: colors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Scan their QR code',
                        style: TextStyle(
                          fontFamily: UmbraTypography.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.accent,
                          letterSpacing: 0.12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<String> _fingerprintGroups(String fp) {
    // Format: "AA:BB:CC:DD EE:FF:00:11 ..."
    final clean = fp.replaceAll(':', '').replaceAll(' ', '');
    final groups = <String>[];
    for (int i = 0; i < clean.length; i += 8) {
      final chunk = clean.substring(i, (i + 8).clamp(0, clean.length));
      final formatted = '${chunk.substring(0, 4)}:${chunk.substring(4)}';
      groups.add(formatted);
    }
    return groups;
  }
}
