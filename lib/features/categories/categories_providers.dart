import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';

class CategoryItem {
  CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? icon;
  final int sortOrder;
  final bool isActive;

  static CategoryItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return CategoryItem(
      id: doc.id,
      name: (d['categoryName'] as String?) ?? '',
      icon: d['icon'] as String?,
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: (d['isActive'] as bool?) ?? true,
    );
  }
}

final activeCategoriesProvider = StreamProvider<List<CategoryItem>>((ref) {
  final db = ref.watch(firestoreProvider);
  final q = db.collection('categories').where('isActive', isEqualTo: true).orderBy('sortOrder');
  return q.snapshots().map((s) => s.docs.map(CategoryItem.fromDoc).toList());
});

