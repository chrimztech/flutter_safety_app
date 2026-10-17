import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/context_ext.dart';
import '../data/fields.dart';
import '../data/json.dart';
import '../data/models.dart';
import '../screens/common/attachments_section.dart';
import '../screens/common/notification_bell.dart';
import '../screens/common/review_section.dart';
import '../ui/dynamic_form.dart';
import '../ui/format.dart';
import '../ui/record_list.dart';
import '../ui/widgets.dart';
import 'module_spec.dart';
import '../ui/theme.dart';

/// Company users never choose a company: the server files their records under their own.
List<FieldSpec> _forViewer(List<FieldSpec> fields, AppUser me) =>
    me.isEmployer ? fields.where((f) => f.kind != FieldKind.company).toList() : fields;

/// List of a module's records with search, status filter, and "New" for those allowed to create.
class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({super.key, required this.spec});

  final ModuleSpec spec;

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  final _list = GlobalKey<RecordListState<Json>>();

  /// Latest regulator review per record id (registers the company keeps itself).
  Map<String, Json> _latest = const {};

  static const _reviewLabels = {'ACCEPTED': 'Accepted', 'CHANGES_REQUESTED': 'Changes requested', 'NOTED': 'Noted'};

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final me = context.me;
    final createFields = me.isEmployer && spec.companyCreateFields != null ? spec.companyCreateFields! : spec.createFields;
    final createLabel = me.isEmployer && spec.companyCreateLabel != null ? spec.companyCreateLabel! : 'New ${spec.singular.toLowerCase()}';
    return Scaffold(
      appBar: AppBar(title: Text(spec.title), actions: const [NotificationBell()]),
      floatingActionButton: createFields.isNotEmpty && spec.canCreate(me)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.push<Object?>(FormScreen(
                  title: createLabel,
                  sections: [FieldSection('', '', '', _forViewer(createFields, me))],
                  submitLabel: 'Create',
                  onSubmit: (p) => context.api.create(spec.path, {...spec.createExtras, ...p}),
                ));
                if (created != null && context.mounted) {
                  showMessage(context, '${spec.singular} created');
                  await _list.currentState?.reload();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(createLabel),
            )
          : null,
      body: RecordList<Json>(
        key: _list,
        load: () async {
          final api = context.api;
          if (spec.reviewType != null) {
            try {
              final rows = await api.list('reviews/latest', query: {'entityType': spec.reviewType});
              final latest = {for (final r in rows) text(r['entityId']): r};
              if (mounted) setState(() => _latest = latest);
            } catch (_) {
              // Review badges are extra; the list still loads.
            }
          }
          final list = await api.list(spec.path);
          list.sort(spec.sort ?? (a, b) => text(b['createdAt']).compareTo(text(a['createdAt'])));
          return list;
        },
        header: spec.header == null && spec.description == null && spec.reviewType == null
            ? null
            : (all) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (_latest.values.any((r) => r['status'] == 'CHANGES_REQUESTED'))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: Card(
                        color: OhsColors.amberTint,
                        shape: amberNotice,
                        child: ListTile(
                          leading: const Icon(Icons.rate_review_outlined, color: OhsColors.amber),
                          title: Text('${_latest.values.where((r) => r['status'] == 'CHANGES_REQUESTED').length} with changes requested by the inspectorate'),
                          subtitle: Text(me.isEmployer ? 'Open them to see what to change.' : 'Awaiting an update from the company.'),
                        ),
                      ),
                    ),
                  if (spec.description != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(spec.description!, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12.5)),
                    ),
                  if (spec.header != null) spec.header!(context, all),
                ]),
        searchHint: 'Search ${spec.title.toLowerCase()}',
        searchText: (r) => [spec.titleOf(r), spec.subtitleOf?.call(r) ?? '', text(r['referenceNumber']), nestedName(r['employer']) ?? ''].join(' '),
        filterValues: spec.statusFilters,
        filterOf: spec.statusKey == null ? null : spec.statusOf,
        emptyIcon: spec.icon,
        emptyTitle: 'No ${spec.title.toLowerCase()}',
        emptyMessage: spec.emptyMessage,
        tile: (context, r, reload) {
          final tone = spec.toneOf(r);
          final company = nestedName(r['employer']);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: toneOf(tone).withValues(alpha: 0.14),
              child: Icon(spec.icon, color: toneOf(tone), size: 20),
            ),
            title: Text(spec.titleOf(r), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [
                if (spec.subtitleOf != null) spec.subtitleOf!(r),
                if (company != null && !me.isEmployer) company,
                if (spec.reviewType != null) 'Review: ${_reviewLabels[_latest[spec.idOf(r)]?['status']] ?? 'not reviewed'}',
              ].where((s) => s.isNotEmpty).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: spec.statusKey == null || spec.statusOf(r).isEmpty ? null : Tag(spec.statusOf(r)),
            onTap: () async {
              await context.push(ModuleDetailScreen(spec: spec, id: spec.idOf(r)));
              await reload();
            },
          );
        },
      ),
    );
  }
}

/// One record: its details, attachments, edit / delete and the module's actions.
class ModuleDetailScreen extends StatefulWidget {
  const ModuleDetailScreen({super.key, required this.spec, required this.id});

  final ModuleSpec spec;
  final String id;

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final _loader = GlobalKey<LoaderState<Json>>();

  String get _recordPath => '${widget.spec.path}/${widget.id}';

  Future<void> _edit(Json r) async {
    final spec = widget.spec;
    final saved = await context.push<Object?>(FormScreen(
      title: 'Edit ${spec.singular.toLowerCase()}',
      sections: [FieldSection('', '', '', _forViewer(spec.editFields ?? spec.createFields, context.me))],
      initial: r,
      onlyChanged: true,
      onSubmit: (p) => context.api.update(_recordPath, p),
    ));
    if (saved != null && mounted) {
      showMessage(context, '${spec.singular} updated');
      await _loader.currentState?.reload();
    }
  }

  Future<void> _delete(Json r) async {
    final spec = widget.spec;
    if (!await confirm(context, 'Delete ${spec.singular.toLowerCase()}', 'Permanently delete "${spec.titleOf(r)}"? This cannot be undone.',
        action: 'Delete', destructive: true)) {
      return;
    }
    if (!mounted) return;
    final ok = await runAction(context, () => context.api.remove(_recordPath), success: '${spec.singular} deleted');
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _run(ModuleAction a, Json r) async {
    if (a.confirm != null && !await confirm(context, a.label, a.confirm!, action: a.label)) return;
    if (!mounted) return;
    final api = context.api;
    Future<Object?> send(Map<String, dynamic> form) {
      final body = {...a.fixed, ...?a.computeFixed?.call(r), ...form};
      return a.postAction == null ? api.update(_recordPath, body) : api.action('$_recordPath/${a.postAction}', body);
    }

    if (a.removes) {
      if (await runAction(context, () => api.remove(_recordPath), success: a.success ?? '${a.label} done') && mounted) Navigator.pop(context);
      return;
    }
    Object? done;
    if (a.fields.isEmpty) {
      done = await runAction(context, () => send(const {}), success: a.success ?? '${a.label} done') ? true : null;
    } else {
      done = await context.push<Object?>(FormScreen(
        title: a.label,
        sections: [FieldSection('', '', '', _forViewer(a.fields, context.me))],
        initial: r,
        submitLabel: a.label,
        onSubmit: send,
      ));
      if (done != null && mounted) showMessage(context, a.success ?? '${a.label} done');
    }
    if (done != null) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: Text(spec.singular)),
      body: Loader<Json>(
        key: _loader,
        load: () => context.api.one(_recordPath),
        builder: (context, r, reload) {
          final actions = spec.actions.where((a) => a.visible?.call(me, r) ?? spec.canEdit(me)).toList();
          final editable = spec.canEdit(me) && (spec.editFields ?? spec.createFields).isNotEmpty;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text(spec.titleOf(r), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (spec.statusKey != null && spec.statusOf(r).isNotEmpty) Tag(spec.statusOf(r)),
                if (spec.toneKey != null && spec.toneOf(r).isNotEmpty) Tag(spec.toneOf(r)),
              ]),
              const SizedBox(height: 12),
              Section(title: 'Details', children: [
                for (final d in spec.details) _DetailValue(item: d, record: r),
              ]),
              if (spec.reviewType != null) ...[
                const SizedBox(height: 10),
                ReviewSection(entityType: spec.reviewType!, entityId: spec.idOf(r)),
              ],
              if (r['confidential'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Clinical findings, vitals and test results are confidential to the company and its occupational health provider.',
                      style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.outline)),
                ),
              if (spec.attachmentType != null) ...[
                const SizedBox(height: 10),
                AttachmentsSection(entityType: spec.attachmentType!, entityId: spec.idOf(r), canUpload: spec.canEdit(me)),
              ],
              const SizedBox(height: 14),
              for (final a in actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonalIcon(onPressed: () => _run(a, r), icon: Icon(a.icon), label: Text(a.label)),
                ),
              if (editable)
                OutlinedButton.icon(onPressed: () => _edit(r), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
              if (spec.canDelete(me))
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () => _delete(r),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.item, required this.record});

  final DetailItem item;
  final Json record;

  @override
  Widget build(BuildContext context) {
    final v = item.read(record);
    switch (item.show) {
      case ShowAs.longText:
        return TextBlock(item.label, str(v));
      case ShowAs.date:
        return InfoRow(item.label, v == null ? null : fmtDate(date(v)));
      case ShowAs.dateTime:
        return InfoRow(item.label, v == null ? null : fmtDateTime(date(v)));
      case ShowAs.number:
        return InfoRow(item.label, v == null ? null : fmtNum(v));
      case ShowAs.money:
        return InfoRow(item.label, v == null ? null : 'K ${fmtNum(v)}');
      case ShowAs.boolean:
        return InfoRow(item.label, v == null ? null : (flag(v) ? 'Yes' : 'No'));
      case ShowAs.list:
        return TextBlock(item.label, v is List ? v.map((e) => '• $e').join('\n') : str(v));
      case ShowAs.company:
        return InfoRow(item.label, nestedName(v) ?? str(v));
      case ShowAs.tag:
        return InfoRow(item.label, v == null ? null : humanize(v.toString()));
      case ShowAs.link:
        final url = str(v);
        if (url == null || url.isEmpty) return const SizedBox.shrink();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.open_in_new),
          title: Text(item.label),
          subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        );
      case ShowAs.text:
        return InfoRow(item.label, v == null ? null : (v is Map ? nestedName(v) : v.toString()));
    }
  }
}
