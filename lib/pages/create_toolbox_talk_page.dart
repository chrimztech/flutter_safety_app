// pages/create_toolbox_talk_page.dart

// This file defines a page for users to create a new, custom safety talk,
// with the added functionality of uploading a document to populate the form.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert'; // To handle JSON parsing

class CreateSafetyTalkPage extends StatefulWidget {
  const CreateSafetyTalkPage({super.key});

  @override
  State<CreateSafetyTalkPage> createState() => _CreateSafetyTalkPageState();
}

class _CreateSafetyTalkPageState extends State<CreateSafetyTalkPage> {
  // Controllers for the form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keyPointController = TextEditingController();

  // A list to hold the key points as they are added
  final List<String> _keyPoints = [];

  // A new variable to hold the uploaded file path
  String? _uploadedFilePath;

  // Function to add a new key point to the list
  void _addKeyPoint() {
    final text = _keyPointController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _keyPoints.add(text);
        _keyPointController.clear();
      });
    }
  }

  // Function to handle the document upload process
  Future<void> _uploadDocument() async {
    // Show a confirmation dialog to prevent accidental data loss
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Overwrite existing data?'),
        content: const Text(
            'Uploading a new document will clear any information you have already entered. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldUpload != true) {
      return; // User cancelled the upload
    }

    // Use file_picker to let the user select a file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'], // Assuming a JSON format for structured data
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final content = await file.readAsString();
        final Map<String, dynamic> data = json.decode(content);

        // Update the form fields with data from the file
        setState(() {
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _keyPoints.clear();
          if (data['keyPoints'] is List) {
            _keyPoints.addAll(List<String>.from(data['keyPoints']));
          }
          _uploadedFilePath = file.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Handle potential errors (e.g., invalid JSON format)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read or parse document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document upload cancelled.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  // Function to clear the uploaded document and form fields
  void _clearDocument() {
    setState(() {
      _uploadedFilePath = null;
      _titleController.clear();
      _descriptionController.clear();
      _keyPoints.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form cleared.'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  // Function to save the new talk and return the data
  void _saveTalk() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      // Show a snackbar or dialog if required fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and Description are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newTalkData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'keyPoints': _keyPoints,
    };
    // Pop the page and pass the new data back to the previous page
    Navigator.of(context).pop(newTalkData);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _keyPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Safety Talk',
            style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the details for your new safety talk or upload a document.',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              // New UI for file upload
              if (_uploadedFilePath == null)
                ElevatedButton.icon(
                  onPressed: _uploadDocument,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                Card(
                  color: Colors.teal.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.file_present, color: Colors.teal),
                    title: Text(
                      'Document uploaded: ${_uploadedFilePath!.split('/').last}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _clearDocument,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Fire Extinguisher Training',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.title, color: Colors.blue),
                ),
                validator: (value) => value!.isEmpty ? 'Title cannot be empty.' : null,
              ),
              const SizedBox(height: 16),
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide a brief summary of the talk.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.description, color: Colors.blue),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Description cannot be empty.' : null,
              ),
              const SizedBox(height: 16),
              // Key Points Section
              const Text(
                'Key Points',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _keyPointController,
                      decoration: InputDecoration(
                        labelText: 'Add a key point',
                        hintText: 'e.g., "Know your fire alarm exits"',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon:
                            const Icon(Icons.fiber_manual_record, size: 16, color: Colors.blue),
                      ),
                      onFieldSubmitted: (_) => _addKeyPoint(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addKeyPoint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display added key points
              ..._keyPoints.map(
                (point) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.check, color: Colors.green),
                    title: Text(point),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _keyPoints.remove(point);
                        });
                      },
                    ),
                  ),
                ),
              ).toList(),
              const SizedBox(height: 24),
              // Save and Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade400, width: 2),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveTalk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Talk', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
