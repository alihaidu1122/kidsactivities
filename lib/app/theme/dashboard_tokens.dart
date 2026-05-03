import 'package:flutter/material.dart';

/// Dashboard tokens keyed off [ThemeData.brightness] via [ThemeExtension].
@immutable
class DashboardTokens extends ThemeExtension<DashboardTokens> {
  const DashboardTokens({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgCard,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.accentBlue,
    required this.accentBlueBg,
    required this.statusApprovedBg,
    required this.statusApprovedText,
    required this.statusPendingBg,
    required this.statusPendingText,
    required this.statusRejectedBg,
    required this.statusRejectedText,
    required this.alertBg,
    required this.alertBorder,
    required this.metricBlueBg,
    required this.metricAmberBg,
    required this.metricGreenBg,
    required this.starColor,
    required this.notifyDot,
    required this.roleParentText,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgCard;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color accentBlue;
  final Color accentBlueBg;
  final Color statusApprovedBg;
  final Color statusApprovedText;
  final Color statusPendingBg;
  final Color statusPendingText;
  final Color statusRejectedBg;
  final Color statusRejectedText;
  final Color alertBg;
  final Color alertBorder;
  final Color metricBlueBg;
  final Color metricAmberBg;
  final Color metricGreenBg;
  final Color starColor;
  final Color notifyDot;
  final Color roleParentText;

  static const dark = DashboardTokens(
    bgPrimary: Color(0xFF0F1117),
    bgSecondary: Color(0xFF161B27),
    bgTertiary: Color(0xFF1E2535),
    bgCard: Color(0xFF0F1117),
    borderColor: Color(0xFF1E2535),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE2E8F0),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFF64748B),
    accentBlue: Color(0xFF2563EB),
    accentBlueBg: Color(0xFF1E3A5F),
    statusApprovedBg: Color(0xFF0A2E1A),
    statusApprovedText: Color(0xFF4ADE80),
    statusPendingBg: Color(0xFF3D2A0A),
    statusPendingText: Color(0xFFFBBF24),
    statusRejectedBg: Color(0xFF2E0A0A),
    statusRejectedText: Color(0xFFF87171),
    alertBg: Color(0xFF1A1200),
    alertBorder: Color(0xFF3D2A0A),
    metricBlueBg: Color(0xFF1E3A5F),
    metricAmberBg: Color(0xFF3D2A0A),
    metricGreenBg: Color(0xFF0A2E1A),
    starColor: Color(0xFFF59E0B),
    notifyDot: Color(0xFFEF4444),
    roleParentText: Color(0xFF93C5FD),
  );

  static const light = DashboardTokens(
    bgPrimary: Color(0xFFF8FAFC),
    bgSecondary: Color(0xFFFFFFFF),
    bgTertiary: Color(0xFFEFF2F6),
    bgCard: Color(0xFFF8FAFC),
    borderColor: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    accentBlue: Color(0xFF2563EB),
    accentBlueBg: Color(0xFFDBEAFE),
    statusApprovedBg: Color(0xFFD1FAE5),
    statusApprovedText: Color(0xFF047857),
    statusPendingBg: Color(0xFFFEF3C7),
    statusPendingText: Color(0xFFB45309),
    statusRejectedBg: Color(0xFFFEE2E2),
    statusRejectedText: Color(0xFFB91C1C),
    alertBg: Color(0xFFFEFCE8),
    alertBorder: Color(0xFFFDE047),
    metricBlueBg: Color(0xFFDBEAFE),
    metricAmberBg: Color(0xFFFEF3C7),
    metricGreenBg: Color(0xFFD1FAE5),
    starColor: Color(0xFFD97706),
    notifyDot: Color(0xFFEF4444),
    roleParentText: Color(0xFF1D4ED8),
  );

  @override
  DashboardTokens copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? bgCard,
    Color? borderColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? accentBlue,
    Color? accentBlueBg,
    Color? statusApprovedBg,
    Color? statusApprovedText,
    Color? statusPendingBg,
    Color? statusPendingText,
    Color? statusRejectedBg,
    Color? statusRejectedText,
    Color? alertBg,
    Color? alertBorder,
    Color? metricBlueBg,
    Color? metricAmberBg,
    Color? metricGreenBg,
    Color? starColor,
    Color? notifyDot,
    Color? roleParentText,
  }) {
    return DashboardTokens(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      bgCard: bgCard ?? this.bgCard,
      borderColor: borderColor ?? this.borderColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      accentBlue: accentBlue ?? this.accentBlue,
      accentBlueBg: accentBlueBg ?? this.accentBlueBg,
      statusApprovedBg: statusApprovedBg ?? this.statusApprovedBg,
      statusApprovedText: statusApprovedText ?? this.statusApprovedText,
      statusPendingBg: statusPendingBg ?? this.statusPendingBg,
      statusPendingText: statusPendingText ?? this.statusPendingText,
      statusRejectedBg: statusRejectedBg ?? this.statusRejectedBg,
      statusRejectedText: statusRejectedText ?? this.statusRejectedText,
      alertBg: alertBg ?? this.alertBg,
      alertBorder: alertBorder ?? this.alertBorder,
      metricBlueBg: metricBlueBg ?? this.metricBlueBg,
      metricAmberBg: metricAmberBg ?? this.metricAmberBg,
      metricGreenBg: metricGreenBg ?? this.metricGreenBg,
      starColor: starColor ?? this.starColor,
      notifyDot: notifyDot ?? this.notifyDot,
      roleParentText: roleParentText ?? this.roleParentText,
    );
  }

  @override
  DashboardTokens lerp(ThemeExtension<DashboardTokens>? other, double t) {
    if (other is! DashboardTokens) return this;
    Color lc(Color a, Color b) => Color.lerp(a, b, t)!;
    return DashboardTokens(
      bgPrimary: lc(bgPrimary, other.bgPrimary),
      bgSecondary: lc(bgSecondary, other.bgSecondary),
      bgTertiary: lc(bgTertiary, other.bgTertiary),
      bgCard: lc(bgCard, other.bgCard),
      borderColor: lc(borderColor, other.borderColor),
      textPrimary: lc(textPrimary, other.textPrimary),
      textSecondary: lc(textSecondary, other.textSecondary),
      textMuted: lc(textMuted, other.textMuted),
      textFaint: lc(textFaint, other.textFaint),
      accentBlue: lc(accentBlue, other.accentBlue),
      accentBlueBg: lc(accentBlueBg, other.accentBlueBg),
      statusApprovedBg: lc(statusApprovedBg, other.statusApprovedBg),
      statusApprovedText: lc(statusApprovedText, other.statusApprovedText),
      statusPendingBg: lc(statusPendingBg, other.statusPendingBg),
      statusPendingText: lc(statusPendingText, other.statusPendingText),
      statusRejectedBg: lc(statusRejectedBg, other.statusRejectedBg),
      statusRejectedText: lc(statusRejectedText, other.statusRejectedText),
      alertBg: lc(alertBg, other.alertBg),
      alertBorder: lc(alertBorder, other.alertBorder),
      metricBlueBg: lc(metricBlueBg, other.metricBlueBg),
      metricAmberBg: lc(metricAmberBg, other.metricAmberBg),
      metricGreenBg: lc(metricGreenBg, other.metricGreenBg),
      starColor: lc(starColor, other.starColor),
      notifyDot: lc(notifyDot, other.notifyDot),
      roleParentText: lc(roleParentText, other.roleParentText),
    );
  }
}

extension DashboardTokensContext on BuildContext {
  DashboardTokens get dash => Theme.of(this).extension<DashboardTokens>() ?? DashboardTokens.dark;
}
