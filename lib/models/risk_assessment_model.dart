// models/risk_assessment_model.dart
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart'; // Make sure this is imported!

enum RiskAssessmentStatus { open, closed, review }

// Create an extension on RiskAssessmentStatus to add helper getters
extension RiskAssessmentStatusExtension on RiskAssessmentStatus {
  String get nameString { // Renamed from statusString to avoid confusion and better reflect its purpose
    switch (this) {
      case RiskAssessmentStatus.open:
        return 'Open';
      case RiskAssessmentStatus.closed:
        return 'Closed';
      case RiskAssessmentStatus.review:
        return 'Review';
    }
  }

  Color get color {
    switch (this) {
      case RiskAssessmentStatus.open:
        return Colors.orange.shade700;
      case RiskAssessmentStatus.closed:
        return Colors.green.shade700;
      case RiskAssessmentStatus.review:
        return Colors.purple.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case RiskAssessmentStatus.open:
        return Icons.warning_amber_rounded;
      case RiskAssessmentStatus.closed:
        return Icons.check_circle_outline_rounded;
      case RiskAssessmentStatus.review:
        return Icons.pending_actions_rounded;
    }
  }
}

class RiskAssessment {
  final String id;
  String title;
  String details;
  DateTime assessmentDate;
  RiskAssessmentStatus status;

  RiskAssessment({
    String? id,
    required this.title,
    this.details = '',
    required this.assessmentDate,
    this.status = RiskAssessmentStatus.open,
  }) : id = id ?? const Uuid().v4();

  // No need for statusString, getStatusColor, getStatusIcon here anymore, they are in the extension!

  // If you need to convert a string to a status enum (e.g., from a backend):
  static RiskAssessmentStatus statusFromString(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'open':
        return RiskAssessmentStatus.open;
      case 'closed':
        return RiskAssessmentStatus.closed;
      case 'review':
        return RiskAssessmentStatus.review;
      default:
        return RiskAssessmentStatus.open; // Default or handle error
    }
  }
}