// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra progress bar with stages for backup progress

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Progress bar with animated fill and optional stage labels
class UmbraProgressBar extends StatefulWidget {
  const UmbraProgressBar({
    super.key,
    required this.progress, // 0.0 to 1.0
    this.stages = const [],
    this.showPercent = true,
    this.height = 8,
    this.borderRadius = 4,
    this.animate = true,
  });

  final double progress;
  final List<UmbraProgressStage> stages;
  final bool showPercent;
  final double height;
  final double borderRadius;
  final bool animate;

  @override
  State<UmbraProgressBar> createState() => _UmbraProgressBarState();
}

class UmbraProgressStage {
  const UmbraProgressStage({
    required this.progress, // 0.0 to 1.0
    required this.label,
    this.color,
  });

  final double progress;
  final String label;
  final Color? color;
}

class _UmbraProgressBarState extends State<UmbraProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _animatedProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: UmbraMotion.durationNormal,
    );
    _animatedProgress = widget.progress;
    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant UmbraProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animatedProgress = oldWidget.progress;
      if (widget.animate) {
        _controller.forward(from: 0);
      } else {
        _animatedProgress = widget.progress;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).reduceMotion;

    final effectiveProgress = reduceMotion ? widget.progress : _animatedProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Stack(
          children: [
            // Track
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
            // Fill
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = reduceMotion ? 1.0 : _controller.value;
                final currentProgress = _animatedProgress * t + widget.progress * (1 - t);
                return FractionallySizedBox(
                  widthFactor: currentProgress.clamp(0.0, 1.0),
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.accent,
                          colors.accentHover,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                );
              },
            ),
            // Stage markers
            if (widget.stages.isNotEmpty)
              Positioned.fill(
                child: Row(
                  children: widget.stages.map((stage) {
                    return Expanded(
                      flex: (stage.progress * 1000).round(),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: Offset(-4, -widget.height / 2 - 2),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: stage.color ?? colors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        // Percent label
        if (widget.showPercent) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(widget.progress * 100).round()}%',
                style: TextStyle(
                  fontFamily: UmbraTypography.fontMono,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                  letterSpacing: 0.12,
                ),
              ),
              if (widget.stages.isNotEmpty)
                Text(
                  _getCurrentStageLabel(widget.progress),
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
        ],
        // Stage labels below
        if (widget.stages.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: widget.stages.map((stage) {
              final isActive = widget.progress >= stage.progress;
              final isCurrent = _getCurrentStageIndex(widget.progress) == widget.stages.indexOf(stage);
              return _StageLabel(
                label: stage.label,
                isActive: isActive,
                isCurrent: isCurrent,
                color: stage.color,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _getCurrentStageLabel(double progress) {
    for (int i = widget.stages.length - 1; i >= 0; i--) {
      if (progress >= widget.stages[i].progress) {
        return widget.stages[i].label;
      }
    }
    return widget.stages.first.label;
  }

  int _getCurrentStageIndex(double progress) {
    for (int i = widget.stages.length - 1; i >= 0; i--) {
      if (progress >= widget.stages[i].progress) {
        return i;
      }
    }
    return 0;
  }
}

class _StageLabel extends StatelessWidget {
  const _StageLabel({
    required this.label,
    required this.isActive,
    required this.isCurrent,
    this.color,
  });

  final String label;
  final bool isActive;
  final bool isCurrent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final effectiveColor = color ?? colors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: UmbraMotion.durationFast,
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? effectiveColor : colors.surfaceHover,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: effectiveColor, width: 2)
                : Border.all(color: colors.separator, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: UmbraTypography.fontSans,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colors.textPrimary : colors.textTertiary,
            height: 1.5,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Backup progress card with status rows
class UmbraBackupProgressCard extends StatelessWidget {
  const UmbraBackupProgressCard({
    super.key,
    required this.progress,
    required this.stages,
    this.lastBackup,
    this.backupSize,
    this.identityBackedUp,
    this.messagesBackedUp,
    this.onCreateBackup,
    this.isCreating = false,
  });

  final double progress;
  final List<UmbraProgressStage> stages;
  final String? lastBackup;
  final String? backupSize;
  final bool? identityBackedUp;
  final bool? messagesBackedUp;
  final VoidCallback? onCreateBackup;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return UmbraToolCard(
      icon: [
        'M5 10.5V8a4 4 0 0 1 8 0v2.5',
        'M12 14.5v2.2',
        'M8 10.5V8a4 4 0 0 1 7.6-1.7',
      ],
      iconColor: colors.accent,
      title: 'Backup',
      description: 'Encrypted backup of your identity and messages',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          UmbraProgressBar(
            progress: progress,
            stages: stages,
            showPercent: true,
          ),
          const SizedBox(height: 16),
          // Status rows
          if (lastBackup != null || backupSize != null) ...[
            Row(
              children: [
                Expanded(
                  child: _StatusRow(
                    label: 'Last Backup',
                    value: lastBackup ?? 'Never',
                    valueColor: colors.textSecondary,
                  ),
                ),
                if (backupSize != null)
                  Expanded(
                    child: _StatusRow(
                      label: 'Size',
                      value: backupSize!,
                      valueColor: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
          if (identityBackedUp != null || messagesBackedUp != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusRow(
                    label: 'Identity',
                    value: identityBackedUp == true ? 'Backed up' : 'Not backed up',
                    valueColor: identityBackedUp == true ? colors.success : colors.warning,
                    icon: identityBackedUp == true
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                  ),
                ),
                if (messagesBackedUp != null)
                  Expanded(
                    child: _StatusRow(
                      label: 'Messages',
                      value: messagesBackedUp == true ? 'Backed up' : 'Not backed up',
                      valueColor: messagesBackedUp == true ? colors.success : colors.warning,
                      icon: messagesBackedUp == true
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                    ),
                  ),
              ],
            ),
          ],
          // Create backup button
          if (onCreateBackup != null) ...[
            const SizedBox(height: 16),
            UmbraToolAction(
              label: isCreating ? 'Creating...' : 'Create Backup',
              onPressed: isCreating ? () {} : onCreateBackup!,
              filled: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

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
