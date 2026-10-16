import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../common/notification_bell.dart';
import 'incident_detail_screen.dart';
import 'report_incident_screen.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final _list = GlobalKey<RecordListState<Incident>>();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    final canReport = me.isEmployer || me.can('incidents:write');
    return Scaffold(
      appBar: AppBar(title: Text(me.isEmployer ? 'Our incidents' : 'Incidents'), actions: const [NotificationBell()]),
      floatingActionButton: canReport
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.push<bool>(const ReportIncidentScreen());
                if (created == true) await _list.currentState?.reload();
              },
              icon: const Icon(Icons.add_alert),
              label: const Text('Report incident'),
            )
          : null,
      body: RecordList<Incident>(
        key: _list,
        load: context.api.incidents,
        searchHint: 'Search title, reference, company, location',
        searchText: (i) => '${i.title} ${i.reference} ${i.company?.name ?? ''} ${i.location} ${i.type}',
        filterValues: Incident.statuses,
        filterOf: (i) => i.status,
        initialFilter: widget.initialStatus,
        emptyIcon: Icons.health_and_safety_outlined,
        emptyTitle: 'No incidents reported',
        emptyMessage: me.isEmployer ? 'Incidents your company reports appear here.' : null,
        tile: (context, i, reload) => ListTile(
          leading: CircleAvatar(
            backgroundColor: toneOf(i.severity).withValues(alpha: 0.15),
            child: Icon(_icon(i.type), color: toneOf(i.severity), size: 20),
          ),
          title: Text(i.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text([i.reference, if (i.company != null && !me.isEmployer) i.company!.name, fmtDate(i.incidentDate)].join(' · '),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Tag(i.severity),
            const SizedBox(height: 4),
            Text(humanize(i.status), style: TextStyle(fontSize: 11, color: toneOf(i.status))),
          ]),
          onTap: () async {
            await context.push(IncidentDetailScreen(id: i.id));
            await reload();
          },
        ),
      ),
    );
  }
}

IconData _icon(String type) => switch (type) {
      'FATALITY' => Icons.dangerous,
      'SERIOUS_INJURY' => Icons.personal_injury,
      'INJURY' => Icons.healing,
      'NEAR_MISS' => Icons.warning_amber,
      _ => Icons.report_problem_outlined,
    };
