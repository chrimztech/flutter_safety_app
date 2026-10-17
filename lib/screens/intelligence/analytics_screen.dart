import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../ui/format.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../companies/companies_screen.dart';

/// Analytics, statistics & KPIs, and the risk picture by district and sector — the web's Government dashboard,
/// Analytics, Statistics and Risk heat map in one place.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<Map<String, Json>> _load(BuildContext context) async {
    final api = context.api;
    Future<Json> get(String path) async => obj(await api.client.get(path)) ?? const {};
    final keys = ['dashboard', 'rates', 'sectors', 'districts', 'top', 'trends', 'inspections'];
    final results = await Future.wait([
      get('analytics/dashboard'),
      get('analytics/injury-rates').catchError((_) => <String, dynamic>{}),
      get('analytics/sector-compliance').catchError((_) => <String, dynamic>{}),
      get('analytics/district-analysis').catchError((_) => <String, dynamic>{}),
      get('analytics/top-risk-employers').catchError((_) => <String, dynamic>{}),
      get('analytics/incident-trends').catchError((_) => <String, dynamic>{}),
      get('analytics/inspection-performance').catchError((_) => <String, dynamic>{}),
    ]);
    return {for (var i = 0; i < keys.length; i++) keys[i]: results[i]};
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Overview'), Tab(text: 'Injury rates'), Tab(text: 'Risk map')],
          ),
        ),
        body: Loader<Map<String, Json>>(
          load: () => _load(context),
          builder: (context, d, reload) => TabBarView(children: [
            RefreshIndicator(onRefresh: reload, child: _Overview(d)),
            RefreshIndicator(onRefresh: reload, child: _Rates(d['rates']!)),
            RefreshIndicator(onRefresh: reload, child: _RiskMap(d)),
          ]),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview(this.d);

  final Map<String, Json> d;

  @override
  Widget build(BuildContext context) {
    final s = d['dashboard']!;
    int n(String k) => integer(s[k]) ?? 0;
    List<({String label, num value})> breakdown(Object? m) =>
        (obj(m) ?? const {}).entries.map((e) => (label: e.key, value: integer(e.value) ?? 0)).toList()..sort((a, b) => b.value.compareTo(a.value));
    final trend = items(obj(d['trends'])?['trends'] ?? s['monthlyTrend']);
    final perf = obj(d['inspections']?['performance']) ?? const {};
    return ListView(padding: const EdgeInsets.all(12), children: [
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
        children: [
          StatTile(label: 'Companies', value: fmtNum(n('totalEmployers')), icon: Icons.factory_outlined),
          StatTile(label: 'Incidents', value: fmtNum(n('totalIncidents')), icon: Icons.report_problem_outlined, color: OhsColors.high),
          StatTile(label: 'Fatalities', value: fmtNum(n('fatalities')), icon: Icons.dangerous_outlined, color: OhsColors.critical),
          StatTile(label: 'Inspections', value: fmtNum(n('totalInspections')), icon: Icons.fact_check_outlined, color: OhsColors.info),
          StatTile(label: 'Complaints', value: fmtNum(n('totalComplaints')), icon: Icons.campaign_outlined, color: OhsColors.medium),
          StatTile(label: 'Enforcement', value: fmtNum(n('totalEnforcementActions')), icon: Icons.gavel_outlined),
          StatTile(label: 'Compliance', value: '${fmtNum(number(s['complianceRate']) ?? 0)}%', icon: Icons.verified_outlined, color: OhsColors.low),
          StatTile(label: 'Avg inspection score', value: '${fmtNum(number(s['averageInspectionScore']) ?? 0)}%', icon: Icons.grade_outlined),
          StatTile(label: 'Active permits', value: fmtNum(n('activePermits')), icon: Icons.verified_user_outlined),
        ],
      ),
      const SizedBox(height: 10),
      if (trend.isNotEmpty)
        Section(title: 'Incidents by month', children: [
          TrendBars(items: [for (final m in trend) (label: text(m['month']), value: integer(m['incidents']) ?? 0)]),
        ]),
      const SizedBox(height: 10),
      Section(title: 'Incidents by type', children: [BarBreakdown(items: breakdown(s['incidentsByType']))]),
      const SizedBox(height: 10),
      Section(title: 'Incidents by severity', children: [BarBreakdown(items: breakdown(s['incidentsBySeverity']), colorFor: toneOf)]),
      const SizedBox(height: 10),
      Section(title: 'Companies by risk level', children: [BarBreakdown(items: breakdown(s['riskDistribution']), colorFor: toneOf)]),
      const SizedBox(height: 10),
      Section(title: 'Inspections by status', children: [BarBreakdown(items: breakdown(s['inspectionsByStatus']), colorFor: toneOf)]),
      if (perf.isNotEmpty) ...[
        const SizedBox(height: 10),
        Section(title: 'Inspection performance', children: [
          InfoRow('Total inspections', fmtNum(perf['totalInspections'])),
          InfoRow('Completed this month', fmtNum(perf['completedThisMonth'])),
          InfoRow('Average score', '${fmtNum(perf['averageScore'])}%'),
          for (final i in items(perf['inspectorStats']))
            InfoRow(text(i['inspector'] ?? i['name'], 'Inspector'), '${fmtNum(i['completed'] ?? i['inspections'])} done · ${fmtNum(i['averageScore'] ?? 0)}%'),
        ]),
      ],
      const SizedBox(height: 10),
      Section(title: 'Training', children: [
        InfoRow('Courses', fmtNum(n('trainingCourses'))),
        InfoRow('Enrolled', fmtNum(n('trainingEnrolled'))),
        InfoRow('Completed', fmtNum(n('trainingCompleted'))),
      ]),
      const SizedBox(height: 24),
    ]);
  }
}

class _Rates extends StatelessWidget {
  const _Rates(this.r);

  final Json r;

  @override
  Widget build(BuildContext context) {
    final sectors = items(r['bySector']);
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text('Rates per 1,000,000 hours worked over the last ${r['periodMonths'] ?? 12} months.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
        children: [
          StatTile(label: 'LTIFR', value: fmtNum(number(r['ltifr']) ?? 0), icon: Icons.trending_up, color: OhsColors.high),
          StatTile(label: 'TRIFR', value: fmtNum(number(r['trifr']) ?? 0), icon: Icons.show_chart),
          StatTile(label: 'Severity rate', value: fmtNum(number(r['severityRate']) ?? 0), icon: Icons.priority_high, color: OhsColors.critical),
        ],
      ),
      const SizedBox(height: 10),
      Section(title: 'Totals', children: [
        InfoRow('Hours worked', fmtNum(r['hoursWorked'])),
        InfoRow('Lost-time injuries', fmtNum(r['lostTimeInjuries'])),
        InfoRow('Recordable injuries', fmtNum(r['recordableInjuries'])),
        InfoRow('Fatalities', fmtNum(r['fatalities'])),
        InfoRow('Days lost', fmtNum(r['daysLost'])),
        if ((integer(r['employersWithEstimatedHours']) ?? 0) > 0)
          Text('${r['employersWithEstimatedHours']} companies have no reported hours; their hours are estimated from headcount.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
      ]),
      if (sectors.isNotEmpty) ...[
        const SizedBox(height: 10),
        Section(title: 'By sector', children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 36,
              columns: const [
                DataColumn(label: Text('Sector')),
                DataColumn(label: Text('Hours'), numeric: true),
                DataColumn(label: Text('LTI'), numeric: true),
                DataColumn(label: Text('LTIFR'), numeric: true),
                DataColumn(label: Text('TRIFR'), numeric: true),
              ],
              rows: [
                for (final s in sectors)
                  DataRow(cells: [
                    DataCell(Text(text(s['sector']))),
                    DataCell(Text(fmtNum(s['hoursWorked']))),
                    DataCell(Text(fmtNum(s['lostTimeInjuries']))),
                    DataCell(Text(fmtNum(s['ltifr']))),
                    DataCell(Text(fmtNum(s['trifr']))),
                  ]),
              ],
            ),
          ),
        ]),
      ],
      const SizedBox(height: 24),
    ]);
  }
}

class _RiskMap extends StatelessWidget {
  const _RiskMap(this.d);

  final Map<String, Json> d;

  @override
  Widget build(BuildContext context) {
    final districts = items(d['districts']?['districts'])..sort((a, b) => (integer(b['incidents']) ?? 0).compareTo(integer(a['incidents']) ?? 0));
    final sectors = items(d['sectors']?['sectors']);
    final top = items(d['top']?['employers']);
    final maxIncidents = districts.fold<int>(1, (m, x) => (integer(x['incidents']) ?? 0) > m ? integer(x['incidents'])! : m);
    return ListView(padding: const EdgeInsets.all(12), children: [
      Section(title: 'Districts', children: [
        if (districts.isEmpty) const Text('No data.'),
        for (final x in districts)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Heat: more incidents and high-risk companies → warmer colour.
              color: Color.lerp(OhsColors.greenTint, const Color(0x59FB7185), (integer(x['incidents']) ?? 0) / maxIncidents),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(child: Text(text(x['name'], 'Unknown'), style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${fmtNum(x['employers'])} cos · ${fmtNum(x['incidents'])} inc · ${fmtNum(x['highRisk'])} high risk · ${fmtNum(x['compliance'])}%',
                  style: const TextStyle(fontFamily: mono, fontSize: 11, color: OhsColors.text2)),
            ]),
          ),
      ]),
      const SizedBox(height: 10),
      Section(title: 'Sector compliance', children: [
        BarBreakdown(items: [for (final s in sectors) (label: text(s['name']), value: number(s['compliance']) ?? 0)]),
        const SizedBox(height: 6),
        for (final s in sectors) InfoRow(text(s['name']), '${fmtNum(s['totalEmployers'])} companies · ${fmtNum(s['incidents'])} incidents'),
      ]),
      const SizedBox(height: 10),
      Section(title: 'Highest-risk companies', children: [
        for (final c in top)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(text(c['name'])),
            subtitle: Text('${text(c['sector'])} · ${text(c['district'])} · ${fmtNum(c['incidents'])} incidents · ${fmtNum(c['compliance'])}% compliance'),
            trailing: Tag(text(c['riskLevel'])),
            onTap: () => context.push(CompanyDetailScreen(id: text(c['id']))),
          ),
      ]),
      const SizedBox(height: 24),
    ]);
  }
}
