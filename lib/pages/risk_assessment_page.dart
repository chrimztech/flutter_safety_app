// pages/risk_assessment_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'quickaccess_bar.dart'; // Changed to common widget directory
import '../models/risk_assessment_model.dart';

class RiskAssessmentPage extends StatefulWidget {
  const RiskAssessmentPage({super.key});

  @override
  State<RiskAssessmentPage> createState() => _RiskAssessmentPageState();
}

enum RiskAssessmentSortOption { dateNewest, dateOldest, titleAsc }

class _RiskAssessmentPageState extends State<RiskAssessmentPage> {
  final List<RiskAssessment> _allAssessments = [];
  List<RiskAssessment> _filteredAndSortedAssessments = [];

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  RiskAssessmentStatus? _currentStatusFilter;
  RiskAssessmentSortOption _currentSortOption = RiskAssessmentSortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _applyFiltersAndSort();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeMockData() {
    final uuid = const Uuid();
    _allAssessments.addAll([
      RiskAssessment(
        id: uuid.v4(),
        title: 'Chemical Handling Procedure Review',
        assessmentDate: DateTime(2025, 7, 20),
        status: RiskAssessmentStatus.open,
details: 'Review of current chemical handling SOPs and spill response plans. Focus on new hazardous materials introduced this quarter.',
      ),
      RiskAssessment(
        id: uuid.v4(),
        title: 'Machine Guarding Inspection',
        assessmentDate: DateTime(2025, 6, 15),
        status: RiskAssessmentStatus.closed,
        details: 'Inspection of all heavy machinery for proper guarding and emergency stops. All identified issues have been resolved.',
      ),
      RiskAssessment(
        id: uuid.v4(),
        title: 'Annual Fire Safety Audit',
        assessmentDate: DateTime(2025, 5, 1),
        status: RiskAssessmentStatus.review,
        details: 'Comprehensive audit of fire suppression systems, alarms, and evacuation routes. Awaiting final sign-off from fire marshal.',
      ),
      RiskAssessment(
        id: uuid.v4(),
        title: 'Ergonomic Workstation Assessment',
        assessmentDate: DateTime(2025, 7, 29),
        status: RiskAssessmentStatus.open,
        details: 'Assessment of office workstations to identify and mitigate ergonomic risks for staff comfort and productivity.',
      ),
      RiskAssessment(
        id: uuid.v4(),
        title: 'Waste Management Compliance Check',
        assessmentDate: DateTime(2025, 4, 10),
        status: RiskAssessmentStatus.closed,
        details: 'Verification of compliance with local environmental regulations for hazardous and non-hazardous waste disposal.',
      ),
    ]);
  }

  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<RiskAssessment> tempAssessments = List.from(_allAssessments);

    // 1. Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      tempAssessments = tempAssessments
          .where((assessment) =>
              assessment.title.toLowerCase().contains(query) ||
              assessment.details.toLowerCase().contains(query))
          .toList();
    }

    // 2. Filter by status
    if (_currentStatusFilter != null) {
      tempAssessments = tempAssessments
          .where((assessment) => assessment.status == _currentStatusFilter)
          .toList();
    }

    // 3. Sort
    tempAssessments.sort((a, b) {
      switch (_currentSortOption) {
        case RiskAssessmentSortOption.dateNewest:
          return b.assessmentDate.compareTo(a.assessmentDate);
        case RiskAssessmentSortOption.dateOldest:
          return a.assessmentDate.compareTo(b.assessmentDate);
        case RiskAssessmentSortOption.titleAsc:
          return a.title.compareTo(b.title);
      }
    });

    setState(() {
      _filteredAndSortedAssessments = tempAssessments;
    });
  }

  Future<void> _showAssessmentDialog({RiskAssessment? assessmentToEdit}) async {
    final bool isEditing = assessmentToEdit != null;
    final TextEditingController titleController = TextEditingController(text: assessmentToEdit?.title);
    final TextEditingController detailsController = TextEditingController(text: assessmentToEdit?.details);
    DateTime selectedDate = assessmentToEdit?.assessmentDate ?? DateTime.now();
    RiskAssessmentStatus selectedStatus = assessmentToEdit?.status ?? RiskAssessmentStatus.open;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Edit Assessment' : 'New Risk Assessment', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Assessment Title',
                  prefixIcon: Icon(Icons.assignment),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details (Optional)',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Use a stateful builder to update date in dialog without rebuilding page
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState2) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
                            setState2(() { // Use setState2 to update dialog's internal state
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RiskAssessmentStatus>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.check_circle_outline),
                  border: OutlineInputBorder(),
                ),
                items: RiskAssessmentStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.nameString),
                  );
                }).toList(),
                onChanged: (RiskAssessmentStatus? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatus = newValue;
                    });
                  }
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
          ElevatedButton.icon(
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Save' : 'Add'),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Assessment title is required'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              if (isEditing) {
                // Update existing assessment
                setState(() {
                  assessmentToEdit!.title = title;
                  assessmentToEdit.details = detailsController.text.trim();
                  assessmentToEdit.assessmentDate = selectedDate;
                  assessmentToEdit.status = selectedStatus;
                  _applyFiltersAndSort(); // Re-filter and sort
                });
              } else {
                // Add new assessment
                final newAssessment = RiskAssessment(
                  id: const Uuid().v4(), // Generate a new ID for new assessments
                  title: title,
                  details: detailsController.text.trim(),
                  assessmentDate: selectedDate,
                  status: selectedStatus,
                );
                setState(() {
                  _allAssessments.insert(0, newAssessment); // Add to the top
                  _applyFiltersAndSort(); // Re-filter and sort
                });
                _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(isEditing
                        ? '"$title" updated successfully!'
                        : '"$title" added successfully!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _deleteAssessment(RiskAssessment assessment) {
    final int index = _allAssessments.indexOf(assessment);
    if (index != -1) {
      final removedItem = _allAssessments.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAssessmentItem(context, removedItem, animation),
        duration: const Duration(milliseconds: 500),
      );
      _applyFiltersAndSort(); // Re-filter and sort
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${removedItem.title}" deleted')),
      );
    }
  }

  Widget _buildAssessmentItem(BuildContext context, RiskAssessment item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1.0,
      child: Dismissible(
        key: ValueKey(item.id),
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
                content: Text("Are you sure you want to delete '${item.title}'?"),
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
          _deleteAssessment(item);
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: InkWell(
            onTap: () {
              // Show full details dialog when tapping the card
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Date: ${DateFormat.yMMMd().format(item.assessmentDate)}'),
                        const SizedBox(height: 8),
                        Text('Status: ${item.status.nameString}', style: TextStyle(color: item.status.color, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(item.details.isEmpty
                            ? 'No additional details provided for this assessment.'
                            : item.details),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(context); // Close details dialog
                        _showAssessmentDialog(assessmentToEdit: item); // Open edit dialog
                      },
                    ),
                  ],
                ),
              );
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(
                item.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "Date: ${DateFormat.yMMMd().format(item.assessmentDate)}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  if (item.details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.details,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: item.status.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.status.icon, color: item.status.color, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.status.nameString,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.status.color,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Replaced PopupMenuButton with an IconButton
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More options',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAssessmentDialog(assessmentToEdit: item);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(item.status == RiskAssessmentStatus.closed ? Icons.lock_open : Icons.lock),
                                  title: Text(item.status == RiskAssessmentStatus.closed ? 'Mark Open' : 'Mark Closed'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      item.status = item.status == RiskAssessmentStatus.closed
                                          ? RiskAssessmentStatus.open
                                          : RiskAssessmentStatus.closed;
                                      _applyFiltersAndSort();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '"${item.title}" marked as ${item.status.nameString}.')),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteAssessment(item);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessments', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search assessments...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.blue.shade700,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RiskAssessmentStatus?>(
                          value: _currentStatusFilter,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.filter_list, color: Colors.white),
                          dropdownColor: Colors.blue.shade700,
                          onChanged: (RiskAssessmentStatus? newValue) {
                            setState(() {
                              _currentStatusFilter = newValue;
                              _applyFiltersAndSort();
                            });
                          },
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Statuses', style: TextStyle(color: Colors.white)),
                            ),
                            ...RiskAssessmentStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.nameString, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RiskAssessmentSortOption>(
                          value: _currentSortOption,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.sort, color: Colors.white),
                          dropdownColor: Colors.blue.shade700,
                          onChanged: (RiskAssessmentSortOption? newValue) {
                            setState(() {
                              _currentSortOption = newValue!;
                              _applyFiltersAndSort();
                            });
                          },
                          items: RiskAssessmentSortOption.values.map((sortOption) {
                            String text;
                            switch (sortOption) {
                              case RiskAssessmentSortOption.dateNewest:
                                text = 'Date (Newest)';
                                break;
                              case RiskAssessmentSortOption.dateOldest:
                                text = 'Date (Oldest)';
                                break;
                              case RiskAssessmentSortOption.titleAsc:
                                text = 'Title (A-Z)';
                                break;
                            }
                            return DropdownMenuItem<RiskAssessmentSortOption>(
                              value: sortOption,
                              child: Text(text, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                        ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _filteredAndSortedAssessments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty && _currentStatusFilter == null
                        ? 'No risk assessments recorded yet.'
                        : 'No matching assessments found.',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the "+" button to add a new assessment.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : AnimatedList(
              key: _listKey,
              initialItemCount: _filteredAndSortedAssessments.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemBuilder: (context, index, animation) {
                return _buildAssessmentItem(context, _filteredAndSortedAssessments[index], animation);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssessmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text("New Assessment"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Risk'),
    );
  }
}