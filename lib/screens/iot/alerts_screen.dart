import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/record_list.dart';
import '../../ui/widgets.dart';
import '../common/notification_bell.dart';
import 'alert_detail_screen.dart';
import 'device_screens.dart';
import '../../ui/theme.dart';

/// IoT hazard monitoring: alerts raised from workplace sensors, and the devices themselves.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hazard alerts'),
          actions: [
            if (context.me.isStaff || context.me.isEmployer)
              IconButton(tooltip: 'Register IoT device', icon: const Icon(Icons.add_circle_outline), onPressed: () => registerDevice(context)),
            const NotificationBell(),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Alerts'), Tab(text: 'Devices')],
          ),
        ),
        body: const TabBarView(children: [_EventsTab(), _DevicesTab()]),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    return RecordList<HazardEvent>(
      load: () async {
        final list = await context.api.hazardEvents();
        const rank = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3};
        list.sort((a, b) {
          if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
          final r = (rank[a.severity] ?? 9).compareTo(rank[b.severity] ?? 9);
          return r != 0 ? r : (b.lastTriggeredAt ?? DateTime(0)).compareTo(a.lastTriggeredAt ?? DateTime(0));
        });
        return list;
      },
      initialFilter: 'OPEN',
      filterValues: const ['OPEN', 'ACKNOWLEDGED', 'RESOLVED', 'FALSE_ALARM'],
      filterOf: (e) => e.status,
      searchHint: 'Search device, zone, company',
      searchText: (e) => '${e.reference} ${e.deviceName} ${e.zone ?? ''} ${e.company?.name ?? ''} ${e.metric} ${e.message}',
      emptyIcon: Icons.sensors,
      emptyTitle: 'No hazard alerts',
      emptyMessage: 'Alerts appear here when workplace sensors detect a hazard.',
      tile: (context, e, reload) => ListTile(
        leading: CircleAvatar(
          backgroundColor: toneOf(e.severity).withValues(alpha: 0.15),
          child: Icon(_metricIcon(e.metric), color: toneOf(e.severity), size: 20),
        ),
        title: Text(e.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([
          e.deviceName,
          if (e.zone != null) e.zone!,
          if (!me.isEmployer && e.company != null) e.company!.name,
          ago(e.lastTriggeredAt ?? e.detectedAt),
        ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Tag(e.severity),
          const SizedBox(height: 4),
          Text(humanize(e.status), style: TextStyle(fontSize: 11, color: toneOf(e.status))),
        ]),
        onTap: () async {
          await context.push(AlertDetailScreen(id: e.id));
          await reload();
        },
      ),
    );
  }
}

class _DevicesTab extends StatelessWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context) {
    return RecordList<IotDevice>(
      load: context.api.devices,
      filterValues: const ['online', 'offline'],
      filterOf: (d) => d.online ? 'online' : 'offline',
      searchHint: 'Search device, zone, company',
      searchText: (d) => '${d.name} ${d.deviceType} ${d.zone ?? ''} ${d.company?.name ?? ''}',
      emptyIcon: Icons.sensors_off,
      emptyTitle: 'No devices',
      tile: (context, d, reload) => ListTile(
        leading: Icon(_deviceIcon(d.deviceType), color: d.online ? OhsColors.green : Theme.of(context).colorScheme.outline),
        title: Text(d.name),
        subtitle: Text([humanize(d.deviceType), d.zone, d.company?.name].whereType<String>().join(' · ')),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Tag(null, label: d.online ? 'Online' : 'Offline', color: d.online ? OhsColors.green : OhsColors.text3),
          const SizedBox(height: 4),
          Text(d.lastSeenAt == null ? 'never seen' : ago(d.lastSeenAt), style: const TextStyle(fontSize: 11)),
        ]),
        onTap: () async {
          await context.push(DeviceDetailScreen(id: d.id));
          await reload();
        },
      ),
    );
  }
}

IconData _metricIcon(String metric) {
  final m = metric.toLowerCase();
  if (m.contains('gas') || m.contains('co') || m.contains('h2s') || m.contains('o2')) return Icons.air;
  if (m.contains('temp') || m.contains('heat')) return Icons.thermostat;
  if (m.contains('noise') || m.contains('db')) return Icons.volume_up;
  if (m.contains('fall')) return Icons.personal_injury;
  if (m.contains('dust') || m.contains('pm')) return Icons.grain;
  if (m.contains('offline') || m.contains('heartbeat')) return Icons.signal_wifi_off;
  return Icons.sensors;
}

IconData _deviceIcon(String type) => switch (type.toUpperCase()) {
      'WEARABLE' => Icons.watch,
      'GAS_DETECTOR' => Icons.air,
      'NOISE_METER' => Icons.volume_up,
      'ENVIRONMENTAL' => Icons.thermostat,
      _ => Icons.sensors,
    };
