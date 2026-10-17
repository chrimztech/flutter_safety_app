import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import '../auth/change_password_screen.dart';
import '../auth/server_settings_screen.dart';
import '../../ui/theme.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return Scaffold(
      appBar: AppBar(title: const Text('My account')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 28, child: Text(me.initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(me.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(me.email),
                  const SizedBox(height: 4),
                  Text([me.roleLabel, me.employerName ?? me.tenantName].whereType<String>().join(' · '),
                      style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        if (!me.isEmployer) const _ProfileStats(),
        const SizedBox(height: 10),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change password'),
              subtitle: const Text('Signs out your other devices'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(const ChangePasswordScreen()),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Signed-in devices'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(const SessionsScreen()),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('Server address'),
              subtitle: Text(context.session.serverUrl),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(const ServerSettingsScreen()),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            if (await confirm(context, 'Sign out', 'Sign out of OHS Mobile on this device?', action: 'Sign out')) {
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                await context.session.signOut();
              }
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 20),
        Center(child: Text('OHS Mobile 1.0 · Occupational Health and Safety', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12))),
      ]),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: context.api.profile(),
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) return const SizedBox.shrink();
        return Section(title: 'My work', children: [
          InfoRow('Staff ID', p.employeeId),
          InfoRow('Department', p.department),
          InfoRow('Inspections done', fmtNum(p.stats['inspectionsCompleted'])),
          InfoRow('Average score', p.stats['averageComplianceScore'] == null ? null : '${fmtNum(p.stats['averageComplianceScore'])}%'),
          InfoRow('Notices issued', fmtNum(p.stats['enforcementIssued'])),
          InfoRow('Pending cases', fmtNum(p.stats['pendingCases'])),
          InfoRow('Last sign-in', fmtDateTime(p.lastLogin)),
        ]);
      },
    );
  }
}

/// The account's sessions (devices), with the ability to sign any other one out.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _loader = GlobalKey<LoaderState<({List<UserSession> sessions, Map<String, dynamic> policy})>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signed-in devices')),
      body: Loader<({List<UserSession> sessions, Map<String, dynamic> policy})>(
        key: _loader,
        load: context.api.sessions,
        builder: (context, d, reload) {
          final active = d.sessions.where((s) => s.active).toList();
          final others = active.where((s) => !s.current).length;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text('For your security you are signed out after ${d.policy['idleMinutes'] ?? 30} minutes without activity, '
                  'and every session ends after ${d.policy['absoluteHours'] ?? 12} hours.',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 10),
              if (others > 0)
                FilledButton.tonalIcon(
                  onPressed: () async {
                    if (!await confirm(context, 'Sign out other devices', 'End $others other session${others == 1 ? '' : 's'}?', action: 'Sign them out')) return;
                    if (!context.mounted) return;
                    final ok = await runAction(context, context.api.endOtherSessions, success: 'Other devices signed out');
                    if (ok) await reload();
                  },
                  icon: const Icon(Icons.logout),
                  label: Text('Sign out $others other device${others == 1 ? '' : 's'}'),
                ),
              const SizedBox(height: 10),
              for (final s in d.sessions)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(s.device.toLowerCase().contains('android') || s.device.toLowerCase().contains('iphone') || s.device.toLowerCase().contains('dart')
                        ? Icons.phone_android
                        : Icons.computer),
                    title: Text(s.device),
                    subtitle: Text(s.active
                        ? 'Active ${ago(s.lastSeenAt)} · signed in ${fmtDateTime(s.createdAt)}${s.ipAddress == null ? '' : '\n${s.ipAddress}'}'
                        : 'Ended ${humanize(s.endReason)} · signed in ${fmtDateTime(s.createdAt)}'),
                    isThreeLine: s.active && s.ipAddress != null,
                    trailing: s.current
                        ? const Tag(null, label: 'This device', color: OhsColors.green)
                        : s.active
                            ? TextButton(
                                onPressed: () async {
                                  final ok = await runAction(context, () => context.api.endSession(s.id), success: 'Signed out');
                                  if (ok) await reload();
                                },
                                child: const Text('Sign out'),
                              )
                            : null,
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}
