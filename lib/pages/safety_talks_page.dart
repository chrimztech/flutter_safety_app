// pages/safety_talks_page.dart
// This file contains a professional and visually appealing
// Safety Talks & Reports page for a Flutter app.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../pages/create_toolbox_talk_page.dart';

// A simple model for a Safety Talk entry
class _SafetyTalk {
  final String title;
  final DateTime date;
  final String filePath;
  final String type; // e.g., 'PDF Upload', 'App-Generated'
  final String? description; // Optional for app-generated talks
  final List<String>? keyPoints; // Optional for app-generated talks

  _SafetyTalk(this.title, this.date, this.filePath, this.type, {this.description, this.keyPoints});
}

// The main Safety Talks page widget.
class SafetyTalksPage extends StatefulWidget {
  const SafetyTalksPage({super.key});

  @override
  State<SafetyTalksPage> createState() => _SafetyTalksPageState();
}

class _SafetyTalksPageState extends State<SafetyTalksPage> {
  // Sample pre-loaded safety talks.
  final List<_SafetyTalk> _safetyTalks = [
    // IMPORTANT: In a real app, 'assets/docs/' paths are not directly
    // openable by OpenFilex. You would need to copy them to a temporary
    // directory first. The upload functionality, however, works as expected
    // because FilePicker provides an absolute path.
    _SafetyTalk('Emergency Evacuation Procedures', DateTime(2025, 7, 20), 'assets/docs/emergency_evacuation.pdf', 'Pre-loaded PDF'),
    _SafetyTalk('Proper Lifting Techniques', DateTime(2025, 7, 13), 'assets/docs/lifting_techniques.pdf', 'Pre-loaded PDF'),
    _SafetyTalk('Hazard Communication Standard', DateTime(2025, 7, 6), 'assets/docs/hazard_communication.pdf', 'Pre-loaded PDF'),
  ];

  // Function to handle file uploads.
  Future<void> _uploadReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      final file = result.files.first;
      setState(() {
        _safetyTalks.add(
          _SafetyTalk(
            file.name!,
            DateTime.now(),
            file.path!, // Use file.path for uploaded files
            'Uploaded File',
          ),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} uploaded successfully.'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    }
  }

  // Function to view a safety talk file or details.
  Future<void> _viewTalk(_SafetyTalk talk) async {
    if (talk.type == 'App-Generated') {
      _showAppGeneratedTalkDetails(talk);
    } else {
      try {
        String path = talk.filePath;
        if (path.startsWith('assets/')) {
          // This is a simplified message for assets as OpenFilex cannot open them directly.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open asset files directly: ${talk.filePath}'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
          return;
        }

        final result = await OpenFilex.open(path);
        if (mounted) {
          if (result.type == ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opened ${talk.title}'),
                backgroundColor: Colors.green.shade600,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open ${talk.title}: ${result.message}'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening file: ${e.toString()}'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
        debugPrint('Error opening file: $e');
      }
    }
  }

  // Function to navigate to the page for creating a new talk.
  Future<void> _createNewTalk() async {
    // Navigate to the new page and await the result (the new talk's data)
    final newTalkData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSafetyTalkPage()),
    );

    // If newTalkData is not null, it means the user saved a new talk.
    if (newTalkData != null) {
      setState(() {
        _safetyTalks.add(
          _SafetyTalk(
            newTalkData['title'] as String,
            DateTime.now(),
            'app_generated_talk_${DateTime.now().millisecondsSinceEpoch}.txt',
            'App-Generated',
            description: newTalkData['description'] as String?,
            keyPoints: List<String>.from(newTalkData['keyPoints'] as List),
          ),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newTalkData['title']} created successfully.'),
            backgroundColor: Colors.blue.shade600,
          ),
        );
      }
    }
  }

  // Function to display details of an app-generated talk in a dialog.
  void _showAppGeneratedTalkDetails(_SafetyTalk talk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(talk.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Date: ${_formatDate(talk.date)}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(talk.description ?? 'No description provided.'),
                if (talk.keyPoints != null && talk.keyPoints!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Key Points:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...talk.keyPoints!.map((point) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 2),
                    child: Text('• $point'),
                  )).toList(),
                ],
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

  // Helper function to format the date.
  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Talks & Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50], // Very light grey background for a professional look
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action Buttons Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      onPressed: _uploadReport,
                      icon: const Icon(Icons.cloud_upload, size: 24),
                      label: const Text('Upload Report', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      onPressed: _createNewTalk,
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text('New Talk', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // List of Safety Talks
              Text(
                'Safety Talks & Reports',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
              ),
              const Divider(height: 20, thickness: 2, color: Colors.blueGrey),
              Expanded(
                child: _safetyTalks.isEmpty
                    ? Center(
                        child: Text(
                          'No safety talks or reports available yet.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _safetyTalks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final talk = _safetyTalks[index];
                          return InkWell(
                            onTap: () => _viewTalk(talk),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Leading Icon
                                  Icon(
                                    talk.type.contains('PDF') || talk.type.contains('File')
                                        ? Icons.picture_as_pdf
                                        : Icons.lightbulb_outline, // Use a different icon for app-generated talks
                                    color: Colors.blue.shade700,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 16),
                                  // Title and Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          talk.title,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(talk.date),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                        Text(
                                          'Source: ${talk.type}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.blueGrey,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Trailing Icon
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
