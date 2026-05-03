// Helpers for activity image URLs from Firestore / Storage.

/// HTTPS/HTTP download URL or `gs://` path for Firebase Storage (via SDK).
String? normalizeFirebaseMediaUrl(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('gs://')) return t;
  return sanitizeImageHttpUrl(t);
}

/// Normalize a URL string for [Image.network] (https only; trims whitespace).
String? sanitizeImageHttpUrl(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  final uri = Uri.tryParse(t);
  if (uri == null) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  if (uri.host.isEmpty) return null;
  return uri.toString();
}

List<String> parsePhotoUrlList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! List) return const [];
  final out = <String>[];
  for (final e in raw) {
    final s = sanitizeImageHttpUrl(e?.toString());
    if (s != null) out.add(s);
  }
  return out;
}

/// Prefer explicit thumbnail, common alternate keys, then first gallery URL.
String? pickThumbnailUrl(Map<String, dynamic> d, List<String> photos) {
  final direct = sanitizeImageHttpUrl(
    (d['thumbnailUrl'] as String?) ?? (d['thumbnail'] as String?) ?? (d['coverImageUrl'] as String?),
  );
  if (direct != null) return direct;
  if (photos.isNotEmpty) return photos.first;
  return null;
}
