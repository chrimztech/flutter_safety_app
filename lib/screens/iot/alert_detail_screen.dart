import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import 'recommendation_card.dart';

/// One hazard alert: what the sensor measured, immediate guidance, AI prevention recommendations and the review.
/// Company users acknowledge alerts and add notes; OHS staff resolve them or mark false alarms.
class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _loader = GlobalKey<LoaderState<(HazardEvent, List<Recommendation>)>>();

  Future<(HazardEvent, List<Recommendation>)> _load() async {
    final api = context.api;
    final results = await Future.wait([api.hazardEvent(widget.id), api.eventRecommendations(widget.id).catchError((_) => <Recommendation>[])]);
    return (results[0] as HazardEvent, results[1] as List<Recommendation>);
  }

  Future<void> _act(String? status, {bool askNote = false, String? title}) async {
    String? note;
    if (askNote) {
      note = await askText(context, title ?? 'Add a note', hint: 'What was found or done on site', required: status == null);
      if (note == null) return;
    }
    if (!mounted) return;
    final ok = await runAction(context, () => context.api.updateHazardEvent(widget.id, status: status, notes: note),
        success: status == null ? 'Note added' : 'Alert ${humanize(status).toLowerCase()}');
    if (ok) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: const Text('Hazard alert')),
      body: Loader<(HazardEvent, List<Recommendation>)>(
        key: _loader,
        load: _load,
        builder: (context, data, reload) {
          final (e, recos) = data;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Card(
                color: toneOf(e.severity).withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Tag(e.severity), const SizedBox(width: 6), Tag(e.status), const Spacer(), Text(e.reference, style: const TextStyle(fontSize: 12))]),
                    const SizedBox(height: 10),
                    Text(e.message, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (e.value != null) ...[
                      const SizedBox(height: 8),
                      Text('${humanize(e.metric)}: ${fmtNum(e.value)}${e.unit == null ? '' : ' ${e.unit}'}'
                          '${e.threshold == null ? '' : '  (limit ${fmtNum(e.threshold)}${e.unit == null ? '' : ' ${e.unit}'})'}'),
                    ],
                  ]),
                ),
              ),
              if ((e.guidance ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Card(
                  color: const Color(0xFFFFF8E1),
                  child: ListTile(
                    leading: const Icon(Icons.priority_high, color: Color(0xFFEF6C00)),
                    title: const Text('Immediate action', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(e.guidance!),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Section(title: 'Where and when', children: [
                InfoRow('Company', e.company?.name),
                InfoRow('Device', [e.deviceName, if (e.deviceType != null) humanize(e.deviceType)].join(' · ')),
                InfoRow('Zone', e.zone),
                InfoRow('Detected', fmtDateTime(e.detectedAt)),
                InfoRow('Last triggered', fmtDateTime(e.lastTriggeredAt)),
                InfoRow('Occurrences', e.occurrences.toString()),
                InfoRow('Detected by', e.ruleName ?? humanize(e.source)),
                InfoRow('Acknowledged by', e.acknowledgedBy),
                InfoRow('Closed by', e.resolvedBy),
                InfoRow('Incident', e.incidentReference),
              ]),
              if (recos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('  PREVENTION RECOMMENDATIONS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 0.8, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final r in recos) Padding(padding: const EdgeInsets.only(bottom: 8), child: RecommendationCard(r)),
              ],
              if ((e.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Notes', children: [Text(e.notes!, style: const TextStyle(height: 1.4))]),
              ],
              const SizedBox(height: 16),
              if (e.status == 'OPEN')
                FilledButton.icon(onPressed: () => _act('ACKNOWLEDGED'), icon: const Icon(Icons.visibility), label: const Text('Acknowledge — we are responding')),
              if (!me.isEmployer && e.isOpen) ...[
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _act('RESOLVED', askNote: true, title: 'How was the hazard resolved?'),
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Resolve — confirmed hazard'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _act('FALSE_ALARM', askNote: true, title: 'Why is this a false alarm?'),
                  icon: const Icon(Icons.do_not_disturb_on_outlined),
                  label: const Text('False alarm'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(onPressed: () => _act(null, askNote: true), icon: const Icon(Icons.note_add_outlined), label: const Text('Add a note')),
              if (me.isEmployer && e.isOpen)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('The inspectorate closes alerts after review.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                ),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}
