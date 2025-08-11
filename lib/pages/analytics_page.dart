// pages/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final List<_StatCardData> _statCardsData = [
    _StatCardData('Total Incidents', 124, Icons.report, Colors.deepPurple),
    _StatCardData('Trainings Completed', 56, Icons.school, Colors.teal),
    _StatCardData('Open Compliance Issues', 8, Icons.warning_amber, Colors.orange),
    _StatCardData('Hazards Identified', 14, Icons.dangerous, Colors.redAccent),
    _StatCardData('Audits Conducted', 28, Icons.fact_check, Colors.blue),
    _StatCardData('Near Misses Reported', 31, Icons.visibility_off, Colors.brown),
  ];

  final List<IncidentTrendData> _incidentTrendData = [
    IncidentTrendData('Jan', 5),
    IncidentTrendData('Feb', 8),
    IncidentTrendData('Mar', 12),
    IncidentTrendData('Apr', 10),
    IncidentTrendData('May', 15),
    IncidentTrendData('Jun', 11),
    IncidentTrendData('Jul', 18),
  ];

  final List<ComplianceStatusData> _complianceStatusData = [
    ComplianceStatusData('Resolved', 70, Colors.green),
    ComplianceStatusData('Open', 20, Colors.orange),
    ComplianceStatusData('Overdue', 10, Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Safety Analytics'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Performance Indicators',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatCardsGrid(theme),
            const SizedBox(height: 30),
            Text(
              'Monthly Incident Trends',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildIncidentTrendChart(theme),
            const SizedBox(height: 30),
            Text(
              'Compliance Issue Status',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildComplianceStatusPieChart(theme),
            const SizedBox(height: 30),
            Text(
              'Other Analytics & Reports',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildOtherAnalyticsPlaceholders(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardsGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _statCardsData.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final stat = _statCardsData[index];
        return _buildStatCard(stat, theme);
      },
    );
  }

  Widget _buildStatCard(_StatCardData data, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: data.color.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.icon, size: 20, color: data.color),
                  const SizedBox(height: 4),
                  Text(
                    data.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: data.value.toDouble()),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Text(
                    NumberFormat.compact().format(value.toInt()),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: data.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTrendChart(ThemeData theme) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 1.8,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _incidentTrendData[value.toInt()].month,
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                    interval: 1,
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(),
                          style: theme.textTheme.bodySmall);
                    },
                    reservedSize: 30,
                    interval: _getChartInterval(
                        _incidentTrendData.map((e) => e.incidents).toList()),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _incidentTrendData
                      .asMap()
                      .entries
                      .map((e) => FlSpot(
                          e.key.toDouble(), e.value.incidents.toDouble()))
                      .toList(),
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.3),
                        Colors.blueAccent.withOpacity(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              minX: 0,
              maxX: (_incidentTrendData.length - 1).toDouble(),
              minY: 0,
              maxY: (_incidentTrendData
                          .map((e) => e.incidents)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceStatusPieChart(ThemeData theme) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 1.2,
          child: PieChart(
            PieChartData(
              sections: _complianceStatusData.map((data) {
                return PieChartSectionData(
                  color: data.color,
                  value: data.percentage.toDouble(),
                  title: '${data.percentage}%',
                  radius: 70,
                  titleStyle: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherAnalyticsPlaceholders(ThemeData theme) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.cloud_upload, color: Colors.blue.shade600),
          title: Text('Emissions Tracking', style: theme.textTheme.titleMedium),
          subtitle:
              const Text('View air and water emission trends over time.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.recycling, color: Colors.green.shade600),
          title: Text('Waste Management Analytics',
              style: theme.textTheme.titleMedium),
          subtitle: const Text(
              'Analyze waste generation, recycling, and disposal data.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading:
              Icon(Icons.person_pin_circle, color: Colors.purple.shade600),
          title: Text('Site-Specific Performance',
              style: theme.textTheme.titleMedium),
          subtitle:
              const Text('Breakdown of analytics by operational site.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
      ],
    );
  }

  double _getChartInterval(List<int> values) {
    if (values.isEmpty) return 1.0;
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal <= 5) return 1.0;
    if (maxVal <= 10) return 2.0;
    if (maxVal <= 20) return 4.0;
    return (maxVal / 5).ceilToDouble();
  }
}

class _StatCardData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCardData(this.title, this.value, this.icon, this.color);
}

class IncidentTrendData {
  final String month;
  final int incidents;
  IncidentTrendData(this.month, this.incidents);
}

class ComplianceStatusData {
  final String status;
  final int percentage;
  final Color color;
  ComplianceStatusData(this.status, this.percentage, this.color);
}
