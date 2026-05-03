import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../activities/activity.dart';
import '../profile/user_profile_providers.dart';
import '../reviews/review.dart';
import 'activity_listing_status.dart';
import 'widgets/dashboard_metric_tile.dart';
import 'widgets/dashboard_status_pill.dart';

class AdminDashboardOverview extends ConsumerWidget {
  const AdminDashboardOverview({
    super.key,
    required this.onViewPendingListings,
    required this.onViewAllListings,
  });

  final VoidCallback onViewPendingListings;
  final VoidCallback onViewAllListings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Dashboard', style: DashboardTextStyles.pageTitle(context.dash)),
                const SizedBox(height: 4),
                const SizedBox(height: 16),
                _platformCard(context, db),
                const SizedBox(height: 16),
                _recentListingsCard(context, db, onViewAllListings),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                _pendingAlertCard(context, db, onViewPendingListings),
                const SizedBox(height: 16),
                _latestReviewsCard(context, db),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _platformCard(BuildContext context, FirebaseFirestore db) {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('activities').snapshots(),
    builder: (context, actSnap) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').snapshots(),
        builder: (context, userSnap) {
          final d = context.dash;
          final loading = !actSnap.hasData || !userSnap.hasData;
          final totalListings = loading
              ? '—'
              : '${actSnap.data!.docs.where((doc) => !isDraftListing(Activity.fromDoc(doc))).length}';
          final pending = loading
              ? '—'
              : '${actSnap.data!.docs.where((doc) => (Activity.fromDoc(doc).approvalStatus.toLowerCase() == 'pending')).length}';
          final totalUsers = loading ? '—' : '${userSnap.data!.docs.length}';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: d.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: d.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Summary', style: DashboardTextStyles.cardTitle(d)),
                const SizedBox(height: 4),
                Text("Today's overview", style: DashboardTextStyles.cardSubtitle(d)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    DashboardMetricTile(
                      emoji: '📋',
                      value: totalListings,
                      label: 'Total Listings',
                      iconBackground: d.metricBlueBg,
                    ),
                    const SizedBox(width: 12),
                    DashboardMetricTile(
                      emoji: '⏳',
                      value: pending,
                      label: 'Pending Approval',
                      iconBackground: d.metricAmberBg,
                    ),
                    const SizedBox(width: 12),
                    DashboardMetricTile(
                      emoji: '👥',
                      value: totalUsers,
                      label: 'Total Users',
                      iconBackground: d.metricGreenBg,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _recentListingsCard(BuildContext context, FirebaseFirestore db, VoidCallback onViewAllListings) {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('activities').orderBy('createdAt', descending: true).limit(10).snapshots(),
    builder: (context, snap) {
      final d = context.dash;
      if (snap.hasError) {
        return Text('Error: ${snap.error}', style: DashboardTextStyles.body(d));
      }
      final docs = snap.data?.docs ?? [];
      final rows = docs.map(Activity.fromDoc).toList();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: d.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: d.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Recent Listings', style: DashboardTextStyles.cardTitle(d)),
                const Spacer(),
                TextButton(
                  onPressed: onViewAllListings,
                  style: TextButton.styleFrom(
                    backgroundColor: d.bgTertiary,
                    foregroundColor: d.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('All Listings', style: DashboardTextStyles.label(d).copyWith(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tableHeader(d),
            if (!snap.hasData)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: d.accentBlue)),
              )
            else if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No listings yet.', style: DashboardTextStyles.body(d)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, _) => Container(height: 1, color: d.bgPrimary),
                itemBuilder: (context, i) {
                  final a = rows[i];
                  final status = listingDisplayStatus(a);
                  return _recentRow(context, i + 1, a.title, a.inquiryCount, status);
                },
              ),
          ],
        ),
      );
    },
  );
}

Widget _tableHeader(DashboardTokens d) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 30, child: Text('#', style: DashboardTextStyles.tableHeader(d))),
        Expanded(flex: 3, child: Text('Activity', style: DashboardTextStyles.tableHeader(d))),
        SizedBox(
          width: 72,
          child: Text('Inquiries', style: DashboardTextStyles.tableHeader(d)),
        ),
        SizedBox(width: 100, child: Text('Status', style: DashboardTextStyles.tableHeader(d))),
      ],
    ),
  );
}

Widget _recentRow(BuildContext context, int index, String title, int inquiries, String status) {
  final d = context.dash;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          child: Text('$index', style: DashboardTextStyles.label(d)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            title.isEmpty ? '(Untitled)' : title,
            style: DashboardTextStyles.tableCell(d).copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 72,
          child: Text('$inquiries', style: DashboardTextStyles.label(d)),
        ),
        SizedBox(
          width: 100,
          child: DashboardStatusPill.forListingStatus(context, status),
        ),
      ],
    ),
  );
}

Widget _pendingAlertCard(BuildContext context, FirebaseFirestore db, VoidCallback onTap) {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('activities').snapshots(),
    builder: (context, snap) {
      final d = context.dash;
      if (!snap.hasData) {
        return _alertShell(
          d,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(color: d.accentBlue),
            ),
          ),
        );
      }
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final pendingDocs = snap.data!.docs.where((doc) {
        final a = Activity.fromDoc(doc);
        return a.approvalStatus.toLowerCase() == 'pending';
      }).toList();
      final x = pendingDocs.length;
      final y = pendingDocs.where((doc) {
        final ts = doc.data()['createdAt'];
        if (ts is! Timestamp) return false;
        final dt = ts.toDate();
        return !dt.isBefore(start);
      }).length;

      return _alertShell(
        d,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: d.statusPendingBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('⏳', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Text('Pending Reviews', style: DashboardTextStyles.cardTitle(d)),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: DashboardTextStyles.cardSubtitle(d).copyWith(fontSize: 11.5, height: 1.5),
                children: [
                  const TextSpan(text: 'You have '),
                  TextSpan(
                    text: '$x',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: d.statusPendingText,
                    ),
                  ),
                  const TextSpan(text: ' listings awaiting approval. Includes '),
                  TextSpan(
                    text: '$y',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: d.statusPendingText,
                    ),
                  ),
                  const TextSpan(text: ' new submissions today.'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: d.bgTertiary,
                  foregroundColor: d.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'View Pending Listings',
                  style: DashboardTextStyles.label(d).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: d.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _alertShell(DashboardTokens d, {required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: d.alertBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: d.alertBorder),
    ),
    child: child,
  );
}

Widget _latestReviewsCard(BuildContext context, FirebaseFirestore db) {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('reviews').orderBy('createdAt', descending: true).limit(4).snapshots(),
    builder: (context, snap) {
      final d = context.dash;
      final reviews = snap.data?.docs.map(Review.fromDoc).toList() ?? [];

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: d.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: d.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest Reviews', style: DashboardTextStyles.cardTitle(d)),
            const SizedBox(height: 12),
            if (!snap.hasData)
              Center(child: CircularProgressIndicator(color: d.accentBlue))
            else if (reviews.isEmpty)
              Text('No reviews yet.', style: DashboardTextStyles.body(d))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => Container(height: 1, color: d.borderColor),
                itemBuilder: (context, i) {
                  final r = reviews[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (r.reviewText ?? '').isEmpty ? '(No text)' : (r.reviewText ?? ''),
                            style: DashboardTextStyles.cardSubtitle(d).copyWith(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _starRow(d, r.rating),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

Widget _starRow(DashboardTokens d, int rating) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (i) => Text(
        i < rating ? '★' : '☆',
        style: TextStyle(
          color: d.starColor,
          fontSize: 11,
        ),
      ),
    ),
  );
}
