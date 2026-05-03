import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../profile/user_profile_providers.dart';
import '../reviews/review.dart';

class AdminReviewsModerationScreen extends ConsumerStatefulWidget {
  const AdminReviewsModerationScreen({super.key});

  @override
  ConsumerState<AdminReviewsModerationScreen> createState() => _AdminReviewsModerationScreenState();
}

class _AdminReviewsModerationScreenState extends ConsumerState<AdminReviewsModerationScreen> {
  final Map<String, String> _activityTitles = {};

  Future<void> _ensureTitles(Iterable<String> ids) async {
    final need = ids.where((id) => id.isNotEmpty && !_activityTitles.containsKey(id)).toSet();
    if (need.isEmpty) return;
    final db = ref.read(firestoreProvider);
    final list = need.toList();
    for (var i = 0; i < list.length; i += 10) {
      final end = i + 10 > list.length ? list.length : i + 10;
      final chunk = list.sublist(i, end);
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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    final dash = context.dash;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reviews', style: DashboardTextStyles.pageTitle(dash)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('reviews').orderBy('createdAt', descending: true).limit(200).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) {
                  return Center(child: CircularProgressIndicator(color: dash.accentBlue));
                }
                final items = snap.data!.docs.map(Review.fromDoc).toList();
                final ids = items.map((e) => e.activityId).toSet();
                WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTitles(ids));

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
                      final r = items[i];
                      final title = _activityTitles[r.activityId] ?? '…';
                      final date = r.createdAt != null ? DateFormat('y-MM-dd').format(r.createdAt!) : '—';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          children: [
                            SizedBox(width: 110, child: Text(r.parentName, style: DashboardTextStyles.tableCell(dash))),
                            Expanded(
                              child: Text(
                                title,
                                style: DashboardTextStyles.tableCell(dash),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 84, child: _stars(r.rating, dash)),
                            SizedBox(
                              width: 180,
                              child: Text(
                                r.reviewText ?? '',
                                style: DashboardTextStyles.body(dash),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 88, child: Text(date, style: DashboardTextStyles.label(dash))),
                            SizedBox(
                              width: 36,
                              child: r.isFlagged ? const Text('🚩', style: TextStyle(fontSize: 16)) : const SizedBox(),
                            ),
                            TextButton(
                              onPressed: () async {
                                await db.doc('reviews/${r.id}').set(
                                  {'isApproved': true, 'isFlagged': false, 'updatedAt': FieldValue.serverTimestamp()},
                                  SetOptions(merge: true),
                                );
                              },
                              child: Text('Approve', style: DashboardTextStyles.label(dash).copyWith(color: dash.statusApprovedText)),
                            ),
                            TextButton(
                              onPressed: () async {
                                await db.doc('reviews/${r.id}').set(
                                  {'isFlagged': true, 'updatedAt': FieldValue.serverTimestamp()},
                                  SetOptions(merge: true),
                                );
                              },
                              child: Text('Flag', style: DashboardTextStyles.label(dash).copyWith(color: dash.statusPendingText)),
                            ),
                            TextButton(
                              onPressed: () async => db.doc('reviews/${r.id}').delete(),
                              child: Text('Delete', style: DashboardTextStyles.label(dash).copyWith(color: dash.statusRejectedText)),
                            ),
                          ],
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

  Widget _stars(int rating, DashboardTokens d) {
    return Row(
      children: List.generate(
        5,
        (i) => Text(
          i < rating ? '★' : '☆',
          style: TextStyle(color: d.starColor, fontSize: 11),
        ),
      ),
    );
  }
}
