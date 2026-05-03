import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../activities/activity.dart';
import '../auth/auth_providers.dart';
import '../inquiries/inquiry.dart';
import '../profile/user_profile_providers.dart';
import '../reviews/review.dart';
import '../provider/create_activity_screen.dart';
import 'widgets/dashboard_metric_tile.dart';

class ProviderDashboardOverview extends ConsumerWidget {
  const ProviderDashboardOverview({
    super.key,
    required this.onViewInquiries,
  });

  final VoidCallback onViewInquiries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = context.dash;
    final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
    if (user == null) {
      return Center(child: CircularProgressIndicator(color: d.accentBlue));
    }
    final db = ref.watch(firestoreProvider);
    final activitiesQ = db.collection('activities').where('providerUserId', isEqualTo: user.uid);
    final inquiriesQ = db.collection('inquiries').where('providerUserId', isEqualTo: user.uid);
    final reviewsStream = db.collection('reviews').where('providerUserId', isEqualTo: user.uid).limit(24).snapshots();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Dashboard', style: DashboardTextStyles.pageTitle(d)),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: activitiesQ.snapshots(),
                  builder: (context, actSnap) {
                    final dx = context.dash;
                    if (!actSnap.hasData) {
                      return _metricsLoading(dx);
                    }
                    final acts = actSnap.data!.docs.map(Activity.fromDoc).toList();
                    final activeApproved = acts
                        .where((a) => a.approvalStatus.toLowerCase() == 'approved' && a.isActive)
                        .length;
                    final totalInq = acts.fold<int>(0, (s, a) => s + a.inquiryCount);
                    final totalViews = acts.fold<int>(0, (s, a) => s + a.viewCount);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dx.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dx.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My performance', style: DashboardTextStyles.cardTitle(dx)),
                          const SizedBox(height: 4),
                          Text('Overview of your listings', style: DashboardTextStyles.cardSubtitle(dx)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              DashboardMetricTile(
                                emoji: '📋',
                                value: '$activeApproved',
                                label: 'Active listings',
                                iconBackground: dx.metricBlueBg,
                              ),
                              const SizedBox(width: 12),
                              DashboardMetricTile(
                                emoji: '💬',
                                value: '$totalInq',
                                label: 'Inquiries received',
                                iconBackground: dx.metricAmberBg,
                              ),
                              const SizedBox(width: 12),
                              DashboardMetricTile(
                                emoji: '👁️',
                                value: '$totalViews',
                                label: 'Total views',
                                iconBackground: dx.metricGreenBg,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateActivityScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: d.accentBlue,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark ? d.textPrimary : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.dark ? d.textPrimary : Colors.white,
                    ),
                    label: Text(
                      'New listing',
                      style: DashboardTextStyles.button(d).copyWith(
                        color: Theme.of(context).brightness == Brightness.dark ? d.textPrimary : Colors.white,
                      ),
                    ),
                  ),
                ),
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
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: inquiriesQ.snapshots(),
                  builder: (context, inqSnap) {
                    final dx = context.dash;
                    if (!inqSnap.hasData) {
                      return _sideCard(
                        dx,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: dx.accentBlue),
                          ),
                        ),
                      );
                    }
                    final list = inqSnap.data!.docs.map(Inquiry.fromDoc).toList();
                    final unread = list.where((q) => q.status.toLowerCase() == 'new').length;
                    return _sideCard(
                      dx,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unread inquiries', style: DashboardTextStyles.cardTitle(dx)),
                          const SizedBox(height: 12),
                          Text(
                            '$unread new',
                            style: DashboardTextStyles.metricValue(dx),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: onViewInquiries,
                              style: TextButton.styleFrom(
                                backgroundColor: dx.bgTertiary,
                                foregroundColor: dx.textSecondary,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                'View Inquiries',
                                style: DashboardTextStyles.label(dx).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: dx.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: reviewsStream,
                  builder: (context, revSnap) {
                    final dx = context.dash;
                    var items = revSnap.data?.docs.map(Review.fromDoc).toList() ?? [];
                    items = items.toList()
                      ..sort((a, b) {
                        final ta = a.createdAt;
                        final tb = b.createdAt;
                        if (ta == null && tb == null) return 0;
                        if (ta == null) return 1;
                        if (tb == null) return -1;
                        return tb.compareTo(ta);
                      });
                    items = items.take(4).toList();

                    return _sideCard(
                      dx,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Latest reviews', style: DashboardTextStyles.cardTitle(dx)),
                          const SizedBox(height: 12),
                          if (!revSnap.hasData)
                            Center(child: CircularProgressIndicator(color: dx.accentBlue))
                          else if (items.isEmpty)
                            Text('No reviews yet.', style: DashboardTextStyles.body(dx))
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items
                                  .map(
                                    (r) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.reviewText ?? '(No text)',
                                              style: DashboardTextStyles.cardSubtitle(dx).copyWith(fontSize: 11),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _stars(dx, r.rating),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsLoading(DashboardTokens d) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: d.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d.borderColor),
      ),
      child: CircularProgressIndicator(color: d.accentBlue),
    );
  }

  Widget _sideCard(DashboardTokens d, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: d.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d.borderColor),
      ),
      child: child,
    );
  }

  Widget _stars(DashboardTokens d, int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
