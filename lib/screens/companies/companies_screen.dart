import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/context_ext.dart';
import '../../data/company_profile.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../common/notification_bell.dart';
import 'company_tools.dart';

/// The agency's register of companies (workplaces).
class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final _list = GlobalKey<RecordListState<Company>>();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: const Text('Companies'), actions: const [NotificationBell()]),
      floatingActionButton: me.isStaff && me.can('employers:write')
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await registerCompany(context)) await _list.currentState?.reload();
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Register company'),
            )
          : null,
      body: RecordList<Company>(
        key: _list,
        load: () async {
          final list = await context.api.companies();
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        },
        searchHint: 'Search name, registration number, district',
        searchText: (c) => '${c.name} ${c.registrationNumber ?? ''} ${c.district ?? ''} ${c.sector ?? ''}',
        filterValues: const ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'],
        filterOf: (c) => c.riskLevel,
        filterLabels: const {'CRITICAL': 'Critical risk', 'HIGH': 'High risk', 'MEDIUM': 'Medium risk', 'LOW': 'Low risk'},
        emptyIcon: Icons.factory_outlined,
        emptyTitle: 'No companies registered',
        tile: (context, c, reload) => ListTile(
          leading: CircleAvatar(
            backgroundColor: toneOf(c.riskLevel).withValues(alpha: 0.15),
            child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase(), style: TextStyle(color: toneOf(c.riskLevel), fontWeight: FontWeight.w800)),
          ),
          title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text([c.sector, c.district, c.registrationNumber].whereType<String>().join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Tag(c.riskLevel, label: '${humanize(c.riskLevel)} risk'),
          onTap: () async {
            await context.push(CompanyDetailScreen(id: c.id));
            await reload();
          },
        ),
      ),
    );
  }
}

/// A company's profile. With [mine] it is the signed-in company user's own company.
class CompanyDetailScreen extends StatelessWidget {
  const CompanyDetailScreen({super.key, this.id, this.mine = false});

  final String? id;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final body = Loader<Company>(
      load: () => mine ? context.api.myCompany() : context.api.company(id!),
      builder: (context, c, reload) => RefreshIndicator(
        onRefresh: reload,
        child: CompanyProfileView(
          company: c,
          actions: _actions(context, c, reload),
        ),
      ),
    );
    if (mine) return body;
    return Scaffold(appBar: AppBar(title: const Text('Company')), body: body);
  }

  List<Widget> _actions(BuildContext context, Company c, Future<void> Function() reload) {
    final me = context.me;
    final canEdit = mine || (me.isStaff && me.can('employers:write'));
    return [
      if (canEdit)
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: Text(mine ? 'Update our profile' : 'Edit company'),
          onPressed: () async {
            if (await editCompany(context, c.raw, mine: mine)) await reload();
          },
        ),
      OutlinedButton.icon(
        icon: const Icon(Icons.location_city),
        label: const Text('Sites / workplaces'),
        onPressed: () => context.push(SitesScreen(employerId: c.id, canEdit: canEdit)),
      ),
      if (!mine && me.isAdmin)
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Delete company'),
          onPressed: () async {
            if (await deleteCompany(context, c.raw) && context.mounted) Navigator.pop(context);
          },
        ),
    ];
  }
}

class CompanyProfileView extends StatelessWidget {
  const CompanyProfileView({super.key, required this.company, this.actions = const []});

  final Company company;
  final List<Widget> actions;

  static String? _show(FieldSpec f, Object? v) {
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    switch (f.kind) {
      case FieldKind.boolean:
        return flag(v) ? 'Yes' : 'No';
      case FieldKind.date:
        return fmtDate(date(v));
      case FieldKind.choice:
        return f.labelFor(v);
      case FieldKind.multiChoice:
        return v.toString().split(',').map((x) => f.labelFor(x.trim()).split(' (').first).join(', ');
      default:
        return v is num ? fmtNum(v) : v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = company;
    final complete = c.profileCompleteness;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text(c.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, children: [Tag(c.riskLevel, label: '${humanize(c.riskLevel)} risk'), Tag(c.status)]),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
        children: [
          StatTile(label: 'Compliance', value: c.complianceScore == null ? '—' : '${fmtNum(c.complianceScore)}%', icon: Icons.verified_outlined),
          StatTile(label: 'Inspections', value: fmtNum(c.inspectionsCount ?? 0), icon: Icons.fact_check_outlined),
          StatTile(label: 'Incidents', value: fmtNum(c.incidentsCount ?? 0), icon: Icons.report_problem_outlined),
        ],
      ),
      if (complete != null) ...[
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Profile $complete% complete', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: complete / 100, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            ]),
          ),
        ),
      ],
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 4, children: actions),
      ],
      const SizedBox(height: 10),
      Section(title: 'Contacts', children: [
        _Contact(label: 'Company', value: c.phone, email: c.email),
        _Contact(label: 'Safety officer', name: c.safetyOfficerName, value: c.safetyOfficerPhone),
        _Contact(label: 'Emergency (24h)', name: c.emergencyContactName, value: c.emergencyContactPhone),
      ]),
      for (final s in companyProfileSections)
        if (s.fields.any((f) => _show(f, c.raw[f.key]) != null)) ...[
          const SizedBox(height: 10),
          Section(title: s.title, children: [
            for (final f in s.fields)
              if (f.kind == FieldKind.multiline || f.kind == FieldKind.multiChoice)
                TextBlock(f.label, _show(f, c.raw[f.key]))
              else
                InfoRow(f.label, _show(f, c.raw[f.key])),
          ]),
        ],
      const SizedBox(height: 24),
    ]);
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.label, this.name, this.value, this.email});

  final String label;
  final String? name;
  final String? value;
  final String? email;

  @override
  Widget build(BuildContext context) {
    if ((value ?? '').isEmpty && (email ?? '').isEmpty && (name ?? '').isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name ?? label),
      subtitle: Text([if (name != null) label, value, email].whereType<String>().where((s) => s.isNotEmpty).join(' · ')),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if ((value ?? '').isNotEmpty) IconButton(icon: const Icon(Icons.call), onPressed: () => launchUrl(Uri(scheme: 'tel', path: value))),
        if ((email ?? '').isNotEmpty) IconButton(icon: const Icon(Icons.mail_outline), onPressed: () => launchUrl(Uri(scheme: 'mailto', path: email))),
      ]),
    );
  }
}
