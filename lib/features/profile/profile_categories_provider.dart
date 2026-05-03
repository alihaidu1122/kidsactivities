import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_profile_providers.dart';

/// Category labels for child "interests" chips (Firestore categories or sane defaults).
final profileInterestCategoriesProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(firestoreProvider);
  return db.collection('categories').orderBy('sortOrder').snapshots().map((s) {
    final names = s.docs
        .map((d) => (d.data()['categoryName'] as String?)?.trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isNotEmpty) return names;
    return ['Sports', 'Arts', 'Music', 'STEM', 'Outdoor', 'Dance', 'Languages'];
  });
});
