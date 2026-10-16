import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/widgets.dart';
import '../inspections/checklist_templates_screen.dart';
import 'audit_screen.dart';
import 'users_screen.dart';

/// System settings for agency administrators: agency profile, sign-in & session security, and admin shortcuts.
class AgencySettingsScreen extends StatefulWidget {
  const AgencySettingsScreen({super.key});

  @override
  State<AgencySettingsScreen> createState() => _AgencySettingsScreenState();
}

class _AgencySettingsScreenState extends State<AgencySettingsScreen> {
  final _loader = GlobalKey<LoaderState<(Json, Json)>>();

  static const _profileFields = [
    FieldSpec('name', 'Agency name', FieldKind.text, required: true),
    FieldSpec('country', 'Country', FieldKind.text),
    FieldSpec('region', 'Province / region', FieldKind.text),
    FieldSpec('contactEmail', 'Official contact email', FieldKind.email),
    FieldSpec('contactPhone', 'Phone', FieldKind.phone),
    FieldSpec('website', 'Website', FieldKind.url),
    FieldSpec('address', 'Physical address', FieldKind.text),
  ];

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: const Text('System settings')),
      body: Loader<(Json, Json)>(
        key: _loader,
        load: () async {
          final r = await Future.wait([api.one('agency/profile'), api.one('agency/security')]);
          return (r[0], r[1]);
        },
        builder: (context, d, reload) {
          final (profile, security) = d;
          final fields = items(security['fields']);
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Section(
                title: 'Agency profile',
                trailing: TextButton(
                  onPressed: () async {
                    final saved = await context.push<Object?>(FormScreen(
                      title: 'Agency profile',
                      sections: const [FieldSection('', '', '', _profileFields)],
                      initial: profile,
                      onlyChanged: true,
                      onSubmit: (p) => api.update('agency/profile', p),
                    ));
                    if (saved != null) await reload();
                  },
                  child: const Text('Edit'),
                ),
                children: [
                  for (final f in _profileFields) InfoRow(f.label, str(profile[f.key])),
                  InfoRow('Agency code', str(profile['code'])),
                  InfoRow('Public reporting', '/report/${text(profile['code'])}'),
                ],
              ),
              const SizedBox(height: 10),
              Section(
                title: 'Sign-in & session security',
                trailing: TextButton(
                  onPressed: () async {
                    final saved = await context.push<Object?>(FormScreen(
                      title: 'Sign-in & session security',
                      intro: 'Leave a value empty to use the platform default. Inactivity and lockout changes apply immediately; '
                          'a new maximum session length applies from each user\'s next sign-in.',
                      sections: [
                        FieldSection('', '', '', [
                          for (final f in fields)
                            FieldSpec(text(f['key']), text(f['label']), FieldKind.integer,
                                min: integer(f['min']), max: integer(f['max']), help: '${f['min']}–${f['max']}, default ${f['default']}'),
                        ]),
                      ],
                      initial: {for (final f in fields) text(f['key']): f['custom'] == true ? f['value'] : null},
                      onSubmit: (p) => api.update('agency/security', {for (final e in p.entries) e.key: e.value ?? ''}),
                    ));
                    if (saved != null) await reload();
                  },
                  child: const Text('Edit'),
                ),
                children: [
                  for (final f in fields)
                    InfoRow(text(f['label']), '${f['value']}${f['custom'] == true ? '  (default ${f['default']})' : '  (default)'}'),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('User management'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(const UsersScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Audit log'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(const AuditScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.checklist),
                    title: const Text('Inspection checklists'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(const ChecklistTemplatesScreen()),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}
