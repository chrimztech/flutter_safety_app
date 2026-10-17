import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../../ui/theme.dart';

const _roles = [('OFFICER', 'OHS Officer'), ('ADMIN', 'Administrator'), ('EMPLOYER', 'Company user')];

String _name(Json u) => '${text(u['firstName'])} ${text(u['lastName'])}'.trim();
String _role(Json u) => text(obj(u['role'])?['name'] ?? u['role']).toUpperCase();

/// Shows the one-time password when email is not configured (otherwise it was emailed).
Future<void> showInvitation(BuildContext context, Object? response, String email, {bool reset = false}) async {
  final body = obj(response) ?? const {};
  final inv = obj(body['invitation']) ?? obj(obj(body['data'])?['invitation']) ?? body;
  final emailed = flag(inv['emailed']);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(reset ? 'Password reset' : 'Account created'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emailed
            ? 'A one-time password was emailed to $email. They choose their own password when they first sign in.'
            : 'Email is not configured, so give this one-time password to $email in person or by phone. '
                'They must change it when they first sign in.'),
        if (!emailed && str(inv['temporaryPassword']) != null) ...[
          const SizedBox(height: 12),
          InfoRow('One-time password', str(inv['temporaryPassword']), copyable: true),
          InfoRow('Valid until', fmtDateTime(date(inv['expiresAt']))),
          const Text('It is not shown again.', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
    ),
  );
}

/// User management (agency administrators): create accounts with one-time passwords, change roles,
/// deactivate / reactivate, reset passwords, sign out devices, delete.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _list = GlobalKey<RecordListState<Json>>();

  static const _createFields = [
    FieldSpec('firstName', 'First name', FieldKind.text, required: true),
    FieldSpec('lastName', 'Last name', FieldKind.text, required: true),
    FieldSpec('email', 'Email', FieldKind.email, required: true),
    FieldSpec('role', 'Role', FieldKind.choice, required: true, initial: 'OFFICER', options: _roles),
    FieldSpec('employerId', 'Company (company users only)', FieldKind.company),
    FieldSpec('phoneNumber', 'Phone', FieldKind.phone),
    FieldSpec('department', 'Department', FieldKind.text),
    FieldSpec('district', 'District', FieldKind.text),
  ];

  Future<void> _create() async {
    final api = context.api;
    String? email;
    final res = await context.push<Object?>(FormScreen(
      title: 'New user',
      intro: 'The person receives a one-time password and chooses their own password at first sign-in.',
      sections: const [FieldSection('', '', '', _createFields)],
      submitLabel: 'Create account',
      onSubmit: (p) async {
        if (p['role'] == 'EMPLOYER' && (p['employerId'] == null)) throw Exception('Choose the company for a company user');
        email = text(p['email']);
        return await api.client.post('users', p);
      },
    ));
    if (res != null && mounted) {
      await showInvitation(context, res, email ?? '');
      await _list.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User management')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.person_add), label: const Text('New user')),
      body: RecordList<Json>(
        key: _list,
        load: () async => (await context.api.list('users'))..sort((a, b) => _name(a).compareTo(_name(b))),
        searchHint: 'Search name or email',
        searchText: (u) => '${_name(u)} ${u['email']} ${nestedName(u['employer']) ?? ''}',
        filterValues: const ['ADMIN', 'OFFICER', 'EMPLOYER'],
        filterOf: _role,
        filterLabels: const {'ADMIN': 'Administrators', 'OFFICER': 'Officers', 'EMPLOYER': 'Company users'},
        emptyIcon: Icons.people_outline,
        emptyTitle: 'No users',
        tile: (context, u, reload) {
          final self = text(u['id']) == context.me.id;
          final active = u['isActive'] != false;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: active ? null : OhsColors.bg3,
              child: Text(_name(u).isEmpty ? '?' : _name(u)[0].toUpperCase()),
            ),
            title: Text('${_name(u)}${self ? ' (you)' : ''}'),
            subtitle: Text([text(u['email']), _roles.firstWhere((r) => r.$1 == _role(u), orElse: () => (_role(u), _role(u))).$2, nestedName(u['employer'])]
                .whereType<String>()
                .join(' · ')),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Tag(null, label: active ? 'Active' : 'Inactive', color: active ? OhsColors.green : OhsColors.text3),
              if (u['mustChangePassword'] == true) const Text('Awaiting first sign-in', style: TextStyle(fontSize: 10, color: OhsColors.amber)),
            ]),
            onTap: () async {
              await context.push(UserDetailScreen(user: u));
              await reload();
            },
          );
        },
      ),
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final Json user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Json _u = widget.user;

  String get _id => text(_u['id']);

  Future<void> _refresh() async {
    final fresh = await context.api.one('users/$_id');
    if (mounted) setState(() => _u = fresh);
  }

  Future<void> _act(Future<void> Function() fn, String done) async {
    if (await runAction(context, fn, success: done)) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.api;
    final self = _id == context.me.id;
    final active = _u['isActive'] != false;
    return Scaffold(
      appBar: AppBar(title: Text(_name(_u))),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Section(title: 'Account', children: [
          InfoRow('Email', text(_u['email']), copyable: true),
          InfoRow('Role', _roles.firstWhere((r) => r.$1 == _role(_u), orElse: () => (_role(_u), _role(_u))).$2),
          InfoRow('Company', nestedName(_u['employer'])),
          InfoRow('Phone', str(_u['phoneNumber'])),
          InfoRow('Department', str(_u['department'])),
          InfoRow('District', str(_u['district'])),
          InfoRow('Status', active ? 'Active' : 'Deactivated'),
          InfoRow('Locked until', _u['lockedUntil'] == null ? null : fmtDateTime(date(_u['lockedUntil']))),
          InfoRow('First sign-in', _u['mustChangePassword'] == true ? 'Not yet — must choose a password' : null),
          InfoRow('Last sign-in', fmtDateTime(date(_u['lastLoginAt']))),
          InfoRow('Created', fmtDate(date(_u['createdAt']))),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit details and role'),
          onPressed: () async {
            final saved = await context.push<Object?>(FormScreen(
              title: 'Edit user',
              sections: const [
                FieldSection('', '', '', [
                  FieldSpec('firstName', 'First name', FieldKind.text, required: true),
                  FieldSpec('lastName', 'Last name', FieldKind.text, required: true),
                  FieldSpec('email', 'Email', FieldKind.email, required: true),
                  FieldSpec('role', 'Role', FieldKind.choice, required: true, options: _roles),
                  FieldSpec('employerId', 'Company (company users only)', FieldKind.company),
                  FieldSpec('phoneNumber', 'Phone', FieldKind.phone),
                  FieldSpec('department', 'Department', FieldKind.text),
                  FieldSpec('district', 'District', FieldKind.text),
                ]),
              ],
              initial: {..._u, 'role': _role(_u)},
              onlyChanged: true,
              onSubmit: (p) => api.update('users/$_id', p),
            ));
            if (saved != null && context.mounted) {
              showMessage(context, 'User updated');
              await _refresh();
            }
          },
        ),
        if (!self) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.password),
            label: const Text('Reset password'),
            onPressed: () async {
              if (!await confirm(context, 'Reset password', 'Issue a new one-time password to ${_u['email']}? Their devices are signed out.', action: 'Reset')) return;
              if (!context.mounted) return;
              Object? res;
              if (await runAction(context, () async => res = await api.action('users/$_id/reset-password'))) {
                if (context.mounted) await showInvitation(context, res, text(_u['email']), reset: true);
              }
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign out on every device'),
            onPressed: () => _act(() => api.action('users/$_id/sessions/end'), 'Signed out everywhere'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(active ? Icons.block : Icons.check_circle_outline),
            label: Text(active ? 'Deactivate' : 'Reactivate'),
            onPressed: () async {
              if (active && !await confirm(context, 'Deactivate', '${_name(_u)} will be signed out and cannot sign in until reactivated.', action: 'Deactivate')) return;
              if (!context.mounted) return;
              await _act(() => api.client.patch('users/$_id/${active ? 'deactivate' : 'activate'}'), active ? 'Deactivated' : 'Reactivated');
            },
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete permanently'),
            onPressed: () async {
              if (!await confirm(context, 'Delete user',
                  'Permanently delete ${_u['email']}? They are signed out and their notifications deleted. Records they created stay; the audit log keeps their email. This cannot be undone.',
                  action: 'Delete', destructive: true)) {
                return;
              }
              if (!context.mounted) return;
              if (await runAction(context, () => api.remove('users/$_id'), success: 'User deleted') && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ]),
    );
  }
}
