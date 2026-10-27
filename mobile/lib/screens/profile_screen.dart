// SPDX-License-Identifier: GPL-3.0-or-later
// profile screen: avatar, kryfo id, the supporter badge when a tier is set,
// and the gear into settings.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import 'avatar_picker_screen.dart';
import '../main.dart' show appState, showAddContact;
import '../supporter.dart';
import '../widgets/kryfo_avatar.dart';
import 'settings_screen_new.dart';
import 'donate_screen.dart';
import 'my_kryfo_screen.dart';
import '../widgets/motion.dart' show haloRoute;
import '../widgets/halo_switch.dart';
import '../l10n/l10n.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenSupport;
  const ProfileScreen({super.key, this.onOpenSupport});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  SupporterTier _tier = SupporterTier.none;
  bool _showSelf = false;
  bool _share = false;

  late final AnimationController _intro;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadBadge();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadBadge() async {
    final t = await loadSupporterTier();
    final self = await loadShowBadgeSelf();
    final share = await loadShareBadge();
    if (!mounted) return;
    setState(() {
      _tier = t;
      _showSelf = self;
      _share = share;
    });
  }

  void _copy(String text, String what) {
    copySensitive(text);
    HapticFeedback.selectionClick();
    showHaloToast(context, l10n.profileCopied(what));
  }

  // a child that fades and slides up, delayed by [order] so sections stagger
  Widget _reveal(int order, Widget child) {
    final start = (order * 0.12).clamp(0.0, 0.8);
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, 1.0, curve: UmbraMotion.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 16),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final id = appState.myId;
    final hasBadge = _tier != SupporterTier.none;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          l10n.profileProfile,
          style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
        ),
        actions: [
          IconButton(
            tooltip: l10n.commonSettings,
            icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
            onPressed: () =>
                Navigator.of(context).push(haloRoute(SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _reveal(
                0,
                Center(
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _intro,
                          curve: const Interval(
                            0.0,
                            0.7,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: Semantics(
                          label: l10n.profileChangeYourFace,
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await Navigator.of(
                                context,
                              ).push(haloRoute(const AvatarPickerScreen()));
                              if (mounted) setState(() {});
                            },
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                KryfoAvatar(
                                  seed: id.isEmpty ? 'kryfo' : id,
                                  size: 96,
                                  choice: appState.myAvatar,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.accent,
                                    border: Border.all(
                                      color: colors.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: colors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // the three words are the name
                          Flexible(
                            child: Text(
                              id,
                              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 15, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12),
                            ),
                          ),
                          if (hasBadge && _showSelf) ...[
                            const SizedBox(width: 8),
                            _badgePill(_tier, glow: true),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _reveal(1, _Section(l10n.profileIdentity)),
              _reveal(
                1,
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(UmbraRadius.lg),
                    border: Border.all(color: colors.separator, width: 0.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PressRow(
                        onTap: () => _copy(id, l10n.profileKryfoId),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                id.isEmpty ? '...' : id,
                                style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 16, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12),
                              ),
                            ),
                            Icon(
                              Icons.copy_outlined,
                              color: colors.textTertiary,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                      if (appState.myOnion.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(color: colors.separator, height: 1),
                        const SizedBox(height: 12),
                        _PressRow(
                          onTap: () =>
                              _copy(appState.myOnion, l10n.profileOnionAddress),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  appState.myOnion,
                                  style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.copy_outlined,
                                color: colors.textTertiary,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (hasBadge) ...[
                _reveal(2, _Section(l10n.profileSupporterBadge)),
                _reveal(
                  2,
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                      border: Border.all(color: colors.separator, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _badgePill(_tier, glow: true),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.profileYouAreAThank(tierKey(_tier)),
                                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _toggleRow(
                          l10n.profileShowMyBadge,
                          l10n.profileOnMyOwnScreens,
                          _showSelf,
                          (v) async {
                            await saveShowBadgeSelf(v);
                            setState(() => _showSelf = v);
                          },
                        ),
                        const SizedBox(height: 10),
                        _toggleRow(
                          l10n.profileLetContactsSeeIt,
                          l10n.profileOffByDefault,
                          _share,
                          (v) async {
                            await saveShareBadge(v);
                            setState(() => _share = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              _reveal(3, _Section(l10n.profileShareConnect)),
              const SizedBox(height: 8),
              _reveal(
                3,
                _PressRow(
                  onTap: () => Navigator.of(
                    context,
                  ).push(haloRoute(const MyKryfoScreen())),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                      border: Border.all(color: colors.separator, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_outlined,
                          color: colors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.profileMyKryfoCode,
                            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colors.textTertiary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _reveal(
                3,
                _PressRow(
                  onTap: () => showAddContact(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                      border: Border.all(color: colors.separator, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          color: colors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.profileAddContact,
                            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colors.textTertiary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _reveal(
                3,
                _Section(
                  hasBadge ? l10n.profileGiveAgain : l10n.profileSupportKryfo,
                ),
              ),
              _reveal(
                3,
                _PressRow(
                  onTap:
                      widget.onOpenSupport ??
                      () => Navigator.of(
                        context,
                      ).push(haloRoute(const DonateScreen())),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                      border: Border.all(color: colors.separator, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          '\u2726',
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasBadge
                                ? l10n.profileKryfoRunsOnWhat
                                : l10n.profileKeepKryfoIndependent,
                            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colors.textTertiary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgePill(SupporterTier t, {bool glow = false}) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(UmbraRadius.xl),
        border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tierGlyph(t),
            style: TextStyle(color: colors.accent, fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            tierLabel(t),
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 8, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12),
          ),
        ],
      ),
    );
    if (!glow) return pill;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final g = 0.25 + (_pulse.value * 0.45);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UmbraRadius.xl),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: g * 0.5),
                blurRadius: 8 + (_pulse.value * 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: pill,
    );
  }

  Widget _toggleRow(
    String label,
    String sub,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
              ),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12)),
            ],
          ),
        ),
        HaloSwitch(value: value, onChanged: (v) => onChanged(v)),
      ],
    );
  }
}

// tap target that scales down slightly on press
class _PressRow extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressRow({required this.child, required this.onTap});
  @override
  State<_PressRow> createState() => _PressRowState();
}

class _PressRowState extends State<_PressRow> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: UmbraMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 0, 0, 10),
      child: Text(
        label,
        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
      ),
    );
  }
}
