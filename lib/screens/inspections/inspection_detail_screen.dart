import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import '../common/attachments_section.dart';
import '../common/record_forms.dart';
import 'checklist_screen.dart';

class InspectionDetailScreen extends StatefulWidget {
  const InspectionDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  final _loader = GlobalKey<LoaderState<Inspection>>();

  @override
  Widget build(BuildContext context) {
    final canEdit = context.me.can('inspections:write') && !context.me.isEmployer;
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection')),
      body: Loader<Inspection>(
        key: _loader,
        load: () => context.api.inspection(widget.id),
        builder: (context, i, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Text(i.company?.name ?? 'Inspection', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [Tag(i.status), Tag(i.type, color: Theme.of(context).colorScheme.primary)]),
            const SizedBox(height: 12),
            if (i.status == 'completed' && i.complianceScore != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(alignment: Alignment.center, children: [
                        CircularProgressIndicator(value: (i.complianceScore! / 100).clamp(0, 1), strokeWidth: 7, color: _scoreColor(i.complianceScore!)),
                        Text('${fmtNum(i.complianceScore)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Compliance score', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${i.violations ?? 0} violation(s) found · completed ${fmtDate(i.completedDate)}'),
                      ]),
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 10),
            Section(title: 'Details', children: [
              InfoRow('Reference', i.reference, copyable: true),
              InfoRow('Scheduled', fmtDateTime(i.scheduledDate)),
              InfoRow('Inspector', i.inspectorName),
              InfoRow('Completed', fmtDate(i.completedDate)),
            ]),
            if ([i.findings, i.recommendations, i.notes].any((t) => (t ?? '').isNotEmpty)) ...[
              const SizedBox(height: 10),
              Section(title: 'Outcome', children: [
                TextBlock('Findings', i.findings),
                TextBlock('Recommendations', i.recommendations),
                TextBlock('Notes', i.notes),
              ]),
            ],
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Inspection checklist'),
                subtitle: Text(canEdit ? 'Apply a template and record Pass / Fail / N/A on site' : 'Items checked during the inspection'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push(InspectionChecklistScreen(inspectionId: i.id, title: i.company?.name ?? i.reference, canEdit: canEdit));
                  await reload();
                },
              ),
            ),
            const SizedBox(height: 10),
            AttachmentsSection(entityType: 'INSPECTION', entityId: i.id, canUpload: canEdit, title: 'Photos & documents'),
            if (canEdit) DeleteButton(path: 'inspections/${i.id}', what: 'inspection'),
            const SizedBox(height: 80),
          ]),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Record outcome'),
              onPressed: () async {
                final i = await context.api.inspection(widget.id);
                if (!context.mounted) return;
                final changed = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _OutcomeSheet(inspection: i),
                );
                if (changed == true) await _loader.currentState?.reload();
              },
            )
          : null,
    );
  }

  static Color _scoreColor(double s) => s >= 80 ? Colors.green : s >= 60 ? Colors.orange : Colors.red;
}

class _OutcomeSheet extends StatefulWidget {
  const _OutcomeSheet({required this.inspection});

  final Inspection inspection;

  @override
  State<_OutcomeSheet> createState() => _OutcomeSheetState();
}

class _OutcomeSheetState extends State<_OutcomeSheet> {
  late String _status = Inspection.statuses.contains(widget.inspection.status) ? widget.inspection.status : 'in_progress';
  late double _score = (widget.inspection.complianceScore ?? 0).clamp(0, 100).toDouble();
  late final _violations = TextEditingController(text: '${widget.inspection.violations ?? 0}');
  late final _findings = TextEditingController(text: widget.inspection.findings);
  late final _recommendations = TextEditingController(text: widget.inspection.recommendations);
  late final _notes = TextEditingController(text: widget.inspection.notes);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('Inspection outcome', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [for (final s in Inspection.statuses) DropdownMenuItem(value: s, child: Text(humanize(s)))],
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 12),
          Text('Compliance score: ${_score.round()}%'),
          Slider(value: _score, min: 0, max: 100, divisions: 20, label: '${_score.round()}%', onChanged: (v) => setState(() => _score = v)),
          TextField(controller: _violations, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Violations found')),
          const SizedBox(height: 12),
          TextField(controller: _findings, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Findings')),
          const SizedBox(height: 12),
          TextField(controller: _recommendations, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Recommendations')),
          const SizedBox(height: 12),
          TextField(controller: _notes, minLines: 1, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final ok = await runAction(
                context,
                () => context.api.updateInspection(widget.inspection.id, {
                  'status': _status,
                  'complianceScore': _score.round(),
                  'violationsCount': int.tryParse(_violations.text.trim()) ?? 0,
                  'findings': _findings.text.trim(),
                  'recommendations': _recommendations.text.trim(),
                  'notes': _notes.text.trim(),
                }),
                success: 'Inspection updated',
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
