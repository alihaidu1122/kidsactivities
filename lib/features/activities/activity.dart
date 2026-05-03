import 'package:cloud_firestore/cloud_firestore.dart';

import 'activity_media.dart';

class Activity {
  Activity({
    required this.id,
    required this.providerUserId,
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    required this.ageRangeMin,
    required this.ageRangeMax,
    required this.priceAmount,
    required this.priceType,
    required this.isActive,
    required this.approvalStatus,
    required this.rejectionReason,
    required this.providerBusinessName,
    required this.viewCount,
    required this.inquiryCount,
    required this.thumbnailUrl,
    required this.photoUrls,
  });

  final String id;
  final String providerUserId;
  final String title;
  final String description;
  final String category;
  final String city;
  final int ageRangeMin;
  final int ageRangeMax;
  final num? priceAmount;
  final String? priceType;
  final bool isActive;
  final String approvalStatus; // pending|approved|rejected
  final String? rejectionReason;
  final String? providerBusinessName;
  final int viewCount;
  final int inquiryCount;
  /// Cover image for lists and cards (Firebase Storage download URL).
  final String? thumbnailUrl;
  /// Gallery image URLs (may overlap with thumbnail).
  final List<String> photoUrls;

  static Activity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final photos = parsePhotoUrlList(
      d['photos'] ?? d['photoUrls'] ?? d['images'] ?? d['imageUrls'],
    );
    final thumb = pickThumbnailUrl(d, photos);

    return Activity(
      id: doc.id,
      providerUserId: (d['providerUserId'] as String?) ?? '',
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      ageRangeMin: (d['ageRangeMin'] as num?)?.toInt() ?? 0,
      ageRangeMax: (d['ageRangeMax'] as num?)?.toInt() ?? 0,
      priceAmount: d['priceAmount'] as num?,
      priceType: d['priceType'] as String?,
      isActive: (d['isActive'] as bool?) ?? true,
      approvalStatus: (d['approvalStatus'] as String?) ?? 'approved',
      rejectionReason: d['rejectionReason'] as String?,
      providerBusinessName: d['providerBusinessName'] as String?,
      viewCount: (d['viewCount'] as num?)?.toInt() ?? 0,
      inquiryCount: (d['inquiryCount'] as num?)?.toInt() ?? 0,
      thumbnailUrl: thumb,
      photoUrls: photos,
    );
  }
}

