// pages/hazard_detection_page.dart
import 'package:flutter/material.dart';

class HazardDetectionPage extends StatefulWidget {
  const HazardDetectionPage({super.key});

  @override
  State<HazardDetectionPage> createState() => _HazardDetectionPageState();
}

class _HazardDetectionPageState extends State<HazardDetectionPage> {
  bool _isLoading = false;
  String _searchQuery = '';

  // Hazard data grouped by categories
  final Map<String, List<Map<String, dynamic>>> _hazardCategories = {
    '🔬 Environmental': [
      {'name': 'Temperature', 'level': 38, 'risk': 'High'},
      {'name': 'Humidity', 'level': 85, 'risk': 'Moderate'},
      {'name': 'Air Quality - CO₂', 'level': 800, 'risk': 'Moderate'},
      {'name': 'Oxygen Level', 'level': 18.0, 'risk': 'Moderate'},
      {'name': 'Particulate Matter (PM2.5)', 'level': 70, 'risk': 'High'},
    ],
    '⚗️ Chemical': [
      {'name': 'Chemical Leak', 'level': null, 'risk': 'Low'},
      {'name': 'Radiation', 'level': 0.15, 'risk': 'Low'},
      {'name': 'Gas Detector - Methane', 'level': 0.02, 'risk': 'Low'},
      {'name': 'Toxic Spill', 'level': null, 'risk': 'High'},
    ],
    '🛠️ Mechanical': [
      {'name': 'Pressure Level', 'level': 1020, 'risk': 'Low'},
      {'name': 'Noise Level', 'level': 95, 'risk': 'High'},
    ],
    '🔥 Emergency Triggers': [
      {'name': 'Fire Outbreak', 'level': null, 'risk': 'High'},
      {'name': 'Toxic Leak', 'level': null, 'risk': 'High'},
    ],
  };

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Icons.check_circle_outline;
      case 'moderate':
        return Icons.warning_amber_outlined;
      case 'high':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  // Compute overall risk from all hazards
  String get _overallRisk {
    final allHazards = _hazardCategories.values.expand((list) => list).toList();
    if (allHazards.any((h) => h['risk'].toLowerCase() == 'high')) {
      return 'High';
    } else if (allHazards.any((h) => h['risk'].toLowerCase() == 'moderate')) {
      return 'Moderate';
    }
    return 'Low';
  }

  // Filter hazards by search query
  List<Map<String, dynamic>> _filterHazards(List<Map<String, dynamic>> hazards) {
    if (_searchQuery.isEmpty) return hazards;
    return hazards
        .where((h) => h['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Hazard Detection'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search hazards...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overall risk summary
            Card(
              color: _riskColor(_overallRisk).withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(_riskIcon(_overallRisk), color: _riskColor(_overallRisk), size: 40),
                title: const Text(
                  'Overall Hazard Level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _overallRisk,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _riskColor(_overallRisk),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Hazard categories with grouped hazards
            for (final category in _hazardCategories.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(category.key, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ..._filterHazards(category.value).map((hazard) {
                final risk = hazard['risk'] ?? 'Unknown';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(_riskIcon(risk), color: _riskColor(risk), size: 32),
                    title: Text(
                      hazard['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      hazard['level'] != null ? 'Level: ${hazard['level']}' : 'Level: N/A',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _riskColor(risk).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        risk,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _riskColor(risk),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
