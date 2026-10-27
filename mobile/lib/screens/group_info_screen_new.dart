// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra group info screen matching groups.html design

import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart' show appState, db;
import '../atmosphere.dart' show Atmo, atmoFromName;
import '../theme/theme.dart';
import '../rooms.dart';
import 'room_link_sheet.dart';
import '../widgets/motion.dart' show haloRoute;
import 'wallpaper_sheet.dart';
import '../widgets/stagger_in.dart';
import '../widgets/sheet_handle.dart';
import '../widgets/halo_sheet.dart';
import '../widgets/confirm_sheet.dart';
import '../l10n/l10n.dart';
import '../l10n/numbers.dart';
import '../widgets/umbra_avatar.dart';
import '../widgets/umbra_danger_button.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  const GroupInfoScreen({super.key, required this.groupId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  String _name = '';
  bool _isAdmin = false;
  String? _roomPub;
  bool get _isRoom => _roomPub != null;
  List<String> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await db.getGroup(widget.groupId);
    final members = await db.getGroupMembers(widget.groupId);
    if (!mounted) return;
    setState(() {
      _name = (g?['name'] as String?) ?? l10n.groupInfoGroup;
      _isAdmin = ((g?['is_admin'] as int?) ?? 0) == 1;
      _roomPub = g?['room_pub'] as String?;
      _members = members;
      _loading = false;
    });
  }

  Future<void> _rename() async {
    final newName = (await showInputSheet(
      context,
      title: l10n.groupInfoRenameGroup,
      initial: _name,
      save: l10n.groupInfoRename,
    ))?.trim();
    if (newName != null && newName.isNotEmpty && newName != _name) {
      await appState.renameGroupAndAnnounce(widget.groupId, newName);
      await _load();
    }
  }

  Future<void> _addMembers() async {
    final available = appState.contacts
        .where((c) => !_members.contains(c.haloId))
        .toList();
    if (available.isEmpty) {
      showHaloToast(context, l10n.groupInfoNoContactsToAdd);
      return;
    }
    final picked = await showHaloSheet<Set<String>>(
      context,
      scroll: true,
      builder: (c) => _AddMemberSheet(available: available),
    );
    if (picked != null && picked.isNotEmpty) {
      try {
        await appState.addMembersToGroup(widget.groupId, picked.toList());
      } catch (e) {
        if (mounted) {
          showHaloToast(
            context,
            e is StateError ? e.message : l10n.groupInfoCouldNotAdd,
          );
        }
        return;
      }
      await _load();
    }
  }

  Future<void> _confirmRemove(String haloId) async {
    final ok = await showConfirmSheet(
      context,
      title: l10n.groupInfoRemove(haloId),
      line: l10n.groupInfoTheyWillStopReceiving,
      yes: l10n.commonRemove,
    );
    if (ok == true) {
      await appState.removeMembersFromGroup(widget.groupId, [haloId]);
      await _load();
    }
  }

  Future<void> _pickAtmosphere() async {
    final current = atmoFromName(await db.getGroupAtmosphere(widget.groupId));
    if (!mounted) return;
    final picked = await showWallpaperSheet(context, current);
    if (picked is! Atmo) return;
    HapticFeedback.selectionClick();
    await db.setGroupAtmosphere(widget.groupId, picked.name);
  }

  Future<void> _openSharedMedia() async {
    final rows = await db.loadGroupMessages(widget.groupId);
    final paths = <String>[];
    for (final r in rows) {
      final mp = r['media_path'] as String?;
      if (mp != null && mp.isNotEmpty && await File(mp).exists()) {
        paths.add(mp);
      }
    }
    if (!mounted) return;
    Navigator.of(context).push(
      haloRoute(
        MediaGalleryScreen(paths: paths.reversed.toList(), title: _name),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showConfirmSheet(
      context,
      title: l10n.groupInfoClearThisConversation,
      line: l10n.groupInfoEveryMessageHereIs,
      yes: l10n.groupInfoClear,
    );
    if (ok == true) {
      await db.clearGroupConversation(widget.groupId);
      if (!mounted) return;
      showHaloToast(context, l10n.groupInfoConversationCleared);
    }
  }

  Future<void> _confirmLeave() async {
    final ok = await showConfirmSheet(
      context,
      title: _isRoom ? l10n.groupInfoLeaveRoom : l10n.groupInfoLeaveGroup,
      line: _isRoom
          ? l10n.groupInfoEverythingInItIs
          : l10n.groupInfoYouWillStopReceiving,
      yes: l10n.groupInfoLeave,
    );
    if (ok == true) {
      await appState.leaveGroupAndAnnounce(widget.groupId);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: CircularProgressIndicator(color: colors.accent)),
      );
    }

    final myId = appState.myId;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.commonBack,
                    icon: Icon(Icons.chevron_left, color: colors.textPrimary, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.groupInfoGroupInfo,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSerif,
                        fontSize: 18,
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
            const SizedBox(height: 8),
            // Group identity
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.45),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _name.isEmpty
                          ? '·'
                          : _name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSerif,
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: colors.accent,
                        fontStyle: FontStyle.italic,
                        height: 1.05,
                        letterSpacing: -0.015,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _isAdmin && !_isRoom ? _rename : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _name,
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
                        if (_isAdmin && !_isRoom) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined, size: 16, color: colors.textTertiary),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.groupInfo1Member(_members.length),
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textTertiary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.groupInfoAdmin,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Members header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    l10n.groupInfoMembers2,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.textTertiary,
                      letterSpacing: 0.14,
                    ),
                  ),
                  const Spacer(),
                  if (_isRoom)
                    GestureDetector(
                      onTap: () async {
                        final link = await appState.roomLinkFor(widget.groupId);
                        if (link != null && context.mounted) {
                          await showRoomLinkSheet(context, link);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2_outlined, size: 14, color: colors.accent),
                          const SizedBox(width: 4),
                          Text(
                            l10n.groupInfoInvite,
                            style: TextStyle(
                              fontFamily: UmbraTypography.fontMono,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.accent,
                              letterSpacing: 0.14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isAdmin && !_isRoom)
                    GestureDetector(
                      onTap: _addMembers,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: colors.accent),
                          const SizedBox(width: 3),
                          Text(
                            l10n.commonAdd,
                            style: TextStyle(
                              fontFamily: UmbraTypography.fontMono,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.accent,
                              letterSpacing: 0.14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Members list
            Expanded(
              child: ListView.builder(
                itemCount: _members.length,
                itemBuilder: (_, i) {
                  final m = _members[i];
                  final isMe = m == myId || (_isRoom && m == _roomPub);
                  return StaggerIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          UmbraAvatar(seed: m, size: UmbraAvatarSize.md),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  looksLikeRoomKey(m) ? roomTag(m) : m,
                                  style: looksLikeRoomKey(m)
                                      ? TextStyle(
                                          fontFamily: UmbraTypography.fontMono,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textPrimary,
                                          letterSpacing: 0.12,
                                        )
                                      : TextStyle(
                                          fontFamily: UmbraTypography.fontSans,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textPrimary,
                                          height: 1.5,
                                          letterSpacing: 0,
                                        ),
                                ),
                                if (isMe)
                                  Text(
                                    l10n.groupInfoYou,
                                    style: TextStyle(
                                      fontFamily: UmbraTypography.fontMono,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: colors.accent,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_isAdmin && !isMe)
                            IconButton(
                              tooltip: l10n.groupInfoRemoveFromGroup,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                                color: colors.textTertiary,
                              ),
                              onPressed: () => _confirmRemove(m),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: _pickAtmosphere,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(UmbraRadius.lg),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.groupInfoWallpaper,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: _openSharedMedia,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(UmbraRadius.lg),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.groupInfoSharedMedia,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: _confirmClear,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(UmbraRadius.lg),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.groupInfoClearConversation,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            // Danger zone - Leave
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: UmbraDangerButton(
                label: _isRoom ? l10n.groupInfoLeaveRoom : l10n.groupInfoLeaveGroup,
                onPressed: _confirmLeave,
                icon: ['M10 19l-7-7 7-7', 'M3 12h18'],
                style: UmbraDangerButtonStyle.filled,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberSheet extends StatelessWidget {
  final List<Contact> available;

  const _AddMemberSheet({required this.available});

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;
    final selected = <String>{};

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Text(
                    l10n.groupInfoAddMembers,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSerif,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: colors.textPrimary,
                      fontStyle: FontStyle.italic,
                      height: 1.05,
                      letterSpacing: -0.015,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${selected.length} ${l10n.groupInfoSelected}',
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
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                itemCount: available.length,
                itemBuilder: (_, i) {
                  final c = available[i];
                  final picked = selected.contains(c.haloId);
                  return InkWell(
                    onTap: () => setState(() {
                      if (picked) {
                        selected.remove(c.haloId);
                      } else {
                        selected.add(c.haloId);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          UmbraAvatar(seed: c.avatarSeed, size: UmbraAvatarSize.md),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.haloId,
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: picked ? colors.accent : Colors.transparent,
                              border: Border.all(
                                color: picked ? colors.accent : colors.separatorStrong,
                                width: 1.4,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: picked
                                ? Icon(Icons.check_rounded, size: 14, color: colors.accentOn)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.separator),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UmbraRadius.lg),
                        ),
                      ),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () => Navigator.pop(context, selected),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: colors.accent,
                        foregroundColor: colors.accentOn,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UmbraRadius.lg),
                        ),
                      ),
                      child: Text(l10n.groupInfoAdd),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Mock MediaGalleryScreen for compilation
class MediaGalleryScreen extends StatelessWidget {
  final List<String> paths;
  final String title;
  const MediaGalleryScreen({required this.paths, required this.title, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}
