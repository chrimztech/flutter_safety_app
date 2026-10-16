import 'package:flutter/material.dart';

import '../data/fields.dart';
import '../data/json.dart';
import '../data/models.dart';
import '../screens/common/company_picker.dart';
import 'format.dart';
import 'widgets.dart';

/// Builds a form from [FieldSpec]s and returns the backend payload (keys exactly as declared).
///
/// Values for an existing record come from [initial] (the record's JSON); a company field reads `employer.id`.
class DynamicForm extends StatefulWidget {
  const DynamicForm({super.key, required this.sections, this.initial = const {}, this.onlyChanged = false});

  final List<FieldSection> sections;
  final Json initial;

  /// For edits: return only the fields whose value changed.
  final bool onlyChanged;

  @override
  State<DynamicForm> createState() => DynamicFormState();
}

class DynamicFormState extends State<DynamicForm> {
  final _form = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  final Map<String, dynamic> _start = {};
  final Map<String, TextEditingController> _text = {};
  final Map<String, String> _companyNames = {};

  Iterable<FieldSpec> get _fields => widget.sections.expand((s) => s.fields);

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      final v = _initialValue(f);
      _values[f.key] = v;
      _start[f.key] = v;
      if (_isText(f.kind)) _text[f.key] = TextEditingController(text: v?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Object? _initialValue(FieldSpec f) {
    final i = widget.initial;
    if (f.kind == FieldKind.company) {
      final e = obj(i['employer']);
      if (e != null && e['id'] != null) {
        _companyNames[e['id'].toString()] = text(e['name']);
        return e['id'].toString();
      }
      return i[f.key] ?? f.initial;
    }
    final raw = i.containsKey(f.key) ? i[f.key] : f.initial;
    if (raw == null) return null;
    switch (f.kind) {
      case FieldKind.date:
        final d = date(raw);
        return d == null ? null : DateTime(d.year, d.month, d.day);
      case FieldKind.dateTime:
        return date(raw);
      case FieldKind.boolean:
        return flag(raw);
      case FieldKind.choice:
        // Match the backend value case-insensitively to the option list.
        final s = raw.toString();
        for (final (v, _) in f.options ?? const <(String, String)>[]) {
          if (v.toLowerCase() == s.toLowerCase()) return v;
        }
        return s;
      case FieldKind.multiChoice:
        return raw is List ? raw.join(',') : raw.toString();
      case FieldKind.score:
        return number(raw) ?? 0;
      default:
        return raw is List ? raw.join(', ') : raw;
    }
  }

  static bool _isText(FieldKind k) => const {
        FieldKind.text,
        FieldKind.multiline,
        FieldKind.email,
        FieldKind.phone,
        FieldKind.url,
        FieldKind.integer,
        FieldKind.decimal,
      }.contains(k);

  /// Validates and returns the payload, or null when invalid.
  Map<String, dynamic>? submit() {
    if (!(_form.currentState?.validate() ?? false)) return null;
    for (final f in _fields.where((f) => f.required && !_isText(f.kind))) {
      final v = _values[f.key];
      if (v == null || (v is String && v.isEmpty)) {
        showMessage(context, '${f.label} is required', error: true);
        return null;
      }
    }
    final out = <String, dynamic>{};
    for (final f in _fields) {
      final v = _encode(f);
      if (widget.onlyChanged && _same(_encodeRaw(f, _start[f.key]), v)) continue;
      out[f.key] = v;
    }
    return out;
  }

  static bool _same(Object? a, Object? b) => (a ?? '').toString() == (b ?? '').toString();

  Object? _encode(FieldSpec f) {
    final v = _isText(f.kind) ? _text[f.key]!.text.trim() : _values[f.key];
    return _encodeRaw(f, v);
  }

  Object? _encodeRaw(FieldSpec f, Object? v) {
    switch (f.kind) {
      case FieldKind.integer:
        final s = v?.toString().trim() ?? '';
        return s.isEmpty ? null : int.tryParse(s);
      case FieldKind.decimal:
        final s = v?.toString().trim() ?? '';
        return s.isEmpty ? null : double.tryParse(s);
      case FieldKind.score:
        return (v as num?)?.round();
      case FieldKind.date:
        if (v is! DateTime) return v?.toString().isEmpty ?? true ? null : v;
        return '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
      case FieldKind.dateTime:
        return v is DateTime ? v.toIso8601String().split('.').first : v;
      case FieldKind.boolean:
        return v == true;
      default:
        final s = v?.toString() ?? '';
        return s.isEmpty ? (f.required ? s : null) : s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final s in widget.sections) ...[
          if (s.title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(s.title.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 0.8, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
            if (s.description.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2, bottom: 4), child: Text(s.description, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.outline))),
            const SizedBox(height: 6),
          ],
          for (final f in s.fields) Padding(padding: const EdgeInsets.only(bottom: 12), child: _field(f)),
        ],
      ]),
    );
  }

  String _label(FieldSpec f) => f.required ? '${f.label} *' : f.label;

  Widget _field(FieldSpec f) {
    switch (f.kind) {
      case FieldKind.choice:
        final options = [...?f.options];
        final v = _values[f.key] as String?;
        if (v != null && v.isNotEmpty && !options.any((o) => o.$1 == v)) options.insert(0, (v, humanize(v)));
        return DropdownButtonFormField<String>(
          initialValue: v == null || v.isEmpty ? null : v,
          isExpanded: true,
          decoration: InputDecoration(labelText: _label(f), helperText: f.help),
          items: [
            if (!f.required) const DropdownMenuItem(value: '', child: Text('—')),
            for (final (value, label) in options) DropdownMenuItem(value: value, child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (x) => setState(() => _values[f.key] = x),
        );
      case FieldKind.multiChoice:
        final selected = ((_values[f.key] as String?) ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
        return InputDecorator(
          decoration: InputDecoration(labelText: _label(f), helperText: f.help, border: InputBorder.none),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (value, label) in f.options ?? const <(String, String)>[])
              FilterChip(
                label: Text(label.split(' (').first),
                selected: selected.contains(value),
                onSelected: (on) => setState(() {
                  on ? selected.add(value) : selected.remove(value);
                  _values[f.key] = selected.join(',');
                }),
              ),
          ]),
        );
      case FieldKind.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          subtitle: f.help == null ? null : Text(f.help!),
          value: _values[f.key] == true,
          onChanged: (x) => setState(() => _values[f.key] = x),
        );
      case FieldKind.date:
      case FieldKind.dateTime:
        final d = _values[f.key] as DateTime?;
        return InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(context: context, initialDate: d ?? now, firstDate: DateTime(1950), lastDate: DateTime(now.year + 20));
            if (picked == null || !mounted) return;
            var value = picked;
            if (f.kind == FieldKind.dateTime) {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(d ?? now));
              value = DateTime(picked.year, picked.month, picked.day, t?.hour ?? 9, t?.minute ?? 0);
            }
            setState(() => _values[f.key] = value);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _label(f),
              helperText: f.help,
              suffixIcon: d == null
                  ? const Icon(Icons.event)
                  : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _values[f.key] = null)),
            ),
            child: Text(d == null ? (f.hint ?? 'Choose a date') : (f.kind == FieldKind.date ? fmtDate(d) : fmtDateTime(d))),
          ),
        );
      case FieldKind.company:
        final id = _values[f.key] as String?;
        return CompanyPicker(
          label: _label(f),
          value: id == null || id.isEmpty ? null : CompanyRef(id, _companyNames[id] ?? 'Selected company'),
          onChanged: (c) => setState(() {
            _values[f.key] = c?.id;
            if (c != null) _companyNames[c.id] = c.name;
          }),
        );
      case FieldKind.score:
        final v = ((_values[f.key] as num?) ?? 0).toDouble().clamp((f.min ?? 0).toDouble(), (f.max ?? 100).toDouble());
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${f.label}: ${v.round()}'),
          Slider(
            value: v,
            min: (f.min ?? 0).toDouble(),
            max: (f.max ?? 100).toDouble(),
            divisions: ((f.max ?? 100) - (f.min ?? 0)).toInt(),
            label: '${v.round()}',
            onChanged: (x) => setState(() => _values[f.key] = x),
          ),
        ]);
      default:
        return TextFormField(
          controller: _text[f.key],
          minLines: f.kind == FieldKind.multiline ? 3 : 1,
          maxLines: f.kind == FieldKind.multiline ? 8 : 1,
          keyboardType: switch (f.kind) {
            FieldKind.email => TextInputType.emailAddress,
            FieldKind.phone => TextInputType.phone,
            FieldKind.url => TextInputType.url,
            FieldKind.integer => TextInputType.number,
            FieldKind.decimal => const TextInputType.numberWithOptions(decimal: true, signed: true),
            FieldKind.multiline => TextInputType.multiline,
            _ => TextInputType.text,
          },
          decoration: InputDecoration(labelText: _label(f), hintText: f.hint, helperText: f.help, alignLabelWithHint: f.kind == FieldKind.multiline),
          validator: (raw) {
            final s = (raw ?? '').trim();
            if (f.required && s.isEmpty) return 'Required';
            if (s.isEmpty) return null;
            if (f.kind == FieldKind.email && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Enter a valid email';
            if (f.kind == FieldKind.integer) {
              final n = int.tryParse(s);
              if (n == null) return 'Whole number';
              if (f.min != null && n < f.min!) return 'At least ${f.min}';
              if (f.max != null && n > f.max!) return 'At most ${f.max}';
            }
            if (f.kind == FieldKind.decimal && double.tryParse(s) == null) return 'Number';
            return null;
          },
        );
    }
  }
}

/// A full-screen form: returns the backend's response (or true) when [onSubmit] succeeds.
class FormScreen extends StatefulWidget {
  const FormScreen({
    super.key,
    required this.title,
    required this.sections,
    required this.onSubmit,
    this.initial = const {},
    this.onlyChanged = false,
    this.submitLabel = 'Save',
    this.intro,
  });

  final String title;
  final List<FieldSection> sections;
  final Json initial;
  final bool onlyChanged;
  final String submitLabel;
  final String? intro;
  final Future<Object?> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _form = GlobalKey<DynamicFormState>();
  bool _busy = false;

  Future<void> _save() async {
    final payload = _form.currentState?.submit();
    if (payload == null) return;
    if (widget.onlyChanged && payload.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await widget.onSubmit(payload);
      if (mounted) Navigator.pop(context, result ?? true);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        if (widget.intro != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(widget.intro!)),
        DynamicForm(key: _form, sections: widget.sections, initial: widget.initial, onlyChanged: widget.onlyChanged),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _busy ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(_busy ? 'Saving...' : widget.submitLabel),
          ),
        ),
      ),
    );
  }
}
