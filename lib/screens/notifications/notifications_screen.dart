import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import '../actions/actions_screen.dart';
import '../complaints/complaints_screen.dart';
import '../enforcement/enforcement_screen.dart';
import '../incidents/incident_detail_screen.dart';
import '../inspections/inspection_detail_screen.dart';
import '../iot/alert_detail_screen.dart';
import '../reports/report_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _loader = GlobalKey<LoaderState<List<AppNotification>>>();

  /// Opens the record a notification is about, from its entity type or link.
  Widget? _target(AppNotification n) {
    final id = n.entityId ?? n.actionUrl?.split('/').last;
    if (id == null || id.isEmpty) return null;
    final kind = (n.entityType ?? n.actionUrl?.split('/').where((p) => p.isNotEmpty).firstOrNull ?? '').toUpperCase();
    final me = context.me;
    return switch (kind) {
      'INCIDENT' || 'INCIDENTS' => IncidentDetailScreen(id: id),
      'INSPECTION' || 'INSPECTIONS' => InspectionDetailScreen(id: id),
      'COMPLAINT' || 'COMPLAINTS' => me.isEmployer ? null : ComplaintDetailScreen(id: id),
      'ENFORCEMENT' => EnforcementDetailScreen(id: id),
      'CORRECTIVE_ACTION' || 'CORRECTIVEACTION' || 'CORRECTIVE-ACTIONS' => ActionDetailScreen(id: id),
      'HAZARD_EVENT' || 'HAZARDEVENT' || 'IOT' => AlertDetailScreen(id: id),
      'REPORT' || 'REPORTS' => me.isEmployer ? null : ReportScreen(id: id),
      _ => null,
    };
  }

  Future<void> _open(AppNotification n) async {
    if (!n.read) {
      try {
        await context.api.markNotificationRead(n.id);
      } catch (_) {}
    }
    if (!mounted) return;
    final screen = _target(n);
    if (screen != null) await context.push(screen);
    await _loader.currentState?.reload();
    if (mounted) await context.session.refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final ok = await runAction(context, context.api.markAllNotificationsRead, success: 'All marked as read');
              if (ok) {
                await _loader.currentState?.reload();
                if (context.mounted) await context.session.refreshUnread();
              }
            },
          ),
        ],
      ),
      body: Loader<List<AppNotification>>(
        key: _loader,
        load: () async {
          final list = await context.api.notifications();
          list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        },
        empty: const EmptyView(icon: Icons.notifications_none, title: 'No notifications', message: 'Alerts about your work appear here.'),
        builder: (context, list, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = list[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  try {
                    await context.api.deleteNotification(n.id);
                  } catch (e) {
                    if (context.mounted) showMessage(context, e.toString(), error: true);
                  }
                  if (context.mounted) await context.session.refreshUnread();
                },
                child: ListTile(
                  tileColor: n.read ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                  leading: Icon(_icon(n.type), color: toneOf(n.type == 'ALERT' ? 'CRITICAL' : n.type == 'WARNING' ? 'HIGH' : 'REPORTED')),
                  title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w700)),
                  subtitle: Text('${n.message}\n${ago(n.createdAt)}', maxLines: 3, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                  onTap: () => _open(n),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static IconData _icon(String type) => switch (type) {
        'ALERT' => Icons.warning_amber_rounded,
        'WARNING' => Icons.report_gmailerrorred,
        'SUCCESS' => Icons.check_circle_outline,
        'ERROR' => Icons.error_outline,
        _ => Icons.info_outline,
      };
}
