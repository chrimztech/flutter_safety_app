// pages/training_management_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Add uuid package to pubspec.yaml
import '../models/training_model.dart'; // Import your new Training model
import '../pages/quickaccess_bar.dart'; // Assuming this is in the parent directory

class TrainingManagementPage extends StatefulWidget {
  const TrainingManagementPage({super.key});

  @override
  State<TrainingManagementPage> createState() => _TrainingManagementPageState();
}

enum TrainingFilter { all, upcoming, completed, overdue, missed, scheduled }

class _TrainingManagementPageState extends State<TrainingManagementPage> {
  final List<Training> _trainings = []; // Use the Training model
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _assignedToController = TextEditingController();
  final Uuid _uuid = const Uuid(); // For generating unique IDs

  DateTime? _selectedDate;
  String _searchQuery = '';
  TrainingFilter _currentFilter = TrainingFilter.all;

  String _selectedTrainingType = 'General'; // Default type for new training
  final List<String> _trainingTypes = [
    'General',
    'Fire Safety',
    'Chemical Handling',
    'Machine Operation',
    'Emergency Response',
    'Waste Management',
    'First Aid',
    'Environmental Compliance',
  ];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    // Current time in Lusaka, Zambia
    final nowLusaka = DateTime.now();

    _trainings.addAll([
      Training(
          id: _uuid.v4(),
          title: 'Emergency Evacuation Drill',
          date: nowLusaka.add(const Duration(days: 3)),
          description: 'Annual mandatory evacuation drill for all staff.',
          type: 'Emergency Response',
          assignedTo: 'All Staff',
          status: TrainingStatus.scheduled),
      Training(
          id: _uuid.v4(),
          title: 'Hazardous Waste Disposal',
          date: nowLusaka.subtract(const Duration(days: 10)),
          description: 'Refresher course on proper disposal of hazardous waste.',
          type: 'Waste Management',
          assignedTo: 'Waste Management Team',
          status: TrainingStatus.completed),
      Training(
          id: _uuid.v4(),
          title: 'PPE Usage and Maintenance',
          date: nowLusaka.subtract(const Duration(days: 5)),
          description: 'Mandatory session on Personal Protective Equipment.',
          type: 'General',
          assignedTo: 'All Production Staff',
          status: TrainingStatus.overdue), // Manually set as overdue for mock
      Training(
          id: _uuid.v4(),
          title: 'Spill Containment Protocol',
          date: nowLusaka.add(const Duration(days: 1)),
          description: 'Hands-on training for chemical spill containment.',
          type: 'Chemical Handling',
          assignedTo: 'Chemical Handling Team',
          status: TrainingStatus.upcoming), // Manually set as upcoming for mock
      Training(
          id: _uuid.v4(),
          title: 'Fire Extinguisher Use',
          date: nowLusaka.subtract(const Duration(days: 30)),
          description: 'Annual training on different types of fire extinguishers.',
          type: 'Fire Safety',
          assignedTo: 'All Staff',
          status: TrainingStatus.completed),
      Training(
          id: _uuid.v4(),
          title: 'Confined Space Entry',
          date: nowLusaka.add(const Duration(days: 45)),
          description: 'Specialized training for confined space entry procedures.',
          type: 'Machine Operation',
          assignedTo: 'Maintenance Team',
          status: TrainingStatus.scheduled),
      Training(
          id: _uuid.v4(),
          title: 'Environmental Audit Procedures',
          date: nowLusaka.subtract(const Duration(days: 60)),
          description: 'Understanding internal and external environmental audit processes.',
          type: 'Environmental Compliance',
          assignedTo: 'EHS Department',
          status: TrainingStatus.missed), // Example of a missed training
    ]);

    // Update initial statuses based on their dates (for actual scheduled/upcoming/overdue)
    _updateAllTrainingStatuses();
  }

  void _updateAllTrainingStatuses() {
    setState(() {
      for (var training in _trainings) {
        training.updateStatusBasedOnDate();
      }
      _sortTrainings(); // Sort after status update
    });
  }

  void _sortTrainings() {
    _trainings.sort((a, b) {
      // Prioritize overdue/upcoming/scheduled first, then completed/missed
      int statusOrder(TrainingStatus status) {
        if (status == TrainingStatus.overdue) return 0;
        if (status == TrainingStatus.upcoming) return 1;
        if (status == TrainingStatus.scheduled) return 2;
        if (status == TrainingStatus.missed) return 3;
        if (status == TrainingStatus.completed) return 4;
        return 5;
      }
      int statusComparison = statusOrder(a.status).compareTo(statusOrder(b.status));
      if (statusComparison != 0) return statusComparison;

      // Then by date (earliest first)
      return a.date.compareTo(b.date);
    });
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  void _openAddEditDialog({Training? trainingToEdit}) {
    bool isEditing = trainingToEdit != null;
    _titleController.text = isEditing ? trainingToEdit.title : '';
    _descriptionController.text = isEditing ? trainingToEdit.description : '';
    _assignedToController.text = isEditing ? trainingToEdit.assignedTo : '';
    _selectedDate = isEditing ? trainingToEdit.date : null;
    _selectedTrainingType = isEditing ? trainingToEdit.type : _trainingTypes.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Edit Training' : 'Add New Training'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Training Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _assignedToController,
                decoration: InputDecoration(
                  labelText: 'Assigned To (e.g., Dept, All Staff)',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    // Update the state of the dialog immediately
                    (context as Element).markNeedsBuild();
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedTrainingType,
                decoration: InputDecoration(
                  labelText: 'Training Type',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _trainingTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTrainingType = newValue!;
                    // Update the state of the dialog immediately
                    (context as Element).markNeedsBuild();
                  });
                },
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
              final description = _descriptionController.text.trim();
              final assignedTo = _assignedToController.text.trim();

              if (title.isEmpty || _selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter title and date')),
                );
                return;
              }

              setState(() {
                if (isEditing) {
                  trainingToEdit!.title = title;
                  trainingToEdit.date = _selectedDate!;
                  trainingToEdit.description = description;
                  trainingToEdit.assignedTo = assignedTo;
                  trainingToEdit.type = _selectedTrainingType;
                  trainingToEdit.updateStatusBasedOnDate(); // Recalculate status
                } else {
                  final newTraining = Training(
                    id: _uuid.v4(),
                    title: title,
                    date: _selectedDate!,
                    description: description,
                    assignedTo: assignedTo,
                    type: _selectedTrainingType,
                  );
                  newTraining.updateStatusBasedOnDate(); // Set initial status based on date
                  _trainings.insert(0, newTraining); // Add to top
                }
                _sortTrainings(); // Re-sort after adding/editing
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEditing ? 'Training updated!' : 'Training added!')),
              );
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTraining(Training training) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Training?'),
        content: Text('Are you sure you want to delete "${training.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _trainings.removeWhere((t) => t.id == training.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Training "${training.title}" deleted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markTrainingAsCompleted(Training training) {
    setState(() {
      training.status = TrainingStatus.completed;
      _sortTrainings();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Training "${training.title}" marked as Completed!')),
    );
  }

  void _markTrainingAsMissed(Training training) {
    setState(() {
      training.status = TrainingStatus.missed;
      _sortTrainings();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Training "${training.title}" marked as Missed.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply filter and search query
    List<Training> filteredTrainings = _trainings.where((training) {
      bool matchesSearch = training.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           training.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           training.assignedTo.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_currentFilter != TrainingFilter.all) {
        matchesFilter = training.status == _currentFilter;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort Trainings',
            onPressed: () {
              setState(() {
                _sortTrainings();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trainings sorted by status and date.')));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110), // Increased height for search and filters
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search training...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.blue.shade700,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                              // To clear the TextField visually, you'd need a TextEditingController.
                              // For now, it will clear when you type next or if you manually clear it.
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TrainingFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(filter.name.capitalize()),
                          selected: _currentFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _currentFilter = selected ? filter : TrainingFilter.all;
                              _updateAllTrainingStatuses(); // Re-evaluate statuses if date changes
                            });
                          },
                          selectedColor: theme.colorScheme.secondary,
                          labelStyle: TextStyle(
                            color: _currentFilter == filter ? Colors.white : theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: filteredTrainings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty && _currentFilter == TrainingFilter.all
                        ? 'No training sessions added yet.'
                        : 'No matching training sessions found.',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty && _currentFilter == TrainingFilter.all
                        ? 'Tap the "+" button to add your first training.'
                        : 'Try adjusting your search or filter.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTrainings.length,
              itemBuilder: (context, index) {
                final training = filteredTrainings[index];
                return Dismissible(
                  key: ValueKey(training.id), // Unique key for Dismissible
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.shade600,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white, size: 36),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: Text("Are you sure you want to delete '${training.title}'?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Delete", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    setState(() {
                      _trainings.removeWhere((item) => item.id == training.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${training.title} deleted')),
                      );
                    });
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: training.status.color.withOpacity(0.5), // Subtle border based on status
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _openAddEditDialog(trainingToEdit: training),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(training.status.icon, color: training.status.color, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    training.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Display status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: training.status.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    training.status.displayName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: training.status.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${DateFormat.yMMMMd().format(training.date)}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (training.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                training.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.category, size: 18, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  training.type,
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.group, size: 18, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  training.assignedTo,
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            if (training.status != TrainingStatus.completed && training.status != TrainingStatus.missed)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _markTrainingAsCompleted(training),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text('Complete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _markTrainingAsMissed(training),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('Missed'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEditDialog, // Use combined dialog
        icon: const Icon(Icons.add),
        label: const Text('Add Training'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white, // Ensure icon and text are white
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Training'),
    );
  }
}

// Utility extension for string capitalization
extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}