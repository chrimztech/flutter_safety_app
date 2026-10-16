import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../common/attachments_section.dart';
import '../common/notification_bell.dart';
import '../common/record_forms.dart';

/// Enforcement notices (warnings, improvement and prohibition notices, fines, prosecutions).
class EnforcementScreen extends StatefulWidget {
  const EnforcementScreen({super.key});

  @override
  State<EnforcementScreen> createState() => _EnforcementScreenState();
}

class _EnforcementScreenState extends State<EnforcementScreen> {
  final _list = GlobalKey<RecordListState<EnforcementNotice>>();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: Text(me.isEmployer ? 'Notices' : 'Enforcement'), actions: const [NotificationBell()]),
      floatingActionButton: me.isStaff
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await issueEnforcement(context)) await _list.currentState?.reload();
              },
              icon: const Icon(Icons.gavel),
              label: const Text('Issue action'),
            )
          : null,
      body: RecordList<EnforcementNotice>(
        key: _list,
        load: () async {
          final list = await context.api.enforcement();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        },
        searchHint: 'Search company, violation, reference',
        searchText: (n) => '${n.reference} ${n.company?.name ?? ''} ${n.violation} ${n.actionType}',
        filterValues: EnforcementNotice.statuses,
        filterOf: (n) => n.status,
        emptyIcon: Icons.gavel_outlined,
        emptyTitle: 'No enforcement notices',
        emptyMessage: me.isEmployer ? 'Notices issued to your company appear here.' : null,
        tile: (context, n, reload) => ListTile(
          leading: CircleAvatar(
            backgroundColor: toneOf(n.actionType).withValues(alpha: 0.15),
            child: Icon(Icons.gavel, color: toneOf(n.actionType), size: 20),
          ),
          title: Text(n.violation, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text([humanize(n.actionType), if (!me.isEmployer && n.company != null) n.company!.name, if (n.dueDate != null) 'Due ${fmtDate(n.dueDate)}'].join(' · ')),
          trailing: Tag(n.status),
          onTap: () async {
            await context.push(EnforcementDetailScreen(id: n.id));
            await reload();
          },
        ),
      ),
    );
  }
}

class EnforcementDetailScreen extends StatefulWidget {
  const EnforcementDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<EnforcementDetailScreen> createState() => _EnforcementDetailScreenState();
}

class _EnforcementDetailScreenState extends State<EnforcementDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final me = context.me;
    final canEdit = me.isStaff;
    return Scaffold(
      appBar: AppBar(title: const Text('Enforcement notice')),
      body: Loader<EnforcementNotice>(
        load: () => context.api.enforcementNotice(widget.id),
        builder: (context, n, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Text(humanize(n.actionType), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [Tag(n.status), Tag(n.actionType)]),
            const SizedBox(height: 12),
            Section(title: 'Notice', children: [
              InfoRow('Reference', n.reference, copyable: true),
              InfoRow('Company', n.company?.name),
              InfoRow('Issued', fmtDate(n.createdAt)),
              InfoRow('Issued by', n.inspector),
              InfoRow('Comply by', fmtDate(n.dueDate)),
              InfoRow('Appeal by', fmtDate(n.appealDeadline)),
              InfoRow('Penalty', n.penalty),
              TextBlock('Violation', n.violation),
              TextBlock('Details', n.details),
              TextBlock('Notes', n.notes),
            ]),
            if (me.isEmployer && n.appealDeadline != null && n.appealDeadline!.isAfter(DateTime.now()))
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('You may appeal this notice before the appeal deadline. Contact the issuing inspector or the agency office.'),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            AttachmentsSection(entityType: 'ENFORCEMENT', entityId: n.id, canUpload: canEdit),
            const SizedBox(height: 14),
            if (canEdit)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in EnforcementNotice.statuses.where((s) => s != n.status))
                  OutlinedButton(
                    onPressed: () async {
                      final ok = await runAction(context, () => context.api.updateEnforcement(n.id, {'status': s}), success: 'Notice ${humanize(s).toLowerCase()}');
                      if (ok) await reload();
                    },
                    child: Text('Mark ${humanize(s).toLowerCase()}'),
                  ),
              ]),
            if (canEdit) DeleteButton(path: 'enforcement/${n.id}', what: 'enforcement action'),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
