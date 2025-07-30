// pages/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // For date formatting in charts if needed

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Mock data for demonstration. In a real app, this would come from a backend.
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

  // Dummy data for compliance status breakdown
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
        foregroundColor: Colors.white, // Ensure title is visible
        elevation: 4,
      ),
      body: SingleChildScrollView( // Use SingleChildScrollView for better scrollability
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

            // Incident Trends Section
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

            // Compliance Status Section
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

            // Placeholder for other analytics
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

  // --- Widget Builders ---

  Widget _buildStatCardsGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true, // Important for GridView inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Prevent GridView from scrolling independently
      itemCount: _statCardsData.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final stat = _statCardsData[index];
        return _buildStatCard(stat, theme);
      },
    );
  }

  Widget _buildStatCard(_StatCardData data, ThemeData theme) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: data.color.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28, // Slightly adjusted size
              backgroundColor: data.color.withOpacity(0.15),
              child: Icon(data.icon, size: 28, color: data.color),
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith( // bodyMedium might be better for card titles
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: data.value.toDouble()),
              duration: const Duration(milliseconds: 1000), // Slightly longer animation
              builder: (context, value, child) {
                return Text(
                  NumberFormat.compact().format(value.toInt()), // Format numbers for larger values
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: data.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 28, // Make numbers stand out more
                  ),
                );
              },
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
          aspectRatio: 1.8, // Adjust aspect ratio for better chart display
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
                        child: Text(_incidentTrendData[value.toInt()].month,
                            style: theme.textTheme.bodySmall),
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
                      return Text(value.toInt().toString(), style: theme.textTheme.bodySmall);
                    },
                    reservedSize: 30,
                    interval: _getChartInterval(_incidentTrendData.map((e) => e.incidents).toList()),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      .map((e) => FlSpot(e.key.toDouble(), e.value.incidents.toDouble()))
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
              maxY: (_incidentTrendData.map((e) => e.incidents).reduce(
                          (a, b) => a > b ? a : b) *
                      1.2), // 20% buffer for max Y
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
          aspectRatio: 1.2, // Adjust aspect ratio for better chart display
          child: PieChart(
            PieChartData(
              sections: _complianceStatusData.map((data) {
                return PieChartSectionData(
                  color: data.color,
                  value: data.percentage.toDouble(),
                  title: '${data.percentage}%',
                  radius: 80,
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
          subtitle: const Text('View air and water emission trends over time.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to detailed emissions page
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.recycling, color: Colors.green.shade600),
          title: Text('Waste Management Analytics', style: theme.textTheme.titleMedium),
          subtitle: const Text('Analyze waste generation, recycling, and disposal data.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to detailed waste management page
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.person_pin_circle, color: Colors.purple.shade600),
          title: Text('Site-Specific Performance', style: theme.textTheme.titleMedium),
          subtitle: const Text('Breakdown of analytics by operational site.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to detailed site analytics page
          },
        ),
      ],
    );
  }

  // Helper function to dynamically calculate chart interval
  double _getChartInterval(List<int> values) {
    if (values.isEmpty) return 1.0;
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal <= 5) return 1.0;
    if (maxVal <= 10) return 2.0;
    if (maxVal <= 20) return 4.0;
    return (maxVal / 5).ceilToDouble(); // Divide into roughly 5 intervals
  }
}

// --- Data Models ---

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
  final int percentage; // Assuming percentage for a pie chart
  final Color color;

  ComplianceStatusData(this.status, this.percentage, this.color);
}