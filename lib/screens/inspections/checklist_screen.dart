import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';

/// Conduct an inspection with a checklist: apply a template, mark each item Pass / Fail / N/A with notes, save.
/// The server recalculates the compliance score and violations, and can raise corrective actions for failed items.
class InspectionChecklistScreen extends StatefulWidget {
  const InspectionChecklistScreen({super.key, required this.inspectionId, required this.title, this.canEdit = false});

  final String inspectionId;
  final String title;
  final bool canEdit;

  @override
  State<InspectionChecklistScreen> createState() => _InspectionChecklistScreenState();
}

class _InspectionChecklistScreenState extends State<InspectionChecklistScreen> {
  List<Json>? _items;
  Object? _error;
  final Map<String, String> _results = {};
  final Map<String, TextEditingController> _notes = {};
  bool _dirty = false;

  String get _path => 'inspections/${widget.inspectionId}/checklist';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await context.api.list(_path);
      _adopt(list);
    } catch (e) {
      setState(() => _error = e);
    }
  }

  void _adopt(List<Json> list) {
    setState(() {
      _error = null;
      _items = list;
      _dirty = false;
      for (final i in list) {
        final id = text(i['id']);
        _results[id] = text(i['result'], 'PENDING');
        _notes.putIfAbsent(id, () => TextEditingController()).text = text(i['notes']);
      }
    });
  }

  Future<void> _applyTemplate() async {
    final templates = await context.api.list('checklists');
    if (!mounted) return;
    final active = templates.where((t) => t['active'] != false).toList();
    if (active.isEmpty) {
      showMessage(context, 'No checklist templates yet. An administrator can create them under Inspection checklists.', error: true);
      return;
    }
    final picked = await showModalBottomSheet<Json>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('Choose a checklist', style: TextStyle(fontWeight: FontWeight.w700))),
          for (final t in active)
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(text(t['name'])),
              subtitle: Text('${text(t['sector'], 'Any sector')} · ${(t['items'] as List?)?.length ?? 0} items'),
              onTap: () => Navigator.pop(ctx, t),
            ),
        ]),
      ),
    );
    if (picked == null || !mounted) return;
    if ((_items ?? const []).isNotEmpty &&
        !await confirm(context, 'Replace checklist', 'Replace the current checklist and its results with "${text(picked['name'])}"?', action: 'Replace')) {
      return;
    }
    if (!mounted) return;
    await runAction(context, () async {
      final list = items(await context.api.action(_path, {'templateId': picked['id']}));
      _adopt(list);
    }, success: 'Checklist applied');
  }

  Future<void> _save({bool createActions = false}) async {
    final results = [
      for (final i in _items ?? const <Json>[])
        {'id': text(i['id']), 'result': _results[text(i['id'])] ?? 'PENDING', 'notes': _notes[text(i['id'])]?.text.trim() ?? ''},
    ];
    Json? summary;
    final ok = await runAction(context, () async {
      summary = obj(await context.api.client.patch(_path, {'results': results, 'createActions': createActions}));
    });
    if (!ok || summary == null || !mounted) return;
    _adopt(items(summary!['items']));
    final s = summary!;
    showMessage(context, 'Saved · score ${fmtNum(s['complianceScore'] ?? 0)}% · ${s['violations']} violation(s)'
        '${(integer(s['actionsCreated']) ?? 0) > 0 ? ' · ${s['actionsCreated']} corrective action(s) raised' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final list = _items;
    final passed = _results.values.where((r) => r == 'PASS').length;
    final failed = _results.values.where((r) => r == 'FAIL').length;
    final pending = _results.values.where((r) => r == 'PENDING').length;
    final score = passed + failed == 0 ? null : (passed * 100 / (passed + failed));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection checklist'),
        actions: [
          if (widget.canEdit) IconButton(tooltip: 'Apply a checklist template', icon: const Icon(Icons.playlist_add), onPressed: _applyTemplate),
        ],
      ),
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : list == null
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? EmptyView(
                      icon: Icons.checklist,
                      title: 'No checklist on this inspection',
                      message: widget.canEdit ? 'Tap the + icon above to apply a checklist template.' : null,
                    )
                  : ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 120), children: [
                      Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                            _Count('Pass', passed, Colors.green),
                            _Count('Fail', failed, Colors.red),
                            _Count('Pending', pending, Colors.grey),
                            _Count('Score', score?.round(), Theme.of(context).colorScheme.primary, suffix: '%'),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final i in list) _item(i),
                    ]),
      bottomNavigationBar: widget.canEdit && (list?.isNotEmpty ?? false)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => _save(), child: Text(_dirty ? 'Save results' : 'Save'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: failed == 0 ? null : () => _save(createActions: true),
                      child: const Text('Save & raise actions', textAlign: TextAlign.center),
                    ),
                  ),
                ]),
              ),
            )
          : null,
    );
  }

  Widget _item(Json i) {
    final id = text(i['id']);
    final result = _results[id] ?? 'PENDING';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(text(i['text']), style: const TextStyle(fontWeight: FontWeight.w600))),
            if (i['mandatory'] == true) const Tag('HIGH', label: 'Mandatory'),
          ]),
          if (str(i['category']) != null) Text(text(i['category']), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'PASS', label: Text('Pass'), icon: Icon(Icons.check, size: 16)),
              ButtonSegment(value: 'FAIL', label: Text('Fail'), icon: Icon(Icons.close, size: 16)),
              ButtonSegment(value: 'NA', label: Text('N/A')),
            ],
            emptySelectionAllowed: true,
            selected: result == 'PENDING' ? <String>{} : {result},
            onSelectionChanged: widget.canEdit
                ? (s) => setState(() {
                      _results[id] = s.isEmpty ? 'PENDING' : s.first;
                      _dirty = true;
                    })
                : null,
          ),
          if (result == 'FAIL' || (_notes[id]?.text.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _notes[id],
              enabled: widget.canEdit,
              minLines: 1,
              maxLines: 4,
              onChanged: (_) => _dirty = true,
              decoration: const InputDecoration(labelText: 'What was found'),
            ),
          ],
          if (str(i['correctiveActionId']) != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Corrective action raised', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
            ),
        ]),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value, this.color, {this.suffix = ''});

  final String label;
  final int? value;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value == null ? '—' : '$value$suffix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}
