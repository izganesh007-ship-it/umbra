// SPDX-License-Identifier: GPL-3.0-or-later
// makes an encrypted backup file and hands it to the system save dialog, or
// to the share sheet when that is refused.

import '../lock_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../backup.dart';
import '../main.dart';
import '../theme/theme.dart';
import '../widgets/fit_column.dart';
import '../widgets/stagger_in.dart';
import '../l10n/l10n.dart';
import '../l10n/numbers.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  void initState() {
    super.initState();
    appState.forceSecure(true);
  }

  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _busy = false;
  String? _error;
  // a backup to keep, or a move to another device. a move writes the mark
  // that retires this phone once the file is made
  bool _move = false;
  double _progress = 0;

  Future<void> _create() async {
    final pw = _p1.text.trim();
    final pw2 = _p2.text.trim();
    if (pw.isEmpty || pw.length < 6) {
      setState(() => _error = l10n.backupPassphraseMustBeAt);
      return;
    }
    if (pw != pw2) {
      setState(() => _error = l10n.backupPassphrasesDonTMatch);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final tempDir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final name = 'kryfo-backup-$ts.kryfo';
      final path = p.join(tempDir.path, name);
      await createBackupFile(
        pw,
        path,
        move: _move,
        onProgress: (a, b) {
          if (mounted && b > 0) setState(() => _progress = a / b);
        },
      );
      var shared = false;
      try {
        shared = await _handOver(path, name);
      } finally {
        // a shared file is read by the other app after share() returns,
        // so that one is left for the boot sweep. every other way out
        // shreds the copy here
        if (!shared) await shredFile(path);
      }
      if (_move) {
        // the file is out of our hands: from here this phone is retired,
        // and the next screen says so
        await appState.markMoved();
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  // the system save dialog first, the share sheet when that is refused.
  // neither reads the file into memory. true when the share sheet took it:
  // that app reads the file after we return, so the copy is left for the
  // boot sweep.
  Future<bool> _handOver(String path, String name) async {
    if (!mounted) return false;
    var saved = false;
    try {
      saved = await lockState.hold(
        () async =>
            await const MethodChannel('halo/platform').invokeMethod<bool>(
              'saveDocument',
              {'path': path, 'name': name},
            ) ??
            false,
      );
    } catch (_) {
      saved = false;
    }
    if (!mounted) return false;
    if (saved) {
      showHaloToast(context, l10n.backupBackupSavedKeepThe);
      return false;
    }
    return _share(path);
  }

  Future<bool> _share(String path) async {
    await lockState.hold(
      () => SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: l10n.backupKryfoBackup,
          text: l10n.backupYourEncryptedKryfoBackup,
        ),
      ),
    );
    return true;
  }

  @override
  void dispose() {
    appState.forceSecure(false);
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: colors.textSecondary),
        title: Text(
          l10n.backupBackUpKryfo,
          style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 22, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
        ),
      ),
      body: SafeArea(
        // fits or scrolls: on a short screen a plain column leaves the
        // button painted outside what can be tapped
        child: FitColumn(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: staggerAll([
            _Choice(
              on: !_move,
              title: l10n.backupBackUp,
              line: l10n.backupACopyToKeep,
              onTap: () => setState(() => _move = false),
            ),
            const SizedBox(height: 8),
            _Choice(
              on: _move,
              title: l10n.backupMoveToAnotherDevice,
              line: l10n.backupTheFileTakesThis,
              onTap: () => setState(() => _move = true),
            ),
            const SizedBox(height: 16),
            Text(
              _move
                  ? l10n.backupOneEncryptedFileYour
                  : l10n.backupOneEncryptedFileYourIdentityYour,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 24),
            _PinField(label: l10n.backupPassphrase, controller: _p1),
            const SizedBox(height: 12),
            _PinField(label: l10n.backupConfirmPassphrase, controller: _p2),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.error, height: 1.5, letterSpacing: 0),
              ),
            const Spacer(),
            GestureDetector(
              onTap: _busy ? null : _create,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _busy ? colors.surfaceHover : colors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  _busy
                      ? (_progress > 0
                            ? l10n.backupWriting(percent(_progress))
                            : l10n.backupCreating)
                      : (_move
                            ? l10n.backupMakeTheFileAnd
                            : l10n.backupCreateBackup),
                  style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w500, color: _busy ? colors.textSecondary : colors.accentOn, height: 1.5, letterSpacing: 0),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _PinField({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary, letterSpacing: 0.12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UmbraRadius.md),
          borderSide: BorderSide(color: colors.separator, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UmbraRadius.md),
          borderSide: BorderSide(color: colors.accent, width: 0.8),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final bool on;
  final String title;
  final String line;
  final VoidCallback onTap;
  const _Choice({
    required this.on,
    required this.title,
    required this.line,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const UmbraMotion.durationNormal,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: on ? colors.accentSoft : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(UmbraRadius.lg),
          border: Border.all(
            color: on ? colors.accent : colors.separator,
            width: on ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14.5, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 3),
            Text(
              line,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.4, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}
