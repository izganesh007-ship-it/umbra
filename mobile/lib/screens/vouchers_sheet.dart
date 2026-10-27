// SPDX-License-Identifier: GPL-3.0-or-later
// who vouched for this person: face, our name for them, the note they left,
// when. only vouchers we hold as accepted contacts ever get here.
import 'package:flutter/material.dart';
import '../main.dart' show db;
import '../theme/theme.dart';
import '../widgets/kryfo_avatar.dart';
import '../widgets/halo_sheet.dart';
import '../widgets/sheet_handle.dart';
import '../l10n/l10n.dart';
import '../l10n/dates.dart';

Future<void> showVouchersSheet(BuildContext context, String haloId) async {
  final rows = await db.vouchesFor(haloId);
  if (!context.mounted || rows.isEmpty) return;
  await showHaloSheet<void>(
    context,
    builder: (_) => _VouchersSheet(rows: rows),
  );
}

class _VouchersSheet extends StatelessWidget {
  final List<Map<String, Object?>> rows;
  const _VouchersSheet({required this.rows});

  String _when(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    if (now.difference(d).inDays < 1) return hourMinute(d);
    if (now.difference(d).inDays < 7) return weekdayShort(d);
    return dayMonth(d);
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              l10n.vouchersVouchedBy(rows.length),
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 20, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
            ),
          ),
          // laid out in full inside the sheet's scroll, so it scrolls as one
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: rows.length,
            itemBuilder: (_, i) =>
                _VoucherRow(row: rows[i], order: i, when: _when),
          ),
        ],
      ),
    );
  }
}

class _VoucherRow extends StatefulWidget {
  final Map<String, Object?> row;
  final int order;
  final String Function(int) when;
  const _VoucherRow({
    required this.row,
    required this.order,
    required this.when,
  });
  @override
  State<_VoucherRow> createState() => _VoucherRowState();
}

class _VoucherRowState extends State<_VoucherRow> {
  double _t = 0;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 + 40 * widget.order), () {
      if (mounted) setState(() => _t = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final r = widget.row;
    final id = r['voucher_id'] as String;
    final name = (r['nickname'] as String?) ?? id;
    final note = r['note'] as String?;
    final verified = (r['verified'] as int? ?? 0) == 1;
    return AnimatedOpacity(
      opacity: _t,
      duration: const Duration(milliseconds: 260),
      curve: UmbraMotion.easeOut,
      child: AnimatedSlide(
        offset: Offset(0, (1 - _t) * 0.1),
        duration: const UmbraMotion.durationSlow,
        curve: UmbraMotion.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KryfoAvatar(
                seed: id,
                size: 38,
                choice: (r['avatar'] as num?)?.toInt(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colors.success,
                          ),
                        ],
                      ],
                    ),
                    if (note != null && note.isNotEmpty)
                      Text(
                        note,
                        style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, fontStyle: FontStyle.italic, height: 1.3, letterSpacing: -0.015),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.when(r['created_at'] as int),
                style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
