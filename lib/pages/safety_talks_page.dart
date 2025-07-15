// pages/safety_talks_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class SafetyTalksPage extends StatefulWidget {
  const SafetyTalksPage({super.key});

  @override
  State<SafetyTalksPage> createState() => _SafetyTalksPageState();
}

class _SafetyTalksPageState extends State<SafetyTalksPage> {
  final List<_SafetyReport> reports = [];

  Future<void> _uploadReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      final file = result.files.first;
      setState(() {
        reports.add(_SafetyReport(file.name, DateTime.now()));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.name} uploaded successfully.'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy – h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Safety Talks'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              onPressed: _uploadReport,
              icon: const Icon(Icons.upload_file, size: 20),
              label: const Text('Upload Report (PDF / DOC)'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Uploaded Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: reports.isEmpty
                  ? const Center(
                      child: Text(
                        'No reports uploaded yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return ListTile(
                          leading: const Icon(Icons.description, color: Colors.green),
                          title: Text(report.name),
                          subtitle: Text('Uploaded on ${_formatDate(report.dateTime)}'),
                          trailing: Icon(Icons.check_circle, color: Colors.green.shade600),
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

class _SafetyReport {
  final String name;
  final DateTime dateTime;

  _SafetyReport(this.name, this.dateTime);
}
