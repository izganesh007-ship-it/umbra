// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra Avatar widget - iMessage-calibrated

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class UmbraAvatar extends StatelessWidget {
  final String? seed;
  final String? name;
  final double size;
  final bool isOnline;
  final bool isGroup;
  final VoidCallback? onTap;
  final Widget? child;

  const UmbraAvatar({
    super.key,
    this.seed,
    this.name,
    this.size = UmbraComponentTokens.avatarMd,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  });

  /// Creates an avatar with a specific size token
  const UmbraAvatar.xs({
    super.key,
    this.seed,
    this.name,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  }) : size = UmbraComponentTokens.avatarXs;

  const UmbraAvatar.sm({
    super.key,
    this.seed,
    this.name,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  }) : size = UmbraComponentTokens.avatarSm;

  const UmbraAvatar.md({
    super.key,
    this.seed,
    this.name,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  }) : size = UmbraComponentTokens.avatarMd;

  const UmbraAvatar.lg({
    super.key,
    this.seed,
    this.name,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  }) : size = UmbraComponentTokens.avatarLg;

  const UmbraAvatar.xl({
    super.key,
    this.seed,
    this.name,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  }) : size = UmbraComponentTokens.avatarXl;

  const UmbraAvatar.xxl({
    super.key,
    this.seed,
    this.name,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  }) : size = UmbraComponentTokens.avatar2xl;

  const UmbraAvatar.xxxl({
    super.key,
    this.seed,
    this.name,
    this.isOnline = false,
    this.isGroup = false,
    this.onTap,
    this.child,
  }) : size = UmbraComponentTokens.avatar3xl;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final radius = size / 2;

    Widget avatarContent = child ??
        _buildAvatarContent(context, colors, radius);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.separator,
          width: 1,
        ),
      ),
      child: ClipOval(child: avatarContent),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: _buildWithOnlineIndicator(avatar, colors, radius),
      );
    }

    return _buildWithOnlineIndicator(avatar, colors, radius);
  }

  Widget _buildWithOnlineIndicator(Widget avatar, UmbraSemanticColors colors, double radius) {
    if (!isOnline) return avatar;

    final indicatorSize = size * 0.25;
    final indicatorRadius = indicatorSize / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: indicatorSize,
            height: indicatorSize,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.surface,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowSm.color,
                  blurRadius: colors.shadowSm.blurRadius,
                  offset: colors.shadowSm.offset,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(BuildContext context, UmbraSemanticColors colors, double radius) {
    if (isGroup) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.accent.withValues(alpha: 0.2),
              colors.accent.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Icon(
          Icons.group_rounded,
          size: radius * 0.9,
          color: colors.accent,
        ),
      );
    }

    if (seed != null && seed!.isNotEmpty) {
      // Generate a consistent color from seed
      final hash = seed!.hashCode;
      final hue = (hash % 360).toDouble();
      final color = HSVColor.fromAHSV(1, hue, 0.55, 0.95).toColor();

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
        ),
        child: Center(
          child: Text(
            _getInitials(name ?? seed!),
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: UmbraTypography.fontSans,
            ),
          ),
        ),
      );
    }

    // Fallback placeholder
    return Container(
      width: size,
      height: size,
      color: colors.surfaceHover,
      child: Icon(
        Icons.person_rounded,
        size: radius * 0.9,
        color: colors.textMuted,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }
}

int min(int a, int b) => a < b ? a : b;
