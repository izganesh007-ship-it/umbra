// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import '../widgets/stagger_in.dart';
import '../widgets/breathing_ring.dart';
import '../main.dart';
import '../theme/theme.dart';
import '../l10n/l10n.dart';
import '../l10n/dates.dart';

const String kNotesPeerId = '_notes_self_';

// note to self: never leaves the phone, stored as messages under the
// reserved kNotesPeerId
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, Object?>> _notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await db.messagesFor(kNotesPeerId);
    if (!mounted) return;
    setState(() => _notes = rows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _save() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    await db.saveMessage(kNotesPeerId, 'in', text);
    _input.clear();
    await _load();
  }

  bool _sameDay(int a, int b) {
    if (a == 0 || b == 0) return false;
    final da = DateTime.fromMillisecondsSinceEpoch(a);
    final dbb = DateTime.fromMillisecondsSinceEpoch(b);
    return da.year == dbb.year && da.month == dbb.month && da.day == dbb.day;
  }

  String _dayLabel(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return l10n.notesToday;
    if (diff == 1) return l10n.notesYesterday;
    return dateCaps(dayMonth(d));
  }

  Widget _dayDivider(int ms) => Center(
    child: Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _dayLabel(ms),
        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 8.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12).copyWith(letterSpacing: track(1.6)),
      ),
    ),
  );

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
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notesNoteToSelf,
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 20, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
            ),
            Text(
              l10n.notesOnlyOnThisPhone,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _notes.isEmpty
                  ? _empty()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: _notes.length,
                      itemBuilder: (_, i) {
                        final n = _notes[i];
                        final text = n['plaintext'] as String? ?? '';
                        final ts = n['sent_at'] as int? ?? 0;
                        final prevTs = i == 0
                            ? 0
                            : (_notes[i - 1]['sent_at'] as int? ?? 0);
                        final showDay = !_sameDay(ts, prevTs);
                        // fade older notes so the newest read brightest
                        final fresh = i >= _notes.length - 2;
                        return StaggerIn(
                          index: i,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDay) _dayDivider(ts),
                              _NoteBubble(text: text, ts: ts, fresh: fresh),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: StaggerIn(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BreathingRing(
                size: 98,
                core: 66,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: colors.accent,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.notesAQuietPlace,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 24, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.notesJotAnythingDownIt,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.55, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.separator, width: 0.5)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(UmbraRadius.radius2xl),
                border: Border.all(color: colors.separator, width: 0.5),
              ),
              child: TextField(
                controller: _input,
                maxLines: 5,
                minLines: 1,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                decoration: InputDecoration(
                  hintText: l10n.notesJotSomethingDown,
                  hintStyle: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textTertiary, height: 1.5, letterSpacing: 0),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _save,
            child: Semantics(
              label: l10n.commonSave,
              button: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: colors.accentOn,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBubble extends StatelessWidget {
  final String text;
  final int ts;
  final bool fresh;
  const _NoteBubble({required this.text, required this.ts, this.fresh = true});

  String _time() {
    if (ts == 0) return '';
    return hourMinute(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.accent.withValues(alpha: fresh ? 1 : 0.4),
                    colors.accent.withValues(alpha: fresh ? 0.35 : 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                decoration: BoxDecoration(
                  color: colors.surfaceHover,
                  borderRadius: BorderRadius.circular(UmbraRadius.lg),
                  border: Border.all(color: colors.separatorStrong, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14.5, fontWeight: FontWeight.w400, color: fresh ? colors.textPrimary : colors.textSecondary, height: 1.5, letterSpacing: 0),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _time(),
                      style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
