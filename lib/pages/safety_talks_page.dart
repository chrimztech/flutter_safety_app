// pages/safety_talks_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../pages/create_safety_talk_page.dart';
import 'package:open_filex/open_filex.dart'; // Ensure this import is here

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
    // IMPORTANT: For 'assets/docs/' files, you need to ensure they are actually
    // added to your pubspec.yaml under the 'assets:' section.
    // Also, OpenFilex.open() works best with absolute file paths, not assets.
    // For assets, you'd typically load them into memory or a temporary file first.
    // For this example, we'll assume 'assets/docs/' are placeholders for files
    // that would be downloaded or generated to a temporary path.
    // If you literally want to open a PDF from assets, you'd need to copy it
    // to a temporary directory first.
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
            file.path!, // Use file.path for uploaded files (this is an absolute path)
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

  // Function to view a safety talk file
  Future<void> _viewTalk(_SafetyTalk talk) async {
    if (talk.type == 'App-Generated') {
      _showAppGeneratedTalkDetails(talk);
    } else {
      // Use open_filex to open the file
      try {
        // For assets, you need to copy them to a temporary directory first
        // This is a simplified example; a real app might use path_provider
        // to get application documents directory for temp files.
        String path = talk.filePath;
        if (path.startsWith('assets/')) {
          // This part is complex. OpenFilex cannot directly open assets.
          // You would need to load the asset as bytes and write it to a temporary file.
          // For simplicity in this demo, we'll just show a message for assets.
          // In a real app, you'd use:
          // final byteData = await rootBundle.load(talk.filePath);
          // final file = File('${(await getTemporaryDirectory()).path}/${talk.filePath.split('/').last}');
          // await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          // path = file.path;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot directly open asset files. Please implement asset copying to temp directory: ${talk.filePath}'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
          return; // Exit if it's an asset for now
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
        // Set AppBar background color to blue
        backgroundColor: Colors.blue.shade700, // Changed to a specific blue shade
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
                      backgroundColor: Theme.of(context).colorScheme.secondary, // Uses secondary color (often blue/accent)
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