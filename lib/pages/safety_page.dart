// pages/safety_page.dart
import 'package:flutter/material.dart';

class SafetySheetsPage extends StatefulWidget {
  const SafetySheetsPage({super.key});

  @override
  State<SafetySheetsPage> createState() => _SafetySheetsPageState();
}

class _SafetySheetsPageState extends State<SafetySheetsPage> {
  final List<_SafetySheet> _allSheets = [
    _SafetySheet('Fire Safety', 'PDF', DateTime(2023, 3, 10)),
    _SafetySheet('Chemical Handling', 'DOCX', DateTime(2023, 4, 5)),
    _SafetySheet('Machine Operation', 'PDF', DateTime(2023, 5, 20)),
    _SafetySheet('Emergency Procedures', 'PDF', DateTime(2023, 6, 15)),
    _SafetySheet('Hazardous Materials', 'DOCX', DateTime(2023, 7, 1)),
  ];

  List<_SafetySheet> _filteredSheets = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _filteredSheets = List.from(_allSheets);
  }

  void _filterSheets(String query) {
    setState(() {
      _search = query.toLowerCase();
      _filteredSheets = _allSheets
          .where((sheet) => sheet.title.toLowerCase().contains(_search))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Data Sheets'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search safety sheets...',
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterSheets,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredSheets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            'No safety sheets found.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSheets.length,
                      itemBuilder: (context, index) {
                        final sheet = _filteredSheets[index];
                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 18),
                            leading: Icon(
                              sheet.type == 'PDF'
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.description_outlined,
                              color: sheet.type == 'PDF'
                                  ? Colors.red.shade400
                                  : Colors.blue.shade700,
                              size: 32,
                            ),
                            title: Text(
                              sheet.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Row(
                              children: [
                                Chip(
                                  label: Text(sheet.type),
                                  labelStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                  backgroundColor: sheet.type == 'PDF'
                                      ? Colors.red.shade400
                                      : Colors.blue.shade600,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 0),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Uploaded: ${sheet.date.toLocal().toShortDateString()}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.download_rounded),
                              tooltip: 'Download Sheet',
                              color: Colors.blue.shade700,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Downloading "${sheet.title}"...'),
                                    backgroundColor: Colors.blue.shade600,
                                  ),
                                );
                              },
                            ),
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

class _SafetySheet {
  final String title;
  final String type;
  final DateTime date;
  _SafetySheet(this.title, this.type, this.date);
}

extension DateFormatting on DateTime {
  String toShortDateString() =>
      '${year.toString()}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
