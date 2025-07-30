// pages/safety_talks_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../pages/create_safety_talk_page.dart'; // IMPORTANT: Adjust 'my_app_name' to your actual project name
// IMPORTANT: Adjust 'my_app_name' to your actual project name

// You might need to add a package like 'open_filex' for viewing files:
import 'package:open_filex/open_filex.dart'; // Add this to your pubspec.yaml if you want to implement file opening

class SafetyTalksPage extends StatefulWidget {
  const SafetyTalksPage({super.key});

  @override
  State<SafetyTalksPage> createState() => _SafetyTalksPageState();
}

// A simple model for a Safety Talk entry
class _SafetyTalk {
  final String title;
  final DateTime date;
  final String filePath; // Mock path for now, for uploaded or app-generated
  final String type; // e.g., 'PDF Upload', 'App-Generated'
  final String? description; // Optional for app-generated talks
  final List<String>? keyPoints; // Optional for app-generated talks

  _SafetyTalk(this.title, this.date, this.filePath, this.type, {this.description, this.keyPoints});
}

class _SafetyTalksPageState extends State<SafetyTalksPage> {
  // Sample pre-loaded safety talks (you'd typically load these from a database/API)
  final List<_SafetyTalk> _safetyTalks = [
    _SafetyTalk('Emergency Evacuation Procedures', DateTime(2025, 7, 20), 'assets/docs/emergency_evacuation.pdf', 'Pre-loaded PDF'),
    _SafetyTalk('Proper Lifting Techniques', DateTime(2025, 7, 13), 'assets/docs/lifting_techniques.pdf', 'Pre-loaded PDF'),
    _SafetyTalk('Hazard Communication Standard', DateTime(2025, 7, 6), 'assets/docs/hazard_communication.pdf', 'Pre-loaded PDF'),
  ];

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
            file.name,
            DateTime.now(),
            file.path!, // Use file.path for uploaded files
            'Uploaded File',
          ),
        );
      });

      // Show success message
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

  // Placeholder for viewing a safety talk file
  Future<void> _viewTalk(_SafetyTalk talk) async {
    if (talk.type == 'App-Generated') {
      // For app-generated talks, we can show a detailed view in a dialog or new page
      _showAppGeneratedTalkDetails(talk);
    } else {
      // For file-based talks, attempt to open the file
      // In a real application, you would use a package like 'open_filex'
      // to open the file based on its path.
      // Example:
      // try {
      //   await OpenFilex.open(talk.filePath);
      // } catch (e) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: Text('Could not open file: ${e.toString()}'),
      //         backgroundColor: Colors.red.shade600,
      //       ),
      //     );
      //   }
      // }

      // For now, we'll just show a simple message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attempting to view: ${talk.title} (${talk.filePath})'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
      debugPrint('Viewing Safety Talk: ${talk.title} at ${talk.filePath}');
    }
  }

  // Navigate to CreateSafetyTalkPage and handle returned data
  Future<void> _createNewTalk() async {
    final newTalkData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSafetyTalkPage()),
    );

    if (newTalkData != null && newTalkData is Map<String, dynamic>) {
      setState(() {
        _safetyTalks.add(
          _SafetyTalk(
            newTalkData['title'],
            DateTime.now(),
            'app_generated_talk_${DateTime.now().millisecondsSinceEpoch}.txt', // A mock path for app-generated
            'App-Generated',
            description: newTalkData['description'],
            keyPoints: List<String>.from(newTalkData['keyPoints']),
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

  // Function to display details of an app-generated talk
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


  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy – h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Safety Talks & Reports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white), // For back button icon
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    onPressed: _uploadReport,
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text('Upload Report'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    onPressed: _createNewTalk, // This now navigates to the new page
                    icon: const Icon(Icons.add_comment, size: 20),
                    label: const Text('New Talk'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Available Safety Talks & Reports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 10), // Spacing between cards
                      itemBuilder: (context, index) {
                        final talk = _safetyTalks[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Icon(
                              talk.type.contains('PDF') || talk.type.contains('File')
                                  ? Icons.picture_as_pdf
                                  : Icons.notes, // Differentiate icon by type
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                            title: Text(
                              talk.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${_formatDate(talk.date)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                                ),
                                Text(
                                  'Source: ${talk.type}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility),
                              color: Colors.blue.shade700,
                              onPressed: () => _viewTalk(talk),
                            ),
                            onTap: () => _viewTalk(talk), // Also view on tap
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}