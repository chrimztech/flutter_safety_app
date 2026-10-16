/// Declarative form fields, so every module's create/edit form is described by data (keys match the backend exactly).
library;

enum FieldKind { text, multiline, email, phone, url, integer, decimal, date, dateTime, choice, multiChoice, boolean, company, score }

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label,
    this.kind, {
    this.required = false,
    this.options,
    this.hint,
    this.help,
    this.initial,
    this.employerEditable = false,
    this.min,
    this.max,
  });

  /// Backend payload key.
  final String key;
  final String label;
  final FieldKind kind;
  final bool required;

  /// (value sent to the backend, label shown).
  final List<(String, String)>? options;
  final String? hint;
  final String? help;

  /// Value for a new record.
  final Object? initial;

  /// Whether a company user may change it from their portal.
  final bool employerEditable;
  final num? min;
  final num? max;

  String labelFor(Object? value) {
    if (value == null) return '';
    final v = value.toString();
    for (final (o, l) in options ?? const <(String, String)>[]) {
      if (o.toLowerCase() == v.toLowerCase()) return l;
    }
    return v;
  }
}

class FieldSection {
  const FieldSection(this.id, this.title, this.description, this.fields);

  final String id;
  final String title;
  final String description;
  final List<FieldSpec> fields;
}

/// Shorthand for option lists where the label is the humanised value.
List<(String, String)> opts(List<String> values) => [
      for (final v in values)
        (v, v.isEmpty ? v : (v.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase())))
    ];
