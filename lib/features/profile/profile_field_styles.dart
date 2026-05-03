import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/dashboard_tokens.dart';

InputDecoration dashProfileInputDecoration(DashboardTokens d, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: d.textFaint,
      letterSpacing: 0.04,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    filled: true,
    fillColor: d.bgPrimary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: d.borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: d.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: d.accentBlue, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  );
}

TextStyle dashProfileInputTextStyle(DashboardTokens d) {
  return GoogleFonts.dmSans(fontSize: 12, color: d.textSecondary);
}

TextStyle dashProfileLabelStyle(DashboardTokens d) {
  return GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.06,
    color: d.textFaint,
  );
}
