import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../analytics/analytics_providers.dart';
import 'admin_tools_screen.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = context.dash;
    final dataAsync = ref.watch(adminAnalyticsProvider);
    final dayLabels = _last7DayLabels();

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Analytics', style: DashboardTextStyles.pageTitle(d))),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(adminAnalyticsProvider),
                  icon: Icon(Icons.refresh, color: d.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminToolsScreen()),
                ),
                child: Text(
                  'Developer: seed demo data',
                  style: DashboardTextStyles.label(d).copyWith(color: d.accentBlue),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: dataAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: d.accentBlue)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load analytics.', style: DashboardTextStyles.body(d)),
                        Text('$e', style: DashboardTextStyles.cardSubtitle(d)),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref.invalidate(adminAnalyticsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (data) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            d: d,
                            label: 'Listings',
                            value: '${data.totalActivities}',
                          ),
                          _MetricCard(
                            d: d,
                            label: 'Users',
                            value: '${data.totalUsers}',
                          ),
                          _MetricCard(
                            d: d,
                            label: 'Pending approval',
                            value: '${data.pendingListings}',
                          ),
                          _MetricCard(
                            d: d,
                            label: 'Reviews',
                            value: '${data.reviewsCount}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: d.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: d.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inquiries (last 7 days)', style: DashboardTextStyles.cardTitle(d)),
                            const SizedBox(height: 4),
                            Text(
                              'Daily new inquiry volume from Firestore.',
                              style: DashboardTextStyles.cardSubtitle(d),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 220,
                              child: LineChart(
                                LineChartData(
                                  minX: 0,
                                  maxX: 6,
                                  minY: 0,
                                  maxY: (data.maxDailyInquiries < 4 ? 4 : data.maxDailyInquiries + 1).toDouble(),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (v) => FlLine(
                                      color: d.borderColor,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        getTitlesWidget: (v, m) => Text(
                                          '${v.toInt()}',
                                          style: DashboardTextStyles.label(d).copyWith(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (v, m) {
                                          final i = v.toInt();
                                          if (i < 0 || i >= dayLabels.length) return const SizedBox();
                                          return Text(
                                            dayLabels[i],
                                            style: DashboardTextStyles.label(d).copyWith(fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(),
                                    topTitles: const AxisTitles(),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: d.borderColor),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (var i = 0; i < 7; i++)
                                          FlSpot(i.toDouble(), data.inquiriesLast7Days[i].toDouble()),
                                      ],
                                      isCurved: true,
                                      color: d.accentBlue,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: d.accentBlue.withValues(alpha: 0.12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _last7DayLabels() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d);
    });
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.d, required this.label, required this.value});

  final DashboardTokens d;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: d.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DashboardTextStyles.label(d)),
          const SizedBox(height: 6),
          Text(value, style: DashboardTextStyles.metricValue(d)),
        ],
      ),
    );
  }
}
