import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../dashboards/widgets/dashboard_status_pill.dart';
import '../profile/user_profile_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final dash = context.dash;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Users', style: DashboardTextStyles.pageTitle(dash)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('users').limit(250).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}', style: DashboardTextStyles.body(dash)),
                  );
                }
                if (!snap.hasData) {
                  return Center(child: CircularProgressIndicator(color: dash.accentBlue));
                }
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final ta = a.data()['createdAt'];
                    final tb = b.data()['createdAt'];
                    if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                    if (ta is Timestamp) return -1;
                    if (tb is Timestamp) return 1;
                    return 0;
                  });

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: dash.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dash.borderColor),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FixedColumnWidth(44),
                          1: FixedColumnWidth(220),
                          2: FixedColumnWidth(100),
                          3: FixedColumnWidth(100),
                          4: FixedColumnWidth(80),
                          5: FixedColumnWidth(100),
                          6: FixedColumnWidth(200),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: dash.bgPrimary),
                        ),
                        children: [
                          TableRow(
                            children: [
                              _th(dash, ''),
                              _th(dash, 'Name / Email'),
                              _th(dash, 'Role'),
                              _th(dash, 'City'),
                              _th(dash, 'Status'),
                              _th(dash, 'Joined'),
                              _th(dash, 'Actions'),
                            ],
                          ),
                          for (final doc in docs) _userRow(context, db, dash, doc),
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

  TableRow _userRow(
    BuildContext context,
    FirebaseFirestore db,
    DashboardTokens dash,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['displayName'] as String?) ?? (data['name'] as String?) ?? '';
    final email = (data['email'] as String?) ?? '';
    final role = (data['role'] as String?) ?? 'parent';
    final city = (data['city'] as String?) ?? '—';
    final active = (data['isActive'] as bool?) ?? true;
    final ts = data['createdAt'];
    final joined = ts is Timestamp ? DateFormat('y-MM-dd').format(ts.toDate()) : '—';
    final label = name.isNotEmpty ? name : (email.isNotEmpty ? email : doc.id);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: _avatar(dash, label),
        ),
        _cell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: DashboardTextStyles.tableCell(dash).copyWith(fontWeight: FontWeight.w500)),
              if (email.isNotEmpty && email != label)
                Text(email, style: DashboardTextStyles.cardSubtitle(dash).copyWith(fontSize: 10)),
            ],
          ),
        ),
        _cell(DashboardStatusPill.forUserRole(context, role)),
        _cell(Text(city, style: DashboardTextStyles.tableCell(dash))),
        _cell(Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? dash.statusApprovedText : dash.textFaint,
              ),
            ),
            const SizedBox(width: 6),
            Text(active ? 'active' : 'inactive', style: DashboardTextStyles.tableCell(dash)),
          ],
        )),
        _cell(Text(joined, style: DashboardTextStyles.tableCell(dash))),
        _cell(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.start,
            children: [
              _mini(dash, 'View', () {}),
              _mini(dash, 'Deactivate', () async {
                await doc.reference.set(
                  {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()},
                  SetOptions(merge: true),
                );
              }),
              _mini(dash, 'Delete', () async {
                await doc.reference.delete();
              }, danger: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mini(DashboardTokens dash, String label, VoidCallback onTap, {bool danger = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: danger ? dash.statusRejectedBg : dash.bgTertiary,
        foregroundColor: danger ? dash.statusRejectedText : dash.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: DashboardTextStyles.label(dash).copyWith(fontSize: 11)),
    );
  }

  Widget _avatar(DashboardTokens dash, String label) {
    final parts = label.trim().split(RegExp(r'\s+'));
    String initials;
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (label.isNotEmpty) {
      initials = label.length >= 2 ? label.substring(0, 2).toUpperCase() : label[0].toUpperCase();
    } else {
      initials = '?';
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
      ),
      child: Text(initials, style: DashboardTextStyles.statusPill(dash).copyWith(fontSize: 10, color: Colors.white)),
    );
  }

  Widget _th(DashboardTokens dash, String s) => Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(s, style: DashboardTextStyles.tableHeader(dash)),
        ),
      );

  Widget _cell(Widget child) => Padding(
        padding: const EdgeInsets.all(10),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
}
