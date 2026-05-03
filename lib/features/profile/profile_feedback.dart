import 'package:flutter/material.dart';

import '../../app/theme/dashboard_tokens.dart';

void showProfileSuccessSnackBar(BuildContext context, String message) {
  final d = context.dash;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    debugPrint('showProfileSuccessSnackBar (no Scaffold): $message');
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: d.statusApprovedBg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: d.statusApprovedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

void showProfileErrorSnackBar(BuildContext context, String message) {
  final d = context.dash;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    debugPrint('showProfileErrorSnackBar (no Scaffold): $message');
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: d.statusRejectedBg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Row(
        children: [
          const Text('❌', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: d.statusRejectedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
