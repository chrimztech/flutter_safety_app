// models/safety_sheet_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SafetySheet {
  final String id;
  final String title;
  final String filePath; // The path to the file on the device
  final String fileExtension;
  final DateTime uploadDate;

  SafetySheet({
    String? id,
    required this.title,
    required this.filePath,
    required this.fileExtension,
    required this.uploadDate,
  }) : id = id ?? const Uuid().v4();

  // Utility method to get an icon based on file extension
  static IconData getIconForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.article_rounded;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_rounded;
      case 'txt':
        return Icons.description_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // Utility method to get a color based on file extension
  static Color getColorForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade700;
      case 'docx':
      case 'doc':
        return Colors.blue.shade700;
      case 'xlsx':
      case 'xls':
        return Colors.green.shade700;
      case 'txt':
        return Colors.grey.shade700;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple.shade700;
      default:
        return Colors.amber.shade700;
    }
  }
}