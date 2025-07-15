// pages/compliance_tracking_page.dart
import 'package:flutter/material.dart';

class ComplianceTrackingPage extends StatefulWidget {
  const ComplianceTrackingPage({super.key});

  @override
  State<ComplianceTrackingPage> createState() => _ComplianceTrackingPageState();
}

class _ComplianceTrackingPageState extends State<ComplianceTrackingPage> {
  final List<Map<String, dynamic>> _allComplianceItems = [
    {
      'title': 'Fire Safety Inspection',
      'dueDate': '2025-08-01',
      'status': 'Completed',
    },
    {
      'title': 'Monthly Equipment Audit',
      'dueDate': '2025-08-15',
      'status': 'Pending',
    },
    {
      'title': 'Worker Safety Training',
      'dueDate': '2025-07-30',
      'status': 'Overdue',
    },
    {
      'title': 'Hazardous Materials Handling',
      'dueDate': '2025-08-10',
      'status': 'Completed',
    },
  ];

  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  List<Map<String, dynamic>> get _filteredComplianceItems {
    var filtered = _allComplianceItems.where((item) {
      final title = item['title'].toString().toLowerCase();
      final matchesSearch = title.contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'All' ||
          item['status'].toString().toLowerCase() ==
              _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) => a['dueDate'].compareTo(b['dueDate']));
    return filtered;
  }

  List<String> get _statusOptions => ['All', 'Completed', 'Pending', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Compliance Tracking'),
        backgroundColor: Colors.blueAccent.shade700,
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search compliance...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.green.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),

              // Status filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusOptions.map((status) {
                    final isSelected = _selectedStatusFilter == status;
                    final color = status == 'Overdue'
                        ? Colors.red
                        : status == 'Pending'
                            ? Colors.orange
                            : status == 'Completed'
                                ? Colors.green
                                : Colors.grey.shade600;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: color.withOpacity(0.25),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected ? color : Colors.grey.shade800,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedStatusFilter = status);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // List header with count
              Text(
                'Compliance Items (${_filteredComplianceItems.length})',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Compliance list or empty state
              Expanded(
                child: _filteredComplianceItems.isEmpty
                    ? Center(
                        child: Text(
                          'No compliance items found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredComplianceItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _filteredComplianceItems[index];
                          return ComplianceItemCard(item: item);
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

class ComplianceItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const ComplianceItemCard({super.key, required this.item});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'overdue':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? 'Unknown';
    final dueDate = item['dueDate'] ?? '';

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        title: Text(
          item['title'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Due Date: $dueDate',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon(status), color: _statusColor(status), size: 20),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  color: _statusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected: ${item['title']}')),
          );
        },
      ),
    );
  }
}
