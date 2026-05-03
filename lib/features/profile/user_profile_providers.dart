import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'user_role.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final idTokenRoleProvider = FutureProvider<UserRole>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return UserRole.unknown;
  final token = await user.getIdTokenResult(true);
  return UserRole.fromString(token.claims?['role'] as String?);
});

final userDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreProvider).doc('users/${user.uid}').snapshots();
});

final userRoleProvider = Provider<AsyncValue<UserRole>>((ref) {
  final tokenRole = ref.watch(idTokenRoleProvider);
  final userDoc = ref.watch(userDocProvider);
  final user = ref.watch(authStateProvider).valueOrNull;

  // Signed-out: don't combine with Firestore stream (empty stream would stall loading).
  if (user == null) {
    return tokenRole.when(
      data: (_) => const AsyncValue.data(UserRole.unknown),
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
    );
  }

  // Prefer custom claim. If missing, fall back to Firestore field for UI.
  return tokenRole.when(
    data: (role) {
      if (role != UserRole.unknown) return AsyncValue.data(role);
      return userDoc.when(
        data: (snap) {
          // First snapshots can be !exists before merge/create; avoid flashing "no role".
          if (snap == null || !snap.exists) {
            return const AsyncValue.loading();
          }
          final roleStr = snap.data()?['role'] as String?;
          final trimmed = roleStr?.trim();
          if (trimmed == null || trimmed.isEmpty) {
            return const AsyncValue.data(UserRole.parent);
          }
          return AsyncValue.data(UserRole.fromString(trimmed));
        },
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

extension _AsyncValueOrNull<T> on AsyncValue<T> {
  T? get valueOrNull => when(data: (v) => v, loading: () => null, error: (err, st) => null);
}

