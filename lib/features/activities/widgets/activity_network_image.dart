import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/dashboard_tokens.dart';
import '../activity_media.dart';

FirebaseStorage _firebaseStorageForBucket(String bucket) {
  final configured = Firebase.app().options.storageBucket;
  if (configured != null && configured == bucket) {
    return FirebaseStorage.instance;
  }
  try {
    return FirebaseStorage.instanceFor(app: Firebase.app(), bucket: bucket);
  } catch (_) {
    return FirebaseStorage.instance;
  }
}

/// Resolves a Firebase download or gs URL when [Reference.refFromURL] fails (e.g. newer bucket names).
Reference? storageReferenceFromFirebaseUrl(String url) {
  final t = url.trim();
  if (t.isEmpty) return null;

  if (t.startsWith('gs://')) {
    try {
      return FirebaseStorage.instance.refFromURL(t);
    } catch (_) {
      return null;
    }
  }

  try {
    return FirebaseStorage.instance.refFromURL(t);
  } catch (_) {}

  final uri = Uri.tryParse(t);
  if (uri == null) return null;

  final match = RegExp(r'^/v0/b/([^/]+)/o/(.+)$').firstMatch(uri.path);
  if (match == null) return null;

  final bucket = Uri.decodeComponent(match.group(1)!);
  final encodedObjectPath = match.group(2)!;
  final objectPath = Uri.decodeFull(encodedObjectPath);

  try {
    return _firebaseStorageForBucket(bucket).ref(objectPath);
  } catch (_) {
    return null;
  }
}

bool _shouldLoadFirebaseStorageViaSdk(String url) {
  final t = url.trim();
  if (t.startsWith('gs://')) return true;
  final lower = t.toLowerCase();
  return lower.contains('firebasestorage.googleapis.com') ||
      lower.contains('firebasestorage.app') ||
      (lower.contains('googleapis.com') && lower.contains('/v0/b/'));
}

/// Loads HTTPS activity images; on web, Firebase Storage URLs use the Storage SDK
/// ([storageReferenceFromFirebaseUrl] + [getData]) so bytes are not blocked by browser CORS on `<img>`.
class ActivityNetworkImage extends StatefulWidget {
  const ActivityNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  State<ActivityNetworkImage> createState() => _ActivityNetworkImageState();
}

class _ActivityNetworkImageState extends State<ActivityNetworkImage> {
  Uint8List? _memoryBytes;
  bool _triedFirebaseSdk = false;
  bool _firebaseFailed = false;

  @override
  void initState() {
    super.initState();
    _startFirebaseSdkLoadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ActivityNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _memoryBytes = null;
      _triedFirebaseSdk = false;
      _firebaseFailed = false;
      _startFirebaseSdkLoadIfNeeded();
    }
  }

  Future<void> _startFirebaseSdkLoadIfNeeded() async {
    final normalized = normalizeFirebaseMediaUrl(widget.url);
    if (normalized == null) return;
    if (!_shouldLoadFirebaseStorageViaSdk(normalized)) return;

    _triedFirebaseSdk = true;
    try {
      final ref = storageReferenceFromFirebaseUrl(normalized);
      if (ref == null) {
        if (mounted) setState(() => _firebaseFailed = true);
        return;
      }
      final bytes = await ref.getData(10 * 1024 * 1024);
      if (!mounted) return;
      if (bytes != null && bytes.isNotEmpty) {
        setState(() => _memoryBytes = bytes);
      } else {
        setState(() => _firebaseFailed = true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _firebaseFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeFirebaseMediaUrl(widget.url);
    final netUrl = sanitizeImageHttpUrl(widget.url);
    final d = context.dash;

    Widget errorBox() => Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          color: d.bgTertiary,
          child: Icon(Icons.broken_image_outlined, color: d.textFaint, size: 28),
        );

    if (normalized == null && netUrl == null) {
      return _wrapClip(errorBox());
    }

    final useSdkBytes = _memoryBytes != null;
    final trySdkPending = normalized != null &&
        _shouldLoadFirebaseStorageViaSdk(normalized) &&
        _triedFirebaseSdk &&
        _memoryBytes == null &&
        !_firebaseFailed;

    Widget img;
    if (useSdkBytes) {
      img = Image.memory(
        _memoryBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => errorBox(),
      );
    } else if (trySdkPending) {
      final loader = Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: d.accentBlue),
        ),
      );
      if (widget.width == null && widget.height == null) {
        img = SizedBox.expand(child: ColoredBox(color: d.bgTertiary, child: loader));
      } else {
        img = SizedBox(width: widget.width, height: widget.height, child: ColoredBox(color: d.bgTertiary, child: loader));
      }
    } else if (netUrl == null) {
      img = errorBox();
    } else {
      img = Image.network(
        netUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final loader = Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: d.accentBlue,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
          if (widget.width == null && widget.height == null) {
            return SizedBox.expand(child: ColoredBox(color: d.bgTertiary, child: loader));
          }
          return SizedBox(width: widget.width, height: widget.height, child: ColoredBox(color: d.bgTertiary, child: loader));
        },
        errorBuilder: (_, _, _) {
          if (widget.width == null && widget.height == null) {
            return SizedBox.expand(
              child: ColoredBox(
                color: d.bgTertiary,
                child: Icon(Icons.image_not_supported_outlined, color: d.textFaint, size: 48),
              ),
            );
          }
          return errorBox();
        },
      );
    }

    return _wrapClip(img);
  }

  Widget _wrapClip(Widget child) {
    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }
}
