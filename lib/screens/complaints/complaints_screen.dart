import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../common/notification_bell.dart';
import '../common/record_forms.dart';

/// Complaints from workers and the public (including anonymous reports from the public portal).
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _list = GlobalKey<RecordListState<Complaint>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints'), actions: const [NotificationBell()]),
      floatingActionButton: context.me.can('complaints:write')
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await lodgeComplaint(context)) await _list.currentState?.reload();
              },
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('New complaint'),
            )
          : null,
      body: RecordList<Complaint>(
        key: _list,
        load: () async {
          final list = await context.api.complaints();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        },
        searchHint: 'Search reference, company, description',
        searchText: (c) => '${c.reference} ${c.companyLabel} ${c.description} ${c.location ?? ''}',
        filterValues: Complaint.statuses,
        filterOf: (c) => c.status,
        emptyIcon: Icons.campaign_outlined,
        emptyTitle: 'No complaints',
        tile: (context, c, reload) => ListTile(
          leading: CircleAvatar(
            backgroundColor: toneOf(c.urgency == 'normal' ? 'LOW' : c.urgency).withValues(alpha: 0.15),
            child: Icon(Icons.campaign_outlined, color: toneOf(c.urgency == 'normal' ? 'LOW' : c.urgency)),
          ),
          title: Text(c.companyLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${c.reference} · ${ago(c.createdAt)}\n${c.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
          isThreeLine: true,
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Tag(c.status),
            if (c.urgency != 'normal') Padding(padding: const EdgeInsets.only(top: 4), child: Text(humanize(c.urgency), style: TextStyle(fontSize: 11, color: toneOf(c.urgency)))),
          ]),
          onTap: () async {
            await context.push(ComplaintDetailScreen(id: c.id));
            await reload();
          },
        ),
      ),
    );
  }
}

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _loader = GlobalKey<LoaderState<Complaint>>();

  @override
  Widget build(BuildContext context) {
    final canEdit = context.me.can('complaints:write');
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint')),
      body: Loader<Complaint>(
        key: _loader,
        load: () => context.api.complaint(widget.id),
        builder: (context, c, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Text(c.companyLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [Tag(c.status), Tag(c.urgency == 'normal' ? 'LOW' : c.urgency, label: '${humanize(c.urgency)} urgency'), Tag(c.type, color: Theme.of(context).colorScheme.primary)]),
            const SizedBox(height: 12),
            Section(title: 'Report', children: [
              InfoRow('Reference', c.reference, copyable: true),
              InfoRow('Received', fmtDateTime(c.createdAt)),
              InfoRow('Source', humanize(c.source)),
              InfoRow('Location', c.location),
              InfoRow('Assigned to', c.assignedTo),
              const SizedBox(height: 6),
              Text(c.description, style: const TextStyle(height: 1.45)),
            ]),
            const SizedBox(height: 10),
            Section(title: 'Complainant', children: [
              if (c.anonymous)
                const Text('Anonymous — the identity of the reporter is protected.')
              else ...[
                InfoRow('Name', c.complainantName),
                InfoRow('Contact', c.complainantContact, copyable: true),
              ],
            ]),
            if ((c.resolutionNotes ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Section(title: 'Resolution', children: [Text(c.resolutionNotes!)]),
            ],
            const SizedBox(height: 16),
            if (canEdit)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in Complaint.statuses.where((s) => s != c.status))
                  OutlinedButton(
                    onPressed: () async {
                      final notes = (s == 'resolved' || s == 'closed')
                          ? await askText(context, 'Resolution', hint: 'What was found and done', required: true)
                          : null;
                      if ((s == 'resolved' || s == 'closed') && notes == null) return;
                      if (!context.mounted) return;
                      final ok = await runAction(
                        context,
                        () => context.api.updateComplaint(c.id, {
                          'status': s,
                          if (s == 'assigned' || s == 'investigating') 'assignedTo': context.me.name,
                          if (notes != null) 'resolutionNotes': notes,
                        }),
                        success: 'Complaint ${humanize(s).toLowerCase()}',
                      );
                      if (ok) await reload();
                    },
                    child: Text(switch (s) {
                      'assigned' => 'Assign to me',
                      'investigating' => 'Start investigation',
                      'resolved' => 'Resolve',
                      'closed' => 'Close',
                      _ => humanize(s),
                    }),
                  ),
              ]),
            if (canEdit) DeleteButton(path: 'complaints/${c.id}', what: 'complaint'),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
