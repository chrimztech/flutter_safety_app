/// Tolerant readers for the backend's JSON (numbers may arrive as int or double, dates as ISO strings).
library;

typedef Json = Map<String, dynamic>;

String? str(Object? v) => v == null ? null : (v is String ? v : v.toString());

String text(Object? v, [String fallback = '']) {
  final s = str(v);
  return s == null || s.isEmpty ? fallback : s;
}

int? integer(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? number(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool flag(Object? v) => v == true || v?.toString().toLowerCase() == 'true';

DateTime? date(Object? v) {
  if (v == null) return null;
  if (v is List && v.length >= 3) {
    // Jackson may serialise dates as [y, m, d, h, min, s]
    final p = v.map((e) => integer(e) ?? 0).toList();
    return DateTime(p[0], p[1], p[2], p.length > 3 ? p[3] : 0, p.length > 4 ? p[4] : 0, p.length > 5 ? p[5] : 0);
  }
  return DateTime.tryParse(v.toString());
}

Json? obj(Object? v) => v is Map ? v.cast<String, dynamic>() : null;

/// The records of a list response: either `{data: [...]}` (paged envelope) or a bare list.
List<Json> items(Object? body) {
  final list = body is Map ? (body['data'] ?? body['rows'] ?? body['items']) : body;
  if (list is! List) return const [];
  return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

/// `{"name": ...}` of a nested record, e.g. the employer of an incident.
String? nestedName(Object? v) => obj(v)?['name']?.toString();

String? nestedId(Object? v) => obj(v)?['id']?.toString();

/// A single record from a response that may be wrapped as `{success: true, data: {...}}`.
Json record(Object? body) {
  final m = obj(body);
  if (m == null) return const {};
  final inner = obj(m['data']);
  return inner != null && m.containsKey('success') ? inner : m;
}
