// pages/hazard_detection_page.dart
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago; 
import 'package:flutter/material.dart';
import '../models/hazard_model.dart'; 

class HazardDetectionPage extends StatefulWidget {
  const HazardDetectionPage({super.key});

  @override
  State<HazardDetectionPage> createState() => _HazardDetectionPageState();
}

class _HazardDetectionPageState extends State<HazardDetectionPage> {
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _dataRefreshTimer; // For automatic refresh

  // Categories definition
  final List<HazardCategory> _categories = [
    HazardCategory(name: 'Environmental', icon: Icons.nature, color: Colors.green.shade700),
    HazardCategory(name: 'Chemical', icon: Icons.science, color: Colors.purple.shade700),
    HazardCategory(name: 'Mechanical', icon: Icons.build, color: Colors.blue.shade700),
    HazardCategory(name: 'Emergency', icon: Icons.crisis_alert, color: Colors.red.shade700),
  ];

  // Live hazard data - will be updated by a "sensor" simulation
  List<Hazard> _liveHazards = [];

  @override
  void initState() {
    super.initState();
    _generateInitialHazards();
    _startAutoRefresh(); // Start simulating real-time data
  }

  @override
  void dispose() {
    _dataRefreshTimer?.cancel(); // Cancel timer when page is disposed
    _searchController.dispose();
    super.dispose();
  }

  // --- Mock Data Generation & Simulation ---

  void _generateInitialHazards() {
    _liveHazards = [
      Hazard(
          name: 'Air Temp.',
          currentValue: 38.0, // Lusaka temperature can reach this
          unit: '°C',
          highThreshold: 35.0,
          criticalThreshold: 40.0,
          category: 'Environmental',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 5))),
      Hazard(
          name: 'Humidity',
          currentValue: 85.0,
          unit: '%',
          highThreshold: 80.0,
          criticalThreshold: 90.0,
          category: 'Environmental',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 10))),
      Hazard(
          name: 'Air Quality (CO₂)',
          currentValue: 800.0,
          unit: 'ppm',
          highThreshold: 1000.0,
          criticalThreshold: 1500.0,
          category: 'Environmental',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 2))),
      Hazard(
          name: 'Oxygen Level',
          currentValue: 18.0,
          unit: '%',
          highThreshold: 21.0,
          criticalThreshold: 19.5, // Low oxygen is critical
          category: 'Environmental',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 1))),
      Hazard(
          name: 'Particulate Matter (PM2.5)',
          currentValue: 70.0,
          unit: 'µg/m³',
          highThreshold: 50.0,
          criticalThreshold: 100.0,
          category: 'Environmental',
          detectedAt: DateTime.now()),
      Hazard(
          name: 'Chemical Leak',
          currentValue: null,
          category: 'Chemical',
          detectedAt: DateTime.now().subtract(const Duration(hours: 1))),
      Hazard(
          name: 'Radiation',
          currentValue: 0.15,
          unit: 'µSv/hr',
          highThreshold: 0.20,
          criticalThreshold: 0.50,
          category: 'Chemical',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 30))),
      Hazard(
          name: 'Methane Gas',
          currentValue: 0.02,
          unit: '%LEL',
          highThreshold: 0.5,
          criticalThreshold: 1.0,
          category: 'Chemical',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 5))),
      Hazard(
          name: 'Pressure Level (Boiler)',
          currentValue: 1020.0,
          unit: 'kPa',
          highThreshold: 1000.0,
          criticalThreshold: 1050.0,
          category: 'Mechanical',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 8))),
      Hazard(
          name: 'Noise Level',
          currentValue: 95.0,
          unit: 'dB',
          highThreshold: 85.0,
          criticalThreshold: 100.0,
          category: 'Mechanical',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 15))),
      Hazard(
          name: 'Fire Outbreak',
          currentValue: null,
          category: 'Emergency',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 20))),
    ];
    // Sort by risk level initially
    _liveHazards.sort((a, b) => b.risk.index.compareTo(a.risk.index));
  }

  void _startAutoRefresh() {
    _dataRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _simulateSensorDataUpdate();
    });
  }

  void _simulateSensorDataUpdate() {
    final random = Random();
    setState(() {
      _liveHazards = _liveHazards.map((hazard) {
        if (hazard.currentValue != null) {
          // Simulate slight fluctuations or spikes for numerical values
          double newValue = hazard.currentValue! + (random.nextDouble() * 2 - 1) * 0.1 * (hazard.highThreshold ?? 10.0);
          if (newValue < 0) newValue = 0; // Prevent negative values

          // Simulate a critical spike occasionally for a few hazards
          if (random.nextDouble() < 0.05 && (hazard.name == 'Air Temp.' || hazard.name == 'Particulate Matter (PM2.5)')) {
            newValue = (hazard.criticalThreshold ?? (hazard.highThreshold! * 1.5)) * (1 + random.nextDouble() * 0.1);
          }

          return Hazard(
            name: hazard.name,
            currentValue: newValue,
            unit: hazard.unit,
            highThreshold: hazard.highThreshold,
            criticalThreshold: hazard.criticalThreshold,
            category: hazard.category,
            detectedAt: DateTime.now(),
          );
        } else {
          // For binary hazards like 'Chemical Leak' or 'Fire Outbreak'
          // Simulate them appearing/disappearing occasionally
          if (random.nextDouble() < 0.02 && (hazard.name == 'Chemical Leak' || hazard.name == 'Fire Outbreak')) {
             return Hazard( // Create a new instance to update detectedAt
              name: hazard.name,
              currentValue: null,
              category: hazard.category,
              detectedAt: DateTime.now(),
            );
          }
          return hazard; // No change if not a simulated event
        }
      }).toList();

      // Ensure that if a critical event is "simulated", it is added if not present
      if (random.nextDouble() < 0.01 && !_liveHazards.any((h) => h.name == 'Toxic Leak' && h.risk == HazardRisk.critical)) {
        _liveHazards.add(Hazard(
          name: 'Toxic Leak',
          currentValue: null,
          category: 'Emergency',
          detectedAt: DateTime.now(),
        ));
      }
      // Clean up old critical events occasionally (e.g., if resolved)
      _liveHazards.removeWhere((h) => (h.name == 'Toxic Leak' || h.name == 'Fire Outbreak' || h.name == 'Chemical Leak') && random.nextDouble() < 0.1);


      // Re-sort hazards by risk level after update
      _liveHazards.sort((a, b) => b.risk.index.compareTo(a.risk.index));
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    // Simulate fetching fresh data
    await Future.delayed(const Duration(seconds: 2));
    _simulateSensorDataUpdate(); // Call simulation to update values
    setState(() => _isLoading = false);
  }

  // Compute overall risk from all hazards
  HazardRisk get _overallRisk {
    if (_liveHazards.any((h) => h.risk == HazardRisk.critical)) {
      return HazardRisk.critical;
    } else if (_liveHazards.any((h) => h.risk == HazardRisk.high)) {
      return HazardRisk.high;
    } else if (_liveHazards.any((h) => h.risk == HazardRisk.moderate)) {
      return HazardRisk.moderate;
    }
    return HazardRisk.low;
  }

  // Filter hazards by search query
  List<Hazard> _filterHazards(List<Hazard> hazards) {
    if (_searchQuery.isEmpty) return hazards;
    return hazards
        .where((h) => h.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overallRisk = _overallRisk;

    // Filter hazards to display, preserving category structure
    final Map<String, List<Hazard>> filteredCategorizedHazards = {};
    for (var category in _categories) {
      final hazardsInCategory = _liveHazards
          .where((h) => h.category == category.name)
          .toList();
      final filteredHazards = _filterHazards(hazardsInCategory);
      if (filteredHazards.isNotEmpty) {
        filteredCategorizedHazards[category.name] = filteredHazards;
      }
    }

    // Determine if there are any hazards to display after filtering
    final bool hasHazardsToDisplay = filteredCategorizedHazards.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Hazard Detection', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
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
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60), // Slightly increased height for search
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white), // Text color for input
              decoration: InputDecoration(
                hintText: 'Search hazards...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.blue.shade700, // Darker blue for search bar
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).primaryColor, // Pull-to-refresh color
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overall risk summary
            Card(
              color: overallRisk.color.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(overallRisk.icon, color: overallRisk.color, size: 48),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Hazard Level',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          overallRisk.displayName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: overallRisk.color,
                          ),
                        ),
                        if (overallRisk == HazardRisk.critical)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Immediate action required!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: overallRisk.color.darken(0.2), // Darken the critical text
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Display hazards or a message if no hazards found
            if (!hasHazardsToDisplay)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No active hazards detected.'
                            : 'No hazards match your search.',
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'All systems appear to be operating within safe limits.'
                            : 'Try adjusting your search query.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              // Hazard categories with grouped hazards
              ..._categories.map((category) {
                final hazardsForCategory = filteredCategorizedHazards[category.name];
                if (hazardsForCategory == null || hazardsForCategory.isEmpty) {
                  return const SizedBox.shrink(); // Hide category if no filtered hazards
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 16),
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '${category.name} Hazards',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: category.color.darken(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...hazardsForCategory.map((hazard) {
                      return _buildHazardListItem(hazard, theme);
                    }).toList(),
                    const SizedBox(height: 16), // Spacing between categories
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardListItem(Hazard hazard, ThemeData theme) {
    final bool isCritical = hazard.risk == HazardRisk.critical;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCritical ? 8 : 4, // Higher elevation for critical hazards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCritical ? BorderSide(color: hazard.risk.color, width: 2) : BorderSide.none,
      ),
      shadowColor: hazard.risk.color.withOpacity(isCritical ? 0.6 : 0.2), // More prominent shadow
      child: InkWell( // Make it tappable for details
        onTap: () {
          _showHazardDetailsDialog(context, hazard);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(hazard.risk.icon, color: hazard.risk.color, size: 36),
              const SizedBox(width: 12),
              Expanded( // <-- This is the fix for the overflow issue
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hazard.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hazard.currentValue != null
                          ? 'Current: ${hazard.currentValue!.toStringAsFixed(1)}${hazard.unit ?? ''}'
                          : 'Status: Detected',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hazard.risk.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hazard.risk.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hazard.risk.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timeago.format(hazard.detectedAt, locale: 'en_short')}', // Using timeago for relative time
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHazardDetailsDialog(BuildContext context, Hazard hazard) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(hazard.risk.icon, color: hazard.risk.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hazard.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: hazard.risk.color.darken(0.2),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Category: ${hazard.category}'),
                const SizedBox(height: 8),
                if (hazard.currentValue != null) ...[
                  Text('Current Value: ${hazard.currentValue!.toStringAsFixed(2)}${hazard.unit ?? ''}'),
                  Text('High Threshold: ${hazard.highThreshold?.toStringAsFixed(2)}${hazard.unit ?? 'N/A'}'),
                  Text('Critical Threshold: ${hazard.criticalThreshold?.toStringAsFixed(2)}${hazard.unit ?? 'N/A'}'),
                  const SizedBox(height: 8),
                ],
                Text('Risk Level: ${hazard.risk.displayName}', style: TextStyle(color: hazard.risk.color, fontWeight: FontWeight.bold)),
                Text('Detected At: ${DateFormat('yyyy-MM-dd HH:mm').format(hazard.detectedAt)}'),
                const SizedBox(height: 16),
                if (hazard.risk == HazardRisk.critical || hazard.risk == HazardRisk.high)
                  Text(
                    'Recommended Action: Immediate investigation and mitigation. Refer to emergency protocols for ${hazard.name}.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 16),
                // Add more details or action buttons here
                ElevatedButton.icon(
                  onPressed: () {
                    // Simulate acknowledging or resolving the hazard
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hazard "${hazard.name}" acknowledged.')),
                    );
                    // In a real app, this would send an update to a backend
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Acknowledge Hazard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Utility extension for color darkening
extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}