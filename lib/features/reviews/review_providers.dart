import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';
import 'review.dart';

final activityApprovedReviewsProvider = StreamProvider.family<List<Review>, String>((ref, activityId) {
  final db = ref.watch(firestoreProvider);
  final q = db
      .collection('reviews')
      .where('activityId', isEqualTo: activityId)
      .where('isApproved', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(4);
  return q.snapshots().map((s) => s.docs.map(Review.fromDoc).toList());
});

