import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_tokens.dart';

/// Typography for dashboard surfaces using DM Sans (no underlines — avoids web spellcheck artifacts).
abstract final class DashboardTextStyles {
  static TextStyle _base(
    DashboardTokens d, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.2,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? d.textPrimary,
      height: height,
      decoration: TextDecoration.none,
      decorationThickness: 0,
    );
  }

  static TextStyle pageTitle(DashboardTokens d) => _base(d, size: 22, weight: FontWeight.w700);

  static TextStyle cardTitle(DashboardTokens d) => _base(d, size: 13, weight: FontWeight.w600);

  static TextStyle cardSubtitle(DashboardTokens d) =>
      _base(d, size: 11, weight: FontWeight.w400, color: d.textMuted);

  static TextStyle body(DashboardTokens d) =>
      _base(d, size: 12.5, weight: FontWeight.w400, color: d.textSecondary);

  static TextStyle tableCell(DashboardTokens d) =>
      _base(d, size: 12.5, color: d.textSecondary);

  static TextStyle label(DashboardTokens d) =>
      _base(d, size: 11, weight: FontWeight.w500, color: d.textMuted);

  static TextStyle metricValue(DashboardTokens d) => _base(d, size: 20, weight: FontWeight.w700);

  static TextStyle navItem(DashboardTokens d) =>
      _base(d, size: 12.5, weight: FontWeight.w500, color: d.textMuted);

  static TextStyle button(DashboardTokens d) =>
      _base(d, size: 12, weight: FontWeight.w600, color: d.textPrimary);

  static TextStyle filterChip(DashboardTokens d) =>
      _base(d, size: 11, weight: FontWeight.w600, color: d.textMuted);

  static TextStyle tableHeader(DashboardTokens d) =>
      _base(d, size: 11, weight: FontWeight.w500, color: d.textMuted);

  static TextStyle statusPill(DashboardTokens d) => _base(d, size: 10, weight: FontWeight.w600);

  static TextStyle logo(DashboardTokens d) => _base(d, size: 13, weight: FontWeight.w600);
}
