// models/hazard_model.dart
// models/hazard_model.dart
import 'package:flutter/material.dart';

// Enum to represent the risk level of a hazard
enum HazardRisk {
  critical,
  high,
  moderate,
  low,
}

// Extension to add properties to the HazardRisk enum
extension HazardRiskExtension on HazardRisk {
  String get displayName {
    switch (this) {
      case HazardRisk.critical:
        return 'Critical';
      case HazardRisk.high:
        return 'High';
      case HazardRisk.moderate:
        return 'Moderate';
      case HazardRisk.low:
      default:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case HazardRisk.critical:
        return Colors.red.shade800;
      case HazardRisk.high:
        return Colors.orange.shade800;
      case HazardRisk.moderate:
        return Colors.yellow.shade800;
      case HazardRisk.low:
      default:
        return Colors.green.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case HazardRisk.critical:
        return Icons.warning_rounded;
      case HazardRisk.high:
        return Icons.warning_rounded;
      case HazardRisk.moderate:
        return Icons.info_rounded;
      case HazardRisk.low:
      default:
        return Icons.check_circle_rounded;
    }
  }
}

// Model for a single hazard category
class HazardCategory {
  final String name;
  final IconData icon;
  final Color color;

  HazardCategory({required this.name, required this.icon, required this.color});
}

// Main model for a detected hazard
class Hazard {
  final String name;
  final double? currentValue;
  final String? unit;
  final double? highThreshold;
  final double? criticalThreshold;
  final String category;
  final DateTime detectedAt;

  Hazard({
    required this.name,
    this.currentValue,
    this.unit,
    this.highThreshold,
    this.criticalThreshold,
    required this.category,
    required this.detectedAt,
  });

  // A getter to compute the risk level based on thresholds
  HazardRisk get risk {
    if (currentValue == null) {
      // For binary hazards like a "Fire Outbreak"
      return HazardRisk.critical;
    }
    if (criticalThreshold != null && currentValue! >= criticalThreshold!) {
      return HazardRisk.critical;
    }
    if (highThreshold != null && currentValue! >= highThreshold!) {
      return HazardRisk.high;
    }
    // Special case for low oxygen being critical
    if (name == 'Oxygen Level' && currentValue! < (criticalThreshold ?? 19.5)) {
      return HazardRisk.critical;
    }
    if (name == 'Oxygen Level' && currentValue! < (highThreshold ?? 21.0)) {
      return HazardRisk.high;
    }
    return HazardRisk.low;
  }
}