import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  Review({
    required this.id,
    required this.activityId,
    required this.parentUserId,
    required this.providerUserId,
    required this.parentName,
    required this.rating,
    required this.reviewText,
    required this.isApproved,
    required this.isFlagged,
    required this.createdAt,
  });

  final String id;
  final String activityId;
  final String parentUserId;
  final String providerUserId;
  final String parentName;
  final int rating;
  final String? reviewText;
  final bool isApproved;
  final bool isFlagged;
  final DateTime? createdAt;

  static Review fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Review(
      id: doc.id,
      activityId: (d['activityId'] as String?) ?? '',
      parentUserId: (d['parentUserId'] as String?) ?? '',
      providerUserId: (d['providerUserId'] as String?) ?? '',
      parentName: (d['parentName'] as String?) ?? 'Anonymous',
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      reviewText: d['reviewText'] as String?,
      isApproved: (d['isApproved'] as bool?) ?? true,
      isFlagged: (d['isFlagged'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

