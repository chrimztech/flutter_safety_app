import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import 'report_screen.dart';
import 'report_tools.dart';

/// Official reports: generate drafts, review, approve and publish; administrators also manage schedules.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _list = GlobalKey<RecordListState<ReportSummary>>();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), actions: [
        if (me.isAdmin)
          IconButton(tooltip: 'Scheduled reports', icon: const Icon(Icons.event_repeat), onPressed: () => context.push(const ReportSchedulesScreen())),
      ]),
      floatingActionButton: me.can('reports:write')
          ? FloatingActionButton.extended(
              onPressed: () async {
                await generateReport(context);
                await _list.currentState?.reload();
              },
              icon: const Icon(Icons.add_chart),
              label: const Text('Generate'),
            )
          : null,
      body: RecordList<ReportSummary>(
        key: _list,
        load: context.api.reports,
        searchHint: 'Search title or reference',
        searchText: (r) => '${r.title} ${r.reference} ${r.category} ${r.preparedByName ?? ''}',
        filterValues: const ['DRAFT', 'IN_REVIEW', 'APPROVED', 'PUBLISHED', 'ARCHIVED'],
        filterOf: (r) => r.status,
        emptyIcon: Icons.description_outlined,
        emptyTitle: 'No reports',
        emptyMessage: "Generate a report from the agency's records, or set up a schedule.",
        tile: (context, r, reload) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.description_outlined, size: 20)),
          title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('${r.reference} · v${r.version} · ${r.period}'),
          trailing: Tag(r.status),
          onTap: () async {
            await context.push(ReportScreen(id: r.id));
            await reload();
          },
        ),
      ),
    );
  }
}
