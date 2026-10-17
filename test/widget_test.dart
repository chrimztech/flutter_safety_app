import 'package:flutter/material.dart';
import 'package:flutter_app_scaffold/app/offline_queue.dart';
import 'package:flutter_app_scaffold/app/session.dart';
import 'package:flutter_app_scaffold/data/api_client.dart';
import 'package:flutter_app_scaffold/data/ohs_api.dart';
import 'package:flutter_app_scaffold/data/json.dart';
import 'package:flutter_app_scaffold/data/models.dart';
import 'package:flutter_app_scaffold/screens/auth/login_screen.dart';
import 'package:flutter_app_scaffold/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('backend JSON', () {
    test('sign-in response gives the user, role and session limits', () {
      final r = AuthResult.fromJson({
        'token': 'abc',
        'user': {
          'id': 'u1',
          'name': 'Field Officer',
          'email': 'officer@ohs.gov.zm',
          'role': 'OFFICER',
          'permissions': ['incidents:read', 'incidents:write'],
          'tenantName': 'Regression Agency',
          'mustChangePassword': false,
        },
        'idleTimeoutMinutes': 30,
        'sessionExpiresAt': '2026-10-16T19:05:02.677',
      });
      expect(r.token, 'abc');
      expect(r.user.isStaff, isTrue);
      expect(r.user.isEmployer, isFalse);
      expect(r.user.can('incidents:write'), isTrue);
      expect(r.user.roleLabel, 'OHS Officer');
      expect(r.idleMinutes, 30);
      expect(r.user.initials, 'FO');
    });

    test('list envelopes and bare lists both parse', () {
      expect(items({'data': [{'id': 1}], 'total': 1}).length, 1);
      expect(items([{'id': 1}, {'id': 2}]).length, 2);
      expect(items({'rows': [{'id': 1}]}).length, 1);
      expect(items(null), isEmpty);
    });

    test('incident with nested company', () {
      final i = Incident.fromJson({
        'id': 'i1',
        'referenceNumber': 'INC-1',
        'type': 'NEAR_MISS',
        'status': 'REPORTED',
        'severity': 'HIGH',
        'title': 'Forklift near miss',
        'incidentDate': '2026-10-01T10:00:00',
        'employer': {'id': 'e1', 'name': 'Lusaka Construction Works'},
        'numberOfPersonsAffected': 2,
      });
      expect(i.company?.name, 'Lusaka Construction Works');
      expect(i.personsAffected, 2);
      expect(i.incidentDate?.day, 1);
    });

    test('overdue corrective action', () {
      final a = CorrectiveAction.fromJson({'id': 'a', 'status': 'open', 'dueDate': '2020-01-01'});
      final done = CorrectiveAction.fromJson({'id': 'b', 'status': 'verified', 'dueDate': '2020-01-01'});
      expect(a.isOverdue, isTrue);
      expect(done.isOverdue, isFalse);
    });

    test('recommendation actions follow the hierarchy of controls', () {
      final r = Recommendation.fromJson({
        'title': 'Gas build-up in Block A',
        'priority': 'HIGH',
        'actions': [
          {'action': 'Install extraction', 'level': 'ENGINEERING'},
          {'action': 'Issue respirators', 'level': 'PPE'},
        ],
        'employer': {'name': 'Ndola Chemical'},
      });
      expect(r.actions.first.level, 'ENGINEERING');
      expect(r.companyName, 'Ndola Chemical');
    });

    test('report document exposes figures and sections', () {
      final r = ReportSummary.fromJson({
        'id': 'r',
        'title': 'Executive overview',
        'status': 'DRAFT',
        'periodFrom': '2026-09-01',
        'periodTo': '2026-09-30',
        'district': 'Lusaka',
        'content': {
          'kpis': [{'label': 'Incidents', 'value': 4}],
          'sections': [{'kind': 'breakdown', 'title': 'By severity', 'items': [{'label': 'HIGH', 'value': 1}]}],
          'findings': ['Incidents rose by 20%'],
        },
      });
      expect(r.kpis.single.value, 4);
      expect(r.sections.single['title'], 'By severity');
      expect(r.autoFindings.single, contains('20%'));
      expect(r.period, '2026-09-01 to 2026-09-30');
      expect(r.scope, 'District: Lusaka');
    });
  });

  group('offline checklist queue', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps the checklist and queued results on the device while offline', () async {
      await OfflineQueue.cacheChecklist('ins-1', [{'id': 'a', 'text': 'Guard rails', 'result': 'PENDING'}]);
      await OfflineQueue.queueResults('ins-1', {'results': [{'id': 'a', 'result': 'FAIL', 'notes': 'missing'}], 'createActions': true});
      expect((await OfflineQueue.cachedChecklist('ins-1'))!.single['text'], 'Guard rails');
      expect((await OfflineQueue.pending('ins-1'))!['createActions'], isTrue);
      expect(await OfflineQueue.pendingCount(), 1);
    });

    test('nothing queued: sync does nothing', () async {
      final api = OhsApi(ApiClient(baseUrl: 'http://127.0.0.1:9', readToken: () async => null));
      expect(await OfflineQueue.sync(api, 'none'), isNull);
    });
  });

  group('formatting', () {
    test('backend codes become readable labels', () {
      expect(humanize('SERIOUS_INJURY'), 'Serious injury');
      expect(humanize('follow_up'), 'Follow up');
      expect(humanize(null), '—');
    });
  });

  testWidgets('sign-in screen offers sign-in, password reset and anonymous reporting', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => SessionController(),
      child: const MaterialApp(home: LoginScreen()),
    ));
    expect(find.text('OHS Mobile'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Report a safety concern'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
