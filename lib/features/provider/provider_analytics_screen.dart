import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../analytics/analytics_providers.dart';

class ProviderAnalyticsScreen extends ConsumerWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = context.dash;
    final dataAsync = ref.watch(providerAnalyticsProvider);
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
                  onPressed: () => ref.invalidate(providerAnalyticsProvider),
                  icon: Icon(Icons.refresh, color: d.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          onPressed: () => ref.invalidate(providerAnalyticsProvider),
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
                          _MetricCard(d: d, label: 'Active listings', value: '${data.listingCount}'),
                          _MetricCard(d: d, label: 'Total views', value: '${data.totalViews}'),
                          _MetricCard(d: d, label: 'Listing inquiries (counts)', value: '${data.totalInquiriesOnListings}'),
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
                            Text('Your inquiries (last 7 days)', style: DashboardTextStyles.cardTitle(d)),
                            const SizedBox(height: 4),
                            Text(
                              'Messages from parents to your listings.',
                              style: DashboardTextStyles.cardSubtitle(d),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  minY: 0,
                                  maxY: (data.maxDailyInquiries < 4 ? 4 : data.maxDailyInquiries + 1).toDouble(),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (v) => FlLine(
                                      color: d.borderColor,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
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
                                  barGroups: [
                                    for (var i = 0; i < 7; i++)
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: data.inquiriesLast7Days[i].toDouble(),
                                            width: 16,
                                            color: d.accentBlue,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (data.topListingsByViews.isNotEmpty) ...[
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
                              Text('Views by listing', style: DashboardTextStyles.cardTitle(d)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    minY: 0,
                                    maxY: (data.maxBarViews < 5 ? 5 : data.maxBarViews + 2).toDouble(),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (v) => FlLine(
                                        color: d.borderColor,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 28,
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
                                            if (i < 0 || i >= data.topListingsByViews.length) {
                                              return const SizedBox();
                                            }
                                            final title = data.topListingsByViews[i].$1;
                                            final short = title.length > 10 ? '${title.substring(0, 10)}…' : title;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                short,
                                                style: DashboardTextStyles.label(d).copyWith(fontSize: 9),
                                              ),
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
                                    barGroups: [
                                      for (var i = 0; i < data.topListingsByViews.length; i++)
                                        BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: data.topListingsByViews[i].$2.toDouble(),
                                              width: 18,
                                              color: d.metricGreenBg,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
      final day = today.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(day);
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
      width: 170,
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
