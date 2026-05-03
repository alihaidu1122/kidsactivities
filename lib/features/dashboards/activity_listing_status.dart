import '../activities/activity.dart';

/// Maps Firestore activity fields to dashboard status pills.
String listingDisplayStatus(Activity a) {
  final s = a.approvalStatus.toLowerCase();
  if (s == 'draft') return 'draft';
  if (!a.isActive && s == 'approved') return 'inactive';
  return a.approvalStatus;
}

bool isDraftListing(Activity a) => a.approvalStatus.toLowerCase() == 'draft';
