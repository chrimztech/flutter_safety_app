import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/widgets.dart';

/// Create forms for staff, with the same fields as the web app's dialogs.

Future<bool> lodgeComplaint(BuildContext context) async {
  final api = context.api;
  final saved = await context.push<Object?>(FormScreen(
    title: 'New complaint',
    intro: 'Record a complaint received by phone, in person or by letter. Public reports from the portal arrive automatically.',
    sections: const [
      FieldSection('', '', '', [
        FieldSpec('employerId', 'Company', FieldKind.company),
        FieldSpec('type', 'Type', FieldKind.choice, required: true, initial: 'other', options: [
          ('unsafe_conditions', 'Unsafe conditions'), ('lack_of_ppe', 'Lack of PPE'), ('inadequate_training', 'Inadequate training'),
          ('retaliation', 'Retaliation'), ('other', 'Other'),
        ]),
        FieldSpec('urgency', 'Urgency', FieldKind.choice, required: true, initial: 'high', options: [('normal', 'Normal'), ('high', 'High'), ('critical', 'Critical — danger to life')]),
        FieldSpec('description', 'Complaint', FieldKind.multiline, required: true),
        FieldSpec('isAnonymous', 'Anonymous complainant', FieldKind.boolean, initial: true),
        FieldSpec('complainantName', 'Complainant name', FieldKind.text, help: 'Only if not anonymous'),
        FieldSpec('complainantContact', 'Complainant contact', FieldKind.text),
        FieldSpec('isRetaliationConcern', 'Complainant fears retaliation', FieldKind.boolean),
      ]),
    ],
    submitLabel: 'Record complaint',
    onSubmit: (p) => api.create('complaints', p),
  ));
  if (saved != null && context.mounted) showMessage(context, 'Complaint recorded');
  return saved != null;
}

Future<bool> issueEnforcement(BuildContext context, {String? employerId}) async {
  final api = context.api;
  final saved = await context.push<Object?>(FormScreen(
    title: 'Issue enforcement action',
    sections: const [
      FieldSection('', '', '', [
        FieldSpec('employerId', 'Company', FieldKind.company, required: true),
        FieldSpec('type', 'Action', FieldKind.choice, required: true, initial: 'warning', options: [
          ('warning', 'Warning'), ('improvement_notice', 'Improvement notice'), ('prohibition_notice', 'Prohibition notice'),
          ('fine', 'Fine'), ('prosecution', 'Prosecution'),
        ]),
        FieldSpec('description', 'Violation', FieldKind.multiline, required: true),
        FieldSpec('penalty', 'Penalty (K)', FieldKind.decimal, initial: 0),
        FieldSpec('dueDate', 'Comply by', FieldKind.date),
        FieldSpec('notes', 'Notes', FieldKind.multiline),
      ]),
    ],
    initial: employerId == null ? const {} : {'employerId': employerId},
    submitLabel: 'Issue',
    onSubmit: (p) => api.create('enforcement', p),
  ));
  if (saved != null && context.mounted) showMessage(context, 'Enforcement action issued');
  return saved != null;
}

Future<bool> raiseCorrectiveAction(BuildContext context) async {
  final api = context.api;
  final saved = await context.push<Object?>(FormScreen(
    title: 'Raise corrective action',
    sections: const [
      FieldSection('', '', '', [
        FieldSpec('employerId', 'Company', FieldKind.company, required: true),
        FieldSpec('title', 'What must be fixed', FieldKind.text, required: true),
        FieldSpec('description', 'Details', FieldKind.multiline),
        FieldSpec('priority', 'Priority', FieldKind.choice, required: true, initial: 'medium', options: [('critical', 'Critical'), ('high', 'High'), ('medium', 'Medium'), ('low', 'Low')]),
        FieldSpec('dueDate', 'Due date', FieldKind.date, required: true),
        FieldSpec('assignedTo', 'Responsible person at the company', FieldKind.text),
        FieldSpec('sourceType', 'Raised from', FieldKind.choice, initial: 'OTHER', options: [
          ('INSPECTION', 'Inspection'), ('INCIDENT', 'Incident'), ('COMPLAINT', 'Complaint'), ('AUDIT', 'Audit'), ('OTHER', 'Other'),
        ]),
        FieldSpec('sourceReference', 'Source reference', FieldKind.text, hint: 'e.g. INS-…'),
      ]),
    ],
    submitLabel: 'Raise action',
    onSubmit: (p) => api.create('corrective-actions', p),
  ));
  if (saved != null && context.mounted) showMessage(context, 'Corrective action raised');
  return saved != null;
}

/// Permanent delete with confirmation; pops the detail screen on success.
Future<void> deleteRecord(BuildContext context, String path, String what) async {
  if (!await confirm(context, 'Delete $what', 'Permanently delete this $what and its attachments? This cannot be undone.', action: 'Delete', destructive: true)) {
    return;
  }
  if (!context.mounted) return;
  final api = context.api;
  if (await runAction(context, () => api.remove(path), success: '${what[0].toUpperCase()}${what.substring(1)} deleted') && context.mounted) {
    Navigator.pop(context);
  }
}

/// A red text button for detail screens.
class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key, required this.path, required this.what});

  final String path;
  final String what;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
        onPressed: () => deleteRecord(context, path, what),
        icon: const Icon(Icons.delete_outline),
        label: Text('Delete $what'),
      );
}
