import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

/// `SERIOUS_INJURY` / `follow_up` → `Serious injury` / `Follow up`
String humanize(String? value) {
  if (value == null || value.isEmpty) return '—';
  final s = value.replaceAll('_', ' ').toLowerCase();
  return s[0].toUpperCase() + s.substring(1);
}

String fmtDate(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy').format(d.toLocal());

String fmtDateTime(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy, HH:mm').format(d.toLocal());

String fmtNum(Object? v) {
  if (v == null) return '—';
  if (v is num) return v % 1 == 0 ? NumberFormat.decimalPattern().format(v) : v.toStringAsFixed(1);
  return v.toString();
}

/// "5 min ago", "3 h ago", "2 d ago", else the date.
String ago(DateTime? d) {
  if (d == null) return '—';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return fmtDate(d);
}

/// Colour for any severity, priority, risk level or status value used by the backend.
Color toneOf(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'CRITICAL':
    case 'FATALITY':
    case 'PROSECUTION':
    case 'OVERDUE':
    case 'OPEN':
      return OhsColors.critical;
    case 'HIGH':
    case 'SERIOUS_INJURY':
    case 'PROHIBITION_NOTICE':
    case 'UNDER_APPEAL':
    case 'IN_REVIEW':
      return OhsColors.high;
    case 'MEDIUM':
    case 'INJURY':
    case 'ACKNOWLEDGED':
    case 'INVESTIGATING':
    case 'IN_PROGRESS':
    case 'ASSIGNED':
    case 'ISSUED':
    case 'ACTIVE':
    case 'IMPROVEMENT_NOTICE':
      return OhsColors.medium;
    case 'LOW':
    case 'RESOLVED':
    case 'COMPLETED':
    case 'VERIFIED':
    case 'CLOSED':
    case 'PUBLISHED':
    case 'APPROVED':
      return OhsColors.low;
    case 'REPORTED':
    case 'RECEIVED':
    case 'SCHEDULED':
    case 'DRAFT':
      return OhsColors.info;
    default:
      return OhsColors.neutral;
  }
}
