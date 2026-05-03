import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/dashboard_tokens.dart';
import '../activities/widgets/activity_network_image.dart';

/// Circular avatar: loads Storage URLs via SDK (web-safe); gradient + initials fallback.
class ProfileAvatarCircle extends StatelessWidget {
  const ProfileAvatarCircle({
    super.key,
    required this.d,
    required this.size,
    required this.initials,
    this.photoUrl,
    this.uploading = false,
    this.onTap,
  });

  final DashboardTokens d;
  final double size;
  final String initials;
  final String? photoUrl;
  final bool uploading;
  final VoidCallback? onTap;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                ActivityNetworkImage(url: url, fit: BoxFit.cover)
              else
                DecoratedBox(
                  decoration: const BoxDecoration(gradient: _gradient),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.dmSans(
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
              if (uploading)
                ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: d.accentBlue),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
