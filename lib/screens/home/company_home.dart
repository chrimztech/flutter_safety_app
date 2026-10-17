import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../data/models.dart';
import '../../modules/module_screens.dart';
import '../../modules/module_spec.dart';
import '../../modules/specs.dart';
import '../../ui/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../actions/actions_screen.dart';
import '../common/notification_bell.dart';
import '../incidents/report_incident_screen.dart';
import '../iot/alert_detail_screen.dart';
import '../iot/alerts_screen.dart';
import 'quick_actions.dart';

typedef _HomeData = ({Company company, List<CorrectiveAction> actions, List<HazardEvent> alerts, List<Incident> incidents, Json reviews});

/// Registers the company keeps itself, with the screen to open when the inspectorate asked for changes.
final _reviewedRegisters = <String, ModuleSpec>{
  'RISK_ASSESSMENT': riskAssessmentsSpec, 'HAZARDOUS_MATERIAL': hazmatSpec, 'EQUIPMENT_CERTIFICATION': equipmentSpec,
  'EMERGENCY_RESPONSE': emergencySpec, 'MEDICAL_SURVEILLANCE': medicalSpec, 'SAFETY_CULTURE': safetyCultureSpec,
};

/// Home for company users: what needs attention at their workplace.
class CompanyHome extends StatelessWidget {
  const CompanyHome({super.key});

  Future<_HomeData> _load(BuildContext context) async {
    final api = context.api;
    final r = await Future.wait<Object>([
      api.myCompany(),
      api.correctiveActions().catchError((_) => <CorrectiveAction>[]),
      api.hazardEvents().catchError((_) => <HazardEvent>[]),
      api.incidents().catchError((_) => <Incident>[]),
      api.one('reviews/summary').catchError((_) => <String, dynamic>{}),
    ]);
    return (
      company: r[0] as Company,
      actions: r[1] as List<CorrectiveAction>,
      alerts: (r[2] as List<HazardEvent>).where((e) => e.isOpen).toList(),
      incidents: r[3] as List<Incident>,
      reviews: r[4] as Json,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: BrandTitle(title: me.employerName ?? 'My company', subtitle: 'Signed in as ${me.name}'),
        actions: const [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(const ReportIncidentScreen()),
        icon: const Icon(Icons.add_alert),
        label: const Text('Report incident'),
      ),
      body: Loader<_HomeData>(
        load: () => _load(context),
        builder: (context, d, reload) {
          final open = d.actions.where((a) => !const ['completed', 'verified', 'cancelled'].contains(a.status.toLowerCase())).toList();
          final overdue = open.where((a) => a.isOverdue).length;
          final thisYear = d.incidents.where((i) => i.incidentDate?.year == DateTime.now().year).length;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              WelcomeBanner(
                eyebrow: fmtToday(),
                title: '${greeting()}, ${me.firstName ?? me.name}',
                subtitle: [d.company.name, if (d.company.sector != null) d.company.sector!].join(' · '),
                trailing: d.company.complianceScore == null ? null : _ScoreRing(d.company.complianceScore!),
              ),
              const SizedBox(height: 10),
              if ((integer(d.reviews['changesRequested']) ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    color: OhsColors.amberTint,
                    shape: amberNotice,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('The inspectorate asked for changes to ${d.reviews['changesRequested']} of your records',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final e in _reviewedRegisters.entries)
                            if ((integer(d.reviews[e.key]) ?? 0) > 0)
                              ActionChip(
                                label: Text('${e.value.title}: ${d.reviews[e.key]}'),
                                onPressed: () => context.push(ModuleListScreen(spec: e.value)),
                              ),
                        ]),
                      ]),
                    ),
                  ),
                ),
              for (final a in d.alerts.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    color: toneOf(a.severity).withValues(alpha: 0.12),
                    shape: noticeShape(toneOf(a.severity)),
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: toneOf(a.severity)),
                      title: Text(a.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${a.deviceName}${a.zone == null ? '' : ' · ${a.zone}'} · ${ago(a.lastTriggeredAt ?? a.detectedAt)}'),
                      trailing: Tag(a.status),
                      onTap: () => context.push(AlertDetailScreen(id: a.id)),
                    ),
                  ),
                ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.7,
                children: [
                  StatTile(label: 'Open actions', value: '${open.length}', icon: Icons.checklist_rtl, onTap: () => context.push(const ActionsScreen())),
                  StatTile(label: 'Overdue actions', value: '$overdue', icon: Icons.schedule, color: overdue > 0 ? OhsColors.critical : OhsColors.low,
                      onTap: () => context.push(const ActionsScreen())),
                  StatTile(label: 'Open hazard alerts', value: '${d.alerts.length}', icon: Icons.sensors, color: d.alerts.isEmpty ? OhsColors.low : OhsColors.high,
                      onTap: () => context.push(const AlertsScreen())),
                  StatTile(label: 'Incidents this year', value: '$thisYear', icon: Icons.report_problem_outlined, color: OhsColors.medium),
                ],
              ),
              const SizedBox(height: 10),
              QuickActions(onDone: reload),
              const SizedBox(height: 10),
              Section(title: 'Compliance', children: [
                InfoRow('Risk level', humanize(d.company.riskLevel)),
                InfoRow('Compliance score', d.company.complianceScore == null ? null : '${fmtNum(d.company.complianceScore)}%'),
                InfoRow('Inspections', fmtNum(d.company.inspectionsCount ?? 0)),
                if (d.company.profileCompleteness != null) ...[
                  const SizedBox(height: 6),
                  Text('Company profile ${d.company.profileCompleteness}% complete'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: d.company.profileCompleteness! / 100, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                ],
              ]),
              if (open.isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Next actions due', children: [
                  for (final a in (open..sort((x, y) => (x.dueDate ?? DateTime(9999)).compareTo(y.dueDate ?? DateTime(9999)))).take(4))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Due ${fmtDate(a.dueDate)}'),
                      trailing: Tag(a.isOverdue ? 'OVERDUE' : a.status, label: a.isOverdue ? 'Overdue' : null),
                      onTap: () => context.push(ActionDetailScreen(id: a.id)),
                    ),
                ]),
              ],
              const SizedBox(height: 90),
            ]),
          );
        },
      ),
    );
  }
}

/// Compliance score as a ring, coloured like the web's score badges.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing(this.score);

  final double score;

  @override
  Widget build(BuildContext context) {
    final c = score >= 80 ? OhsColors.green : score >= 60 ? OhsColors.amber : OhsColors.red;
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
          child: CircularProgressIndicator(value: (score / 100).clamp(0, 1), strokeWidth: 5, color: c, backgroundColor: OhsColors.bg3),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${score.round()}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1)),
          const Text('SCORE', style: TextStyle(fontFamily: mono, fontSize: 7.5, color: OhsColors.text3, letterSpacing: 0.6)),
        ]),
      ]),
    );
  }
}
