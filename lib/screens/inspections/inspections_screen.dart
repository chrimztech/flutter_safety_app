import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../app/offline_queue.dart';
import '../../data/json.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../common/company_picker.dart';
import '../common/notification_bell.dart';
import 'inspection_detail_screen.dart';

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final _list = GlobalKey<RecordListState<Inspection>>();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    final canSchedule = me.can('inspections:write') && !me.isEmployer;
    return Scaffold(
      appBar: AppBar(title: const Text('Inspections'), actions: const [NotificationBell()]),
      floatingActionButton: canSchedule
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await scheduleInspection(context)) await _list.currentState?.reload();
              },
              icon: const Icon(Icons.event_available),
              label: const Text('Schedule'),
            )
          : null,
      body: RecordList<Inspection>(
        key: _list,
        load: () async {
          // Kept on the phone so inspections can be opened without a connection.
          final client = context.api.client;
          final list = await OfflineQueue.withOfflineCopy('inspections', () => client.get('inspections'),
              (json) => items(json).map(Inspection.fromJson).toList());
          // Soonest upcoming first, then most recent.
          list.sort((a, b) => (b.scheduledDate ?? DateTime(0)).compareTo(a.scheduledDate ?? DateTime(0)));
          return list;
        },
        searchHint: 'Search company, reference, inspector',
        searchText: (i) => '${i.reference} ${i.company?.name ?? ''} ${i.inspectorName ?? ''} ${i.type}',
        filterValues: Inspection.statuses,
        filterOf: (i) => i.status,
        emptyIcon: Icons.fact_check_outlined,
        emptyTitle: 'No inspections',
        emptyMessage: me.isEmployer ? 'Inspections of your workplaces appear here.' : 'Schedule one with the button below.',
        tile: (context, i, reload) => ListTile(
          leading: CircleAvatar(
            backgroundColor: toneOf(i.status).withValues(alpha: 0.15),
            child: Icon(i.status == 'completed' ? Icons.task_alt : Icons.fact_check_outlined, color: toneOf(i.status), size: 20),
          ),
          title: Text(i.company?.name ?? 'Inspection', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${humanize(i.type)} · ${fmtDate(i.scheduledDate)}${i.inspectorName == null ? '' : ' · ${i.inspectorName}'}'),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Tag(i.status),
            if (i.complianceScore != null && i.status == 'completed')
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('${fmtNum(i.complianceScore)}%', style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          onTap: () async {
            await context.push(InspectionDetailScreen(id: i.id));
            await reload();
          },
        ),
      ),
    );
  }
}

/// Opens the schedule form; true when an inspection was scheduled.
Future<bool> scheduleInspection(BuildContext context) async =>
    await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const ScheduleInspectionSheet()) == true;

class ScheduleInspectionSheet extends StatefulWidget {
  const ScheduleInspectionSheet({super.key});

  @override
  State<ScheduleInspectionSheet> createState() => ScheduleInspectionSheetState();
}

class ScheduleInspectionSheetState extends State<ScheduleInspectionSheet> {
  CompanyRef? _company;
  String _type = 'routine';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final _notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Schedule inspection', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        CompanyPicker(value: _company, onChanged: (c) => setState(() => _company = c)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: [for (final t in Inspection.types) DropdownMenuItem(value: t, child: Text(humanize(t)))],
          onChanged: (v) => setState(() => _type = v ?? _type),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: const Text('Date'),
          subtitle: Text(fmtDate(_date)),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 730)));
            if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, 9));
          },
        ),
        TextField(controller: _notes, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _company == null
              ? null
              : () async {
                  final ok = await runAction(
                    context,
                    () => context.api.scheduleInspection(employerId: _company!.id, type: _type, date: _date, notes: _notes.text.trim()),
                    success: 'Inspection scheduled',
                  );
                  if (ok && context.mounted) Navigator.pop(context, true);
                },
          child: const Text('Schedule'),
        ),
      ]),
    );
  }
}
