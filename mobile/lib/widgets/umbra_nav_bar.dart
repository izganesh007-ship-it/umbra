// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra Navigation Bar widget - Large title (96px) and collapsed (56px) variants

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum UmbraNavBarVariant {
  large,      // 96px with large title (Fraunces 28px, weight 700)
  collapsed,  // 56px with inline title (Inter 20px, weight 600)
}

enum UmbraNavBarBackStyle {
  none,
  back,       // Back arrow
  close,      // Close X
}

class UmbraNavBar extends StatelessWidget {
  final UmbraNavBarVariant variant;
  final String title;
  final String? subtitle;
  final UmbraNavBarBackStyle backStyle;
  final VoidCallback? onBack;
  final List<Widget>? leadingActions;
  final List<Widget>? trailingActions;
  final Widget? connectionStatus;
  final bool showBottomBorder;
  final double? scrollOffset; // For animated transition

  const UmbraNavBar({
    super.key,
    required this.variant,
    required this.title,
    this.subtitle,
    this.backStyle = UmbraNavBarBackStyle.none,
    this.onBack,
    this.leadingActions,
    this.trailingActions,
    this.connectionStatus,
    this.showBottomBorder = true,
    this.scrollOffset,
  });

  /// Large title variant (96px)
  const UmbraNavBar.large({
    super.key,
    required this.title,
    this.subtitle,
    this.backStyle = UmbraNavBarBackStyle.none,
    this.onBack,
    this.leadingActions,
    this.trailingActions,
    this.connectionStatus,
    this.showBottomBorder = true,
    this.scrollOffset,
  }) : variant = UmbraNavBarVariant.large;

  /// Collapsed variant (56px)
  const UmbraNavBar.collapsed({
    super.key,
    required this.title,
    this.subtitle,
    this.backStyle = UmbraNavBarBackStyle.back,
    this.onBack,
    this.leadingActions,
    this.trailingActions,
    this.connectionStatus,
    this.showBottomBorder = true,
    this.scrollOffset,
  }) : variant = UmbraNavBarVariant.collapsed;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).controller.reduceMotion;

    final isLarge = variant == UmbraNavBarVariant.large;
    final height = isLarge ? UmbraComponentTokens.navBarHeightLarge : UmbraComponentTokens.navBarHeight;

    // Calculate animation progress for smooth transition
    final scrollProgress = scrollOffset != null
        ? (scrollOffset! / 50).clamp(0.0, 1.0)
        : (isLarge ? 0.0 : 1.0);

    final animatedHeight = reduceMotion
        ? height
        : lerpDouble(UmbraComponentTokens.navBarHeightLarge, UmbraComponentTokens.navBarHeight, scrollProgress)!;

    final titleOpacity = reduceMotion
        ? (isLarge ? 1.0 : 0.0)
        : lerpDouble(1.0, 0.0, scrollProgress)!;

    final collapsedTitleOpacity = reduceMotion
        ? (isLarge ? 0.0 : 1.0)
        : lerpDouble(0.0, 1.0, scrollProgress)!;

    return Container(
      height: animatedHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: colors.navBg,
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: colors.navBorder,
                  width: 0.5,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowFrosted.color,
            blurRadius: colors.shadowFrosted.blurRadius,
            offset: colors.shadowFrosted.offset,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: animatedHeight,
              child: _buildContent(
                context,
                colors,
                isLarge,
                scrollProgress,
                titleOpacity,
                collapsedTitleOpacity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UmbraSemanticColors colors,
    bool isLarge,
    double scrollProgress,
    double titleOpacity,
    double collapsedTitleOpacity,
  ) {
    final titleStyle = isLarge
        ? TextStyle(
            fontSize: UmbraComponentTokens.navTitleSize,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: UmbraTypography.fontSerif,
            height: UmbraTypography.leadingTight,
            letterSpacing: UmbraTypography.trackingTight,
          )
        : TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: UmbraTypography.fontSans,
            height: UmbraTypography.leadingSnug,
            letterSpacing: UmbraTypography.trackingTight,
          );

    final subtitleStyle = TextStyle(
      fontSize: UmbraTypography.textSm,
      fontWeight: FontWeight.w400,
      color: colors.textSecondary,
      fontFamily: UmbraTypography.fontSans,
      height: UmbraTypography.leadingNormal,
    );

    return Stack(
      children: [
        // Leading actions (back button + custom leading)
        Positioned(
          left: UmbraSpacing.space4,
          top: 0,
          bottom: 0,
          child: _buildLeading(context, colors),
        ),

        // Title area (center)
        Center(
          child: AnimatedOpacity(
            opacity: titleOpacity,
            duration: reduceMotion ? Duration.zero : UmbraMotion.durationFast,
            curve: UmbraMotion.easeOut,
            child: Transform.translate(
              offset: Offset(0, isLarge ? 0 : 8 * (1 - titleOpacity)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: UmbraSpacing.space0),
                    Text(
                      subtitle!,
                      style: subtitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Collapsed title (shows when scrolling)
        Center(
          child: AnimatedOpacity(
            opacity: collapsedTitleOpacity,
            duration: reduceMotion ? Duration.zero : UmbraMotion.durationFast,
            curve: UmbraMotion.easeOut,
            child: Transform.translate(
              offset: Offset(0, 8 * collapsedTitleOpacity),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: UmbraTypography.fontSans,
                  height: UmbraTypography.leadingSnug,
                  letterSpacing: UmbraTypography.trackingTight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),

        // Trailing actions
        Positioned(
          right: UmbraSpacing.space4,
          top: 0,
          bottom: 0,
          child: _buildTrailing(context, colors),
        ),
      ],
    );
  }

  Widget _buildLeading(BuildContext context, UmbraSemanticColors colors) {
    final actions = <Widget>[];

    // Back/Close button
    if (backStyle != UmbraNavBarBackStyle.none) {
      actions.add(
        _NavActionButton(
          icon: backStyle == UmbraNavBarBackStyle.back
              ? Icons.chevron_left_rounded
              : Icons.close_rounded,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: backStyle == UmbraNavBarBackStyle.back ? 'Back' : 'Close',
        ),
      );
    }

    // Custom leading actions
    if (leadingActions != null) {
      actions.addAll(leadingActions!);
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: actions,
    );
  }

  Widget _buildTrailing(BuildContext context, UmbraSemanticColors colors) {
    final actions = <Widget>[];

    // Connection status
    if (connectionStatus != null) {
      actions.add(connectionStatus!);
    }

    // Custom trailing actions
    if (trailingActions != null) {
      actions.addAll(trailingActions!);
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: actions,
    );
  }
}

class _NavActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _NavActionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(UmbraRadius.full),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// Connection status widget for nav bar
class UmbraConnectionStatus extends StatelessWidget {
  final UmbraConnectionState state;
  final String? customText;

  const UmbraConnectionStatus({
    super.key,
    required this.state,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    Color dotColor;
    String text;
    IconData? icon;

    switch (state) {
      case UmbraConnectionState.connected:
        dotColor = colors.success;
        text = customText ?? 'Sealed';
        icon = Icons.lock_rounded;
        break;
      case UmbraConnectionState.connecting:
        dotColor = colors.warning;
        text = customText ?? 'Connecting…';
        icon = Icons.sync_rounded;
        break;
      case UmbraConnectionState.offline:
        dotColor = colors.error;
        text = customText ?? 'Offline';
        icon = Icons.wifi_off_rounded;
        break;
      case UmbraConnectionState.torConnecting:
        dotColor = colors.warning;
        text = customText ?? 'Tor…';
        icon = Icons.router_rounded;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated dot
        _AnimatedDot(color: dotColor, state: state),
        SizedBox(width: UmbraSpacing.space2),
        // Text (hidden when collapsed)
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              fontSize: UmbraTypography.textXs,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              fontFamily: UmbraTypography.fontMono,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

enum UmbraConnectionState {
  connected,
  connecting,
  offline,
  torConnecting,
}

class _AnimatedDot extends StatefulWidget {
  final Color color;
  final UmbraConnectionState state;

  const _AnimatedDot({
    required this.color,
    required this.state,
  });

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.state == UmbraConnectionState.connecting ||
        widget.state == UmbraConnectionState.torConnecting) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == UmbraConnectionState.connecting ||
        widget.state == UmbraConnectionState.torConnecting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = widget.state == UmbraConnectionState.connecting ||
                widget.state == UmbraConnectionState.torConnecting
            ? 0.3 + 0.7 * _controller.value
            : 1.0;

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: opacity * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
