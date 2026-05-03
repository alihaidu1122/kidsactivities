import 'package:flutter/material.dart';

import '../../../app/theme/dashboard_text_styles.dart';
import '../../../app/theme/dashboard_tokens.dart';

class DashboardStatusPill extends StatelessWidget {
  const DashboardStatusPill({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  factory DashboardStatusPill.forListingStatus(BuildContext context, String status) {
    final d = context.dash;
    final s = status.toLowerCase();
    return DashboardStatusPill(
      label: status,
      backgroundColor: switch (s) {
        'approved' => d.statusApprovedBg,
        'pending' => d.statusPendingBg,
        'rejected' => d.statusRejectedBg,
        'inactive' => d.bgTertiary,
        'draft' => d.bgTertiary,
        _ => d.bgTertiary,
      },
      foregroundColor: switch (s) {
        'approved' => d.statusApprovedText,
        'pending' => d.statusPendingText,
        'rejected' => d.statusRejectedText,
        'inactive' => d.textMuted,
        'draft' => d.textFaint,
        _ => d.textMuted,
      },
    );
  }

  factory DashboardStatusPill.forInquiryStatus(BuildContext context, String status) {
    final d = context.dash;
    final s = status.toLowerCase();
    return DashboardStatusPill(
      label: status,
      backgroundColor: switch (s) {
        'new' => d.statusPendingBg,
        'read' => d.bgTertiary,
        'responded' => d.statusApprovedBg,
        'closed' => d.bgSecondary,
        _ => d.bgTertiary,
      },
      foregroundColor: switch (s) {
        'new' => d.statusPendingText,
        'read' => d.textMuted,
        'responded' => d.statusApprovedText,
        'closed' => d.textFaint,
        _ => d.textMuted,
      },
    );
  }

  factory DashboardStatusPill.forUserRole(BuildContext context, String role) {
    final d = context.dash;
    final r = role.toLowerCase();
    return DashboardStatusPill(
      label: role,
      backgroundColor: switch (r) {
        'parent' => d.accentBlueBg,
        'provider' => d.statusApprovedBg,
        'admin' => d.statusPendingBg,
        _ => d.bgTertiary,
      },
      foregroundColor: switch (r) {
        'parent' => d.roleParentText,
        'provider' => d.statusApprovedText,
        'admin' => d.statusPendingText,
        _ => d.textMuted,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? d.bgTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: DashboardTextStyles.statusPill(d).copyWith(
          color: foregroundColor ?? d.textMuted,
        ),
      ),
    );
  }
}
