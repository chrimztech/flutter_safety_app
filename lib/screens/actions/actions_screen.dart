import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../common/attachments_section.dart';
import '../common/notification_bell.dart';
import '../common/record_forms.dart';
import '../../ui/theme.dart';

/// Corrective actions: what a company must fix, by when. Companies report progress with evidence; inspectors verify.
class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  final _list = GlobalKey<RecordListState<CorrectiveAction>>();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: Text(me.isEmployer ? 'Actions to complete' : 'Corrective actions'), actions: const [NotificationBell()]),
      floatingActionButton: me.isStaff
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await raiseCorrectiveAction(context)) await _list.currentState?.reload();
              },
              icon: const Icon(Icons.add_task),
              label: const Text('Raise action'),
            )
          : null,
      body: RecordList<CorrectiveAction>(
        key: _list,
        load: () async {
          final list = await context.api.correctiveActions();
          // Overdue first, then by due date.
          list.sort((a, b) {
            if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
            return (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999));
          });
          return list;
        },
        searchHint: 'Search title, reference, company',
        searchText: (a) => '${a.title} ${a.reference} ${a.company?.name ?? ''} ${a.sourceReference ?? ''}',
        filterValues: const ['overdue', ...CorrectiveAction.statuses],
        filterOf: (a) => a.isOverdue ? 'overdue' : a.status,
        initialFilter: null,
        emptyIcon: Icons.checklist_rtl,
        emptyTitle: 'No corrective actions',
        emptyMessage: me.isEmployer ? 'Actions the inspectorate requires from your company appear here.' : null,
        header: (all) {
          final overdue = all.where((a) => a.isOverdue).length;
          if (overdue == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Card(
              color: OhsColors.redTint,
              shape: redNotice,
              child: ListTile(
                leading: const Icon(Icons.schedule, color: OhsColors.red),
                title: Text('$overdue action${overdue == 1 ? ' is' : 's are'} overdue'),
                subtitle: const Text('Complete them or contact your inspector.'),
              ),
            ),
          );
        },
        tile: (context, a, reload) => ListTile(
          leading: CircleAvatar(
            backgroundColor: toneOf(a.isOverdue ? 'OVERDUE' : a.priority).withValues(alpha: 0.15),
            child: Icon(a.status == 'verified' ? Icons.verified : Icons.build_circle_outlined, color: toneOf(a.isOverdue ? 'OVERDUE' : a.priority)),
          ),
          title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text([
            if (!me.isEmployer && a.company != null) a.company!.name,
            'Due ${fmtDate(a.dueDate)}',
          ].join(' · ')),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Tag(a.isOverdue ? 'OVERDUE' : a.status, label: a.isOverdue ? 'Overdue' : null),
            const SizedBox(height: 4),
            Text(humanize(a.priority), style: TextStyle(fontSize: 11, color: toneOf(a.priority))),
          ]),
          onTap: () async {
            await context.push(ActionDetailScreen(id: a.id));
            await reload();
          },
        ),
      ),
    );
  }
}

class ActionDetailScreen extends StatefulWidget {
  const ActionDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ActionDetailScreen> createState() => _ActionDetailScreenState();
}

class _ActionDetailScreenState extends State<ActionDetailScreen> {
  final _loader = GlobalKey<LoaderState<CorrectiveAction>>();

  Future<void> _setStatus(CorrectiveAction a, String status, {bool askNotes = false}) async {
    String? notes;
    if (askNotes) {
      notes = await askText(context, status == 'completed' ? 'What was done?' : 'Verification notes',
          hint: status == 'completed' ? 'Describe the fix; add photos as evidence below' : null, required: status == 'completed', action: 'Submit');
      if (notes == null) return;
    }
    if (!mounted) return;
    final ok = await runAction(
      context,
      () => context.api.updateCorrectiveAction(a.id, {
        'status': status,
        if (notes != null && status == 'completed') 'completionNotes': notes,
        if (notes != null && status == 'verified') 'verificationNotes': notes,
        if (status == 'verified') 'verifiedBy': context.me.name,
      }),
      success: 'Marked ${humanize(status).toLowerCase()}',
    );
    if (ok) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: const Text('Corrective action')),
      body: Loader<CorrectiveAction>(
        key: _loader,
        load: () => context.api.correctiveAction(widget.id),
        builder: (context, a, reload) {
          final s = a.status.toLowerCase();
          final closed = const ['verified', 'cancelled'].contains(s);
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text(a.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                Tag(a.status),
                Tag(a.priority, label: '${humanize(a.priority)} priority'),
                if (a.isOverdue) const Tag('OVERDUE', label: 'Overdue'),
              ]),
              const SizedBox(height: 12),
              Section(title: 'Details', children: [
                InfoRow('Reference', a.reference, copyable: true),
                InfoRow('Company', a.company?.name),
                InfoRow('Raised from', [humanize(a.sourceType), a.sourceReference].whereType<String>().where((x) => x != '—').join(' ')),
                InfoRow('Assigned to', a.assignedTo),
                InfoRow('Due', fmtDate(a.dueDate)),
                InfoRow('Completed', fmtDate(a.completedDate)),
                InfoRow('Verified', a.verifiedBy == null ? null : '${a.verifiedBy} · ${fmtDate(a.verifiedDate)}'),
                TextBlock('What must be done', a.description),
                TextBlock('Completion notes', a.completionNotes),
                TextBlock('Verification notes', a.verificationNotes),
              ]),
              const SizedBox(height: 10),
              AttachmentsSection(entityType: 'CORRECTIVE_ACTION', entityId: a.id, canUpload: !closed, title: 'Evidence'),
              const SizedBox(height: 14),
              if (!closed) ...[
                if (s == 'open')
                  OutlinedButton.icon(onPressed: () => _setStatus(a, 'in_progress'), icon: const Icon(Icons.play_arrow), label: const Text('Start work')),
                if (s == 'open' || s == 'in_progress')
                  FilledButton.icon(
                    onPressed: () => _setStatus(a, 'completed', askNotes: true),
                    icon: const Icon(Icons.task_alt),
                    label: Text(me.isEmployer ? 'Mark completed — send for verification' : 'Mark completed'),
                  ),
                if (!me.isEmployer && s == 'completed')
                  FilledButton.icon(onPressed: () => _setStatus(a, 'verified', askNotes: true), icon: const Icon(Icons.verified), label: const Text('Verify')),
                if (!me.isEmployer && s == 'completed')
                  TextButton(onPressed: () => _setStatus(a, 'in_progress'), child: const Text('Not acceptable — reopen')),
              ],
              if (!me.isEmployer) DeleteButton(path: 'corrective-actions/${a.id}', what: 'corrective action'),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}
