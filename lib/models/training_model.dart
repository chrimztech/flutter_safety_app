// models/training_model.dart
import 'package:flutter/material.dart';

enum TrainingStatus {
  scheduled,
  upcoming,
  completed,
  overdue,
  missed, // Added missed status
}

extension TrainingStatusExtension on TrainingStatus {
  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  Color get color {
    switch (this) {
      case TrainingStatus.completed:
        return Colors.green;
      case TrainingStatus.upcoming:
        return Colors.blue; // Changed from orange to blue for upcoming
      case TrainingStatus.scheduled:
        return Colors.lightBlue; // A lighter blue for scheduled
      case TrainingStatus.overdue:
        return Colors.orange; // Overdue is more critical than just upcoming
      case TrainingStatus.missed:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TrainingStatus.completed:
        return Icons.check_circle_outline;
      case TrainingStatus.upcoming:
        return Icons.event;
      case TrainingStatus.scheduled:
        return Icons.calendar_today;
      case TrainingStatus.overdue:
        return Icons.access_time_filled;
      case TrainingStatus.missed:
        return Icons.cancel_outlined;
    }
  }
}

class Training {
  final String id; // Unique ID for each training (e.g., UUID from backend)
  String title;
  DateTime date;
  String description; // More details about the training
  String type; // e.g., "Online Course", "Workshop", "Drill"
  String assignedTo; // e.g., "All Staff", "Maintenance Dept", "John Doe"
  TrainingStatus status;

  Training({
    required this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.type = 'General',
    this.assignedTo = 'All Staff',
    this.status = TrainingStatus.scheduled,
  });

  // Factory constructor to create a Training object from a map (useful for mock data or API)
  factory Training.fromMap(Map<String, dynamic> map) {
    TrainingStatus parsedStatus;
    try {
      parsedStatus = TrainingStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == map['status'].toLowerCase());
    } catch (e) {
      parsedStatus = TrainingStatus.scheduled; // Default if status is unknown
    }

    return Training(
      id: map['id'] ?? UniqueKey().toString(), // Generate ID if not provided
      title: map['title'],
      date: DateTime.parse(map['date']),
      description: map['description'] ?? '',
      type: map['type'] ?? 'General',
      assignedTo: map['assignedTo'] ?? 'All Staff',
      status: parsedStatus,
    );
  }

  // Convert to map (useful for saving or sending to API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String().split('T')[0], // Just date part
      'description': description,
      'type': type,
      'assignedTo': assignedTo,
      'status': status.name,
    };
  }

  // Method to update status based on current date
  void updateStatusBasedOnDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final trainingDateOnly = DateTime(date.year, date.month, date.day);

    if (status == TrainingStatus.completed || status == TrainingStatus.missed) {
      return; // Do not change status if already completed or missed
    }

    if (trainingDateOnly.isBefore(today)) {
      status = TrainingStatus.overdue;
    } else if (trainingDateOnly.isAtSameMomentAs(today)) {
      status = TrainingStatus.upcoming; // Upcoming means today
    } else if (trainingDateOnly.isAfter(today) && trainingDateOnly.difference(today).inDays <= 7) {
      status = TrainingStatus.upcoming; // Within 7 days is also upcoming
    } else {
      status = TrainingStatus.scheduled;
    }
  }
}