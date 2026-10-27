// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra Input Bar widget - frosted glass, 56px height, expandable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';

typedef OnSendCallback = void Function(String text, {bool secure, bool disguise, int? burnSeconds});
typedef OnAttachCallback = void Function();
typedef OnVoiceCallback = void Function();

class UmbraInputBar extends StatefulWidget {
  final OnSendCallback onSend;
  final OnAttachCallback? onAttach;
  final OnVoiceCallback? onVoice;
  final String? hintText;
  final String? initialText;
  final bool isSecure;
  final bool isDisguised;
  final int? burnSeconds;
  final bool enabled;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onSecureToggle;
  final VoidCallback? onDisguiseToggle;
  final VoidCallback? onBurnToggle;
  final List<Widget>? trailingActions;

  const UmbraInputBar({
    super.key,
    required this.onSend,
    this.onAttach,
    this.onVoice,
    this.hintText,
    this.initialText,
    this.isSecure = false,
    this.isDisguised = false,
    this.burnSeconds,
    this.enabled = true,
    this.focusNode,
    this.controller,
    this.onTextChanged,
    this.onSecureToggle,
    this.onDisguiseToggle,
    this.onBurnToggle,
    this.trailingActions,
  });

  @override
  State<UmbraInputBar> createState() => _UmbraInputBarState();
}

class _UmbraInputBarState extends State<UmbraInputBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _expandController;
  late Animation<double> _heightAnimation;

  bool _isComposing = false;
  bool _showExpandOptions = false;
  double _currentHeight = UmbraComponentTokens.inputBarHeight;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialText);
    _focusNode = widget.focusNode ?? FocusNode();
    _expandController = AnimationController(
      duration: UmbraMotion.durationNormal,
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: UmbraComponentTokens.inputBarHeight,
      end: UmbraComponentTokens.inputBarHeightExpanded,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: UmbraMotion.easeSpring,
    ));

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _controller.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() => _isComposing = isComposing);
    }
    widget.onTextChanged?.call(_controller.text);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSend(
        text,
        secure: widget.isSecure,
        disguise: widget.isDisguised,
        burnSeconds: widget.burnSeconds,
      );
      _controller.clear();
      setState(() => _isComposing = false);
    }
  }

  void _handleAttach() {
    if (widget.enabled) {
      widget.onAttach?.call();
    }
  }

  void _handleVoice() {
    if (widget.enabled) {
      widget.onVoice?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).controller.reduceMotion;

    return AnimatedBuilder(
      animation: reduceMotion ? kAlwaysDismissedAnimation : _expandController,
      builder: (context, child) {
        final height = reduceMotion
            ? (_focusNode.hasFocus ? UmbraComponentTokens.inputBarHeightExpanded : UmbraComponentTokens.inputBarHeight)
            : _heightAnimation.value;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: colors.inputBg,
            border: Border(
              top: BorderSide(
                color: _focusNode.hasFocus ? colors.inputFocusBorder : colors.inputBorder,
                width: _focusNode.hasFocus ? 2 : 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadowFrosted.color,
                blurRadius: colors.shadowFrosted.blurRadius,
                offset: colors.shadowFrosted.offset,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(UmbraComponentTokens.inputBarRadius),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: _buildContent(context, colors),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UmbraSemanticColors colors) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: UmbraComponentTokens.inputBarPaddingX,
        vertical: UmbraComponentTokens.inputBarPaddingY,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Leading actions (attach, voice)
          _buildLeadingActions(context, colors),

          // Text input area
          Expanded(
            child: _buildTextInput(context, colors),
          ),

          // Trailing actions (secure, disguise, burn, send)
          _buildTrailingActions(context, colors),
        ],
      ),
    );
  }

  Widget _buildLeadingActions(BuildContext context, UmbraSemanticColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attach button
        if (widget.onAttach != null)
          _InputActionButton(
            icon: Icons.attach_file_rounded,
            onPressed: _handleAttach,
            enabled: widget.enabled,
            tooltip: 'Attach',
          ),

        // Voice button
        if (widget.onVoice != null)
          _InputActionButton(
            icon: Icons.mic_rounded,
            onPressed: _handleVoice,
            enabled: widget.enabled,
            tooltip: 'Voice message',
          ),
      ],
    );
  }

  Widget _buildTextInput(BuildContext context, UmbraSemanticColors colors) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: UmbraComponentTokens.inputBarHeightExpanded - UmbraComponentTokens.inputBarPaddingY * 2,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(UmbraRadius.full),
        border: Border.all(
          color: _focusNode.hasFocus ? colors.inputFocusBorder : colors.inputBorder,
          width: _focusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: null,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: UmbraComponentTokens.inputTextSize,
          fontFamily: UmbraTypography.fontSans,
          color: colors.textPrimary,
          height: UmbraTypography.leadingNormal,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Message',
          hintStyle: TextStyle(
            fontSize: UmbraComponentTokens.inputTextSize,
            fontFamily: UmbraTypography.fontSans,
            color: colors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: UmbraSpacing.space4,
            vertical: UmbraSpacing.space2,
          ),
          isDense: true,
        ),
        onSubmitted: (_) => _handleSend(),
        inputFormatters: [
          LengthLimitingTextInputFormatter(4096),
        ],
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context, UmbraSemanticColors colors) {
    final actions = <Widget>[];

    // Secure toggle
    if (widget.onSecureToggle != null) {
      actions.add(
        _InputActionButton(
          icon: widget.isSecure ? Icons.lock_rounded : Icons.lock_open_rounded,
          onPressed: widget.onSecureToggle!,
          enabled: widget.enabled,
          isActive: widget.isSecure,
          activeColor: colors.accent,
          tooltip: widget.isSecure ? 'Disable secure' : 'Enable secure',
        ),
      );
    }

    // Disguise toggle
    if (widget.onDisguiseToggle != null) {
      actions.add(
        _InputActionButton(
          icon: Icons.face_rounded,
          onPressed: widget.onDisguiseToggle!,
          enabled: widget.enabled,
          isActive: widget.isDisguised,
          activeColor: colors.warning,
          tooltip: widget.isDisguised ? 'Disable disguise' : 'Enable disguise',
        ),
      );
    }

    // Burn timer toggle
    if (widget.onBurnToggle != null) {
      actions.add(
        _InputActionButton(
          icon: Icons.timer_rounded,
          onPressed: widget.onBurnToggle!,
          enabled: widget.enabled,
          isActive: widget.burnSeconds != null && widget.burnSeconds! > 0,
          activeColor: colors.warning,
          tooltip: widget.burnSeconds != null && widget.burnSeconds! > 0
              ? 'Disable burn timer'
              : 'Set burn timer',
        ),
      );
    }

    // Custom trailing actions
    if (widget.trailingActions != null) {
      actions.addAll(widget.trailingActions!);
    }

    // Send button
    actions.add(
      _SendButton(
        onPressed: _handleSend,
        enabled: widget.enabled && _isComposing,
        isComposing: _isComposing,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }
}

class _InputActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isActive;
  final Color? activeColor;
  final String? tooltip;

  const _InputActionButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
    this.isActive = false,
    this.activeColor,
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
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(UmbraRadius.full),
          child: AnimatedContainer(
            duration: UmbraMotion.durationFast,
            curve: UmbraMotion.easeSpring,
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (activeColor ?? colors.accent).withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 22,
              color: enabled
                  ? (isActive ? activeColor ?? colors.accent : colors.textSecondary)
                  : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;
  final bool isComposing;

  const _SendButton({
    required this.onPressed,
    required this.enabled,
    required this.isComposing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return AnimatedScale(
      scale: isComposing ? 1.0 : 0.8,
      duration: UmbraMotion.durationFast,
      curve: UmbraMotion.easeSpring,
      child: AnimatedOpacity(
        opacity: isComposing ? 1.0 : 0.0,
        duration: UmbraMotion.durationFast,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(UmbraRadius.full),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? colors.accent : colors.separator,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: enabled ? colors.accentOn : colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension for easy usage
extension UmbraInputBarExtension on UmbraInputBar {
  static Widget secure({
    required OnSendCallback onSend,
    OnAttachCallback? onAttach,
    OnVoiceCallback? onVoice,
    required bool isSecure,
    required VoidCallback onSecureToggle,
    String? hintText,
    bool enabled = true,
  }) {
    return UmbraInputBar(
      onSend: onSend,
      onAttach: onAttach,
      onVoice: onVoice,
      hintText: hintText,
      isSecure: isSecure,
      onSecureToggle: onSecureToggle,
      enabled: enabled,
    );
  }
}
