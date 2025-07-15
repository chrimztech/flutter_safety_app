// pages/analytics_page.dart
import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<_StatCardData> stats = [
      _StatCardData('Incidents Reported', 124, Icons.report, Colors.deepPurple),
      _StatCardData('Completed Trainings', 56, Icons.school, Colors.teal),
      _StatCardData('Open Compliance Issues', 8, Icons.warning_amber, Colors.orange),
      _StatCardData('Hazards Detected', 14, Icons.dangerous, Colors.redAccent),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.blue.shade700,
        elevation: 3,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                itemCount: stats.length,
                padding: const EdgeInsets.only(bottom: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return _buildStatCard(stat, theme);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatCardData data, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: data.value.toDouble()),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
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
                  radius: 30,
                  backgroundColor: data.color.withOpacity(0.15),
                  child: Icon(data.icon, size: 30, color: data.color),
                ),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.toInt().toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: data.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCardData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCardData(this.title, this.value, this.icon, this.color);
}
