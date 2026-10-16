import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import '../common/company_picker.dart';

/// Statutory incident notification. Company users report for their own company; officers choose the company.
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _persons = TextEditingController(text: '1');
  final _lostDays = TextEditingController();
  String _type = 'INJURY';
  String _severity = 'MEDIUM';
  DateTime _when = DateTime.now();
  CompanyRef? _company;
  bool _busy = false;

  Future<void> _pickWhen() async {
    final d = await showDatePicker(context: context, initialDate: _when, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    setState(() => _when = DateTime(d.year, d.month, d.day, t?.hour ?? _when.hour, t?.minute ?? _when.minute));
  }

  Future<void> _submit() async {
    final me = context.me;
    if (!_form.currentState!.validate()) return;
    if (!me.isEmployer && _company == null) {
      showMessage(context, 'Choose the company where it happened', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final created = await context.api.reportIncident(
        type: _type,
        severity: _severity,
        title: _title.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        incidentDate: _when,
        personsAffected: int.tryParse(_persons.text.trim()) ?? 1,
        employerId: me.isEmployer ? me.employerId : _company!.id,
        lostWorkDays: int.tryParse(_lostDays.text.trim()),
      );
      if (!mounted) return;
      showMessage(context, 'Incident ${created.reference} reported');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    final serious = _type == 'FATALITY' || _type == 'SERIOUS_INJURY';
    return Scaffold(
      appBar: AppBar(title: const Text('Report incident')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (me.isEmployer)
            InfoRow('Company', me.employerName)
          else
            CompanyPicker(value: _company, onChanged: (c) => setState(() => _company = c)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type *'),
            items: [for (final t in Incident.types) DropdownMenuItem(value: t, child: Text(humanize(t)))],
            onChanged: (v) => setState(() {
              _type = v ?? _type;
              if (_type == 'FATALITY') _severity = 'CRITICAL';
            }),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _severity,
            decoration: const InputDecoration(labelText: 'Severity *'),
            items: [for (final s in Incident.severities) DropdownMenuItem(value: s, child: Text(humanize(s)))],
            onChanged: (v) => setState(() => _severity = v ?? _severity),
          ),
          if (serious)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Fatalities and serious injuries must also be reported to the inspectorate by the fastest means (phone) without delay.',
                  style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Short title *', hintText: 'e.g. Worker fell from scaffold'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Location *', hintText: 'Site, building, area'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('When it happened'),
            subtitle: Text(fmtDateTime(_when)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _pickWhen,
          ),
          TextFormField(
            controller: _description,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'What happened *', alignLabelWithHint: true),
            validator: (v) => (v ?? '').trim().length < 10 ? 'Describe what happened' : null,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _persons,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Persons affected *'),
                validator: (v) => int.tryParse((v ?? '').trim()) == null ? 'Number' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lostDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lost work days'),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.send),
            label: Text(_busy ? 'Submitting...' : 'Submit report'),
          ),
        ]),
      ),
    );
  }
}
