import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import '../companies/companies_screen.dart';
import '../inspections/inspection_detail_screen.dart';

/// Compliance calendar: inspections, permit / certificate expiries, action deadlines, medical examinations by date.
class ComplianceCalendarScreen extends StatefulWidget {
  const ComplianceCalendarScreen({super.key});

  @override
  State<ComplianceCalendarScreen> createState() => _ComplianceCalendarScreenState();
}

class _ComplianceCalendarScreenState extends State<ComplianceCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _loader = GlobalKey<LoaderState<List<Json>>>();
  String? _type;

  String _d(DateTime d) => d.toIso8601String().substring(0, 10);

  void _shift(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
    _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compliance calendar')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(fmtDate(_month).split(' ').skip(1).join(' '),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
          ]),
        ),
        Expanded(
          child: Loader<List<Json>>(
            key: _loader,
            load: () => context.api.list('analytics/calendar',
                query: {'from': _d(_month), 'to': _d(DateTime(_month.year, _month.month + 1, 0))}),
            builder: (context, events, reload) {
              final types = events.map((e) => text(e['type'])).toSet().toList()..sort();
              final shown = events.where((e) => _type == null || text(e['type']) == _type).toList()
                ..sort((a, b) => text(a['date']).compareTo(text(b['date'])));
              final byDay = <String, List<Json>>{};
              for (final e in shown) {
                byDay.putIfAbsent(text(e['date']), () => []).add(e);
              }
              return Column(children: [
                if (types.isNotEmpty) FilterChips(values: types, selected: _type, onSelected: (v) => setState(() => _type = v)),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: reload,
                    child: shown.isEmpty
                        ? ListView(children: const [EmptyView(icon: Icons.event_available, title: 'Nothing due this month')])
                        : ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 24), children: [
                            for (final day in byDay.keys) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 4),
                                child: Text(fmtDate(date(day)), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              for (final e in byDay[day]!)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: Icon(_icon(text(e['type'])), color: toneOf(text(e['status']))),
                                    title: Text(text(e['title'])),
                                    subtitle: Text([humanize(text(e['type'])), text(e['subtitle'])].where((s) => s.isNotEmpty).join(' · ')),
                                    trailing: text(e['status']).isEmpty ? null : Tag(text(e['status'])),
                                    onTap: _target(e) == null ? null : () => context.push(_target(e)!),
                                  ),
                                ),
                            ],
                          ]),
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget? _target(Json e) {
    final link = text(e['link']);
    final id = link.split('/').last.split('?').first.split('=').last;
    if (link.contains('inspection') && id.length > 20) return InspectionDetailScreen(id: id);
    return null;
  }

  static IconData _icon(String type) {
    final t = type.toLowerCase();
    if (t.contains('inspection')) return Icons.fact_check_outlined;
    if (t.contains('permit')) return Icons.verified_outlined;
    if (t.contains('cert') || t.contains('equipment')) return Icons.build_circle_outlined;
    if (t.contains('action')) return Icons.checklist_rtl;
    if (t.contains('medical')) return Icons.medical_services_outlined;
    if (t.contains('enforcement') || t.contains('notice')) return Icons.gavel_outlined;
    return Icons.event;
  }
}

/// Compliance tracking: every company with its compliance score, risk and inspection coverage, worst first.
class ComplianceTrackingScreen extends StatelessWidget {
  const ComplianceTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compliance tracking')),
      body: Loader<(List<Company>, List<Inspection>)>(
        load: () async {
          final r = await Future.wait<Object>([context.api.companies(), context.api.inspections()]);
          return (r[0] as List<Company>, r[1] as List<Inspection>);
        },
        builder: (context, data, reload) {
          final (companies, inspections) = data;
          final lastInspection = <String, DateTime>{};
          for (final i in inspections.where((i) => i.status == 'completed')) {
            final id = i.company?.id;
            final d = i.completedDate ?? i.scheduledDate;
            if (id == null || d == null) continue;
            if (lastInspection[id] == null || d.isAfter(lastInspection[id]!)) lastInspection[id] = d;
          }
          final yearAgo = DateTime.now().subtract(const Duration(days: 365));
          final notInspected = companies.where((c) => lastInspection[c.id] == null || lastInspection[c.id]!.isBefore(yearAgo)).length;
          final scored = companies.where((c) => c.complianceScore != null && c.complianceScore! > 0).toList();
          final avg = scored.isEmpty ? 0 : scored.map((c) => c.complianceScore!).reduce((a, b) => a + b) / scored.length;
          final sorted = [...companies]..sort((a, b) => (a.complianceScore ?? 0).compareTo(b.complianceScore ?? 0));
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: [
                  StatTile(label: 'Average compliance', value: '${fmtNum(avg)}%', icon: Icons.verified_outlined),
                  StatTile(label: 'Below 60%', value: '${companies.where((c) => (c.complianceScore ?? 0) < 60).length}', icon: Icons.warning_amber, color: Colors.red),
                  StatTile(label: 'Not inspected in 12 months', value: '$notInspected', icon: Icons.event_busy, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 10),
              for (final c in sorted)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${c.sector ?? '—'} · last inspected ${lastInspection[c.id] == null ? 'never' : fmtDate(lastInspection[c.id])}'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: ((c.complianceScore ?? 0) / 100).clamp(0, 1),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        color: (c.complianceScore ?? 0) >= 80 ? Colors.green : (c.complianceScore ?? 0) >= 60 ? Colors.orange : Colors.red,
                      ),
                    ]),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${fmtNum(c.complianceScore ?? 0)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Tag(c.riskLevel),
                    ]),
                    onTap: () => context.push(CompanyDetailScreen(id: c.id)),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}
