// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra settings screen matching settings.html design

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show appState, db, lockState, wipeHalo;
import '../lock_state.dart';
import '../intro_prefs.dart';
import '../scam_prefs.dart';
import '../miui_autostart.dart';
import '../widgets/motion.dart' show haloRoute;
import 'why_kryfo_screen.dart';
import 'transport_screen.dart';
import 'bridges_screen.dart';
import 'seen_screen.dart';
import '../notif_permission.dart';
import 'modes_screen.dart';
import 'blocked_screen.dart';
import 'pins_screen.dart';
import 'backup_screen.dart';
import '../wipe.dart';
import 'restore_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notifications.dart';
import '../delivery_mode.dart';
import 'getting_messages_screen.dart';
import '../widgets/halo_rows.dart';
import '../widgets/stagger_in.dart';
import '../widgets/confirm_sheet.dart';
import '../l10n/l10n.dart';
import '../widgets/language_sheet.dart';
import '../wipe_word.dart';
import '../theme/theme.dart';
import '../widgets/umbra_settings_item.dart';
import '../widgets/umbra_toggle.dart';
import '../widgets/umbra_theme_selector.dart';
import '../widgets/umbra_accent_grid.dart';
import '../widgets/umbra_danger_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _hidePreview;
  bool _disguise = false;
  bool _acceptIntros = true;
  bool _shieldOn = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final results = await Future.wait([
      loadHideNotifContent(),
      appState.loadDisguisePref(),
      loadAcceptIntros(),
      loadScamShieldOn(),
    ]);
    if (!mounted) return;
    setState(() {
      _hidePreview = results[0];
      _disguise = results[1];
      _acceptIntros = results[2];
      _shieldOn = results[3];
    });
  }

  Future<void> _confirmWipe() async {
    final go = await showConfirmSheet(
      context,
      title: l10n.settingsWipeKryfo,
      line: l10n.settingsIdentityMessagesContactsAnd,
      yes: l10n.commonContinue,
      keep: l10n.commonCancel,
    );
    if (!go || !mounted) return;

    final typed = (await showInputSheet(
      context,
      title: l10n.settingsTypeWipeToConfirm(l10n.settingsWipeWord),
      line: l10n.settingsTheLastStepNothing,
      hint: l10n.settingsWipeWord,
      mono: true,
      rose: true,
      save: l10n.settingsWipeKryfo2,
    ));
    if (isWipeWord(typed, l10n.settingsWipeWord)) await wipeHalo();
  }

  Widget _postureLine(UmbraSemanticColors colors, String label, bool on, String onText, String offText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: UmbraMotion.durationNormal,
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              on ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(on),
              size: 16,
              color: on ? colors.accent : colors.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colors.textPrimary,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedDefaultTextStyle(
            duration: UmbraMotion.durationNormal,
            style: TextStyle(
              fontFamily: UmbraTypography.fontMono,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: on ? colors.accent : colors.textTertiary,
              letterSpacing: 0.12,
            ),
            child: Text(on ? onText : offText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final themeController = UmbraTheme.of(context);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Navigation header
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.commonBack,
                    icon: Icon(Icons.chevron_left, color: colors.textSecondary, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.commonSettings,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSerif,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: colors.textPrimary,
                        fontStyle: FontStyle.italic,
                        height: 1.05,
                        letterSpacing: -0.015,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Settings list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Protections card
                  ListenableBuilder(
                    listenable: Listenable.merge([appState, lockState]),
                    builder: (_, _) {
                      final tor = appState.torUsable;
                      final onTor = appState.sendMode == 'private';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(UmbraRadius.xl),
                          border: Border.all(color: colors.separator, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.settingsYourProtections,
                              style: TextStyle(
                                fontFamily: UmbraTypography.fontMono,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.accent,
                                letterSpacing: 0.12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _postureLine(colors,
                              l10n.settingsTorRouting,
                              onTor && tor,
                              l10n.settingsConnected,
                              onTor
                                  ? l10n.settingsConnecting
                                  : appState.sendMode == 'fast'
                                      ? l10n.settingsOffFastMode
                                      : l10n.settingsOffMode,
                            ),
                            _postureLine(colors,
                              l10n.settingsScreenshots,
                              appState.blockScreenshotsApplied,
                              l10n.settingsBlocked2,
                              l10n.settingsAllowed,
                            ),
                            _postureLine(colors,
                              l10n.settingsAppLock,
                              lockState.enabled,
                              l10n.settingsOn,
                              l10n.settingsOff,
                            ),
                            FutureBuilder<bool>(
                              future: notificationsEnabled(),
                              builder: (_, snap) => snap.data == false
                                  ? _postureLine(colors,
                                      l10n.settingsNotifications,
                                      false,
                                      '',
                                      l10n.settingsBlockedByAndroid,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Language
                  UmbraSettingsSection(title: l10n.languageTitle),
                  UmbraSettingsItem(
                    icon: ['M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm0 18a8 8 0 1 1 8-8 8 8 0 0 1-8 8z', 'M12 6v6l4 2'],
                    title: l10n.languageTitle,
                    subtitle: languageValue(),
                    trailing: UmbraSettingsChevron(),
                    onTap: () => pickLanguage(context),
                  ),

                  const SizedBox(height: 24),

                  // Privacy & Security
                  UmbraSettingsSection(title: l10n.settingsPrivacy),
                  UmbraSettingsItem(
                    icon: ['M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'],
                    title: l10n.settingsSpeedPrivacy,
                    subtitle: appState.sendMode == 'fast'
                        ? l10n.settingsFast
                        : appState.sendMode == 'balanced'
                            ? l10n.settingsRelay1Hop
                            : l10n.settingsOnion3Hops,
                    trailing: UmbraSettingsChevron(),
                    onTap: () async {
                      await Navigator.of(context).push(haloRoute(const ModesScreen()));
                      if (mounted) setState(() {});
                    },
                  ),
                  UmbraSettingsItem(
                    icon: ['M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z', 'M2 12h20'],
                    title: l10n.settingsBridges,
                    subtitle: appState.bridgesOn ? l10n.commonOn : l10n.commonOff,
                    trailing: UmbraSettingsChevron(),
                    onTap: () async {
                      await Navigator.push(context, haloRoute(const BridgesScreen()));
                      if (mounted) setState(() {});
                    },
                  ),
                  UmbraSettingsItem(
                    icon: ['M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9', 'M13.73 21a2 2 0 0 1-3.46 0'],
                    title: l10n.settingsGettingMessages,
                    subtitle: switch (_hidePreview) {
                      null => deliveryModeName(appState.deliveryMode),
                      true => l10n.settingsPreviewHidden(deliveryModeName(appState.deliveryMode)),
                      false => l10n.settingsPreviewShown(deliveryModeName(appState.deliveryMode)),
                    },
                    trailing: UmbraSettingsChevron(),
                    onTap: () async {
                      await Navigator.of(context).push(haloRoute(const GettingMessagesScreen()));
                      final v = await loadHideNotifContent();
                      if (mounted) setState(() => _hidePreview = v);
                    },
                  ),
                  UmbraSettingsItem(
                    icon: ['M13 2L3 14h9l-1 8 10-12h-9l1-8z'],
                    title: l10n.settingsRunInBackground,
                    subtitle: l10n.settingsSoMessagesArrive,
                    trailing: UmbraSettingsChevron(),
                    onTap: () => forceShowBackgroundPrompt(context),
                  ),
                  UmbraSettingsItem(
                    icon: ['M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z', 'M3.27 6.96L12 12.01l8.73-5.05', 'M12 22.08V12'],
                    title: l10n.settingsTransport,
                    subtitle: l10n.settingsWhatTheNetworkIs,
                    trailing: UmbraSettingsChevron(),
                    onTap: () => Navigator.push(context, haloRoute(const TransportScreen())),
                  ),
                  UmbraSettingsItem(
                    icon: ['M12 22c5.52 0 10-4.48 10-10S17.52 2 12 2 2 6.48 2 12s4.48 10 10 10z', 'M15.17 10L12 13.17 8.83 10', 'M15.17 14L12 17.17l-3.17-3.17'],
                    title: l10n.settingsBlocked,
                    trailing: UmbraSettingsChevron(),
                    onTap: () => Navigator.of(context).push(haloRoute(const BlockedScreen())),
                  ),
                  UmbraToggleRow(
                    icon: ['M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2', 'M9 11l3 3L22 4', 'M21 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'],
                    title: l10n.settingsAcceptIntroductions,
                    subtitle: l10n.settingsFriendsCanIntroduceYou,
                    value: _acceptIntros,
                    onChanged: (v) async {
                      setState(() => _acceptIntros = v);
                      await saveAcceptIntros(v);
                    },
                  ),
                  UmbraToggleRow(
                    icon: ['M12 22c5.52 0 10-4.48 10-10S17.52 2 12 2 2 6.48 2 12s4.48 10 10 10z', 'M12 6v6l4 2'],
                    title: l10n.settingsScamShield,
                    subtitle: l10n.settingsChecksStrangersOnYour,
                    value: _shieldOn,
                    onChanged: (v) async {
                      setState(() => _shieldOn = v);
                      await saveScamShieldOn(v);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Security
                  UmbraSettingsSection(title: l10n.settingsSecurity),
                  UmbraToggleRow(
                    icon: ['M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19M1 1l22 22'],
                    title: l10n.settingsBlockScreenshots,
                    subtitle: appState.blockScreenshotsPending
                        ? l10n.settingsWholeAppHiddenFrom
                        : l10n.settingsWholeAppHiddenFromRecentsAnd,
                    value: appState.blockScreenshots,
                    onChanged: (v) async {
                      await appState.setBlockScreenshots(v);
                      if (mounted) setState(() {});
                    },
                  ),
                  UmbraToggleRow(
                    icon: ['M12 3v1', 'M12 20v1', 'M4.22 4.22l.71.71', 'M19.07 19.07l.71.71', 'M1 12h1', 'M21 12h1', 'M4.22 19.78l.71-.71', 'M19.07 4.93l.71-.71'],
                    title: l10n.settingsLightTheme,
                    subtitle: l10n.settingsSameProtectionBrighter,
                    value: themeController.isLight,
                    onChanged: (v) async {
                      await appState.setLight(v);
                      if (mounted) setState(() {});
                    },
                  ),
                  UmbraSettingsItem(
                    icon: ['M12 1a2 2 0 0 1 2 2v6h2a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-6H2a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2h6a2 2 0 0 1 2-2zm0 2H2a1 1 0 0 0-1 1v6h2V3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v6h2V3a1 1 0 0 0-1-1H6a1 1 0 0 0-1 1v6h2V3a1 1 0 0 0-1-1z'],
                    title: l10n.settingsAppLock2,
                    subtitle: l10n.settingsYourPinAndA,
                    trailing: UmbraSettingsChevron(),
                    onTap: () => Navigator.of(context).push(haloRoute(const PinsScreen())),
                  ),

                  const SizedBox(height: 24),

                  // Backup
                  UmbraSettingsSection(title: l10n.settingsBackup),
                  UmbraSettingsItem(
                    icon: ['M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z', 'M17 21V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v11'],
                    title: l10n.settingsBackUpIdentity,
                    subtitle: l10n.settingsEncryptedFile,
                    trailing: UmbraSettingsChevron(),
                    onTap: () => Navigator.of(context).push(haloRoute(const BackupScreen())),
                  ),
                  UmbraSettingsItem(
                    icon: ['M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4', 'M17 4l-4 4-4-4', 'M12 15V4'],
                    title: l10n.settingsRestoreFromBackup,
                    subtitle: l10n.settingsReplaceCurrent,
                    trailing: UmbraSettingsChevron(),
                    onTap: () => Navigator.of(context).push(haloRoute(const RestoreScreen())),
                  ),

                  const SizedBox(height: 24),

                  // Voice
                  UmbraSettingsSection(title: l10n.settingsVoice),
                  UmbraToggleRow(
                    icon: ['M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z', 'M19 10v2a7 7 0 0 1-14 0v-2', 'M3 10v2a7 7 0 0 0 14 0v-2'],
                    title: l10n.settingsDisguiseVoice,
                    subtitle: l10n.settingsShiftsYourPitchBefore,
                    value: _disguise,
                    onChanged: (v) async {
                      setState(() => _disguise = v);
                      await appState.saveDisguisePref(v);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Appearance
                  UmbraSettingsSection(title: 'Appearance'),
                  UmbraThemeSelector(
                    selectedMode: themeController.mode,
                    onChanged: (mode) => themeController.setThemeMode(mode),
                  ),
                  const SizedBox(height: 16),
                  UmbraAccentGrid(
                    selectedAccent: UmbraAccent.values.firstWhere(
                      (a) => a.color == (themeController.isLight ? colors.accent : colors.accent),
                      orElse: () => themeController.isLight ? UmbraAccent.indigo : UmbraAccent.amber,
                    ),
                    onChanged: (accent) {
                      // TODO: Save accent preference
                    },
                    mode: themeController.mode,
                  ),

                  const SizedBox(height: 24),

                  // About
                  UmbraSettingsSection(title: l10n.settingsAbout),
                  UmbraSettingsItem(
                    icon: ['M12 17v4M9 12h6M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z'],
                    title: l10n.settingsWhyKryfo,
                    subtitle: l10n.settingsHowItProtectsYou,
                    trailing: UmbraSettingsChevron(),
                    onTap: () => Navigator.push(context, haloRoute(const WhyKryfoScreen())),
                  ),
                  UmbraSettingsItem(
                    icon: ['M13 2L3 14h9l-1 8 10-12h-9l1-8z', 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4', 'M7 10l5 5 5-5'],
                    title: l10n.settingsResetMyInviteLink,
                    subtitle: l10n.settingsOldLinksAndCodes,
                    trailing: UmbraSettingsChevron(),
                    onTap: () async {
                      final ok = await showConfirmSheet(
                        context,
                        title: l10n.settingsResetMyInviteLink,
                        line: l10n.settingsOldLinksAndCodesWillStop,
                        yes: l10n.commonReset,
                        keep: l10n.commonCancel,
                      );
                      if (ok && mounted) {
                        await appState.resetInviteLink();
                        showHaloToast(context, l10n.settingsInviteLinkReset);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Danger Zone
                  UmbraSettingsSection(title: l10n.settingsDangerZone),
                  UmbraDangerActionRow(
                    icon: ['M19 7l-8 8-8-8M3 7l8 8 8-8'],
                    title: l10n.settingsWipeKryfo,
                    subtitle: l10n.settingsThisDeletesEverything,
                    buttonLabel: l10n.settingsWipeKryfo,
                    onPressed: _confirmWipe,
                    buttonStyle: UmbraDangerButtonStyle.filled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
