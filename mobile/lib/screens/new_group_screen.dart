// SPDX-License-Identifier: GPL-3.0-or-later
// pick a name and members, then create and announce the group

import 'package:flutter/material.dart';
import '../main.dart' show appState;
import '../theme/theme.dart';
import '../widgets/kryfo_avatar.dart';
import 'group_chat_screen.dart';
import '../widgets/motion.dart' show haloRoute;
import '../widgets/stagger_in.dart';
import '../l10n/l10n.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});
  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _creating = false;

  bool get _canCreate =>
      _nameCtrl.text.trim().isNotEmpty && _selected.isNotEmpty && !_creating;

  Future<void> _create() async {
    setState(() => _creating = true);
    final String groupId;
    try {
      groupId = await appState.createGroupAndAnnounce(
        _nameCtrl.text.trim(),
        _selected.toList(),
      );
    } catch (e) {
      // group is full: let the user trim the list
      if (mounted) {
        setState(() => _creating = false);
        showHaloToast(
          context,
          e is StateError ? e.message : l10n.newGroupCouldNotCreate,
        );
      }
      return;
    }
    if (!mounted) return;
    // land inside the new group, like other messengers do
    Navigator.of(context).pop();
    Navigator.of(context).push(haloRoute(GroupChatScreen(groupId: groupId)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final contacts = appState.contacts;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.commonBack,
                    icon: Icon(
                      Icons.chevron_left,
                      color: colors.textPrimary,
                      size: 26,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.newGroupNewGroup,
                      style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
                    ),
                  ),
                  GestureDetector(
                    onTap: _canCreate ? _create : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _canCreate
                            ? colors.accent
                            : colors.surfaceHover,
                        borderRadius: BorderRadius.circular(UmbraRadius.md),
                      ),
                      child: Text(
                        _creating ? l10n.newGroupCreating : l10n.newGroupCreate,
                        style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w500, color: _canCreate
                              ? colors.accentOn
                              : colors.textTertiary, height: 1.5, letterSpacing: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                cursorColor: colors.accent,
                decoration: InputDecoration(
                  hintText: l10n.newGroupGroupName,
                  hintStyle: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 16, fontWeight: FontWeight.w400, color: colors.textTertiary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
                  filled: true,
                  fillColor: colors.surfaceElevated,
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Row(
                children: [
                  Text(
                    l10n.newGroupMembers,
                    style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.14),
                  ),
                  const Spacer(),
                  Text(
                    _selected.isEmpty
                        ? l10n.newGroupPickAtLeastOne
                        : l10n.newGroupSelected(_selected.length),
                    style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          l10n.newGroupAddAtLeastOne,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (_, i) {
                        final c = contacts[i];
                        final picked = _selected.contains(c.haloId);
                        return StaggerIn(
                          index: i,
                          child: InkWell(
                            onTap: () => setState(() {
                              if (picked) {
                                _selected.remove(c.haloId);
                              } else {
                                _selected.add(c.haloId);
                              }
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  KryfoAvatar(seed: c.avatarSeed, size: 36),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      c.haloId,
                                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: picked
                                          ? colors.accent
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: picked
                                            ? colors.accent
                                            : colors.separatorStrong,
                                        width: 1.4,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: picked
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: colors.accentOn,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
