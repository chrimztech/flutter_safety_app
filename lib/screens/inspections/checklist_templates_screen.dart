import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/widgets.dart';

/// Checklist templates used to conduct inspections. Officers and administrators maintain them.
class ChecklistTemplatesScreen extends StatefulWidget {
  const ChecklistTemplatesScreen({super.key});

  @override
  State<ChecklistTemplatesScreen> createState() => _ChecklistTemplatesScreenState();
}

class _ChecklistTemplatesScreenState extends State<ChecklistTemplatesScreen> {
  final _loader = GlobalKey<LoaderState<List<Json>>>();

  static const _fields = [
    FieldSpec('name', 'Name', FieldKind.text, required: true),
    FieldSpec('sector', 'Sector', FieldKind.text, hint: 'Leave empty for any sector'),
    FieldSpec('description', 'Description', FieldKind.multiline),
    FieldSpec('itemsText', 'Items', FieldKind.multiline, required: true,
        help: 'One item per line. Start a line with "?" for an optional (non-mandatory) item, and use "Category: item" to group.'),
  ];

  /// "Category: text" lines → items; a leading "?" marks an item optional.
  static List<Map<String, Object?>> _parse(String lines) => [
        for (final raw in lines.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty))
          () {
            final optional = raw.startsWith('?');
            final line = optional ? raw.substring(1).trim() : raw;
            final i = line.indexOf(':');
            return {
              'text': i > 0 && i < 40 ? line.substring(i + 1).trim() : line,
              'category': i > 0 && i < 40 ? line.substring(0, i).trim() : null,
              'mandatory': !optional,
            };
          }(),
      ];

  static String _unparse(Json t) => [
        for (final i in items(t['items']))
          '${i['mandatory'] == false ? '? ' : ''}${str(i['category']) == null ? '' : '${i['category']}: '}${text(i['text'])}',
      ].join('\n');

  Future<void> _edit([Json? template]) async {
    final api = context.api;
    final saved = await context.push<Object?>(FormScreen(
      title: template == null ? 'New checklist template' : 'Edit template',
      sections: const [FieldSection('', '', '', _fields)],
      initial: template == null ? const {} : {...template, 'itemsText': _unparse(template)},
      onSubmit: (p) {
        final body = {
          'name': p['name'],
          'sector': p['sector'] ?? '',
          'description': p['description'] ?? '',
          'items': _parse(text(p['itemsText'])),
        };
        return template == null ? api.create('checklists', body) : api.update('checklists/${template['id']}', body);
      },
    ));
    if (saved != null) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.me.isStaff && context.me.can('inspections:write');
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection checklists')),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('New template'))
          : null,
      body: Loader<List<Json>>(
        key: _loader,
        load: () => context.api.list('checklists'),
        empty: const EmptyView(icon: Icons.checklist, title: 'No checklist templates', message: 'Templates are applied to inspections to score them item by item.'),
        builder: (context, list, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
            for (final t in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Icon(Icons.checklist, color: t['active'] == false ? Colors.grey : Theme.of(context).colorScheme.primary),
                  title: Text(text(t['name'])),
                  subtitle: Text('${text(t['sector'], 'Any sector')} · ${items(t['items']).length} items${t['active'] == false ? ' · inactive' : ''}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (str(t['description']) != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text(t['description']))),
                    for (final i in items(t['items']))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${i['mandatory'] == false ? '○' : '●'} ${str(i['category']) == null ? '' : '[${i['category']}] '}${text(i['text'])}'),
                      ),
                    if (canEdit)
                      Wrap(spacing: 8, children: [
                        TextButton.icon(onPressed: () => _edit(t), icon: const Icon(Icons.edit, size: 18), label: const Text('Edit')),
                        TextButton(
                          onPressed: () async {
                            final ok = await runAction(context, () => context.api.update('checklists/${t['id']}', {'active': t['active'] == false}),
                                success: t['active'] == false ? 'Template activated' : 'Template deactivated');
                            if (ok) await reload();
                          },
                          child: Text(t['active'] == false ? 'Activate' : 'Deactivate'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                          onPressed: () async {
                            if (!await confirm(context, 'Delete template', 'Delete "${text(t['name'])}"? Inspections that already used it keep their results.',
                                action: 'Delete', destructive: true)) {
                              return;
                            }
                            if (!context.mounted) return;
                            final ok = await runAction(context, () => context.api.remove('checklists/${t['id']}'), success: 'Template deleted');
                            if (ok) await reload();
                          },
                          child: const Text('Delete'),
                        ),
                      ]),
                  ],
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
