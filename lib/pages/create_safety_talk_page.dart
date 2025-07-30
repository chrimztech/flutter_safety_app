// pages/create_safety_talk_page.dart
import 'package:flutter/material.dart';

class CreateSafetyTalkPage extends StatefulWidget {
  const CreateSafetyTalkPage({super.key});

  @override
  State<CreateSafetyTalkPage> createState() => _CreateSafetyTalkPageState();
}

class _CreateSafetyTalkPageState extends State<CreateSafetyTalkPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _keyPointsControllers = [TextEditingController()];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _keyPointsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addKeyPointField() {
    setState(() {
      _keyPointsControllers.add(TextEditingController());
    });
  }

  void _removeKeyPointField(int index) {
    setState(() {
      if (_keyPointsControllers.length > 1) { // Ensure at least one field remains
        _keyPointsControllers[index].dispose();
        _keyPointsControllers.removeAt(index);
      } else {
        // Optionally, clear the last field instead of removing if only one
        _keyPointsControllers[index].clear();
      }
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text;
      final String description = _descriptionController.text;
      final List<String> keyPoints = _keyPointsControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // Return the new safety talk data
      Navigator.pop(context, {
        'title': title,
        'description': description,
        'keyPoints': keyPoints,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Safety Talk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary, // Use a distinct color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Talk Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the talk';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Brief Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brief description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Key Discussion Points:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _keyPointsControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _keyPointsControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Key Point ${index + 1}',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a key point';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_keyPointsControllers.length > 1) // Allow removal if more than one
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeKeyPointField(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addKeyPointField,
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  label: const Text('Add Another Key Point', style: TextStyle(color: Colors.blue)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary, // Use primary color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Safety Talk',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}