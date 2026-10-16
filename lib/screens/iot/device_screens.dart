import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';
import 'alert_detail_screen.dart';

const deviceTypes = [
  ('GAS_DETECTOR', 'Gas detector'), ('NOISE_METER', 'Noise monitor'), ('ENVIRONMENT', 'Environment / heat-stress station'),
  ('WEARABLE', 'Worker wearable'), ('VIBRATION', 'Machine vibration sensor'), ('FIRE_SMOKE', 'Smoke / fire detector'),
  ('PROXIMITY', 'Proximity warning system'), ('AI_CAMERA', 'AI camera (edge vision)'),
];

const _deviceFields = [
  FieldSpec('name', 'Name', FieldKind.text, required: true, hint: 'e.g. Shaft 3 gas monitor'),
  FieldSpec('deviceType', 'Device type', FieldKind.choice, required: true, initial: 'GAS_DETECTOR', options: deviceTypes),
  FieldSpec('employerId', 'Company', FieldKind.company, required: true),
  FieldSpec('zone', 'Zone', FieldKind.text, hint: 'e.g. Underground level 3'),
  FieldSpec('locationDescription', 'Location', FieldKind.text),
  FieldSpec('serialNumber', 'Serial number', FieldKind.text),
  FieldSpec('manufacturer', 'Manufacturer', FieldKind.text),
  FieldSpec('model', 'Model', FieldKind.text),
  FieldSpec('reportingIntervalSeconds', 'Reporting interval (seconds)', FieldKind.integer, initial: 60, min: 5),
  FieldSpec('latitude', 'GPS latitude', FieldKind.decimal),
  FieldSpec('longitude', 'GPS longitude', FieldKind.decimal),
];

/// Shows a new device key once (it is stored hashed on the server).
Future<void> _showKey(BuildContext context, Object? response) async {
  final r = obj(response) ?? const {};
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Device key'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text(r['note'], 'Store this key on the device now. It cannot be shown again.')),
        const SizedBox(height: 10),
        InfoRow('API key', str(r['apiKey']), copyable: true),
        InfoRow('Send readings to', str(r['ingestUrl']), copyable: true),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('I have stored it'))],
    ),
  );
}

Future<bool> registerDevice(BuildContext context) async {
  final api = context.api;
  Object? res;
  final done = await context.push<Object?>(FormScreen(
    title: 'Register IoT device',
    intro: 'The device sends readings with its own key; alerts are raised automatically by the detection rules.',
    sections: const [FieldSection('', '', '', _deviceFields)],
    submitLabel: 'Register',
    onSubmit: (p) async => res = await api.client.post('iot/devices', p),
  ));
  if (done == null || !context.mounted) return false;
  await _showKey(context, res);
  return true;
}

class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  final _loader = GlobalKey<LoaderState<Json>>();

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    final api = context.api;
    return Scaffold(
      appBar: AppBar(title: const Text('Device')),
      body: Loader<Json>(
        key: _loader,
        load: () => api.one('iot/devices/${widget.id}/detail'),
        builder: (context, d, reload) {
          final dev = obj(d['device']) ?? const {};
          final online = dev['online'] == true;
          final quality = obj(d['quality']) ?? const {};
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text(text(dev['name']), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                Tag(null, label: online ? 'Online' : 'Offline', color: online ? Colors.green : Colors.grey),
                Tag(text(dev['status'])),
              ]),
              const SizedBox(height: 10),
              Section(title: 'Device', children: [
                InfoRow('Type', deviceTypes.firstWhere((t) => t.$1 == dev['deviceType'], orElse: () => (text(dev['deviceType']), humanize(text(dev['deviceType'])))).$2),
                InfoRow('Company', nestedName(dev['employer'])),
                InfoRow('Zone', str(dev['zone'])),
                InfoRow('Location', str(dev['locationDescription'])),
                InfoRow('Serial', str(dev['serialNumber'])),
                InfoRow('Model', [str(dev['manufacturer']), str(dev['model'])].whereType<String>().join(' ')),
                InfoRow('Reports every', dev['reportingIntervalSeconds'] == null ? null : '${dev['reportingIntervalSeconds']} s'),
                InfoRow('Last seen', dev['lastSeenAt'] == null ? 'Never' : ago(date(dev['lastSeenAt']))),
                InfoRow('Key prefix', str(dev['apiKeyPrefix'])),
                InfoRow('Battery', quality['battery'] == null ? null : '${fmtNum(quality['battery'])}%'),
              ]),
              const SizedBox(height: 10),
              Section(title: 'Readings — last ${text(d['range'], '24h')}', children: [
                for (final m in items(d['metrics']))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(text(m['label'], text(m['metric']))),
                    subtitle: Text(m['count'] == 0
                        ? 'No readings'
                        : 'min ${fmtNum(m['min'])} · avg ${fmtNum(m['avg'])} · max ${fmtNum(m['max'])} ${text(m['unit'])} · ${m['count']} readings'
                            '${items(m['thresholds']).isEmpty ? '' : '\nLimits: ${items(m['thresholds']).map((t) => '${humanize(text(t['severity']))} ${text(t['operator']) == 'LT' || text(t['operator']) == 'LTE' ? '<' : '≥'} ${fmtNum(t['threshold'])}').join(', ')}'}'),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m['latest'] == null ? '—' : '${fmtNum(m['latest'])} ${text(m['unit'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Tag(text(m['band']) == 'NO_DATA' ? null : text(m['band']), label: humanize(text(m['band']))),
                    ]),
                  ),
              ]),
              if (items(d['openEvents'] ?? d['events']).isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Alerts', children: [
                  for (final e in items(d['events']).take(10))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.warning_amber_rounded, color: toneOf(text(e['severity']))),
                      title: Text(text(e['message']), maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${humanize(text(e['status']))} · ${ago(date(e['lastTriggeredAt'] ?? e['detectedAt']))}'),
                      onTap: () => context.push(AlertDetailScreen(id: text(e['id']))),
                    ),
                ]),
              ],
              if (items(d['rules']).isNotEmpty) ...[
                const SizedBox(height: 10),
                Section(title: 'Detection rules applied', children: [
                  for (final r in items(d['rules']))
                    InfoRow(text(r['name']),
                        '${text(r['metric'])} ${text(r['operator']) == 'LT' || text(r['operator']) == 'LTE' ? '<' : '≥'} ${fmtNum(r['threshold'])} → ${humanize(text(r['severity']))}${r['enabled'] == false ? ' (off)' : ''}'),
                ]),
              ],
              const SizedBox(height: 14),
              if (me.isStaff) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit device'),
                  onPressed: () async {
                    final saved = await context.push<Object?>(FormScreen(
                      title: 'Edit device',
                      sections: [
                        FieldSection('', '', '', [
                          ..._deviceFields,
                          const FieldSpec('status', 'Status', FieldKind.choice, options: [('ACTIVE', 'Active'), ('DISABLED', 'Disabled')]),
                        ]),
                      ],
                      initial: dev,
                      onlyChanged: true,
                      onSubmit: (p) => api.update('iot/devices/${widget.id}', p),
                    ));
                    if (saved != null) await reload();
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.key),
                  label: const Text('Issue a new device key'),
                  onPressed: () async {
                    if (!await confirm(context, 'New device key', 'The old key stops working immediately; the device must be updated with the new one.', action: 'Issue new key')) return;
                    if (!context.mounted) return;
                    Object? res;
                    if (await runAction(context, () async => res = await api.action('iot/devices/${widget.id}/rotate-key')) && context.mounted) {
                      await _showKey(context, res);
                      await reload();
                    }
                  },
                ),
              ],
              if (me.isAdmin)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete device and its readings'),
                  onPressed: () async {
                    if (!await confirm(context, 'Delete device', 'Delete ${text(dev['name'])} with all its readings and alerts?', action: 'Delete', destructive: true)) return;
                    if (!context.mounted) return;
                    if (await runAction(context, () => api.remove('iot/devices/${widget.id}'), success: 'Device deleted') && context.mounted) Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}
