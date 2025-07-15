class IncidentModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dateOccurred;
  final String location;
  final String severity;
  final String reportedBy;
  final List<String> attachments; // Optional: URLs or file paths

  IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateOccurred,
    required this.location,
    required this.severity,
    required this.reportedBy,
    this.attachments = const [],
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      dateOccurred: DateTime.tryParse(json['dateOccurred'] ?? '') ?? DateTime.now(),
      location: json['location'] ?? '',
      severity: json['severity'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'dateOccurred': dateOccurred.toIso8601String(),
      'location': location,
      'severity': severity,
      'reportedBy': reportedBy,
      'attachments': attachments,
    };
  }
}
