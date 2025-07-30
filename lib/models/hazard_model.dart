// models/hazard_model.dart
// models/hazard_model.dart (create this new file)
import 'package:flutter/material.dart';

enum HazardRisk {
  low,
  moderate,
  high,
  critical, // Added critical for more severity
}

extension HazardRiskExtension on HazardRisk {
  Color get color {
    switch (this) {
      case HazardRisk.low:
        return Colors.green;
      case HazardRisk.moderate:
        return Colors.orange;
      case HazardRisk.high:
        return Colors.red;
      case HazardRisk.critical:
        return Colors.red.shade900; // Even darker red for critical
    }
  }

  IconData get icon {
    switch (this) {
      case HazardRisk.low:
        return Icons.check_circle_outline;
      case HazardRisk.moderate:
        return Icons.warning_amber_outlined;
      case HazardRisk.high:
        return Icons.error_outline;
      case HazardRisk.critical:
        return Icons.crisis_alert; // A more urgent icon
    }
  }

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class Hazard {
  final String name;
  final double? currentValue;
  final String? unit; // e.g., '°C', '%', 'ppm'
  final double? highThreshold; // Value above which it's high
  final double? criticalThreshold; // Value above which it's critical
  final String category;
  final DateTime detectedAt;

  HazardRisk get risk {
    if (currentValue == null) {
      // For hazards like 'Toxic Spill', 'Fire Outbreak' which are binary
      // We assume they are high/critical if they exist in the list.
      // This logic can be refined if you have a separate 'is_active' flag.
      if (name == 'Fire Outbreak' || name == 'Toxic Leak' || name == 'Toxic Spill') {
        return HazardRisk.critical; // Treat these as critical if they appear
      }
      return HazardRisk.high; // Default for non-quantifiable but present hazards
    }

    if (criticalThreshold != null && currentValue! >= criticalThreshold!) {
      return HazardRisk.critical;
    }
    if (highThreshold != null && currentValue! >= highThreshold!) {
      return HazardRisk.high;
    }
    if (highThreshold != null && currentValue! >= highThreshold! * 0.75) { // Moderate if approaching high
      return HazardRisk.moderate;
    }
    return HazardRisk.low;
  }

  Hazard({
    required this.name,
    this.currentValue,
    this.unit,
    this.highThreshold,
    this.criticalThreshold,
    required this.category,
    required this.detectedAt,
  });
}

// Data for hazard categories
class HazardCategory {
  final String name;
  final IconData icon; // Icon for the category
  final Color color; // Color for the category

  HazardCategory({required this.name, required this.icon, required this.color});
}