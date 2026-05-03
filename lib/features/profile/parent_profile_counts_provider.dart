import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'user_profile_providers.dart';

class ParentProfileCounts {
  const ParentProfileCounts({
    required this.children,
    required this.inquiries,
    required this.reviews,
  });

  final int children;
  final int inquiries;
  final int reviews;
}

/// Live counts for the parent profile summary card (children subcollection + root inquiries/reviews).
final parentProfileCountsProvider = StreamProvider<ParentProfileCounts>((ref) {
  final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
  if (user == null) return const Stream.empty();
  final db = ref.watch(firestoreProvider);
  final uid = user.uid;

  return Stream.multi((controller) {
    var childrenN = 0;
    var inquiriesN = 0;
    var reviewsN = 0;

    void emit() {
      if (controller.isClosed) return;
      controller.add(ParentProfileCounts(
        children: childrenN,
        inquiries: inquiriesN,
        reviews: reviewsN,
      ));
    }

    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    subs.add(
      db.collection('users').doc(uid).collection('children').snapshots().listen((s) {
        childrenN = s.docs.length;
        emit();
      }),
    );
    subs.add(
      db.collection('inquiries').where('parentUserId', isEqualTo: uid).snapshots().listen((s) {
        inquiriesN = s.docs.length;
        emit();
      }),
    );
    subs.add(
      db.collection('reviews').where('parentUserId', isEqualTo: uid).snapshots().listen((s) {
        reviewsN = s.docs.length;
        emit();
      }),
    );

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
  });
});
