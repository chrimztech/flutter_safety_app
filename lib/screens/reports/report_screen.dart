import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../data/models.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// A report as a document: headline figures, breakdowns, trends, tables, findings — plus the review workflow.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.id});

  final String id;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _loader = GlobalKey<LoaderState<ReportSummary>>();

  Future<void> _workflow(Future<void> Function() action, String done) async {
    final ok = await runAction(context, action, success: done);
    if (ok) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: Loader<ReportSummary>(
        key: _loader,
        load: () => context.api.reportDocument(widget.id),
        builder: (context, r, reload) {
          final api = context.api;
          final ownReport = r.preparedById != null && r.preparedById == me.id;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text(r.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [Tag(r.status), Tag(null, label: 'v${r.version}', color: Theme.of(context).colorScheme.primary)]),
              const SizedBox(height: 10),
              Section(title: 'About', children: [
                InfoRow('Reference', r.reference, copyable: true),
                InfoRow('Type', r.category),
                InfoRow('Period', r.period),
                InfoRow('Scope', r.scope),
                InfoRow('Prepared by', r.preparedByName),
                InfoRow('Approved by', r.approvedByName),
                InfoRow('Published', fmtDate(r.publishedAt)),
              ]),
              if ((r.reviewComment ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Card(
                  color: OhsColors.amberTint,
                  shape: amberNotice,
                  child: ListTile(leading: const Icon(Icons.rate_review_outlined), title: const Text('Reviewer comment'), subtitle: Text(r.reviewComment!)),
                ),
              ],
              if ((r.summary ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Summary', children: [Text(r.summary!, style: const TextStyle(height: 1.45))]),
              ],
              if (r.kpis.isNotEmpty) ...[
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.1,
                  children: [
                    for (final k in r.kpis)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(fmtNum(k.value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            Text(k.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ],
              for (final s in r.sections) ...[const SizedBox(height: 10), _ReportSection(s)],
              const SizedBox(height: 10),
              Section(title: 'Findings', children: [
                for (final f in r.autoFindings) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('• $f')),
                TextBlock('Reviewer findings', r.findings),
                if (r.autoFindings.isEmpty && (r.findings ?? '').isEmpty) const Text('No findings recorded.'),
              ]),
              if ((r.recommendations ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Recommendations', children: [Text(r.recommendations!, style: const TextStyle(height: 1.45))]),
              ],
              const SizedBox(height: 16),
              if (me.can('reports:write') && r.status == 'DRAFT')
                FilledButton.icon(onPressed: () => _workflow(() => api.submitReport(r.id), 'Submitted for review'), icon: const Icon(Icons.send), label: const Text('Submit for review')),
              if (me.isAdmin && r.status == 'IN_REVIEW') ...[
                FilledButton.icon(
                  onPressed: ownReport
                      ? null
                      : () async {
                          final c = await askText(context, 'Approve report', hint: 'Comment (optional)', action: 'Approve');
                          if (c != null) await _workflow(() => api.approveReport(r.id, comment: c), 'Report approved');
                        },
                  icon: const Icon(Icons.verified),
                  label: Text(ownReport ? 'Another administrator must approve' : 'Approve'),
                ),
                const SizedBox(height: 8),
              ],
              if (me.isAdmin && (r.status == 'IN_REVIEW' || r.status == 'APPROVED'))
                OutlinedButton.icon(
                  onPressed: () async {
                    final c = await askText(context, 'Return to draft', hint: 'What needs to change?', required: true, action: 'Return');
                    if (c != null) await _workflow(() => api.returnReport(r.id, c), 'Returned to draft');
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('Return to draft'),
                ),
              if (me.isAdmin && r.status == 'APPROVED') ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    if (await confirm(context, 'Publish report', 'Once published the report is locked and cannot be edited.', action: 'Publish')) {
                      await _workflow(() => api.publishReport(r.id), 'Report published');
                    }
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('Publish'),
                ),
              ],
              const SizedBox(height: 8),
              if (me.can('reports:write') && (r.status == 'DRAFT' || r.status == 'IN_REVIEW'))
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Edit title, summary, findings, recommendations'),
                  onPressed: () async {
                    final saved = await context.push<Object?>(FormScreen(
                      title: 'Edit report text',
                      sections: const [
                        FieldSection('', '', '', [
                          FieldSpec('title', 'Title', FieldKind.text, required: true),
                          FieldSpec('summary', 'Summary', FieldKind.multiline),
                          FieldSpec('findings', 'Reviewer findings', FieldKind.multiline),
                          FieldSpec('recommendations', 'Recommendations', FieldKind.multiline),
                        ]),
                      ],
                      initial: {'title': r.title, 'summary': r.summary, 'findings': r.findings, 'recommendations': r.recommendations},
                      onlyChanged: true,
                      onSubmit: (p) => api.update('reports/${r.id}', p),
                    ));
                    if (saved != null) await _loader.currentState?.reload();
                  },
                ),
              if (me.can('reports:write') && r.status == 'DRAFT')
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate from the latest records'),
                  onPressed: () async {
                    if (await confirm(context, 'Regenerate', 'Rebuild this draft from the latest records? The version number increases.', action: 'Regenerate')) {
                      await _workflow(() => api.action('reports/${r.id}/regenerate'), 'Report regenerated');
                    }
                  },
                ),
              if (me.isAdmin && r.status == 'PUBLISHED')
                TextButton.icon(
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive'),
                  onPressed: () => _workflow(() => api.action('reports/${r.id}/archive'), 'Report archived'),
                ),
              if (!kIsWeb)
                TextButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download CSV'),
                  onPressed: () => runAction(context, () async {
                    final bytes = await api.client.getBytes('reports/${r.id}/export');
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/${r.reference.isEmpty ? 'report' : r.reference}.csv');
                    await file.writeAsBytes(bytes, flush: true);
                    final result = await OpenFilex.open(file.path);
                    if (result.type != ResultType.done) throw Exception('Saved to ${file.path}; no app on this device opens CSV files.');
                  }),
                ),
              if (me.can('reports:write') && (me.isAdmin || r.status == 'DRAFT' || r.status == 'IN_REVIEW'))
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete report'),
                  onPressed: () async {
                    if (!await confirm(context, 'Delete report', 'Permanently delete ${r.reference}?', action: 'Delete', destructive: true)) return;
                    if (!context.mounted) return;
                    if (await runAction(context, () => api.remove('reports/${r.id}'), success: 'Report deleted') && context.mounted) Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection(this.s);

  final Json s;

  @override
  Widget build(BuildContext context) {
    final kind = text(s['kind']);
    final title = text(s['title']);
    if (kind == 'table') {
      final columns = ((s['columns'] as List?) ?? const []).map((e) => e.toString()).toList();
      final rows = ((s['rows'] as List?) ?? const []).whereType<List>().toList();
      return Section(title: title, children: [
        if (rows.isEmpty)
          const Text('No records.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 44,
              columnSpacing: 18,
              columns: [for (final c in columns) DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.w700)))],
              rows: [
                for (final r in rows)
                  DataRow(cells: [for (var i = 0; i < columns.length; i++) DataCell(Text(i < r.length ? fmtNum(r[i]) : ''))]),
              ],
            ),
          ),
      ]);
    }
    final entries = items(s['items']).map((i) => (label: text(i['label']), value: number(i['value']) ?? 0)).toList();
    if (kind == 'trend') {
      return Section(title: title, children: [
        TrendBars(items: [for (final e in entries) (label: e.label.split(' ').first, value: e.value)], height: 150),
      ]);
    }
    final primary = Theme.of(context).colorScheme.primary;
    // Severity-like labels keep their status colour; other categories (sectors, districts) use the brand colour.
    return Section(title: title, children: [BarBreakdown(items: entries, colorFor: (l) => toneOf(l) == OhsColors.neutral ? primary : toneOf(l))]);
  }
}
