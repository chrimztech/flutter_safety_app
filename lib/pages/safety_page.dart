// pages/safety_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:uuid/uuid.dart'; // Ensure uuid is in your pubspec.yaml

import '../models/safety_sheet_model.dart'; // Import the new model
import 'quickaccess_bar.dart'; // Assuming its path

class SafetySheetsPage extends StatefulWidget {
  const SafetySheetsPage({super.key});

  @override
  State<SafetySheetsPage> createState() => _SafetySheetsPageState();
}

enum SafetySheetSortOption { titleAsc, dateDesc }

class _SafetySheetsPageState extends State<SafetySheetsPage> {
  final List<SafetySheet> _allSheets = []; // Use the new model
  List<SafetySheet> _filteredAndSortedSheets = [];
  final TextEditingController _searchController = TextEditingController();
  String _currentFileExtensionFilter = 'All'; // Filter by file type
  SafetySheetSortOption _currentSortOption = SafetySheetSortOption.dateDesc; // Default sort

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _applyFiltersAndSort();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeMockData() {
    final uuid = const Uuid();
    _allSheets.addAll([
      SafetySheet(
          id: uuid.v4(),
          title: 'Fire Safety Guidelines',
          filePath: 'assets/docs/fire_safety.pdf', // Example local path
          fileExtension: 'pdf',
          uploadDate: DateTime(2025, 7, 28)), // Recent date
      SafetySheet(
          id: uuid.v4(),
          title: 'Chemical Spill Response Procedure',
          filePath: 'assets/docs/chemical_response.docx',
          fileExtension: 'docx',
          uploadDate: DateTime(2025, 7, 15)),
      SafetySheet(
          id: uuid.v4(),
          title: 'Lockout/Tagout Procedures',
          filePath: 'assets/docs/loto_procedures.pdf',
          fileExtension: 'pdf',
          uploadDate: DateTime(2025, 6, 20)),
      SafetySheet(
          id: uuid.v4(),
          title: 'Waste Segregation Manual',
          filePath: 'assets/docs/waste_manual.xlsx',
          fileExtension: 'xlsx',
          uploadDate: DateTime(2025, 5, 10)),
      SafetySheet(
          id: uuid.v4(),
          title: 'Emergency Contact List',
          filePath: 'assets/docs/emergency_contacts.pdf',
          fileExtension: 'pdf',
          uploadDate: DateTime(2025, 7, 29)), // Even more recent
      SafetySheet(
          id: uuid.v4(),
          title: 'Environmental Impact Assessment Guide',
          filePath: 'assets/docs/eia_guide.pdf',
          fileExtension: 'pdf',
          uploadDate: DateTime(2024, 1, 15)),
    ]);
  }

  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<SafetySheet> tempSheets = List.from(_allSheets);

    // 1. Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      tempSheets = tempSheets
          .where((sheet) => sheet.title.toLowerCase().contains(query))
          .toList();
    }

    // 2. Filter by file extension
    if (_currentFileExtensionFilter != 'All') {
      tempSheets = tempSheets
          .where((sheet) =>
              sheet.fileExtension.toLowerCase() ==
              _currentFileExtensionFilter.toLowerCase())
          .toList();
    }

    // 3. Sort
    tempSheets.sort((a, b) {
      if (_currentSortOption == SafetySheetSortOption.titleAsc) {
        return a.title.compareTo(b.title);
      } else {
        // Default to dateDesc (most recent first)
        return b.uploadDate.compareTo(a.uploadDate);
      }
    });

    setState(() {
      _filteredAndSortedSheets = tempSheets;
    });
  }

  // --- File Operations (Simulated) ---

  Future<void> _pickAndAddFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'xlsx', 'txt', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final fileExtension = result.files.single.extension ?? 'unknown';

        // Prompt user for a title for the sheet
        String? sheetTitle = await _showTitleInputDialog(fileName);

        if (sheetTitle != null && sheetTitle.isNotEmpty) {
          final newSheet = SafetySheet(
            id: null, // Let the model generate a new UUID
            title: sheetTitle,
            filePath: filePath,
            fileExtension: fileExtension,
            uploadDate: DateTime.now(),
          );

          setState(() {
            _allSheets.insert(0, newSheet); // Add to the top
            _applyFiltersAndSort(); // Re-filter and sort
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${newSheet.title}" added successfully!')),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sheet addition cancelled. Title is required.')),
          );
        }
      } else {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File selection cancelled.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<String?> _showTitleInputDialog(String defaultTitle) {
    TextEditingController titleTextController = TextEditingController(text: defaultTitle.split('.').first);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Sheet Title'),
        content: TextField(
          controller: titleTextController,
          decoration: const InputDecoration(hintText: 'e.g., MSDS for Acid X'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, titleTextController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  Future<void> _openFile(String filePath) async {
    if (filePath.startsWith('assets/')) {
      // For assets, we can't directly open with open_filex without copying
      // to a temporary path first. For simplicity, we'll just show a message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open asset file directly: $filePath')),
      );
      // In a real app, you'd copy the asset to a temp directory and then open:
      /*
      try {
        final byteData = await rootBundle.load(filePath);
        final file = File('${(await getTemporaryDirectory()).path}/${filePath.split('/').last}');
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        await OpenFilex.open(file.path);
      } catch (e) {
        print('Error opening asset: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening asset: $e')),
        );
      }
      */
    } else {
      // For actual files picked from device
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    }
  }

  void _confirmDeleteSheet(SafetySheet sheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Safety Sheet?'),
        content: Text('Are you sure you want to delete "${sheet.title}"? This action cannot be undone and will not delete the actual file from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allSheets.removeWhere((s) => s.id == sheet.id);
                _applyFiltersAndSort(); // Re-filter and sort
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sheet "${sheet.title}" deleted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSheetDetails(SafetySheet sheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(sheet.title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('File Type: ${sheet.fileExtension.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Uploaded On: ${DateFormat.yMMMMd().format(sheet.uploadDate)}'),
              const SizedBox(height: 8),
              Text('File Path: ${sheet.filePath}'), // For debugging/info
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close details dialog
              _openFile(sheet.filePath); // Attempt to open the file
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
          ),
        ],
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
    final List<String> availableFileExtensions =
        {'All', ..._allSheets.map((s) => s.fileExtension.capitalize())}.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Data Sheets', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110), // Height for search bar and filters
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search safety sheets...',
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
                    // Filter by Type
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentFileExtensionFilter,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.filter_list, color: Colors.white),
                          dropdownColor: Colors.blue.shade700,
                          onChanged: (String? newValue) {
                            setState(() {
                              _currentFileExtensionFilter = newValue!;
                              _applyFiltersAndSort();
                            });
                          },
                          items: availableFileExtensions.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort Options
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SafetySheetSortOption>(
                          value: _currentSortOption,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.sort, color: Colors.white),
                          dropdownColor: Colors.blue.shade700,
                          onChanged: (SafetySheetSortOption? newValue) {
                            setState(() {
                              _currentSortOption = newValue!;
                              _applyFiltersAndSort();
                            });
                          },
                          items: SafetySheetSortOption.values.map((SafetySheetSortOption option) {
                            return DropdownMenuItem<SafetySheetSortOption>(
                              value: option,
                              child: Text(
                                option == SafetySheetSortOption.titleAsc
                                    ? 'Title (A-Z)'
                                    : 'Date (Newest)',
                                style: const TextStyle(color: Colors.white),
                              ),
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
      body: _filteredAndSortedSheets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_copy, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty && _currentFileExtensionFilter == 'All'
                        ? 'No safety sheets uploaded yet.'
                        : 'No matching safety sheets found.',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the "+" button to upload your first safety sheet.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredAndSortedSheets.length,
              itemBuilder: (context, index) {
                final sheet = _filteredAndSortedSheets[index];
                return Dismissible(
                  key: ValueKey(sheet.id),
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
                          content: Text("Are you sure you want to delete '${sheet.title}'? This will only remove it from the list, not the file from your device."),
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
                      _allSheets.removeWhere((item) => item.id == sheet.id);
                      _applyFiltersAndSort(); // Re-filter and sort
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${sheet.title}" deleted')),
                      );
                    });
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      leading: Icon(
                        SafetySheet.getIconForExtension(sheet.fileExtension),
                        color: SafetySheet.getColorForExtension(sheet.fileExtension),
                        size: 36,
                      ),
                      title: Text(
                        sheet.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(sheet.fileExtension.toUpperCase()),
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                backgroundColor: SafetySheet.getColorForExtension(sheet.fileExtension),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Uploaded: ${DateFormat.yMMMMd().format(sheet.uploadDate)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                          // Optional: display file path for debugging/info
                          // Text(sheet.filePath, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'open') {
                            _openFile(sheet.filePath);
                          } else if (value == 'details') {
                            _showSheetDetails(sheet);
                          } else if (value == 'delete') {
                            _confirmDeleteSheet(sheet);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.visibility),
                                SizedBox(width: 8),
                                Text('Open File'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline),
                                SizedBox(width: 8),
                                Text('Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
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
                      onTap: () => _openFile(sheet.filePath), // Tap to open file quickly
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndAddFile,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add Safety Sheet'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Safety'),
    );
  }
}

// Utility extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}