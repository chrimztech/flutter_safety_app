import 'package:flutter/material.dart';

import '../../app/config.dart';
import '../../app/context_ext.dart';
import '../../ui/widgets.dart';

/// The address of the agency's OHS server. Checked with the server's health endpoint before saving.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final _url = TextEditingController(text: context.session.serverUrl);
  String? _status;
  bool _ok = false;
  bool _busy = false;

  Future<void> _test({bool save = false}) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final session = context.session;
    final previous = session.serverUrl;
    await session.setServerUrl(_url.text);
    try {
      await session.api.client.get('auth/health', auth: false);
      setState(() {
        _ok = true;
        _status = 'Connected to ${session.api.client.baseUrl}';
      });
      if (save && mounted) {
        showMessage(context, 'Server address saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (!save) await session.setServerUrl(previous);
      setState(() {
        _ok = false;
        _status = e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server address')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('The address of your agency\'s OHS platform, for example https://ohs.agency.gov.zm. '
            'On the Android emulator, the computer running the server is 10.0.2.2.'),
        const SizedBox(height: 16),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Server URL', prefixIcon: Icon(Icons.dns_outlined)),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ActionChip(label: Text('Default (${ServerConfig.defaultUrl})'), onPressed: () => _url.text = ServerConfig.defaultUrl),
        ]),
        if (_status != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Icon(_ok ? Icons.check_circle : Icons.error, color: _ok ? Colors.green : Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(_status!)),
          ]),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _test(), child: const Text('Test connection'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(onPressed: _busy ? null : () => _test(save: true), child: const Text('Save'))),
        ]),
      ]),
    );
  }
}
