// pages/incident_reporting_page.dart
import 'package:flutter/material.dart';

class IncidentReportingPage extends StatefulWidget {
  const IncidentReportingPage({super.key});

  @override
  State<IncidentReportingPage> createState() => _IncidentReportingPageState();
}

class _IncidentReportingPageState extends State<IncidentReportingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedCategory;
  String? _selectedSeverity;

  final List<String> _categories = ['Fire', 'Chemical', 'Equipment', 'Other'];
  final List<String> _severities = ['Low', 'Medium', 'High', 'Critical'];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.blue.shade800,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showCustomSnack(String message, {Color? color = Colors.green, IconData icon = Icons.check_circle}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showCustomSnack("Please pick the incident date", color: Colors.red, icon: Icons.error);
      return;
    }
    if (_selectedCategory == null) {
      _showCustomSnack("Please select a category", color: Colors.red, icon: Icons.warning);
      return;
    }
    if (_selectedSeverity == null) {
      _showCustomSnack("Please select severity", color: Colors.red, icon: Icons.warning);
      return;
    }

    final incident = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'date': _selectedDate,
      'category': _selectedCategory,
      'severity': _selectedSeverity,
    };

    _showCustomSnack("Incident '${incident['title']}' reported successfully!");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear Form?"),
        content: const Text("Do you want to reset the form now?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _formKey.currentState?.reset();
              _titleController.clear();
              _descriptionController.clear();
              _locationController.clear();
              setState(() {
                _selectedDate = null;
                _selectedCategory = null;
                _selectedSeverity = null;
              });
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue),
              hintText: label,
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    IconData icon = Icons.arrow_drop_down_circle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue),
              filled: true,
              fillColor: Colors.blue.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            validator: (value) => value == null ? 'Select $label' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Date of Incident"),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.date_range, color: Colors.blue),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Tap to select date'
                    : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedDate == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Reporting'),
        backgroundColor: Colors.blue.shade700,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField(
                controller: _titleController,
                label: 'Incident Title',
                icon: Icons.warning,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.notes,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: _categories,
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Severity',
                value: _selectedSeverity,
                items: _severities,
                onChanged: (val) => setState(() => _selectedSeverity = val),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Submit Incident"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
