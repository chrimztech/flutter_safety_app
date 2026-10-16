import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';

/// The tamper-evident audit trail: filter by category and text, open an entry, verify the hash chain.
/// [basePath] is `audit-logs` for an agency or `platform/audit` for the platform console.
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key, this.basePath = 'audit-logs', this.title = 'Audit log', this.extraQuery = const {}});

  final String basePath;
  final String title;
  final Map<String, dynamic> extraQuery;

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  static const _categories = {'security': 'Security', 'logins': 'Sign-ins', 'failures': 'Failures', 'deletions': 'Deletions'};
  final List<Json> _rows = [];
  String? _category;
  String _q = '';
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _rows.clear();
      }
    });
    try {
      final body = obj(await context.api.client.get(widget.basePath, query: {
        ...widget.extraQuery,
        'page': _page,
        'size': 30,
        if (_category != null) 'category': _category,
        if (_q.isNotEmpty) 'q': _q,
      }));
      setState(() {
        _rows.addAll(items(body));
        _total = integer(body?['total']) ?? _rows.length;
        _page++;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    Json? r;
    final ok = await runAction(context, () async => r = obj(await context.api.client.get('${widget.basePath}/verify', query: widget.extraQuery)));
    if (!ok || r == null || !mounted) return;
    final verified = text(r!['status']) == 'VERIFIED';
    final issues = items(r!['issues']);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(verified ? Icons.verified : Icons.gpp_bad, color: verified ? Colors.green : Colors.red, size: 40),
        title: Text(verified ? 'Audit trail intact' : 'Integrity problems found'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r!['checkedEntries'] ?? 0} entries checked.'),
          for (final i in issues.take(8)) Text('• ${humanize(text(i['type']))} at #${i['seq'] ?? '?'}: ${text(i['detail'] ?? i['message'])}'),
          if (issues.length > 8) Text('…and ${issues.length - 8} more'),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(tooltip: 'Verify integrity', icon: const Icon(Icons.verified_user_outlined), onPressed: _verify),
      ]),
      body: Column(children: [
        SearchBox(
          hint: 'Search user, action, record',
          onChanged: (v) {
            _q = v.trim();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _q == v.trim()) _load(reset: true);
            });
          },
        ),
        FilterChips(
          values: _categories.keys.toList(),
          labels: _categories,
          selected: _category,
          onSelected: (c) {
            setState(() => _category = c);
            _load(reset: true);
          },
        ),
        Expanded(
          child: _error != null && _rows.isEmpty
              ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
              : RefreshIndicator(
                  onRefresh: () => _load(reset: true),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.extentAfter < 300 && _rows.length < _total) _load();
                      return false;
                    },
                    child: ListView.separated(
                      itemCount: _rows.length + 1,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i == _rows.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: _loading ? const CircularProgressIndicator() : Text('${_rows.length} of $_total entries', style: const TextStyle(fontSize: 12)),
                            ),
                          );
                        }
                        final e = _rows[i];
                        final ok = e['success'] != false && (integer(e['statusCode']) ?? 200) < 400;
                        return ListTile(
                          dense: true,
                          leading: Icon(ok ? Icons.check_circle_outline : Icons.error_outline, color: ok ? Colors.green : Colors.red, size: 20),
                          title: Text(text(e['description'], text(e['action'])), maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${text(e['actorEmail'], 'system')} · ${fmtDateTime(date(e['timestamp']))}'),
                          onTap: () => _detail(text(e['id'])),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ]),
    );
  }

  Future<void> _detail(String id) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (ctx, scroll) => FutureBuilder<Json>(
          future: context.api.one('${widget.basePath}/$id'),
          builder: (ctx, snap) {
            if (!snap.hasData) return Center(child: snap.hasError ? Text(snap.error.toString()) : const CircularProgressIndicator());
            final e = snap.data!;
            return ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
              Text(text(e['description'], text(e['action'])), style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 10),
              InfoRow('When', fmtDateTime(date(e['timestamp']))),
              InfoRow('Who', [str(e['actorEmail']), str(e['actorRole'])].whereType<String>().join(' · ')),
              InfoRow('Action', str(e['action'])),
              InfoRow('Module', str(e['module'])),
              InfoRow('Record', [str(e['entityType']), str(e['entityId'])].whereType<String>().join(' ')),
              InfoRow('Request', [str(e['httpMethod']), str(e['requestPath'])].whereType<String>().join(' ')),
              InfoRow('Result', e['statusCode'] == null ? null : '${e['statusCode']}${e['durationMs'] == null ? '' : ' · ${e['durationMs']} ms'}'),
              InfoRow('IP address', str(e['ipAddress'])),
              InfoRow('Sequence', str(e['seq'])),
              InfoRow('Hash valid', e['hashValid'] == null ? null : (e['hashValid'] == true ? 'Yes' : 'NO — entry altered')),
              TextBlock('Error', str(e['errorMessage'])),
              TextBlock('Submitted data (secrets hidden)', str(e['payload'] ?? e['newValues'])),
              TextBlock('Device', str(e['userAgent'])),
            ]);
          },
        ),
      ),
    );
  }
}
