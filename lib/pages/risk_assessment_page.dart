// pages/risk_assessment_page.dart
import 'package:flutter/material.dart';
import 'quickaccess_bar.dart';

class RiskAssessmentPage extends StatefulWidget {
  const RiskAssessmentPage({super.key});

  @override
  State<RiskAssessmentPage> createState() => _RiskAssessmentPageState();
}

class _RiskAssessmentPageState extends State<RiskAssessmentPage> {
  final List<Map<String, dynamic>> _assessments = [
    {
      'title': 'Chemical Handling',
      'date': '2025-07-20',
      'status': 'Open',
      'details': 'Handling chemicals safely and effectively.',
    },
    {
      'title': 'Machine Operation',
      'date': '2025-06-15',
      'status': 'Closed',
      'details': 'Assessment for machine operation risks.',
    },
    {
      'title': 'Fire Drill',
      'date': '2025-05-01',
      'status': 'Open',
      'details': 'Regular fire safety drill evaluation.',
    },
  ];

  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  void _openAddDialog() {
    _titleController.clear();
    _detailsController.clear();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('New Risk Assessment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Assessment Title',
                    prefixIcon: const Icon(Icons.assignment),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Details (Optional)',
                    prefixIcon: const Icon(Icons.info_outline),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final title = _titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Assessment title is required'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final newItem = {
                          'title': title,
                          'date': DateTime.now().toString().substring(0, 10),
                          'status': 'Open',
                          'details': _detailsController.text.trim(),
                        };

                        setState(() {
                          _assessments.insert(0, newItem);
                        });
                        _listKey.currentState?.insertItem(0);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'open' => Colors.orange,
      'closed' => Colors.green,
      _ => Colors.grey,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status.toLowerCase()) {
      'open' => Icons.lock_open,
      'closed' => Icons.lock,
      _ => Icons.help_outline,
    };
  }

  Widget _buildAssessmentItem(BuildContext context, int index, Animation<double> animation) {
    final item = _assessments[index];

    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          title: Text(item['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text("Date: ${item['date']}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor(item['status']).withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(item['status']),
                    color: _statusColor(item['status']), size: 18),
                const SizedBox(width: 6),
                Text(item['status'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor(item['status']),
                        fontSize: 13)),
              ],
            ),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(item['title']),
                content: Text(item['details'].toString().isEmpty
                    ? 'No additional details.'
                    : item['details']),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessment'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
      body: _assessments.isEmpty
          ? Center(
              child: Text('No assessments found.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
          : AnimatedList(
              key: _listKey,
              initialItemCount: _assessments.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemBuilder: _buildAssessmentItem,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text("New Assessment"),
        backgroundColor: theme.colorScheme.primary,
        elevation: 5,
      ),
       bottomNavigationBar: const QuickAccessBar(currentLabel: 'Risk'),
    );
  }
}
