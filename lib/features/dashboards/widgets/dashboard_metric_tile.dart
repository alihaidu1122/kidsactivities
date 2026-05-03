import 'package:flutter/material.dart';

import '../../../app/theme/dashboard_text_styles.dart';
import '../../../app/theme/dashboard_tokens.dart';

class DashboardMetricTile extends StatelessWidget {
  const DashboardMetricTile({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    required this.iconBackground,
  });

  final String emoji;
  final String value;
  final String label;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: d.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: d.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 6),
            Text(value, style: DashboardTextStyles.metricValue(d)),
            Text(label, style: DashboardTextStyles.label(d)),
          ],
        ),
      ),
    );
  }
}
