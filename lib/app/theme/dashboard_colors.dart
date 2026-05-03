import 'package:flutter/material.dart';

/// Dark admin/provider dashboard palette (client-approved spec).
abstract final class DashboardColors {
  static const Color bgPrimary = Color(0xFF0F1117);
  static const Color bgSecondary = Color(0xFF161B27);
  static const Color bgTertiary = Color(0xFF1E2535);
  static const Color bgCard = Color(0xFF0F1117);

  static const Color borderColor = Color(0xFF1E2535);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textFaint = Color(0xFF64748B);

  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueBg = Color(0xFF1E3A5F);

  static const Color statusApprovedBg = Color(0xFF0A2E1A);
  static const Color statusApprovedText = Color(0xFF4ADE80);
  static const Color statusPendingBg = Color(0xFF3D2A0A);
  static const Color statusPendingText = Color(0xFFFBBF24);
  static const Color statusRejectedBg = Color(0xFF2E0A0A);
  static const Color statusRejectedText = Color(0xFFF87171);

  static const Color alertBg = Color(0xFF1A1200);
  static const Color alertBorder = Color(0xFF3D2A0A);

  static const Color metricBlueBg = Color(0xFF1E3A5F);
  static const Color metricAmberBg = Color(0xFF3D2A0A);
  static const Color metricGreenBg = Color(0xFF0A2E1A);

  static const Color starColor = Color(0xFFF59E0B);
  static const Color notifyDot = Color(0xFFEF4444);
}
