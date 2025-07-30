// models/compliance_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Add uuid package to your pubspec.yaml

// Enum for compliance status
enum ComplianceStatus {
  pending,
  completed,
  overdue,
  // Add other statuses if needed
}

// Extension to add properties to ComplianceStatus enum
extension ComplianceStatusExtension on ComplianceStatus {
  String get displayString {
    switch (this) {
      case ComplianceStatus.pending:
        return 'Pending';
      case ComplianceStatus.completed:
        return 'Completed';
      case ComplianceStatus.overdue:
        return 'Overdue';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplianceStatus.pending:
        return Icons.hourglass_empty;
      case ComplianceStatus.completed:
        return Icons.check_circle;
      case ComplianceStatus.overdue:
        return Icons.error;
    }
  }

  Color get color {
    switch (this) {
      case ComplianceStatus.pending:
        return Colors.orange.shade700;
      case ComplianceStatus.completed:
        return Colors.green.shade700;
      case ComplianceStatus.overdue:
        return Colors.red.shade700;
    }
  }
}

// Compliance Item Model
class ComplianceItem {
  final String id; // Unique ID for each item
  String title;
  String description;
  DateTime dueDate;
  ComplianceStatus status;
  DateTime? completionDate; // Nullable for pending/overdue

  ComplianceItem({
    String? id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.status = ComplianceStatus.pending,
    this.completionDate,
  }) : id = id ?? const Uuid().v4(); // Generate a unique ID if not provided

  // Method to update status and completion date
  void updateStatus(ComplianceStatus newStatus) {
    status = newStatus;
    if (newStatus == ComplianceStatus.completed) {
      completionDate = DateTime.now();
    } else {
      completionDate = null; // Clear completion date if not completed
    }
  }
}

// Extension to get end of day for DateTime comparison
extension DateTimeExtension on DateTime {
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}