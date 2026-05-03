import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../activities/activity.dart';
import '../dashboards/activity_listing_status.dart';
import '../dashboards/widgets/dashboard_status_pill.dart';
import '../profile/user_profile_providers.dart';

class AdminListingsManageScreen extends ConsumerStatefulWidget {
  const AdminListingsManageScreen({super.key, this.initialFilter = 'all'});

  /// all | pending | approved | rejected | inactive | draft
  final String initialFilter;

  @override
  ConsumerState<AdminListingsManageScreen> createState() => _AdminListingsManageScreenState();
}

class _AdminListingsManageScreenState extends ConsumerState<AdminListingsManageScreen> {
  late String _filter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilter(Activity a) {
    final display = listingDisplayStatus(a);
    return switch (_filter) {
      'all' => true,
      'pending' => display == 'pending',
      'approved' => display == 'approved',
      'rejected' => display == 'rejected',
      'inactive' => display == 'inactive',
      'draft' => display == 'draft',
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    final d = context.dash;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Listings', style: DashboardTextStyles.pageTitle(d)),
          const SizedBox(height: 16),
          Row(
            children: [
              _chip(d, 'All', 'all'),
              const SizedBox(width: 8),
              _chip(d, 'Pending', 'pending'),
              const SizedBox(width: 8),
              _chip(d, 'Approved', 'approved'),
              const SizedBox(width: 8),
              _chip(d, 'Rejected', 'rejected'),
              const SizedBox(width: 8),
              _chip(d, 'Inactive', 'inactive'),
              const SizedBox(width: 8),
              _chip(d, 'Draft', 'draft'),
              const Spacer(),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: DashboardTextStyles.body(d),
                  spellCheckConfiguration: SpellCheckConfiguration.disabled(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search…',
                    hintStyle: DashboardTextStyles.label(d).copyWith(color: d.textFaint),
                    filled: true,
                    fillColor: d.bgPrimary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: d.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: d.accentBlue),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('activities').orderBy('createdAt', descending: true).limit(400).snapshots(),
              builder: (context, snap) {
                final dx = context.dash;
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) {
                  return Center(child: CircularProgressIndicator(color: dx.accentBlue));
                }
                final q = _searchCtrl.text.trim().toLowerCase();
                final items = snap.data!.docs
                    .map(Activity.fromDoc)
                    .where(_matchesFilter)
                    .where((a) {
                      if (q.isEmpty) return true;
                      return a.title.toLowerCase().contains(q) ||
                          (a.providerBusinessName ?? '').toLowerCase().contains(q) ||
                          a.city.toLowerCase().contains(q);
                    })
                    .toList();

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: dx.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dx.borderColor),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FixedColumnWidth(40),
                          1: FixedColumnWidth(220),
                          2: FixedColumnWidth(140),
                          3: FixedColumnWidth(100),
                          4: FixedColumnWidth(90),
                          5: FixedColumnWidth(72),
                          6: FixedColumnWidth(110),
                          7: FixedColumnWidth(220),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: dx.bgPrimary),
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: dx.bgSecondary),
                            children: [
                              _th(dx, '#'),
                              _th(dx, 'Activity'),
                              _th(dx, 'Provider'),
                              _th(dx, 'City'),
                              _th(dx, 'Age range'),
                              _th(dx, 'Inq.'),
                              _th(dx, 'Status'),
                              _th(dx, 'Actions'),
                            ],
                          ),
                          for (var i = 0; i < items.length; i++) _dataRow(context, db, i + 1, items[i]),
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
    );
  }

  Widget _chip(DashboardTokens d, String label, String value) {
    final on = _filter == value;
    return TextButton(
      onPressed: () => setState(() => _filter = value),
      style: TextButton.styleFrom(
        backgroundColor: on ? d.accentBlue : d.bgTertiary,
        foregroundColor:
            on ? (Theme.of(context).brightness == Brightness.dark ? d.textPrimary : Colors.white) : d.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: DashboardTextStyles.filterChip(d)),
    );
  }

  TableRow _dataRow(BuildContext context, FirebaseFirestore db, int index, Activity a) {
    final d = context.dash;
    final status = listingDisplayStatus(a);
    return TableRow(
      children: [
        _td(Text('$index', style: DashboardTextStyles.label(d))),
        _td(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                a.title.isEmpty ? '(Untitled)' : a.title,
                style: DashboardTextStyles.tableCell(d).copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                a.category,
                style: DashboardTextStyles.cardSubtitle(d).copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _td(Text(a.providerBusinessName ?? '—', style: DashboardTextStyles.tableCell(d))),
        _td(Text(a.city, style: DashboardTextStyles.tableCell(d))),
        _td(Text('${a.ageRangeMin}–${a.ageRangeMax}', style: DashboardTextStyles.tableCell(d))),
        _td(Text('${a.inquiryCount}', style: DashboardTextStyles.tableCell(d))),
        _td(DashboardStatusPill.forListingStatus(context, status)),
        _td(
          Row(
            children: [
              if (status == 'pending')
                _miniAction(
                  d,
                  'Approve',
                  bg: d.statusApprovedBg,
                  fg: d.statusApprovedText,
                  onTap: () => _approve(db, a.id),
                ),
              if (status == 'pending') const SizedBox(width: 6),
              if (status == 'pending')
                _miniAction(
                  d,
                  'Reject',
                  bg: d.statusRejectedBg,
                  fg: d.statusRejectedText,
                  onTap: () => _reject(context, db, a.id),
                ),
              const SizedBox(width: 6),
              _miniAction(
                d,
                'Delete',
                bg: d.bgTertiary,
                fg: d.textMuted,
                onTap: () => _delete(context, db, a.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniAction(
    DashboardTokens d,
    String label, {
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: DashboardTextStyles.label(d).copyWith(fontSize: 11, color: fg)),
    );
  }

  Future<void> _approve(FirebaseFirestore db, String id) async {
    await db.doc('activities/$id').set(
      {
        'approvalStatus': 'approved',
        'rejectionReason': null,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _reject(BuildContext context, FirebaseFirestore db, String id) async {
    final reason = await showDialog<String>(context: context, builder: (context) => const _RejectListingDialog());
    if (reason == null) return;
    await db.doc('activities/$id').set(
      {
        'approvalStatus': 'rejected',
        'rejectionReason': reason.trim().isEmpty ? 'Rejected' : reason.trim(),
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _delete(BuildContext context, FirebaseFirestore db, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dx = ctx.dash;
        return AlertDialog(
        backgroundColor: dx.bgSecondary,
        title: Text('Delete listing?', style: DashboardTextStyles.cardTitle(dx)),
        content: Text('This cannot be undone.', style: DashboardTextStyles.body(dx)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      );
      },
    );
    if (ok != true) return;
    await db.doc('activities/$id').delete();
  }

  Widget _th(DashboardTokens d, String s) => Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(s, style: DashboardTextStyles.tableHeader(d)),
        ),
      );

  Widget _td(Widget child) => Padding(
        padding: const EdgeInsets.all(10),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
}

class _RejectListingDialog extends StatefulWidget {
  const _RejectListingDialog();

  @override
  State<_RejectListingDialog> createState() => _RejectListingDialogState();
}

class _RejectListingDialogState extends State<_RejectListingDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    return AlertDialog(
      backgroundColor: d.bgSecondary,
      title: Text('Reject listing', style: DashboardTextStyles.cardTitle(d)),
      content: TextField(
        controller: _ctrl,
        spellCheckConfiguration: SpellCheckConfiguration.disabled(),
        decoration: InputDecoration(
          hintText: 'Reason (optional)',
          hintStyle: DashboardTextStyles.label(d).copyWith(color: d.textFaint),
          filled: true,
          fillColor: d.bgPrimary,
        ),
        style: DashboardTextStyles.body(d),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Reject')),
      ],
    );
  }
}
