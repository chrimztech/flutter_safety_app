import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import '../common/attachments_section.dart';
import '../common/record_forms.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _loader = GlobalKey<LoaderState<Incident>>();

  Future<void> _update(Incident i) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UpdateIncidentSheet(incident: i),
    );
    if (changed == true) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.me.can('incidents:write') && !context.me.isEmployer;
    return Scaffold(
      appBar: AppBar(title: const Text('Incident')),
      body: Loader<Incident>(
        key: _loader,
        load: () => context.api.incident(widget.id),
        builder: (context, i, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Text(i.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [Tag(i.severity), Tag(i.status), Tag(i.type, color: Theme.of(context).colorScheme.primary)]),
            const SizedBox(height: 12),
            Section(title: 'Details', children: [
              InfoRow('Reference', i.reference, copyable: true),
              InfoRow('Company', i.company?.name),
              InfoRow('Location', i.location),
              InfoRow('Occurred', fmtDateTime(i.incidentDate)),
              InfoRow('Reported', fmtDateTime(i.reportedDate)),
              InfoRow('Persons affected', i.personsAffected?.toString()),
              InfoRow('Lost work days', i.lostWorkDays?.toString()),
            ]),
            const SizedBox(height: 10),
            Section(title: 'What happened', children: [Text(i.description, style: const TextStyle(height: 1.45))]),
            if ((i.investigationNotes ?? '').isNotEmpty || (i.correctiveActions ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Section(title: 'Investigation', children: [
                TextBlock('Findings', i.investigationNotes),
                TextBlock('Corrective actions', i.correctiveActions),
              ]),
            ],
            const SizedBox(height: 10),
            AttachmentsSection(entityType: 'INCIDENT', entityId: i.id, canUpload: canEdit),
            if (canEdit) DeleteButton(path: 'incidents/${i.id}', what: 'incident'),
            const SizedBox(height: 80),
          ]),
        ),
      ),
      floatingActionButton: canEdit
          ? Builder(
              builder: (context) => FloatingActionButton.extended(
                onPressed: () async {
                  final i = await context.api.incident(widget.id);
                  if (context.mounted) await _update(i);
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Update'),
              ),
            )
          : null,
    );
  }
}

class _UpdateIncidentSheet extends StatefulWidget {
  const _UpdateIncidentSheet({required this.incident});

  final Incident incident;

  @override
  State<_UpdateIncidentSheet> createState() => _UpdateIncidentSheetState();
}

class _UpdateIncidentSheetState extends State<_UpdateIncidentSheet> {
  late String _status = widget.incident.status;
  late final _notes = TextEditingController(text: widget.incident.investigationNotes);
  late final _actions = TextEditingController(text: widget.incident.correctiveActions);
  late final _lost = TextEditingController(text: widget.incident.lostWorkDays?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('Update incident', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: Incident.statuses.contains(_status) ? _status : null,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [for (final s in Incident.statuses) DropdownMenuItem(value: s, child: Text(humanize(s)))],
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notes, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Investigation findings')),
          const SizedBox(height: 12),
          TextField(controller: _actions, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Corrective actions')),
          const SizedBox(height: 12),
          TextField(controller: _lost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lost work days')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final ok = await runAction(
                context,
                () => context.api.updateIncident(widget.incident.id, {
                  'status': _status,
                  'investigationNotes': _notes.text.trim(),
                  'correctiveActions': _actions.text.trim(),
                  if (int.tryParse(_lost.text.trim()) != null) 'lostWorkDays': int.parse(_lost.text.trim()),
                }),
                success: 'Incident updated',
              );
              if (ok && context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ]),
      ),
    );
  }
}
