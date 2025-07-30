// pages/incident_reporting_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:uuid/uuid.dart'; // Ensure uuid is in your pubspec.yaml

import 'quickaccess_bar.dart'; // Assuming its path
import '../models/incident_model.dart'; // Import the new model

class IncidentReportingPage extends StatefulWidget {
  const IncidentReportingPage({super.key});

  @override
  State<IncidentReportingPage> createState() => _IncidentReportingPageState();
}

enum IncidentSortOption { dateNewest, dateOldest, titleAsc, severityHighToLow }

class _IncidentReportingPageState extends State<IncidentReportingPage> {
  final List<Incident> _allIncidents = []; // Master list of all incidents
  List<Incident> _filteredAndSortedIncidents = []; // List shown in UI

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  IncidentCategory? _currentCategoryFilter; // Null for "All"
  bool? _currentStatusFilter; // Null for "All", true for Closed, false for Open
  IncidentSortOption _currentSortOption = IncidentSortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _initializeMockData(); // Populate with some initial data
    _applyFiltersAndSort(); // Apply filters/sort for initial display
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeMockData() {
    final uuid = const Uuid();
    _allIncidents.addAll([
      Incident(
        id: uuid.v4(),
        title: 'Minor Chemical Spill - Lab 3',
        description: 'Small spill of ethanol due to faulty seal on a reagent bottle. Contained quickly by lab personnel.',
        location: 'Laboratory - Lab 3',
        incidentDate: DateTime(2025, 7, 28),
        category: IncidentCategory.chemical,
        severity: IncidentSeverity.low,
        isClosed: true,
      ),
      Incident(
        id: uuid.v4(),
        title: 'Forklift Near Miss - Warehouse',
        description: 'Forklift almost collided with pedestrian due to blind corner. No injuries, but concern about visibility.',
        location: 'Warehouse - Aisle 7',
        incidentDate: DateTime(2025, 7, 29),
        category: IncidentCategory.nearMiss,
        severity: IncidentSeverity.medium,
        isClosed: false,
      ),
      Incident(
        id: uuid.v4(),
        title: 'Electrical Fault - Production Line A',
        description: 'Sparking observed from control panel. Production shut down immediately. Electrician called for repair.',
        location: 'Production Area - Line A',
        incidentDate: DateTime(2025, 7, 27),
        category: IncidentCategory.equipment,
        severity: IncidentSeverity.high,
        isClosed: false,
      ),
      Incident(
        id: uuid.v4(),
        title: 'Small Fire - Waste Incinerator',
        description: 'Small uncontrolled fire in the waste incinerator. Extinguished with onsite fire extinguishers. No major damage.',
        location: 'Waste Management - Incinerator',
        incidentDate: DateTime(2025, 7, 25),
        category: IncidentCategory.fire,
        severity: IncidentSeverity.medium,
        isClosed: true,
      ),
      Incident(
        id: uuid.v4(),
        title: 'Unidentified Liquid Leak - Loading Dock',
        description: 'Puddle of unknown liquid found near loading dock. Area cordoned off. Samples sent for analysis.',
        location: 'Loading Dock 1',
        incidentDate: DateTime(2025, 7, 30), // Today
        category: IncidentCategory.spill,
        severity: IncidentSeverity.critical,
        isClosed: false,
      ),
    ]);
  }

  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<Incident> tempIncidents = List.from(_allIncidents);

    // 1. Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      tempIncidents = tempIncidents
          .where((incident) =>
              incident.title.toLowerCase().contains(query) ||
              incident.description.toLowerCase().contains(query) ||
              incident.location.toLowerCase().contains(query))
          .toList();
    }

    // 2. Filter by category
    if (_currentCategoryFilter != null) {
      tempIncidents = tempIncidents
          .where((incident) => incident.category == _currentCategoryFilter)
          .toList();
    }

    // 3. Filter by status (Open/Closed)
    if (_currentStatusFilter != null) {
      tempIncidents = tempIncidents
          .where((incident) => incident.isClosed == _currentStatusFilter)
          .toList();
    }

    // 4. Sort
    tempIncidents.sort((a, b) {
      switch (_currentSortOption) {
        case IncidentSortOption.dateNewest:
          return b.incidentDate.compareTo(a.incidentDate);
        case IncidentSortOption.dateOldest:
          return a.incidentDate.compareTo(b.incidentDate);
        case IncidentSortOption.titleAsc:
          return a.title.compareTo(b.title);
        case IncidentSortOption.severityHighToLow:
          return b.severity.index.compareTo(a.severity.index); // Higher enum index = higher severity
      }
    });

    // Handle AnimatedList specific logic for removals/additions
    setState(() {
      // Find items removed from the filtered list and remove them from AnimatedList
      Set<String> newIds = _filteredAndSortedIncidents.map((e) => e.id).toSet();
      for (int i = _filteredAndSortedIncidents.length - 1; i >= 0; i--) {
        if (!tempIncidents.any((element) => element.id == _filteredAndSortedIncidents[i].id)) {
          final removedItem = _filteredAndSortedIncidents.removeAt(i);
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildIncidentItem(context, removedItem, animation),
            duration: const Duration(milliseconds: 500),
          );
        }
      }

      // Find items added to the filtered list and insert them into AnimatedList
      for (int i = 0; i < tempIncidents.length; i++) {
        if (!_filteredAndSortedIncidents.any((element) => element.id == tempIncidents[i].id)) {
          _filteredAndSortedIncidents.insert(i, tempIncidents[i]);
          _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 500));
        }
      }

      // Update the order for existing items (important after sorting)
      _filteredAndSortedIncidents = tempIncidents;
    });
  }

  // --- Incident Form (Dialog) ---
  Future<void> _showIncidentFormDialog({Incident? incidentToEdit}) async {
    final bool isEditing = incidentToEdit != null;
    final _formKey = GlobalKey<FormState>(); // New key for dialog form

    final TextEditingController titleController = TextEditingController(text: incidentToEdit?.title);
    final TextEditingController descriptionController = TextEditingController(text: incidentToEdit?.description);
    final TextEditingController locationController = TextEditingController(text: incidentToEdit?.location);

    DateTime? selectedDate = incidentToEdit?.incidentDate;
    IncidentCategory? selectedCategory = incidentToEdit?.category;
    IncidentSeverity? selectedSeverity = incidentToEdit?.severity;

    // Local state management for dropdowns and date picker within the dialog
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Use StatefulBuilder to manage internal dialog state
          builder: (context, setState2) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Incident' : 'Report New Incident', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Incident Title', prefixIcon: Icon(Icons.warning)),
                        validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                        validator: (value) => value == null || value.isEmpty ? 'Location is required' : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(selectedDate == null
                            ? 'Select Incident Date'
                            : 'Incident Date: ${DateFormat.yMMMd().format(selectedDate!)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && picked != selectedDate) {
                            setState2(() { // Update dialog's state
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<IncidentCategory>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                        items: IncidentCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.categoryString),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState2(() => selectedCategory = value); // Update dialog's state
                        },
                        validator: (value) => value == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<IncidentSeverity>(
                        value: selectedSeverity,
                        decoration: const InputDecoration(labelText: 'Severity', prefixIcon: Icon(Icons.error_outline)),
                        items: IncidentSeverity.values.map((severity) {
                          return DropdownMenuItem(
                            value: severity,
                            child: Text(severity.severityString),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState2(() => selectedSeverity = value); // Update dialog's state
                        },
                        validator: (value) => value == null ? 'Please select severity' : null,
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
                  label: Text(isEditing ? 'Save' : 'Report'),
                  onPressed: () {
                    if (!_formKey.currentState!.validate() || selectedDate == null || selectedCategory == null || selectedSeverity == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields and select date/category/severity.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (isEditing) {
                      setState(() { // Update main page's state
                        incidentToEdit!.title = titleController.text.trim();
                        incidentToEdit.description = descriptionController.text.trim();
                        incidentToEdit.location = locationController.text.trim();
                        incidentToEdit.incidentDate = selectedDate!;
                        incidentToEdit.category = selectedCategory!;
                        incidentToEdit.severity = selectedSeverity!;
                        _applyFiltersAndSort(); // Re-filter and sort after update
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incident "${incidentToEdit.title}" updated successfully!')));
                    } else {
                      final newIncident = Incident(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        location: locationController.text.trim(),
                        incidentDate: selectedDate!,
                        category: selectedCategory!,
                        severity: selectedSeverity!,
                      );
                      setState(() { // Update main page's state
                        _allIncidents.insert(0, newIncident); // Add to the top
                        _applyFiltersAndSort(); // Re-filter and sort after addition
                      });
                      // If the list is empty before adding, AnimatedList won't have a context for insertItem(0)
                      // This needs careful handling with AnimatedList + filters/sort.
                      // A simpler approach for lists with filters is to just call setState
                      // and rebuild the entire list, or manage removals/insertions more carefully.
                      // For this example, we assume _listKey.currentState is generally available
                      // if items are added to a non-empty list or if it's the first item.
                      if (_filteredAndSortedIncidents.isEmpty || _filteredAndSortedIncidents[0].id == newIncident.id) {
                         _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incident "${newIncident.title}" reported successfully!')));
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

  void _deleteIncident(Incident incident) {
    // Find the original index in _allIncidents
    final int originalIndex = _allIncidents.indexOf(incident);
    if (originalIndex != -1) {
      _allIncidents.removeAt(originalIndex);
    }

    // Find the index in the currently filtered list
    final int displayIndex = _filteredAndSortedIncidents.indexOf(incident);
    if (displayIndex != -1) {
      _filteredAndSortedIncidents.removeAt(displayIndex); // Remove from display list instantly
      _listKey.currentState?.removeItem(
        displayIndex,
        (context, animation) => _buildIncidentItem(context, incident, animation), // Pass the removed item back
        duration: const Duration(milliseconds: 500),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incident "${incident.title}" deleted')),
      );
    }
  }

  Widget _buildIncidentItem(BuildContext context, Incident item, Animation<double> animation) {
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
          _deleteIncident(item);
          // _applyFiltersAndSort() is called within _deleteIncident
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            leading: Icon(item.category.categoryIcon, color: item.severity.severityColor, size: 36),
            title: Text(item.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Location: ${item.location}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                Text("Date: ${DateFormat.yMMMd().format(item.incidentDate)}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.severity.severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item.severity.severityString,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.severity.severityColor,
                          fontSize: 12)),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view') {
                  // Show full details dialog
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Location: ${item.location}'),
                            Text('Incident Date: ${DateFormat.yMMMd().format(item.incidentDate)}'),
                            Text('Reported Date: ${DateFormat.yMMMd().add_jm().format(item.reportedDate)}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(item.category.categoryIcon, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text('Category: ${item.category.categoryString}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.error_outline, size: 18, color: item.severity.severityColor),
                                const SizedBox(width: 8),
                                Text('Severity: ${item.severity.severityString}',
                                    style: TextStyle(color: item.severity.severityColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(item.description.isEmpty
                                ? 'No detailed description provided.'
                                : item.description),
                            const SizedBox(height: 12),
                            Chip(
                              label: Text(item.isClosed ? 'Closed' : 'Open'),
                              backgroundColor: item.isClosed ? Colors.green.shade100 : Colors.orange.shade100,
                              avatar: Icon(item.isClosed ? Icons.lock : Icons.lock_open, size: 18, color: item.isClosed ? Colors.green.shade700 : Colors.orange.shade700),
                            ),
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
                            _showIncidentFormDialog(incidentToEdit: item); // Open edit dialog
                          },
                        ),
                      ],
                    ),
                  );
                } else if (value == 'edit') {
                  _showIncidentFormDialog(incidentToEdit: item);
                } else if (value == 'toggle_status') {
                  setState(() {
                    item.isClosed = !item.isClosed;
                    _applyFiltersAndSort(); // Re-filter and sort after status change
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Incident "${item.title}" marked as ${item.isClosed ? "Closed" : "Open"}.')),
                  );
                } else if (value == 'delete') {
                  _deleteIncident(item);
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
                      Icon(item.isClosed ? Icons.lock_open : Icons.lock),
                      const SizedBox(width: 8),
                      Text(item.isClosed ? 'Mark Open' : 'Mark Closed'),
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
              icon: const Icon(Icons.more_vert),
            ),
            onTap: () {
              // Optionally, make tapping the list tile show the details dialog
              // This is handled by the 'view' popup menu item above.
            },
          ),
        ),
      ),
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
        title: const Text('Incident Reporting', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160), // Increased height for more filters
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search incidents...',
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
                    // Category Filter
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IncidentCategory?>(
                          value: _currentCategoryFilter,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.filter_list, color: Colors.white),
                          dropdownColor: Colors.blue.shade700,
                          onChanged: (IncidentCategory? newValue) {
                            setState(() {
                              _currentCategoryFilter = newValue;
                              _applyFiltersAndSort();
                            });
                          },
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Categories', style: TextStyle(color: Colors.white)),
                            ),
                            ...IncidentCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category.categoryString, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Filter (Open/Closed)
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool?>(
                          value: _currentStatusFilter,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                          dropdownColor: Colors.blue.shade700,
                          onChanged: (bool? newValue) {
                            setState(() {
                              _currentStatusFilter = newValue;
                              _applyFiltersAndSort();
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Statuses', style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: false, // false for open
                              child: Text('Open', style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: true, // true for closed
                              child: Text('Closed', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sort Options (separate row for better layout)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IncidentSortOption>(
                          value: _currentSortOption,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.sort, color: Colors.white),
                          dropdownColor: Colors.blue.shade700,
                          onChanged: (IncidentSortOption? newValue) {
                            setState(() {
                              _currentSortOption = newValue!;
                              _applyFiltersAndSort();
                            });
                          },
                          items: IncidentSortOption.values.map((sortOption) {
                            String text;
                            switch (sortOption) {
                              case IncidentSortOption.dateNewest:
                                text = 'Date (Newest)';
                                break;
                              case IncidentSortOption.dateOldest:
                                text = 'Date (Oldest)';
                                break;
                              case IncidentSortOption.titleAsc:
                                text = 'Title (A-Z)';
                                break;
                              case IncidentSortOption.severityHighToLow:
                                text = 'Severity (High to Low)';
                                break;
                            }
                            return DropdownMenuItem<IncidentSortOption>(
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
      body: _filteredAndSortedIncidents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_problem, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty && _currentCategoryFilter == null && _currentStatusFilter == null
                        ? 'No incidents reported yet.'
                        : 'No matching incidents found.',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the "+" button to report a new incident.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : AnimatedList(
              key: _listKey,
              initialItemCount: _filteredAndSortedIncidents.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemBuilder: (context, index, animation) {
                return _buildIncidentItem(context, _filteredAndSortedIncidents[index], animation);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIncidentFormDialog(), // Call the dialog
        icon: const Icon(Icons.add),
        label: const Text("Report Incident"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Incident'), // Assuming you'll add 'Incident' as a label
    );
  }
}