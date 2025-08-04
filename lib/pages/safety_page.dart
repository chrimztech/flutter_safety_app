// pages/safety_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../models/safety_sheet_model.dart';
import 'quickaccess_bar.dart';

class SafetySheetsPage extends StatefulWidget {
  const SafetySheetsPage({super.key});

  @override
  State<SafetySheetsPage> createState() => _SafetySheetsPageState();
}

enum SafetySheetSortOption { titleAsc, dateDesc }

class _SafetySheetsPageState extends State<SafetySheetsPage> {
  final List<SafetySheet> _allSheets = [];
  List<SafetySheet> _filteredAndSortedSheets = [];
  final TextEditingController _searchController = TextEditingController();
  String _currentFileExtensionFilter = 'All';
  SafetySheetSortOption _currentSortOption = SafetySheetSortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _applyFiltersAndSort();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeMockData() {
    _allSheets.addAll([
      SafetySheet(
          title: 'Emergency Contact List',
          filePath: 'assets/docs/emergency_contacts.pdf',
          fileExtension: 'pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 1))),
      SafetySheet(
          title: 'Fire Safety Guidelines',
          filePath: 'assets/docs/fire_safety.pdf',
          fileExtension: 'pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 5))),
      SafetySheet(
          title: 'Chemical Spill Response Procedure',
          filePath: 'assets/docs/chemical_response.docx',
          fileExtension: 'docx',
          uploadDate: DateTime.now().subtract(const Duration(days: 10))),
      SafetySheet(
          title: 'Lockout/Tagout Procedures',
          filePath: 'assets/docs/loto_procedures.pdf',
          fileExtension: 'pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 40))),
      SafetySheet(
          title: 'Waste Segregation Manual',
          filePath: 'assets/docs/waste_manual.xlsx',
          fileExtension: 'xlsx',
          uploadDate: DateTime.now().subtract(const Duration(days: 70))),
      SafetySheet(
          title: 'Environmental Impact Assessment Guide',
          filePath: 'assets/docs/eia_guide.pdf',
          fileExtension: 'pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 200))),
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
          .where((sheet) => sheet.fileExtension.toLowerCase() == _currentFileExtensionFilter.toLowerCase())
          .toList();
    }

    // 3. Sort
    tempSheets.sort((a, b) {
      if (_currentSortOption == SafetySheetSortOption.titleAsc) {
        return a.title.compareTo(b.title);
      } else {
        return b.uploadDate.compareTo(a.uploadDate);
      }
    });

    setState(() {
      _filteredAndSortedSheets = tempSheets;
    });
  }

  // --- File Operations ---

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

        String? sheetTitle = await _showTitleInputDialog(fileName);

        if (sheetTitle != null && sheetTitle.isNotEmpty) {
          final newSheet = SafetySheet(
            title: sheetTitle,
            filePath: filePath,
            fileExtension: fileExtension,
            uploadDate: DateTime.now(),
          );

          setState(() {
            _allSheets.insert(0, newSheet);
            _applyFiltersAndSort();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${newSheet.title}" added successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sheet addition cancelled. Title is required.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
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
    // Check if it's an asset file
    if (filePath.startsWith('assets/')) {
      try {
        final byteData = await rootBundle.load(filePath);
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${filePath.split('/').last}');
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        
        final result = await OpenFilex.open(file.path);
        if (mounted && result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open asset file: ${result.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening asset file: $e')),
          );
        }
      }
    } else {
      // It's a file from the device
      final result = await OpenFilex.open(filePath);
      if (mounted && result.type != ResultType.done) {
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _allSheets.removeWhere((s) => s.id == sheet.id);
          _applyFiltersAndSort();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sheet "${sheet.title}" deleted.')),
        );
      }
    });
  }

  void _showSheetDetails(SafetySheet sheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(sheet.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDetailRow(context, 'File Type:', sheet.fileExtension.toUpperCase()),
            _buildDetailRow(context, 'Uploaded On:', DateFormat.yMMMMd().format(sheet.uploadDate)),
            // You can choose to show the path for debugging or hide it for users
            // _buildDetailRow(context, 'File Path:', sheet.filePath, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _openFile(sheet.filePath);
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {TextOverflow? overflow}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
              overflow: overflow,
            ),
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
    
    // Sort the extensions alphabetically for a cleaner dropdown
    availableFileExtensions.sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Data Sheets', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _pickAndAddFile,
            tooltip: 'Add new safety sheet',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    _buildDropdownFilter(
                      label: 'Filter by Type',
                      items: availableFileExtensions,
                      value: _currentFileExtensionFilter,
                      onChanged: (String? newValue) {
                        setState(() {
                          _currentFileExtensionFilter = newValue!;
                          _applyFiltersAndSort();
                        });
                      },
                      icon: Icons.filter_list,
                      theme: theme,
                    ),
                    const SizedBox(width: 16),
                    // Sort Options
                    _buildDropdownSort(
                      label: 'Sort by',
                      value: _currentSortOption,
                      onChanged: (SafetySheetSortOption? newValue) {
                        setState(() {
                          _currentSortOption = newValue!;
                          _applyFiltersAndSort();
                        });
                      },
                      icon: Icons.sort,
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _filteredAndSortedSheets.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredAndSortedSheets.length,
              itemBuilder: (context, index) {
                final sheet = _filteredAndSortedSheets[index];
                return _buildSheetListItem(sheet, theme);
              },
            ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Safety'),
    );
  }
  
  Widget _buildDropdownFilter({
    required String label,
    required List<String> items,
    required String value,
    required Function(String?) onChanged,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(30),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            style: const TextStyle(color: Colors.white),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.blue.shade700,
            onChanged: onChanged,
            isExpanded: true,
            hint: Text(label, style: const TextStyle(color: Colors.white70)),
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSort({
    required String label,
    required SafetySheetSortOption value,
    required Function(SafetySheetSortOption?) onChanged,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(30),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SafetySheetSortOption>(
            value: value,
            style: const TextStyle(color: Colors.white),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.blue.shade700,
            onChanged: onChanged,
            isExpanded: true,
            hint: Text(label, style: const TextStyle(color: Colors.white70)),
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
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.shade400),
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
              'Tap the "+" button to add your first safety sheet.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetListItem(SafetySheet sheet, ThemeData theme) {
    return Dismissible(
      key: ValueKey(sheet.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade600,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 36),
      ),
      confirmDismiss: (direction) => _showConfirmDeleteDialog(context, sheet),
      onDismissed: (direction) {
        setState(() {
          _allSheets.removeWhere((item) => item.id == sheet.id);
          _applyFiltersAndSort();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${sheet.title}" deleted')),
        );
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
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Uploaded: ${DateFormat.yMMMMd().format(sheet.uploadDate)}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'open') {
                _openFile(sheet.filePath);
              } else if (value == 'details') {
                _showSheetDetails(sheet);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: Text('Open File'),
              ),
              const PopupMenuItem(
                value: 'details',
                child: Text('Details'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
          onTap: () => _openFile(sheet.filePath),
        ),
      ),
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

Future<bool?> _showConfirmDeleteDialog(BuildContext context, SafetySheet sheet) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}