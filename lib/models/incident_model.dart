// models/incident_model.dart
import 'package:flutter/material.dart'; // Import for MaterialColor and IconData
import 'package:uuid/uuid.dart'; // Ensure uuid is in your pubspec.yaml

// Incident Category Enum
enum IncidentCategory {
  chemical,
  nearMiss,
  equipment,
  fire,
  spill,
  injury,
  environmental,
  safetyViolation,
  other,
}

// Extension on IncidentCategory to provide string and icon representations
extension IncidentCategoryExtension on IncidentCategory {
  String get categoryString {
    switch (this) {
      case IncidentCategory.chemical:
        return 'Chemical Spill';
      case IncidentCategory.nearMiss:
        return 'Near Miss';
      case IncidentCategory.equipment:
        return 'Equipment Failure';
      case IncidentCategory.fire:
        return 'Fire Incident';
      case IncidentCategory.spill:
        return 'General Spill';
      case IncidentCategory.injury:
        return 'Injury';
      case IncidentCategory.environmental:
        return 'Environmental';
      case IncidentCategory.safetyViolation:
        return 'Safety Violation';
      case IncidentCategory.other:
        return 'Other';
    }
  }

  IconData get categoryIcon {
    switch (this) {
      case IncidentCategory.chemical:
        return Icons.science;
      case IncidentCategory.nearMiss:
        return Icons.warning;
      case IncidentCategory.equipment:
        return Icons.build;
      case IncidentCategory.fire:
        return Icons.fireplace;
      case IncidentCategory.spill:
        return Icons.liquor;
      case IncidentCategory.injury:
        return Icons.healing;
      case IncidentCategory.environmental:
        return Icons.nature;
      case IncidentCategory.safetyViolation:
        return Icons.gavel;
      case IncidentCategory.other:
        return Icons.category;
    }
  }
}

// Incident Severity Enum
enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

// Extension on IncidentSeverity to provide string and color representations
extension IncidentSeverityExtension on IncidentSeverity {
  String get severityString {
    switch (this) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  Color get severityColor {
    switch (this) {
      case IncidentSeverity.low:
        return Colors.green;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.red;
      case IncidentSeverity.critical:
        return Colors.purple; // Or a more alarming color like deep red/black
    }
  }
}

class Incident {
  final String id;
  String title;
  String description;
  String location;
  DateTime incidentDate;
  final DateTime reportedDate; // Date when the incident was reported (created)
  IncidentCategory category;
  IncidentSeverity severity;
  bool isClosed;

  Incident({
    String? id,
    required this.title,
    required this.description,
    required this.location,
    required this.incidentDate,
    required this.category,
    required this.severity,
    this.isClosed = false,
  })  : id = id ?? const Uuid().v4(),
        reportedDate = DateTime.now(); // Set reportedDate automatically
}