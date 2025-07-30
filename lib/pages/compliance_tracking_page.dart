// pages/compliance_tracking_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/compliance_model.dart'; // Import the new model
import 'quickaccess_bar.dart'; // Assuming its path is now in widgets

class ComplianceTrackingPage extends StatefulWidget {
  const ComplianceTrackingPage({super.key});

  @override
  State<ComplianceTrackingPage> createState() => _ComplianceTrackingPageState();
}

class _ComplianceTrackingPageState extends State<ComplianceTrackingPage> {
  final List<ComplianceItem> _allComplianceItems = []; // Master list
  List<ComplianceItem> _filteredAndSortedItems = []; // List shown in UI

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatusFilter = 'All'; // Changed to string for display

  @override
  void initState() {
    super.initState();
    _initializeMockData(); // Populate with some initial data
    _applyFiltersAndSort(); // Apply filters/sort for initial display
    _searchController.addListener(_onSearchChanged);
  }

  // --- Mock Data Initialization ---
  void _initializeMockData() {
    _allComplianceItems.addAll([
      ComplianceItem(
        title: 'Fire Safety Inspection',
        dueDate: DateTime(2025, 8, 1),
        status: ComplianceStatus.completed,
        completionDate: DateTime(2025, 7, 28, 10, 0),
        description: 'Annual inspection of fire extinguishers and alarms.',
      ),
      ComplianceItem(
        title: 'Monthly Equipment Audit',
        dueDate: DateTime(2025, 8, 15),
        status: ComplianceStatus.pending,
        description: 'Audit of all heavy machinery and tools in the workshop.',
      ),
      ComplianceItem(
        title: 'Worker Safety Training (Q3)',
        dueDate: DateTime(2025, 7, 30), // Current date, so it's overdue
        status: ComplianceStatus.overdue,
        description: 'Mandatory safety training session for all new employees and refreshers for existing staff.',
      ),
      ComplianceItem(
        title: 'Hazardous Materials Handling Permit Renewal',
        dueDate: DateTime(2025, 8, 10),
        status: ComplianceStatus.pending,
        description: 'Renewal of permit for storing and handling hazardous chemicals.',
      ),
      ComplianceItem(
        title: 'Waste Management Audit',
        dueDate: DateTime(2025, 9, 5),
        status: ComplianceStatus.pending,
        description: 'Review of waste segregation and disposal procedures.',
      ),
      ComplianceItem(
        title: 'First Aid Kit Restock',
        dueDate: DateTime(2025, 7, 20),
        status: ComplianceStatus.completed,
        completionDate: DateTime(2025, 7, 18, 14, 30),
        description: 'Checking and restocking all first aid stations across the facility.',
      ),
    ]);
  }

  // --- Search and Filter Logic ---
  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<ComplianceItem> tempItems = List.from(_allComplianceItems);

    // 1. Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      tempItems = tempItems
          .where((item) =>
              item.title.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query))
          .toList();
    }

    // 2. Filter by status
    if (_selectedStatusFilter != 'All') {
      final selectedEnumStatus = ComplianceStatus.values.firstWhere(
          (e) => e.displayString == _selectedStatusFilter,
          orElse: () => ComplianceStatus.pending); // Default if not found
      tempItems = tempItems
          .where((item) => item.status == selectedEnumStatus)
          .toList();
    }

    // 3. Sort by due date (overdue first)
    tempItems.sort((a, b) {
      // Sort overdue items first, then by due date
      if (a.status == ComplianceStatus.overdue && b.status != ComplianceStatus.overdue) {
        return -1; // a comes before b
      } else if (b.status == ComplianceStatus.overdue && a.status != ComplianceStatus.overdue) {
        return 1; // b comes before a
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    setState(() {
      _filteredAndSortedItems = tempItems;
    });
  }

  // --- Refresh Functionality ---
  Future<void> _refresh() async {
    // In a real application, you would fetch fresh data here.
    // For this example, we just re-apply filters and sorts.
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    setState(() {
      // This will ensure any newly overdue items are reflected
      // (assuming real data fetching would update their status)
      // For mock data, you might explicitly re-evaluate overdue status here
      // if it's not handled by the ComplianceItem model itself on creation/update.
      _applyFiltersAndSort();
    });
  }

  // --- Add/Edit Compliance Item Dialog ---
  Future<void> _showComplianceItemFormDialog({ComplianceItem? itemToEdit}) async {
    final bool isEditing = itemToEdit != null;
    final _formKey = GlobalKey<FormState>();

    final TextEditingController titleController = TextEditingController(text: itemToEdit?.title);
    final TextEditingController descriptionController = TextEditingController(text: itemToEdit?.description);
    DateTime? selectedDueDate = itemToEdit?.dueDate;
    ComplianceStatus? selectedStatus = itemToEdit?.status;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState2) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Compliance Item' : 'Add New Compliance Item', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.note_add)),
                        validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(selectedDueDate == null
                            ? 'Select Due Date'
                            : 'Due Date: ${DateFormat.yMMMd().format(selectedDueDate!)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2030), // Adjust as needed
                          );
                          if (picked != null && picked != selectedDueDate) {
                            setState2(() {
                              selectedDueDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ComplianceStatus>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.check_circle_outline)),
                        items: ComplianceStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(status.icon, color: status.color),
                                const SizedBox(width: 8),
                                Text(status.displayString),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState2(() => selectedStatus = value);
                        },
                        validator: (value) => value == null ? 'Please select a status' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Save' : 'Add'),
                  onPressed: () {
                    if (!_formKey.currentState!.validate() || selectedDueDate == null || selectedStatus == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill all required fields and select due date/status.'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (isEditing) {
                      setState(() {
                        itemToEdit!.title = titleController.text.trim();
                        itemToEdit.description = descriptionController.text.trim();
                        itemToEdit.dueDate = selectedDueDate!;
                        itemToEdit.updateStatus(selectedStatus!); // Use the model's update method
                        _applyFiltersAndSort();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Compliance item "${itemToEdit.title}" updated successfully!')));
                    } else {
                      final newItem = ComplianceItem(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        dueDate: selectedDueDate!,
                        status: selectedStatus!,
                      );
                      setState(() {
                        _allComplianceItems.insert(0, newItem);
                        _applyFiltersAndSort();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Compliance item "${newItem.title}" added successfully!')));
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Delete Compliance Item ---
  void _deleteComplianceItem(ComplianceItem item) {
    setState(() {
      _allComplianceItems.removeWhere((element) => element.id == item.id);
      _applyFiltersAndSort(); // Re-filter and sort after deletion
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compliance item "${item.title}" deleted')),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Compliance Tracking', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700, // Corrected: Using Colors.blue
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100), // Adjusted height for filters
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search compliance...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.blue.shade600, // Corrected: Using Colors.blue
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              _applyFiltersAndSort();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // 'All' chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedStatusFilter == 'All',
                            selectedColor: Colors.white.withOpacity(0.3), // Lighter selected color
                            backgroundColor: Colors.blue.shade600, // Corrected: Using Colors.blue
                            labelStyle: TextStyle(
                              color: _selectedStatusFilter == 'All' ? Colors.white : Colors.white70,
                              fontWeight: _selectedStatusFilter == 'All' ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedStatusFilter = selected ? 'All' : 'All'; // Toggle to 'All'
                                _applyFiltersAndSort();
                              });
                            },
                          ),
                        ),
                        // Status chips
                        ...ComplianceStatus.values.map((statusEnum) {
                          final isSelected = _selectedStatusFilter == statusEnum.displayString;
                          final color = isSelected ? statusEnum.color : Colors.white70;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(statusEnum.displayString),
                              selected: isSelected,
                              selectedColor: statusEnum.color.withOpacity(0.3), // Lighter selected color for better contrast
                              backgroundColor: Colors.blue.shade600, // Corrected: Using Colors.blue
                              labelStyle: TextStyle(
                                color: color,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedStatusFilter = selected ? statusEnum.displayString : 'All';
                                  _applyFiltersAndSort();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compliance Items (${_filteredAndSortedItems.length})',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.blue.shade900, // Corrected: Using Colors.blue
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredAndSortedItems.isEmpty
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
                        itemCount: _filteredAndSortedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _filteredAndSortedItems[index];
                          return ComplianceItemCard(
                            item: item,
                            onEdit: () => _showComplianceItemFormDialog(itemToEdit: item),
                            onDelete: () => _deleteComplianceItem(item),
                            onToggleStatus: () {
                              setState(() {
                                // Simple toggle between pending and completed for demonstration
                                item.updateStatus(item.status == ComplianceStatus.pending
                                    ? ComplianceStatus.completed
                                    : ComplianceStatus.pending);
                                _applyFiltersAndSort(); // Re-sort if status affects order
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Item "${item.title}" marked as ${item.status.displayString}')));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComplianceItemFormDialog(),
        label: const Text('Add Compliance Item'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade700, // Corrected: Using Colors.blue
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Compliance'),
    );
  }
}

class ComplianceItemCard extends StatelessWidget {
  final ComplianceItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const ComplianceItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the due date is today or in the past for pending items
    // This logic should ideally be within the ComplianceItem model or a helper.
    final bool isOverdue = item.status == ComplianceStatus.pending && item.dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)).endOfDay);
    // Note: The mock data already sets some to 'overdue' manually.
    // For live data, you'd calculate this based on due date and current date.
    // The sorting logic in _applyFiltersAndSort also prioritizes overdue.

    // Determine the displayed status and color/icon
    final ComplianceStatus displayedStatus = isOverdue ? ComplianceStatus.overdue : item.status;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          _showDetailsDialog(context, item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      } else if (value == 'toggle_status') {
                        onToggleStatus();
                      } else if (value == 'view') {
                        _showDetailsDialog(context, item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(item.status == ComplianceStatus.pending ? Icons.check : Icons.restore),
                            const SizedBox(width: 8),
                            Text(item.status == ComplianceStatus.pending ? 'Mark Completed' : 'Mark Pending'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Due Date: ${DateFormat.yMMMd().format(item.dueDate)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              if (item.completionDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Completed On: ${DateFormat.yMMMd().format(item.completionDate!)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: displayedStatus.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(displayedStatus.icon, color: displayedStatus.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        displayedStatus.displayString,
                        style: TextStyle(
                          color: displayedStatus.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, ComplianceItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Description: ${item.description.isNotEmpty ? item.description : "No description provided."}'),
                const SizedBox(height: 8),
                Text('Due Date: ${DateFormat.yMMMd().format(item.dueDate)}'),
                if (item.completionDate != null)
                  Text('Completed On: ${DateFormat.yMMMd().add_jm().format(item.completionDate!)}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(item.status.icon, color: item.status.color, size: 18),
                    const SizedBox(width: 8),
                    Text('Status: ${item.status.displayString}',
                        style: TextStyle(color: item.status.color, fontWeight: FontWeight.bold)),
                  ],
                ),
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
            TextButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(context); // Close details dialog
                onEdit(); // Open edit dialog through the callback
              },
            ),
          ],
        );
      },
    );
  }
}
