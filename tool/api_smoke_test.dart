// Exercises the app's data layer against a running OHS backend.
//
//   dart run tool/api_smoke_test.dart [baseUrl] [staffEmail] [staffPassword] [companyEmail] [companyPassword]
//
// Defaults target a local TEST backend on port 8081 with the regression fixture accounts.
// Read-only apart from: adding a note to a hazard alert, and one public test report.
import 'dart:io';

import 'package:flutter_app_scaffold/data/api_client.dart';
import 'package:flutter_app_scaffold/data/ohs_api.dart';

var _passed = 0;
var _failed = 0;

Future<void> check(String name, Future<Object?> Function() body) async {
  try {
    final detail = await body();
    _passed++;
    stdout.writeln('PASS $name${detail == null ? '' : '  ($detail)'}');
  } catch (e) {
    _failed++;
    stdout.writeln('FAIL $name  -> $e');
  }
}

Future<void> main(List<String> args) async {
  final base = args.isNotEmpty ? args[0] : 'http://localhost:8081';
  final staffEmail = args.length > 1 ? args[1] : 'officer@ohs.gov.zm';
  final staffPassword = args.length > 2 ? args[2] : 'Regress#O1x';
  final companyEmail = args.length > 3 ? args[3] : 'employer@company.com';
  final companyPassword = args.length > 4 ? args[4] : 'Regress#E1x';

  String? token;
  String? endedReason;
  final api = OhsApi(ApiClient(baseUrl: base, readToken: () async => token, onUnauthorized: (m) => endedReason = m));

  // ---- public portal (no account)
  final agencies = await api.agencies();
  await check('public: agencies listed', () async => '${agencies.length} agencies');
  final agency = agencies.firstWhere((a) => a.code == 'regression', orElse: () => agencies.first);
  await check('public: companies of ${agency.code}', () async => '${(await api.publicCompanies(agency.code)).length} companies');
  final submitted = await api.submitPublicComplaint(agency.code,
      description: 'Mobile smoke test: blocked fire exit in warehouse', urgency: 'normal', companyName: 'Smoke Test Ltd');
  await check('public: report submitted', () async => submitted.reference);
  await check('public: report tracked', () async {
    final t = await api.trackComplaint(agency.code, submitted.reference, submitted.trackingCode);
    if (t['status'] == null) throw StateError('no status');
    return t['status'];
  });

  // ---- sign-in errors
  await check('wrong password rejected with server message', () async {
    try {
      await api.login(staffEmail, 'definitely-wrong');
    } on ApiException catch (e) {
      if (e.status != 401) throw StateError('status ${e.status}');
      return e.message;
    }
    throw StateError('accepted a wrong password');
  });
  // Clear the failed attempt so the lockout counter does not build up across runs.
  final auth = await api.login(staffEmail, staffPassword);
  token = auth.token;
  await check('staff sign-in', () async => '${auth.user.name} · ${auth.user.roleLabel} · idle ${auth.idleMinutes} min');
  await check('validate session', () async => (await api.validate()).user?.email);
  await check('profile', () async => (await api.profile()).fullName);
  await check('sessions', () async => '${(await api.sessions()).sessions.length} sessions');

  // ---- staff data
  await check('dashboard', () async => 'incidents ${(await api.dashboard())['totalIncidents']}');
  await check('iot stats', () async => 'open events ${(await api.iotStats())['openEvents']}');
  final incidents = await api.incidents();
  await check('incidents', () async => '${incidents.length}');
  if (incidents.isNotEmpty) await check('incident detail', () async => (await api.incident(incidents.first.id)).reference);
  await check('inspections', () async => '${(await api.inspections()).length}');
  final complaints = await api.complaints();
  await check('complaints (includes the public report)',
      () async => complaints.any((c) => c.reference == submitted.reference) ? '${complaints.length}' : throw StateError('not found'));
  final companies = await api.companies();
  await check('companies', () async => '${companies.length}');
  if (companies.isNotEmpty) await check('company detail', () async => (await api.company(companies.first.id)).name);
  await check('enforcement', () async => '${(await api.enforcement()).length}');
  await check('corrective actions', () async => '${(await api.correctiveActions()).length}');
  final events = await api.hazardEvents();
  await check('hazard events', () async => '${events.length}');
  if (events.isNotEmpty) {
    await check('hazard event recommendations', () async => '${(await api.eventRecommendations(events.first.id)).length}');
    await check('note on hazard event', () async => (await api.updateHazardEvent(events.first.id, notes: 'Smoke test note')).notes?.split('\n').last);
  }
  await check('devices', () async => '${(await api.devices()).length}');
  await check('recommendations', () async => '${(await api.recommendations()).length}');
  await check('reports', () async => '${(await api.reports()).length}');
  await check('notifications', () async => '${(await api.notifications()).length}');
  await check('unread count (background)', () async => '${await api.unreadNotifications()}');

  // ---- company user
  final companyAuth = await api.login(companyEmail, companyPassword);
  final staffToken = token;
  token = companyAuth.token;
  await check('company sign-in', () async => '${companyAuth.user.roleLabel} · ${companyAuth.user.employerName}');
  await check('my company', () async => (await api.myCompany()).name);
  await check('company incidents', () async => '${(await api.incidents()).length}');
  await check('company actions', () async => '${(await api.correctiveActions()).length}');
  await check('company alerts', () async => '${(await api.hazardEvents()).length}');
  await check('company cannot open agency dashboard', () async {
    try {
      await api.dashboard();
    } on ApiException catch (e) {
      if (e.status != 403) throw StateError('status ${e.status}');
      return 'denied';
    }
    throw StateError('allowed');
  });

  // ---- session end is reported to the app
  await api.logout();
  await check('signed-out token is refused and reported', () async {
    try {
      await api.myCompany();
    } on ApiException catch (e) {
      if (!e.isUnauthorized || endedReason == null) throw StateError('status ${e.status}, reason $endedReason');
      return endedReason;
    }
    throw StateError('still accepted');
  });
  token = staffToken;
  await api.logout();

  stdout.writeln('\n$_passed/${_passed + _failed} passed');
  exit(_failed == 0 ? 0 : 1);
}
