import 'package:cloud_firestore/cloud_firestore.dart';

class Inquiry {
  Inquiry({
    required this.id,
    required this.activityId,
    required this.parentUserId,
    required this.providerUserId,
    required this.parentName,
    required this.parentEmail,
    required this.parentPhone,
    required this.childAge,
    required this.message,
    required this.preferredContactMethod,
    required this.status,
    required this.providerResponse,
    required this.createdAt,
  });

  final String id;
  final String activityId;
  final String parentUserId;
  final String providerUserId;
  final String parentName;
  final String? parentEmail;
  final String? parentPhone;
  final int? childAge;
  final String message;
  final String preferredContactMethod; // email|phone|either
  final String status;
  final String? providerResponse;
  final DateTime? createdAt;

  static Inquiry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'] as Timestamp?;
    return Inquiry(
      id: doc.id,
      activityId: (d['activityId'] as String?) ?? '',
      parentUserId: (d['parentUserId'] as String?) ?? '',
      providerUserId: (d['providerUserId'] as String?) ?? '',
      parentName: (d['parentName'] as String?) ?? '',
      parentEmail: d['parentEmail'] as String?,
      parentPhone: d['parentPhone'] as String?,
      childAge: (d['childAge'] as num?)?.toInt(),
      message: (d['message'] as String?) ?? '',
      preferredContactMethod: (d['preferredContactMethod'] as String?) ?? 'either',
      status: (d['status'] as String?) ?? 'new',
      providerResponse: d['providerResponse'] as String?,
      createdAt: ts?.toDate(),
    );
  }
}

