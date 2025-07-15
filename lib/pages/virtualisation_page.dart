// pages/virtualisation_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_page.dart'; // Make sure this import path is correct

class VirtualizationPage extends StatefulWidget {
  const VirtualizationPage({super.key});

  @override
  State<VirtualizationPage> createState() => _VirtualizationPageState();
}

class _VirtualizationPageState extends State<VirtualizationPage> with SingleTickerProviderStateMixin {
  bool _isVirtualizationEnabled = false;
  bool _showAdvancedSettings = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<String> _logs = [
    '🟢 VM-01 started successfully',
    '🟢 VM-02 network bridged',
    '🟢 VM-03 snapshot created',
    '🔄 Syncing virtualization profiles...',
    '✅ Resource allocation check completed',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    Color color = Colors.blue,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing != null
            ? Text(trailing, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            : null,
      ),
    );
  }

  Widget _buildMonitoringChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(show: true),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 2),
                    FlSpot(1, 2.5),
                    FlSpot(2, 1.5),
                    FlSpot(3, 3),
                    FlSpot(4, 2.8),
                    FlSpot(5, 3.5),
                  ],
                  isCurved: true,
                  barWidth: 3,
                  color: Colors.blue,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _logs.map((log) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(log, style: const TextStyle(fontSize: 14)),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtualization'),
        backgroundColor: Colors.blue,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Back to Dashboard',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _buildInfoCard(
                icon: Icons.settings_input_component,
                title: 'Enable Virtualization',
                subtitle: 'Turn on/off virtualization environment',
                color: _isVirtualizationEnabled ? Colors.green : Colors.red,
              ),
              SwitchListTile.adaptive(
                value: _isVirtualizationEnabled,
                onChanged: (val) => setState(() => _isVirtualizationEnabled = val),
                title: const Text("Virtualization Enabled"),
                activeColor: Colors.blue,
              ),
              const SizedBox(height: 20),
              if (_isVirtualizationEnabled) ...[
                _buildInfoCard(
                  icon: Icons.computer,
                  title: 'Virtual Machines Running',
                  trailing: '3',
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildMonitoringChart(),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _showAdvancedSettings,
                  onChanged: (val) => setState(() => _showAdvancedSettings = val),
                  title: const Text("Show Advanced Settings"),
                  activeColor: Colors.blue,
                ),
                if (_showAdvancedSettings) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.memory,
                    title: 'Resource Allocation',
                    subtitle: '8 CPUs • 16 GB RAM',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.network_check,
                    title: 'Network Configuration',
                    subtitle: 'NAT, Bridged Adapter',
                    color: Colors.teal,
                  ),
                ],
                const SizedBox(height: 20),
                Text('🔍 Activity Logs', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildLogList(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
