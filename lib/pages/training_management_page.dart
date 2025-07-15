// pages/training_management_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainingManagementPage extends StatefulWidget {
  const TrainingManagementPage({super.key});

  @override
  State<TrainingManagementPage> createState() => _TrainingManagementPageState();
}

class _TrainingManagementPageState extends State<TrainingManagementPage> {
  final List<Map<String, dynamic>> _trainings = [
    {'title': 'Fire Safety Training', 'date': '2025-07-30', 'status': 'Upcoming'},
    {'title': 'Chemical Handling', 'date': '2025-06-20', 'status': 'Completed'},
    {'title': 'Machine Operation', 'date': '2025-08-15', 'status': 'Scheduled'},
  ];

  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  String _searchQuery = '';

  void _openAddDialog() {
    _titleController.clear();
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Training'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Training Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                leading: const Icon(Icons.date_range),
                title: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : DateFormat.yMMMMd().format(_selectedDate!),
                ),
                trailing: const Icon(Icons.edit_calendar),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty || _selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter title and date')),
                );
                return;
              }

              setState(() {
                _trainings.insert(0, {
                  'title': title,
                  'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  'status': 'Scheduled',
                });
              });

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _trainings
        .where((t) => t['title'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Management'),
        backgroundColor: Colors.blue.shade700,
        elevation: 3,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search training...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No training sessions found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(item['status']),
                            child: const Icon(Icons.school, color: Colors.white),
                          ),
                          title: Text(
                            item['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Date: ${item['date']}'),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor(item['status']).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['status'],
                              style: TextStyle(
                                color: _statusColor(item['status']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Training'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
