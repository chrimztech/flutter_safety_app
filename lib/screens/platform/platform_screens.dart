import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../account/account_screen.dart';
import '../admin/audit_screen.dart';
import '../admin/users_screen.dart' show showInvitation;
import '../common/notification_bell.dart';
import '../../ui/theme.dart';

/// Platform console for the super-admin: agencies, platform users, active sessions, audit, all companies.
class PlatformShell extends StatefulWidget {
  const PlatformShell({super.key});

  @override
  State<PlatformShell> createState() => _PlatformShellState();
}

class _PlatformShellState extends State<PlatformShell> {
  int _index = 0;

  static const _tabs = <(IconData, String, Widget)>[
    (Icons.account_balance_outlined, 'Agencies', AgenciesScreen()),
    (Icons.people_outline, 'Users', PlatformUsersScreen()),
    (Icons.devices_other, 'Sessions', PlatformSessionsScreen()),
    (Icons.receipt_long_outlined, 'Audit', AuditScreen(basePath: 'platform/audit', title: 'Platform audit log')),
    (Icons.menu, 'More', _PlatformMore()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [for (final t in _tabs) t.$3]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.$1), label: t.$2)],
      ),
    );
  }
}

class _PlatformMore extends StatelessWidget {
  const _PlatformMore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.factory_outlined),
          title: const Text('Companies — all agencies'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(const PlatformCompaniesScreen()),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('My account'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(const AccountScreen()),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- agencies

class AgenciesScreen extends StatefulWidget {
  const AgenciesScreen({super.key});

  @override
  State<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends State<AgenciesScreen> {
  final _list = GlobalKey<RecordListState<Json>>();

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: const Text('Agencies'), actions: const [NotificationBell()]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_business),
        label: const Text('Add agency'),
        onPressed: () async {
          String? email;
          final res = await context.push<Object?>(FormScreen(
            title: 'Add agency',
            intro: 'The first administrator receives a one-time password and sets up the agency.',
            sections: const [
              FieldSection('agency', 'Agency', '', [
                FieldSpec('name', 'Agency name', FieldKind.text, required: true),
                FieldSpec('code', 'Code', FieldKind.text, required: true, help: 'Short, lowercase — used in the public reporting link, e.g. zambia-ohs'),
                FieldSpec('country', 'Country', FieldKind.text, required: true),
                FieldSpec('region', 'Region', FieldKind.text),
                FieldSpec('contactEmail', 'Contact email', FieldKind.email),
                FieldSpec('contactPhone', 'Contact phone', FieldKind.phone),
              ]),
              FieldSection('admin', 'First administrator', '', [
                FieldSpec('adminFirstName', 'First name', FieldKind.text, required: true),
                FieldSpec('adminLastName', 'Last name', FieldKind.text, required: true),
                FieldSpec('adminEmail', 'Email', FieldKind.email, required: true),
              ]),
            ],
            submitLabel: 'Create agency',
            onSubmit: (p) async {
              email = text(p['adminEmail']);
              return await api.client.post('platform/tenants', p);
            },
          ));
          if (res != null && context.mounted) {
            await showInvitation(context, res, email ?? '');
            await _list.currentState?.reload();
          }
        },
      ),
      body: RecordList<Json>(
        key: _list,
        load: () async => (await api.list('platform/tenants'))
          ..sort((a, b) {
            // Applications waiting for approval first.
            final p = (text(a['status']) == 'PENDING' ? 0 : 1).compareTo(text(b['status']) == 'PENDING' ? 0 : 1);
            return p != 0 ? p : text(a['name']).compareTo(text(b['name']));
          }),
        searchHint: 'Search agencies',
        searchText: (t) => '${t['name']} ${t['code']} ${t['country']}',
        filterValues: const ['PENDING', 'ACTIVE', 'SUSPENDED'],
        filterOf: (t) => text(t['status']),
        emptyIcon: Icons.account_balance_outlined,
        emptyTitle: 'No agencies',
        tile: (context, t, reload) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.account_balance, size: 20)),
          title: Text(text(t['name'])),
          subtitle: Text('${text(t['code'])} · ${text(t['country'])} · ${fmtNum(t['users'])} users · ${fmtNum(t['employers'])} companies'),
          trailing: Tag(text(t['status']), color: toneOf(text(t['status']) == 'PENDING' ? 'HIGH' : text(t['status']) == 'SUSPENDED' ? 'CRITICAL' : 'LOW')),
          onTap: () async {
            await context.push(AgencyDetailScreen(agency: t));
            await reload();
          },
        ),
      ),
    );
  }
}

class AgencyDetailScreen extends StatelessWidget {
  const AgencyDetailScreen({super.key, required this.agency});

  final Json agency;

  @override
  Widget build(BuildContext context) {
    final t = agency;
    final id = text(t['id']);
    final status = text(t['status']);
    final api = context.api;

    Future<void> addUser(String role) async {
      String? email;
      final res = await context.push<Object?>(FormScreen(
        title: role == 'ADMIN' ? 'Add administrator' : 'Add officer',
        sections: const [
          FieldSection('', '', '', [
            FieldSpec('firstName', 'First name', FieldKind.text, required: true),
            FieldSpec('lastName', 'Last name', FieldKind.text, required: true),
            FieldSpec('email', 'Email', FieldKind.email, required: true),
          ]),
        ],
        submitLabel: 'Create account',
        onSubmit: (p) async {
          email = text(p['email']);
          return await api.client.post('platform/tenants/$id/users', {...p, 'role': role});
        },
      ));
      if (res != null && context.mounted) await showInvitation(context, res, email ?? '');
    }

    return Scaffold(
      appBar: AppBar(title: Text(text(t['name']))),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Section(title: 'Agency', trailing: Tag(status), children: [
          InfoRow('Code', str(t['code'])),
          InfoRow('Country', str(t['country'])),
          InfoRow('Region', str(t['region'])),
          InfoRow('Contact email', str(t['contactEmail'])),
          InfoRow('Contact phone', str(t['contactPhone'])),
          InfoRow('Administrators', (t['adminEmails'] as List?)?.join(', ')),
          InfoRow('Users', fmtNum(t['users'])),
          InfoRow('Companies', fmtNum(t['employers'])),
          InfoRow('Inspections', fmtNum(t['inspections'])),
          InfoRow('Incidents', fmtNum(t['incidents'])),
          InfoRow('Registered', fmtDate(date(t['createdAt']))),
          TextBlock('Application notes', str(t['registrationNotes'])),
        ]),
        const SizedBox(height: 12),
        if (status == 'PENDING') ...[
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Approve agency'),
            onPressed: () async {
              Object? res;
              if (await runAction(context, () async => res = await api.action('platform/tenants/$id/approve'), success: 'Agency approved') && context.mounted) {
                final body = obj(res) ?? const {};
                if (body['invitation'] != null) await showInvitation(context, res, text(body['adminEmail'] ?? body['email']));
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Reject application'),
            onPressed: () async {
              final reason = await askText(context, 'Reject application', hint: 'Reason (sent to the applicant)', required: true, action: 'Reject');
              if (reason == null || !context.mounted) return;
              if (await runAction(context, () => api.action('platform/tenants/$id/reject', {'reason': reason}), success: 'Application rejected') && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
        if (status == 'ACTIVE') ...[
          FilledButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Enter agency (support mode)'),
            onPressed: () {
              context.session.enterAgency(id, text(t['name']));
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Add administrator'), onPressed: () => addUser('ADMIN')),
          const SizedBox(height: 8),
          OutlinedButton.icon(icon: const Icon(Icons.badge_outlined), label: const Text('Add officer'), onPressed: () => addUser('OFFICER')),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit details'),
          onPressed: () async {
            final saved = await context.push<Object?>(FormScreen(
              title: 'Edit agency',
              sections: const [
                FieldSection('', '', '', [
                  FieldSpec('name', 'Agency name', FieldKind.text, required: true),
                  FieldSpec('country', 'Country', FieldKind.text),
                  FieldSpec('region', 'Region', FieldKind.text),
                  FieldSpec('contactEmail', 'Contact email', FieldKind.email),
                  FieldSpec('contactPhone', 'Contact phone', FieldKind.phone),
                ]),
              ],
              initial: t,
              onlyChanged: true,
              onSubmit: (p) => api.update('platform/tenants/$id', p),
            ));
            if (saved != null && context.mounted) Navigator.pop(context);
          },
        ),
        if (status != 'PENDING') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(status == 'SUSPENDED' ? Icons.play_arrow : Icons.pause),
            label: Text(status == 'SUSPENDED' ? 'Reactivate agency' : 'Suspend agency'),
            onPressed: () async {
              final suspend = status != 'SUSPENDED';
              if (suspend &&
                  !await confirm(context, 'Suspend agency',
                      'All its users are signed out and blocked, and its public reporting page closes. Data is kept.', action: 'Suspend', destructive: true)) {
                return;
              }
              if (!context.mounted) return;
              if (await runAction(context, () => api.update('platform/tenants/$id', {'status': suspend ? 'SUSPENDED' : 'ACTIVE'}),
                      success: suspend ? 'Agency suspended' : 'Agency reactivated') &&
                  context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Delete agency and all its data'),
          onPressed: () async {
            Json impact = const {};
            try {
              impact = await api.one('platform/tenants/$id/delete-impact');
            } catch (_) {}
            if (!context.mounted) return;
            final records = obj(impact['records']) ?? const {};
            final code = await askText(
              context,
              'Delete ${text(t['name'])}',
              hint: 'This permanently deletes the agency, its users and ${records.values.fold<num>(0, (a, b) => a + (number(b) ?? 0))} records. '
                  'Type the agency code (${text(t['code'])}) to confirm.',
              required: true,
              action: 'Delete',
            );
            if (code == null || !context.mounted) return;
            if (await runAction(context, () => api.client.delete('platform/tenants/$id?confirm=${Uri.encodeQueryComponent(code)}'), success: 'Agency deleted') &&
                context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- platform users

class PlatformUsersScreen extends StatelessWidget {
  const PlatformUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: const Text('Platform users')),
      body: RecordList<Json>(
        load: () async => (await api.list('platform/users'))..sort((a, b) => text(a['email']).compareTo(text(b['email']))),
        searchHint: 'Search name, email, agency',
        searchText: (u) => '${u['firstName']} ${u['lastName']} ${u['email']} ${u['agencyName'] ?? ''} ${u['employerName'] ?? ''}',
        filterValues: const ['SUPER_ADMIN', 'ADMIN', 'OFFICER', 'EMPLOYER'],
        filterOf: (u) => text(u['role']),
        emptyIcon: Icons.people_outline,
        emptyTitle: 'No users',
        tile: (context, u, reload) {
          final active = u['isActive'] != false;
          final superAdmin = text(u['role']) == 'SUPER_ADMIN';
          return ListTile(
            title: Text('${text(u['firstName'])} ${text(u['lastName'])}'.trim()),
            subtitle: Text([text(u['email']), humanize(text(u['role'])), str(u['agencyName']) ?? 'Platform', str(u['employerName'])].whereType<String>().join(' · ')),
            trailing: Tag(null, label: active ? 'Active' : 'Inactive', color: active ? OhsColors.green : OhsColors.text3),
            onTap: superAdmin
                ? null
                : () => showModalBottomSheet<void>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(title: Text(text(u['email']), style: const TextStyle(fontWeight: FontWeight.w700))),
                          ListTile(
                            leading: const Icon(Icons.password),
                            title: const Text('Reset password'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              Object? res;
                              if (await runAction(context, () async => res = await api.action('platform/users/${u['id']}/reset-password')) && context.mounted) {
                                await showInvitation(context, res, text(u['email']), reset: true);
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Sign out everywhere'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await runAction(context, () => api.action('platform/users/${u['id']}/sessions/end'), success: 'Signed out everywhere');
                            },
                          ),
                          ListTile(
                            leading: Icon(active ? Icons.block : Icons.check_circle_outline),
                            title: Text(active ? 'Deactivate' : 'Reactivate'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              if (await runAction(context, () => api.update('platform/users/${u['id']}', {'isActive': !active}),
                                  success: active ? 'Deactivated' : 'Reactivated')) {
                                await reload();
                              }
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
                            title: Text('Delete permanently', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              if (!await confirm(context, 'Delete user', 'Permanently delete ${u['email']}? This cannot be undone.', action: 'Delete', destructive: true)) {
                                return;
                              }
                              if (!context.mounted) return;
                              if (await runAction(context, () => api.remove('platform/users/${u['id']}'), success: 'User deleted')) await reload();
                            },
                          ),
                        ]),
                      ),
                    ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- sessions and companies

class PlatformSessionsScreen extends StatelessWidget {
  const PlatformSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: const Text('Active sessions')),
      body: RecordList<Json>(
        load: () => api.list('platform/sessions'),
        searchHint: 'Search user, device, IP',
        searchText: (s) => '${s['userEmail']} ${s['userName'] ?? ''} ${s['device'] ?? ''} ${s['ipAddress'] ?? ''}',
        emptyIcon: Icons.devices_other,
        emptyTitle: 'Nobody is signed in',
        tile: (context, s, reload) => ListTile(
          leading: const Icon(Icons.devices),
          title: Text(text(s['userName'], text(s['userEmail']))),
          subtitle: Text('${text(s['userEmail'])} · ${humanize(text(s['role']))}\n${text(s['device'], 'Unknown device')} · active ${ago(date(s['lastSeenAt']))}'),
          isThreeLine: true,
          trailing: TextButton(
            onPressed: () async {
              if (!await confirm(context, 'End session', 'Sign ${s['userEmail']} out on ${text(s['device'], 'this device')}?', action: 'End session')) return;
              if (!context.mounted) return;
              if (await runAction(context, () => api.action('platform/sessions/${s['id']}/end'), success: 'Session ended')) await reload();
            },
            child: const Text('End'),
          ),
        ),
      ),
    );
  }
}

class PlatformCompaniesScreen extends StatelessWidget {
  const PlatformCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companies — all agencies')),
      body: RecordList<Json>(
        load: () async => (await context.api.list('platform/employers'))..sort((a, b) => text(a['name']).compareTo(text(b['name']))),
        searchHint: 'Search company, agency, district',
        searchText: (c) => '${c['name']} ${c['registrationNumber']} ${c['agencyName']} ${c['district']} ${c['sector']}',
        filterValues: const ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'],
        filterOf: (c) => text(c['riskLevel']),
        emptyIcon: Icons.factory_outlined,
        emptyTitle: 'No companies',
        tile: (context, c, reload) => ListTile(
          title: Text(text(c['name'])),
          subtitle: Text([text(c['agencyName']), text(c['sector']), text(c['district']), '${fmtNum(c['numberOfEmployees'])} employees'].join(' · ')),
          trailing: Tag(text(c['riskLevel'])),
        ),
      ),
    );
  }
}
