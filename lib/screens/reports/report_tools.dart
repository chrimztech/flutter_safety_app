import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import 'report_screen.dart';

const reportTypes = [
  ('executive', 'Executive overview'), ('incidents', 'Incidents'), ('injury-statistics', 'Injury statistics'),
  ('inspections', 'Inspections'), ('compliance', 'Compliance & employer registry'), ('complaints', 'Complaints'),
  ('enforcement', 'Enforcement'), ('permits', 'Permits & licensing'), ('corrective-actions', 'Corrective actions'),
  ('iot-hazards', 'IoT hazard monitoring'),
];

/// Generates a report draft (figures frozen at generation) and opens it.
Future<void> generateReport(BuildContext context) async {
  final api = context.api;
  final year = DateTime.now().year;
  final created = await context.push<Object?>(FormScreen(
    title: 'Generate report',
    intro: 'The report is created as a draft with its figures frozen. Submit it for review; another administrator approves it.',
    sections: [
      FieldSection('', '', '', [
        const FieldSpec('type', 'Report type', FieldKind.choice, required: true, initial: 'executive', options: reportTypes),
        const FieldSpec('title', 'Title', FieldKind.text, hint: 'Leave blank to name it from the type and period'),
        FieldSpec('dateFrom', 'From', FieldKind.date, initial: '$year-01-01'),
        FieldSpec('dateTo', 'To', FieldKind.date, initial: DateTime.now().toIso8601String().substring(0, 10)),
        const FieldSpec('district', 'District (optional)', FieldKind.text),
        const FieldSpec('sector', 'Sector (optional)', FieldKind.text),
        const FieldSpec('employerId', 'Company (optional)', FieldKind.company),
      ]),
    ],
    submitLabel: 'Generate draft',
    onSubmit: (p) => api.create('reports', p),
  ));
  final id = obj(created)?['id'];
  if (id != null && context.mounted) await context.push(ReportScreen(id: id.toString()));
}

/// Scheduled reports (administrators): generated automatically after each period as drafts for review.
class ReportSchedulesScreen extends StatefulWidget {
  const ReportSchedulesScreen({super.key});

  @override
  State<ReportSchedulesScreen> createState() => _ReportSchedulesScreenState();
}

class _ReportSchedulesScreenState extends State<ReportSchedulesScreen> {
  final _loader = GlobalKey<LoaderState<List<Json>>>();

  static const _frequencies = [
    ('WEEKLY', 'Weekly — every Monday, previous week'),
    ('MONTHLY', 'Monthly — on the 1st, previous month'),
    ('QUARTERLY', 'Quarterly — previous quarter'),
    ('YEARLY', 'Yearly — on 1 January, previous year'),
  ];

  String _type(Object? t) => reportTypes.firstWhere((r) => r.$1 == t, orElse: () => (text(t), humanize(text(t)))).$2;

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled reports')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New schedule'),
        onPressed: () async {
          final saved = await context.push<Object?>(FormScreen(
            title: 'New scheduled report',
            sections: const [
              FieldSection('', '', '', [
                FieldSpec('type', 'Report type', FieldKind.choice, required: true, initial: 'executive', options: reportTypes),
                FieldSpec('frequency', 'Frequency', FieldKind.choice, required: true, initial: 'MONTHLY', options: _frequencies),
                FieldSpec('district', 'District (optional)', FieldKind.text),
                FieldSpec('sector', 'Sector (optional)', FieldKind.text),
                FieldSpec('employerId', 'Company (optional)', FieldKind.company),
              ]),
            ],
            onSubmit: (p) => api.create('reports/schedules', p),
          ));
          if (saved != null) await _loader.currentState?.reload();
        },
      ),
      body: Loader<List<Json>>(
        key: _loader,
        load: () => api.list('reports/schedules'),
        empty: const EmptyView(icon: Icons.event_repeat, title: 'No scheduled reports', message: 'Have a report drafted automatically after every week, month, quarter or year.'),
        builder: (context, list, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
            for (final s in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${humanize(text(s['frequency']))} · ${_type(s['type'])}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      Tag(null, label: s['active'] == false ? 'Paused' : 'Active', color: s['active'] == false ? Colors.grey : Colors.green),
                    ]),
                    const SizedBox(height: 4),
                    Text([str(s['employerName']), str(s['district']), str(s['sector'])].whereType<String>().join(' · ').ifEmpty('Whole agency')),
                    Text('Next run ${s['active'] == false ? '—' : fmtDateTime(date(s['nextRunAt']))} · last run ${fmtDateTime(date(s['lastRunAt']))}',
                        style: const TextStyle(fontSize: 12)),
                    if (str(s['lastError']) != null) Text('Last run failed: ${s['lastError']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    Wrap(spacing: 4, children: [
                      TextButton(
                        onPressed: () async {
                          Object? r;
                          if (await runAction(context, () async => r = await api.action('reports/schedules/${s['id']}/run'), success: 'Report generated') &&
                              context.mounted) {
                            final id = obj(r)?['id'];
                            if (id != null) await context.push(ReportScreen(id: id.toString()));
                            await reload();
                          }
                        },
                        child: const Text('Run now'),
                      ),
                      if (str(s['lastReportId']) != null)
                        TextButton(onPressed: () => context.push(ReportScreen(id: text(s['lastReportId']))), child: const Text('Last report')),
                      TextButton(
                        onPressed: () async {
                          if (await runAction(context, () => api.update('reports/schedules/${s['id']}', {'active': s['active'] == false}),
                              success: s['active'] == false ? 'Schedule resumed' : 'Schedule paused')) {
                            await reload();
                          }
                        },
                        child: Text(s['active'] == false ? 'Resume' : 'Pause'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                        onPressed: () async {
                          if (!await confirm(context, 'Delete schedule', 'Reports it already produced are kept.', action: 'Delete', destructive: true)) return;
                          if (!context.mounted) return;
                          if (await runAction(context, () => api.remove('reports/schedules/${s['id']}'), success: 'Schedule deleted')) await reload();
                        },
                        child: const Text('Delete'),
                      ),
                    ]),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
