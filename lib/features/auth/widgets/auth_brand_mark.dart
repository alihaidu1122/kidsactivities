import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vector-style brand block (gradient tile + KidsHub wordmark). No image assets required.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key, this.compact = false});

  /// Smaller footprint for dense headers (e.g. sign-in app bar area).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logoBox = compact ? 44.0 : 56.0;
    final titleSize = compact ? 22.0 : 26.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoBox,
          height: logoBox,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(logoBox * 0.22),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.28),
                blurRadius: compact ? 10 : 18,
                offset: Offset(0, compact ? 4 : 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text('🎯', style: TextStyle(fontSize: logoBox * 0.42)),
        ),
        SizedBox(height: compact ? 10 : 14),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.dmSans(fontSize: titleSize, fontWeight: FontWeight.w800, height: 1.1),
            children: [
              TextSpan(text: 'Kids', style: TextStyle(color: scheme.onSurface)),
              TextSpan(text: 'Hub', style: TextStyle(color: scheme.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
