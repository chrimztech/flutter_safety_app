import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/company_profile.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/widgets.dart';
import '../admin/users_screen.dart' show showInvitation;

/// Registers a company with the full profile (same fields as the web registration), optionally with a portal account.
Future<bool> registerCompany(BuildContext context) async {
  final api = context.api;
  Object? res;
  final done = await context.push<Object?>(FormScreen(
    title: 'Register company',
    intro: 'Fields marked * are required. Everything can be completed later by the company from its portal.',
    sections: [
      ...companyProfileSections,
      const FieldSection('portal', 'Company portal access', 'Optionally create an account for the company to report incidents and actions.', [
        FieldSpec('portalCreate', 'Create a company portal account', FieldKind.boolean),
        FieldSpec('portalFirstName', 'First name', FieldKind.text),
        FieldSpec('portalLastName', 'Last name', FieldKind.text),
        FieldSpec('portalEmail', 'Email', FieldKind.email),
        FieldSpec('portalPhone', 'Phone', FieldKind.phone),
      ]),
    ],
    submitLabel: 'Register company',
    onSubmit: (p) async {
      final portal = p['portalCreate'] == true;
      if (portal && [p['portalFirstName'], p['portalLastName'], p['portalEmail']].any((v) => v == null || v.toString().isEmpty)) {
        throw Exception('Portal access: enter first name, last name and email — or switch it off.');
      }
      final company = Map<String, dynamic>.from(p)..removeWhere((k, v) => k.startsWith('portal') || v == null);
      final male = integer(company['maleWorkers']) ?? 0, female = integer(company['femaleWorkers']) ?? 0;
      if (company['numberOfEmployees'] == null && male + female > 0) company['numberOfEmployees'] = male + female;
      res = await api.client.post('employers/register', {
        'company': company,
        'sites': const [],
        'portalUser': portal
            ? {'firstName': p['portalFirstName'], 'lastName': p['portalLastName'], 'email': p['portalEmail'], 'phoneNumber': p['portalPhone']}
            : null,
      });
      return res;
    },
  ));
  if (done == null || !context.mounted) return false;
  final portal = obj(obj(res)?['portalUser']);
  if (portal != null) await showInvitation(context, portal, text(portal['email']));
  if (context.mounted) showMessage(context, 'Company registered');
  return true;
}

/// Edits a company profile. With [mine] (company users) only the fields a company may update are shown.
Future<bool> editCompany(BuildContext context, Json company, {bool mine = false}) async {
  final api = context.api;
  final sections = [
    for (final s in companyProfileSections)
      if (!mine || s.fields.any((f) => f.employerEditable))
        FieldSection(s.id, s.title, s.description, mine ? s.fields.where((f) => f.employerEditable).toList() : s.fields),
  ];
  final saved = await context.push<Object?>(FormScreen(
    title: mine ? 'Update our company profile' : 'Edit company',
    intro: mine ? 'Registration details, licences and the risk classification are maintained by the inspectorate.' : null,
    sections: sections,
    initial: company,
    onlyChanged: true,
    onSubmit: (p) => mine ? api.update('employers/me', p) : api.update('employers/${company['id']}', p),
  ));
  if (saved != null && context.mounted) showMessage(context, 'Company profile saved');
  return saved != null;
}

/// Administrators: permanently delete a company and all its records (registration number confirms when it has history).
Future<bool> deleteCompany(BuildContext context, Json company) async {
  final api = context.api;
  final id = text(company['id']);
  Json impact = const {};
  try {
    impact = await api.one('employers/$id/delete-impact');
  } catch (_) {}
  if (!context.mounted) return false;
  final records = (obj(impact['records']) ?? obj(impact['impact']) ?? impact).entries.where((e) => (number(e.value) ?? 0) > 0).toList();
  String? code;
  if (records.isNotEmpty) {
    code = await askText(
      context,
      'Delete ${text(company['name'])}',
      hint: 'This permanently deletes the company and ${records.map((e) => '${e.value} ${e.key.toLowerCase()}').join(', ')}. '
          'Type its registration number (${text(company['registrationNumber'])}) to confirm.',
      required: true,
      action: 'Delete',
    );
    if (code == null) return false;
  } else if (!await confirm(context, 'Delete company', 'Permanently delete ${text(company['name'])}?', action: 'Delete', destructive: true)) {
    return false;
  }
  if (!context.mounted) return false;
  return runAction(context, () => api.client.delete('employers/$id${code == null ? '' : '?confirm=${Uri.encodeQueryComponent(code)}'}'),
      success: 'Company deleted');
}

const _siteFields = [
  FieldSpec('name', 'Site name', FieldKind.text, required: true),
  FieldSpec('siteType', 'Type', FieldKind.choice, options: companySiteTypes),
  FieldSpec('address', 'Address', FieldKind.text),
  FieldSpec('district', 'District', FieldKind.text),
  FieldSpec('province', 'Province', FieldKind.text),
  FieldSpec('workers', 'Workers on site', FieldKind.integer, min: 0),
  FieldSpec('siteManager', 'Site manager', FieldKind.text),
  FieldSpec('sitePhone', 'Site phone', FieldKind.phone),
  FieldSpec('activities', 'Activities', FieldKind.multiline),
  FieldSpec('hazards', 'Main hazards', FieldKind.multiline),
  FieldSpec('latitude', 'GPS latitude', FieldKind.decimal),
  FieldSpec('longitude', 'GPS longitude', FieldKind.decimal),
];

/// A company's workplaces (sites). Company users maintain their own; staff maintain any.
class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key, required this.employerId, required this.canEdit});

  final String employerId;
  final bool canEdit;

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  final _loader = GlobalKey<LoaderState<List<Json>>>();

  String get _base => 'employers/${widget.employerId}/sites';

  Future<void> _edit([Json? site]) async {
    final api = context.api;
    final saved = await context.push<Object?>(FormScreen(
      title: site == null ? 'Add site' : 'Edit site',
      sections: const [FieldSection('', '', '', _siteFields)],
      initial: site ?? const {},
      onSubmit: (p) => site == null ? api.create(_base, p) : api.update('$_base/${site['id']}', p),
    ));
    if (saved != null) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sites')),
      floatingActionButton:
          widget.canEdit ? FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add_location_alt), label: const Text('Add site')) : null,
      body: Loader<List<Json>>(
        key: _loader,
        load: () => context.api.list(_base),
        empty: const EmptyView(icon: Icons.location_city, title: 'No sites recorded', message: 'Add each workplace: factory, mine, branch, construction site...'),
        builder: (context, list, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
            for (final s in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(text(s['name'])),
                  subtitle: Text([
                    companySiteTypes.firstWhere((t) => t.$1 == s['siteType'], orElse: () => ('', '')).$2,
                    text(s['district']),
                    if (s['workers'] != null) '${s['workers']} workers',
                    text(s['siteManager']),
                  ].where((x) => x.isNotEmpty).join(' · ')),
                  trailing: widget.canEdit
                      ? PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') return _edit(s);
                            if (!await confirm(context, 'Remove site', 'Remove ${text(s['name'])}?', action: 'Remove', destructive: true)) return;
                            if (!context.mounted) return;
                            if (await runAction(context, () => context.api.remove('$_base/${s['id']}'), success: 'Site removed')) await reload();
                          },
                          itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Remove'))],
                        )
                      : null,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
