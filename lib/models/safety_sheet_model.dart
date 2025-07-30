// models/safety_sheet_model.dart
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart'; // <--- ADD THIS LINE

class SafetySheet {
  final String id; // Unique ID for each sheet
  String title;
  final String filePath; // Simulate actual file path or URL
  final String fileExtension; // e.g., 'pdf', 'docx', 'xlsx'
  final DateTime uploadDate;

  SafetySheet({
    required String? id, // Nullable to allow generating new IDs
    required this.title,
    required this.filePath,
    required this.fileExtension,
    required this.uploadDate,
  }) : id = id ?? const Uuid().v4(); // Generate UUID if ID is null

  // Factory constructor for creating from a map (e.g., from JSON/backend)
  factory SafetySheet.fromMap(Map<String, dynamic> map) {
    return SafetySheet(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      fileExtension: map['fileExtension'],
      uploadDate: DateTime.parse(map['uploadDate']),
    );
  }

  // Convert to map for storage or API calls
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileExtension': fileExtension,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }

  // Helper to get Icon based on file extension
  static IconData getIconForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_outlined;
      case 'xlsx':
      case 'xls':
        return Icons.grid_on_outlined;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_outlined;
      case 'txt':
        return Icons.text_snippet_outlined;
      case 'zip':
      case 'rar':
        return Icons.archive_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // Helper to get Color based on file extension
  static Color getColorForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade600;
      case 'docx':
      case 'doc':
        return Colors.blue.shade700;
      case 'xlsx':
      case 'xls':
        return Colors.green.shade700;
      case 'pptx':
      case 'ppt':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}