import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../common/notification_bell.dart';
import '../complaints/complaints_screen.dart';
import '../incidents/incidents_screen.dart';
import '../inspections/inspections_screen.dart';
import '../iot/alerts_screen.dart';
import '../iot/recommendation_card.dart';
import 'quick_actions.dart';

typedef _DashboardData = ({Json stats, Json iot, List<Recommendation> recommendations, List<HazardEvent> openAlerts});

/// Officers' and administrators' overview of the agency.
class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  Future<_DashboardData> _load(BuildContext context) async {
    final api = context.api;
    final results = await Future.wait<Object>([
      api.dashboard(),
      api.iotStats().catchError((_) => <String, dynamic>{}),
      api.recommendations().catchError((_) => <Recommendation>[]),
      api.hazardEvents().catchError((_) => <HazardEvent>[]),
    ]);
    final events = (results[3] as List<HazardEvent>).where((e) => e.isOpen).toList()
      ..sort((a, b) => (b.lastTriggeredAt ?? DateTime(0)).compareTo(a.lastTriggeredAt ?? DateTime(0)));
    return (
      stats: results[0] as Json,
      iot: results[1] as Json,
      recommendations: results[2] as List<Recommendation>,
      openAlerts: events,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, ${me.firstName ?? me.name}', style: const TextStyle(fontSize: 18)),
          Text(me.tenantName ?? 'Occupational Health and Safety', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ]),
        actions: const [NotificationBell()],
      ),
      body: Loader<_DashboardData>(
        load: () => _load(context),
        builder: (context, d, reload) {
          final s = d.stats;
          int n(String k) => integer(s[k]) ?? 0;
          final bySeverity = (obj(s['incidentsBySeverity']) ?? const {}).entries.map((e) => (label: e.key, value: integer(e.value) ?? 0)).toList()
            ..sort((a, b) => _sevRank(a.label).compareTo(_sevRank(b.label)));
          final trend = items(s['monthlyTrend']);
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              if (d.openAlerts.isNotEmpty)
                Card(
                  color: OhsColors.critical.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: const Icon(Icons.sensors, color: OhsColors.critical),
                    title: Text('${d.openAlerts.length} open hazard alert${d.openAlerts.length == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(d.openAlerts.first.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(const AlertsScreen()),
                  ),
                ),
              if (d.openAlerts.isNotEmpty) const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.35,
                children: [
                  StatTile(label: 'Incidents this month', value: fmtNum(n('monthlyIncidents')), icon: Icons.report_problem_outlined, color: OhsColors.high,
                      onTap: () => context.push(const IncidentsScreen())),
                  StatTile(label: 'Fatalities', value: fmtNum(n('fatalities')), icon: Icons.dangerous_outlined, color: OhsColors.critical,
                      onTap: () => context.push(const IncidentsScreen())),
                  StatTile(label: 'Active inspections', value: fmtNum(n('activeInspections')), icon: Icons.fact_check_outlined, color: OhsColors.info,
                      onTap: () => context.push(const InspectionsScreen())),
                  StatTile(label: 'Pending complaints', value: fmtNum(n('pendingComplaints')), icon: Icons.campaign_outlined, color: OhsColors.medium,
                      onTap: () => context.push(const ComplaintsScreen())),
                  StatTile(label: 'Compliance rate', value: '${fmtNum(number(s['complianceRate']) ?? 0)}%', icon: Icons.verified_outlined, color: OhsColors.low),
                  StatTile(label: 'Registered companies', value: fmtNum(n('totalEmployers')), icon: Icons.factory_outlined),
                ],
              ),
              const SizedBox(height: 10),
              QuickActions(onDone: reload),
              const SizedBox(height: 10),
              Section(title: 'Incidents by severity', children: [BarBreakdown(items: bySeverity, colorFor: toneOf)]),
              if (trend.isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Incidents — last 12 months', children: [
                  TrendBars(items: [for (final m in trend) (label: text(m['month']), value: integer(m['incidents']) ?? 0)]),
                ]),
              ],
              if (d.iot.isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Workplace sensors', children: [
                  InfoRow('Devices online', '${integer(d.iot['online']) ?? 0} of ${integer(d.iot['devices']) ?? 0}'),
                  InfoRow('Open alerts', '${integer(d.iot['openEvents']) ?? 0} (${integer(d.iot['criticalOpen']) ?? 0} critical)'),
                  InfoRow('Alerts in 24 h', fmtNum(integer(d.iot['eventsLast24h']) ?? 0)),
                  InfoRow('Companies monitored', fmtNum(integer(d.iot['companiesMonitored']) ?? 0)),
                ]),
              ],
              if (d.recommendations.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('  AI PREVENTION RECOMMENDATIONS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 0.8, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final r in d.recommendations.take(5)) Padding(padding: const EdgeInsets.only(bottom: 8), child: RecommendationCard(r)),
              ],
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }

  static int _sevRank(String s) => const {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3}[s.toUpperCase()] ?? 9;
}
