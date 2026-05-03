import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../profile/user_profile_providers.dart';

/// Aggregate counts + last-7-day inquiry buckets (day 0 = six days ago, 6 = today).
class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.totalActivities,
    required this.totalUsers,
    required this.pendingListings,
    required this.inquiriesLast7Days,
    required this.reviewsCount,
  });

  final int totalActivities;
  final int totalUsers;
  final int pendingListings;
  final List<int> inquiriesLast7Days;
  final int reviewsCount;

  int get maxDailyInquiries =>
      inquiriesLast7Days.isEmpty ? 0 : inquiriesLast7Days.reduce((a, b) => a > b ? a : b);
}

final adminAnalyticsProvider = FutureProvider.autoDispose<AdminAnalyticsData>((ref) async {
  final db = ref.watch(firestoreProvider);
  final activitiesCount = (await db.collection('activities').count().get()).count ?? 0;
  final usersCount = (await db.collection('users').count().get()).count ?? 0;
  final pendingCount =
      (await db.collection('activities').where('approvalStatus', isEqualTo: 'pending').count().get()).count ??
          0;
  final reviewsCount = (await db.collection('reviews').count().get()).count ?? 0;

  final inqSnap = await db.collection('inquiries').orderBy('createdAt', descending: true).limit(800).get();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final buckets = List.filled(7, 0);
  for (final doc in inqSnap.docs) {
    final c = doc.data()['createdAt'];
    if (c is! Timestamp) continue;
    final dt = c.toDate();
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff < 0 || diff >= 7) continue;
    buckets[6 - diff]++;
  }

  return AdminAnalyticsData(
    totalActivities: activitiesCount,
    totalUsers: usersCount,
    pendingListings: pendingCount,
    inquiriesLast7Days: buckets,
    reviewsCount: reviewsCount,
  );
});

class ProviderAnalyticsData {
  const ProviderAnalyticsData({
    required this.listingCount,
    required this.totalViews,
    required this.totalInquiriesOnListings,
    required this.inquiriesLast7Days,
    required this.topListingsByViews,
  });

  final int listingCount;
  final int totalViews;
  final int totalInquiriesOnListings;
  final List<int> inquiriesLast7Days;
  final List<(String title, int views)> topListingsByViews;

  int get maxDailyInquiries =>
      inquiriesLast7Days.isEmpty ? 0 : inquiriesLast7Days.reduce((a, b) => a > b ? a : b);

  int get maxBarViews =>
      topListingsByViews.isEmpty ? 0 : topListingsByViews.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
}

final providerAnalyticsProvider = FutureProvider.autoDispose<ProviderAnalyticsData>((ref) async {
  final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
  final db = ref.watch(firestoreProvider);
  if (user == null) {
    return const ProviderAnalyticsData(
      listingCount: 0,
      totalViews: 0,
      totalInquiriesOnListings: 0,
      inquiriesLast7Days: [0, 0, 0, 0, 0, 0, 0],
      topListingsByViews: [],
    );
  }

  final actsSnap =
      await db.collection('activities').where('providerUserId', isEqualTo: user.uid).limit(100).get();

  var totalViews = 0;
  var totalInq = 0;
  final listings = <(String, int)>[];
  for (final doc in actsSnap.docs) {
    final d = doc.data();
    final v = (d['viewCount'] as num?)?.toInt() ?? 0;
    final iq = (d['inquiryCount'] as num?)?.toInt() ?? 0;
    totalViews += v;
    totalInq += iq;
    final title = (d['title'] as String?) ?? '';
    listings.add((title.isEmpty ? 'Listing' : title, v));
  }
  listings.sort((a, b) => b.$2.compareTo(a.$2));
  final top = listings.take(6).toList();

  final inqSnap = await db.collection('inquiries').where('providerUserId', isEqualTo: user.uid).get();
  final docs = inqSnap.docs.toList()
    ..sort((a, b) {
      final ta = a.data()['createdAt'];
      final tb = b.data()['createdAt'];
      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
      if (ta is Timestamp) return -1;
      if (tb is Timestamp) return 1;
      return 0;
    });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final buckets = List.filled(7, 0);
  for (final doc in docs.take(500)) {
    final c = doc.data()['createdAt'];
    if (c is! Timestamp) continue;
    final dt = c.toDate();
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff < 0 || diff >= 7) continue;
    buckets[6 - diff]++;
  }

  return ProviderAnalyticsData(
    listingCount: actsSnap.docs.length,
    totalViews: totalViews,
    totalInquiriesOnListings: totalInq,
    inquiriesLast7Days: buckets,
    topListingsByViews: top,
  );
});
