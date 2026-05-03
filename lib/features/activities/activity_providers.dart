import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';
import 'activity.dart';

class ActivityFilters {
  const ActivityFilters({
    this.city,
    this.category,
    this.minAge,
    this.maxPrice,
    this.query,
  });

  final String? city;
  final String? category;
  final int? minAge;
  final num? maxPrice;
  final String? query;

  ActivityFilters copyWith({
    String? city,
    String? category,
    int? minAge,
    num? maxPrice,
    String? query,
  }) {
    return ActivityFilters(
      city: city ?? this.city,
      category: category ?? this.category,
      minAge: minAge ?? this.minAge,
      maxPrice: maxPrice ?? this.maxPrice,
      query: query ?? this.query,
    );
  }
}

final activityFiltersProvider =
    NotifierProvider<ActivityFiltersController, ActivityFilters>(ActivityFiltersController.new);

class ActivityFiltersController extends Notifier<ActivityFilters> {
  @override
  ActivityFilters build() => const ActivityFilters();

  void setCity(String? city) => state = ActivityFilters(
        city: city,
        category: state.category,
        minAge: state.minAge,
        maxPrice: state.maxPrice,
        query: state.query,
      );

  void setCategory(String? category) => state = ActivityFilters(
        city: state.city,
        category: category,
        minAge: state.minAge,
        maxPrice: state.maxPrice,
        query: state.query,
      );

  void setMinAge(int? minAge) => state = ActivityFilters(
        city: state.city,
        category: state.category,
        minAge: minAge,
        maxPrice: state.maxPrice,
        query: state.query,
      );
  void setSearchQuery(String? q) {
    final t = q?.trim();
    state = ActivityFilters(
      city: state.city,
      category: state.category,
      minAge: state.minAge,
      maxPrice: state.maxPrice,
      query: t == null || t.isEmpty ? null : t,
    );
  }

  void clear() => state = const ActivityFilters();
}

/// Single activity document (e.g. deep link from discover).
final activityByIdProvider = StreamProvider.autoDispose.family<Activity?, String>((ref, id) {
  final db = ref.watch(firestoreProvider);
  return db.collection('activities').doc(id).snapshots().map((s) {
    if (!s.exists) return null;
    return Activity.fromDoc(s);
  });
});

final activitiesFeedProvider = StreamProvider<List<Activity>>((ref) {
  final db = ref.watch(firestoreProvider);
  final f = ref.watch(activityFiltersProvider);

  Query<Map<String, dynamic>> q = db
      .collection('activities')
      .where('isActive', isEqualTo: true)
      .where('approvalStatus', isEqualTo: 'approved');
  if (f.city != null && f.city!.isNotEmpty) q = q.where('city', isEqualTo: f.city);
  if (f.category != null && f.category!.isNotEmpty) q = q.where('category', isEqualTo: f.category);

  // Minimal MVP: range filters need composite indexes; keep optional.
  if (f.minAge != null) q = q.where('ageRangeMin', isLessThanOrEqualTo: f.minAge);
  if (f.maxPrice != null) q = q.where('priceAmount', isLessThanOrEqualTo: f.maxPrice);

  // Basic ordering.
  q = q.orderBy('updatedAt', descending: true);

  return q.snapshots().map((snap) {
    var list = snap.docs.map(Activity.fromDoc).toList();
    final search = f.query?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      list = list
          .where(
            (a) =>
                a.title.toLowerCase().contains(search) ||
                a.category.toLowerCase().contains(search) ||
                (a.providerBusinessName ?? '').toLowerCase().contains(search),
          )
          .toList();
    }
    return list;
  });
});

