import 'package:flutter/material.dart';

import '../data/fields.dart';
import '../data/json.dart';
import '../data/models.dart';

/// How a detail value is shown.
enum ShowAs { text, longText, date, dateTime, number, money, boolean, list, company, tag, link }

class DetailItem {
  const DetailItem(this.label, this.key, [this.show = ShowAs.text]);

  final String label;

  /// Backend key, or `a.b` for nested values.
  final String key;
  final ShowAs show;

  Object? read(Json record) {
    Object? v = record;
    for (final part in key.split('.')) {
      v = v is Map ? v[part] : null;
    }
    return v;
  }
}

/// A button on a record (renew, record result, update status...). Opens a form of [fields] (if any), then sends
/// `fixed + form values` as PATCH to the record, or POST to `[path]/{id}/[postAction]`.
class ModuleAction {
  const ModuleAction({
    required this.label,
    required this.icon,
    this.fields = const [],
    this.fixed = const {},
    this.postAction,
    this.visible,
    this.confirm,
    this.success,
    this.computeFixed,
    this.removes = false,
  });

  final String label;
  final IconData icon;
  final List<FieldSpec> fields;
  final Map<String, dynamic> fixed;

  /// Built at run time (e.g. today's date).
  final Map<String, dynamic> Function(Json record)? computeFixed;
  final String? postAction;
  final bool Function(AppUser me, Json record)? visible;
  final String? confirm;
  final String? success;

  /// Deletes the record instead of updating it (e.g. withdrawing an application).
  final bool removes;
}

bool _staff(AppUser me) => me.isStaff;

/// Duty holder: only the company keeps (creates, edits, deletes) these records.
bool companyKeeps(AppUser me) => me.isEmployer;
bool _anyone(AppUser me) => true;

/// A record type shown with the generic list / detail / form screens. Field keys match the backend exactly; the
/// permission callbacks mirror the web app (the server enforces the same rules).
class ModuleSpec {
  const ModuleSpec({
    required this.id,
    required this.title,
    required this.singular,
    required this.icon,
    required this.path,
    required this.titleOf,
    this.subtitleOf,
    this.statusKey,
    this.statusFilters = const [],
    this.toneKey,
    this.details = const [],
    this.createFields = const [],
    this.editFields,
    this.createExtras = const {},
    this.canCreate = _staff,
    this.canEdit = _staff,
    this.canDelete = _staff,
    this.canView = _anyone,
    this.attachmentType,
    this.actions = const [],
    this.emptyMessage,
    this.sort,
    this.description,
    this.header,
    this.reviewType,
    this.companyCreateFields,
    this.companyCreateLabel,
  });

  final String id;
  final String title;
  final String singular;
  final IconData icon;

  /// Collection path, e.g. `permits` → GET permits, GET permits/{id}, POST permits, PATCH permits/{id}, DELETE permits/{id}.
  final String path;
  final String Function(Json r) titleOf;
  final String Function(Json r)? subtitleOf;
  final String? statusKey;
  final List<String> statusFilters;

  /// Field that colours the record (severity, priority, hazard level...). Defaults to the status.
  final String? toneKey;
  final List<DetailItem> details;
  final List<FieldSpec> createFields;

  /// Defaults to [createFields].
  final List<FieldSpec>? editFields;
  final Map<String, dynamic> createExtras;
  final bool Function(AppUser me) canCreate;
  final bool Function(AppUser me) canEdit;
  final bool Function(AppUser me) canDelete;
  final bool Function(AppUser me) canView;
  final String? attachmentType;
  final List<ModuleAction> actions;
  final String? emptyMessage;
  final int Function(Json a, Json b)? sort;
  final String? description;

  /// What a company user fills in when creating (e.g. a permit application); defaults to [createFields].
  final List<FieldSpec>? companyCreateFields;
  final String? companyCreateLabel;

  /// Set for registers the company keeps itself (duty holder): the inspectorate records reviews of type [reviewType].
  final String? reviewType;

  /// Optional summary above the list (e.g. a risk matrix).
  final Widget Function(BuildContext context, List<Json> all)? header;

  String statusOf(Json r) => statusKey == null ? '' : text(r[statusKey!]);
  String toneOf(Json r) => text(r[toneKey ?? statusKey ?? ''], '');
  String idOf(Json r) => text(r['id']);
}
