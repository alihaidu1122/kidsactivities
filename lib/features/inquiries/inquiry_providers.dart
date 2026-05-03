import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';
import '../auth/auth_providers.dart';
import 'inquiry.dart';

final mySentInquiriesProvider = StreamProvider<List<Inquiry>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  final db = ref.watch(firestoreProvider);
  final q = db
      .collection('inquiries')
      .where('parentUserId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true);
  return q.snapshots().map((s) => s.docs.map(Inquiry.fromDoc).toList());
});

final providerInboxProvider = StreamProvider<List<Inquiry>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  final db = ref.watch(firestoreProvider);
  final q = db
      .collection('inquiries')
      .where('providerUserId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true);
  return q.snapshots().map((s) => s.docs.map(Inquiry.fromDoc).toList());
});

extension _AsyncValueOrNull<T> on AsyncValue<T> {
  T? get valueOrNull => when(data: (v) => v, loading: () => null, error: (err, st) => null);
}

