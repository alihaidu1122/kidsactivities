import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../dashboards/widgets/dashboard_status_pill.dart';
import '../inquiries/inquiry.dart';
import '../profile/user_profile_providers.dart';

class AdminInquiriesScreen extends ConsumerStatefulWidget {
  const AdminInquiriesScreen({super.key});

  @override
  ConsumerState<AdminInquiriesScreen> createState() => _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends ConsumerState<AdminInquiriesScreen> {
  final Map<String, String> _activityTitles = {};

  Future<void> _ensureTitles(Iterable<String> ids) async {
    final need = ids.where((id) => id.isNotEmpty && !_activityTitles.containsKey(id)).toSet();
    if (need.isEmpty) return;
    final db = ref.read(firestoreProvider);
    final list = need.toList();
    for (var i = 0; i < list.length; i += 10) {
      final chunk = list.sublist(i, i + 10 > list.length ? list.length : i + 10);
      final snaps = await Future.wait(chunk.map((id) => db.doc('activities/$id').get()));
      if (!mounted) return;
      setState(() {
        for (var j = 0; j < chunk.length; j++) {
          final t = snaps[j].data()?['title'] as String?;
          _activityTitles[chunk[j]] = t?.isNotEmpty == true ? t! : '—';
        }
      });
    }
  }

  static String _rel(DateTime? t) {
    if (t == null) return '—';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 48) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    final dash = context.dash;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Inquiries', style: DashboardTextStyles.pageTitle(dash)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('inquiries').orderBy('createdAt', descending: true).limit(150).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) {
                  return Center(child: CircularProgressIndicator(color: dash.accentBlue));
                }
                final items = snap.data!.docs.map(Inquiry.fromDoc).toList();
                final ids = items.map((e) => e.activityId).toSet();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _ensureTitles(ids);
                });

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: dash.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dash.borderColor),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Container(height: 1, color: dash.bgPrimary),
                    itemBuilder: (context, i) {
                      final q = items[i];
                      final title = _activityTitles[q.activityId] ?? '…';
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openDetail(context, db, q),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              child: Row(
                                children: [
                                  SizedBox(width: 120, child: Text(q.parentName, style: DashboardTextStyles.tableCell(dash))),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: DashboardTextStyles.tableCell(dash).copyWith(fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 48,
                                    child: Text(
                                      q.childAge?.toString() ?? '—',
                                      style: DashboardTextStyles.label(dash),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      q.message,
                                      style: DashboardTextStyles.body(dash),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 36, child: Text(_contactIcon(q.preferredContactMethod))),
                                  SizedBox(
                                    width: 110,
                                    child: DashboardStatusPill.forInquiryStatus(context, q.status),
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: Text(_rel(q.createdAt), style: DashboardTextStyles.label(dash)),
                                  ),
                                  TextButton(
                                    onPressed: () => _openDetail(context, db, q),
                                    child: Text('View', style: DashboardTextStyles.label(dash).copyWith(color: dash.accentBlue)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _contactIcon(String method) {
    return switch (method.toLowerCase()) {
      'email' => '📧',
      'phone' => '📱',
      _ => '✉️',
    };
  }

  void _openDetail(BuildContext context, FirebaseFirestore db, Inquiry q) {
    final ctrl = TextEditingController(text: q.providerResponse ?? '');
    final sheetDash = context.dash;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetDash.bgSecondary,
      builder: (context) {
        return Material(
          color: sheetDash.bgSecondary,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Inquiry', style: DashboardTextStyles.pageTitle(sheetDash)),
                  const SizedBox(height: 12),
                  Text(q.parentName, style: DashboardTextStyles.cardTitle(sheetDash)),
                  Text(q.parentEmail ?? q.parentPhone ?? '', style: DashboardTextStyles.body(sheetDash)),
                  const SizedBox(height: 12),
                  Text('Message', style: DashboardTextStyles.label(sheetDash)),
                  Text(q.message, style: DashboardTextStyles.body(sheetDash)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    style: DashboardTextStyles.body(sheetDash),
                    decoration: InputDecoration(
                      labelText: 'Response',
                      labelStyle: DashboardTextStyles.label(sheetDash),
                      filled: true,
                      fillColor: sheetDash.bgPrimary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      await db.doc('inquiries/${q.id}').set(
                        {
                          'providerResponse': ctrl.text.trim(),
                          'status': 'responded',
                          'respondedAt': FieldValue.serverTimestamp(),
                        },
                        SetOptions(merge: true),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save response'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
