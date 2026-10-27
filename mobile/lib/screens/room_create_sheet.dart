// SPDX-License-Identifier: GPL-3.0-or-later
// make a burner room: a name, how long it lives, whether it has a cap. one
// sheet, one button. the link comes right after.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart' show appState;
import '../rooms.dart';
import '../theme/theme.dart';
import '../widgets/notice_banner.dart';
import '../widgets/halo_sheet.dart';
import '../widgets/sheet_handle.dart';
import '../widgets/halo_switch.dart';
import '../l10n/l10n.dart';

// returns the new room's group id, or null if the sheet was dismissed
Future<String?> showRoomCreateSheet(BuildContext context) {
  return showHaloSheet<String>(
    context,
    scroll: true,
    builder: (_) => const _RoomCreateSheet(),
  );
}

class _RoomCreateSheet extends StatefulWidget {
  const _RoomCreateSheet();
  @override
  State<_RoomCreateSheet> createState() => _RoomCreateSheetState();
}

class _RoomCreateSheetState extends State<_RoomCreateSheet> {
  final _nameCtrl = TextEditingController();
  Duration _expiry = roomDefaultExpiry;
  bool _capOn = false;
  int _cap = roomDefaultCap;
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_creating) return;
    HapticFeedback.mediumImpact();
    setState(() => _creating = true);
    try {
      final id = await appState.createRoom(
        _nameCtrl.text,
        expiry: _expiry,
        cap: _capOn ? _cap : null,
      );
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      showHaloToast(context, l10n.roomCreateCouldNotCreateThe);
    }
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final insets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: UmbraMotion.easeOut,
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 18),
              Text(
                l10n.roomCreateBurnerRoom,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 22, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.roomCreateARoomThatEnds,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                maxLength: 32,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                cursorColor: colors.accent,
                decoration: InputDecoration(
                  hintText: l10n.roomCreateRoomName,
                  hintStyle: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textTertiary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
                  counterText: '',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(UmbraRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.roomCreateEndsAfter,
                style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final d in roomExpiryOptions) ...[
                    _Chip(
                      label: expiryLabel(d),
                      on: _expiry == d,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _expiry = d);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.roomCreateMemberCap,
                          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                        ),
                        Text(
                          _capOn
                              ? l10n.roomCreateNoOnePastThe(_cap)
                              : l10n.roomCreateOffAnyoneWithThe,
                          style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
                        ),
                      ],
                    ),
                  ),
                  HaloSwitch(
                    value: _capOn,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _capOn = v);
                    },
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: UmbraMotion.easeOut,
                alignment: Alignment.topCenter,
                child: _capOn
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            for (final n in roomCapOptions) ...[
                              _Chip(
                                label: '$n',
                                on: _cap == n,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _cap = n);
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              const SizedBox(height: 14),
              NoticeBanner(
                glyph: NoticeGlyph.clock,
                text: l10n.roomCreateThisRoomAndEverything(
                  expiryWords(_expiry),
                ),
                color: colors.accent,
              ),
              const SizedBox(height: 14),
              _GoButton(
                label: _creating
                    ? l10n.roomCreateCreating
                    : l10n.roomCreateCreateRoom,
                enabled: !_creating,
                onTap: _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// a mono chip, the kind timers and counts wear here
class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: UmbraMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on
              ? colors.accent.withValues(alpha: 0.16)
              : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: on ? colors.accent : colors.separator,
            width: on ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w500, color: on ? colors.accent : colors.textSecondary, letterSpacing: 0.12),
        ),
      ),
    );
  }
}

class _GoButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _GoButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  @override
  State<_GoButton> createState() => _GoButtonState();
}

class _GoButtonState extends State<_GoButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.enabled ? colors.accent : colors.surfaceHover,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.label,
            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 15, fontWeight: FontWeight.w600, color: widget.enabled ? colors.ink : colors.textTertiary, height: 1.5, letterSpacing: 0),
          ),
        ),
      ),
    );
  }
}
