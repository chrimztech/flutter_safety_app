// Exercises every data-driven module and admin/platform flow against a running TEST backend, using the very field
// definitions the app's forms send — so a wrong key or value fails here, not in the field.
//
//   flutter test test/live_modules_test.dart --dart-define=OHS_LIVE_URL=http://localhost:8081
//
// Creates records and deletes them again. Never point this at production.
import 'dart:io';

import 'package:flutter_app_scaffold/app/offline_queue.dart';
import 'package:flutter_app_scaffold/data/api_client.dart';
import 'package:flutter_app_scaffold/data/company_profile.dart';
import 'package:flutter_app_scaffold/data/fields.dart';
import 'package:flutter_app_scaffold/data/json.dart';
import 'package:flutter_app_scaffold/data/ohs_api.dart';
import 'package:flutter_app_scaffold/modules/module_spec.dart';
import 'package:flutter_app_scaffold/modules/specs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const liveUrl = String.fromEnvironment('OHS_LIVE_URL');
final skip = liveUrl.isEmpty ? 'set --dart-define=OHS_LIVE_URL to run' : null;

/// A value of the right kind for a field (what a user would enter).
Object? sample(FieldSpec f, String companyId, String tag) {
  final today = DateTime.now();
  String d(DateTime x) => x.toIso8601String().substring(0, 10);
  switch (f.kind) {
    case FieldKind.text:
    case FieldKind.multiline:
      return 'Mobile test ${f.label} $tag';
    case FieldKind.email:
      return 'mobile.$tag.${today.microsecondsSinceEpoch}@example.com';
    case FieldKind.phone:
      return '+260970000000';
    case FieldKind.url:
      return 'https://example.com/$tag';
    case FieldKind.integer:
      return f.initial ?? f.min ?? 1;
    case FieldKind.decimal:
      return f.key == 'latitude' ? -12.8 : f.key == 'longitude' ? 28.2 : 1.5;
    case FieldKind.date:
      return d(today.add(const Duration(days: 30)));
    case FieldKind.dateTime:
      return today.toIso8601String().split('.').first;
    case FieldKind.choice:
      return f.initial ?? f.options!.first.$1;
    case FieldKind.multiChoice:
      return f.options!.take(2).map((o) => o.$1).join(',');
    case FieldKind.boolean:
      return false;
    case FieldKind.company:
      return companyId;
    case FieldKind.score:
      return 70;
  }
}

Map<String, dynamic> payloadFor(List<FieldSpec> fields, String companyId, String tag) =>
    {for (final f in fields) f.key: sample(f, companyId, tag)};

void main() {
  setUpAll(() => HttpOverrides.global = null);

  late OhsApi api;
  late String companyId;

  /// Each signed-in client keeps its own token.
  Future<OhsApi> signIn(String email, String password) async {
    String? token;
    final a = OhsApi(ApiClient(baseUrl: liveUrl, readToken: () async => token));
    token = (await a.login(email, password)).token;
    return a;
  }

  setUp(() async {
    if (liveUrl.isEmpty) return;
    api = await signIn('admin@ohs.gov.zm', 'Regress#A1x');
    companyId = (await api.companies()).first.id;
  });

  final specs = <ModuleSpec>[
    investigationsSpec, riskAssessmentsSpec, permitsSpec, emergencySpec, safetyCultureSpec, medicalSpec,
    equipmentSpec, hazmatSpec, legislationSpec, trainingProgramsSpec, resourcesSpec,
  ];

  for (final spec in specs) {
    test('module ${spec.id}: create, read, actions, edit, delete', () async {
      // Duty holder: registers are kept by the company itself; the inspectorate only reviews them.
      final staff = api;
      final owner = spec.reviewType == null ? api : await signIn('employer@company.com', 'Regress#E1x');
      final fields = spec.reviewType == null ? spec.createFields : spec.createFields.where((f) => f.kind != FieldKind.company).toList();
      if (spec.reviewType != null) {
        await expectLater(staff.create(spec.path, {...spec.createExtras, ...payloadFor(spec.createFields, companyId, spec.id)}),
            throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)));
      }
      final api0 = owner;
      final created = await api0.create(spec.path, {...spec.createExtras, ...payloadFor(fields, companyId, spec.id)});
      final id = spec.idOf(created);
      expect(id, isNotEmpty, reason: 'create returned $created');
      final path = '${spec.path}/$id';

      final read = await api0.one(path);
      expect(spec.titleOf(read), isNotEmpty);
      expect(spec.subtitleOf?.call(read) ?? '', isA<String>());
      for (final d in spec.details) {
        d.read(read); // every declared detail key resolves without error
      }
      // Every value the form sent comes back (proves the key is accepted, not silently dropped).
      for (final f in fields.where((f) => f.kind == FieldKind.text && f.key != 'date')) {
        expect(text(read[f.key]), contains('Mobile test'), reason: '${spec.id}.${f.key} was not saved');
      }

      for (final a in spec.actions) {
        final body = {...a.fixed, ...?a.computeFixed?.call(read), ...payloadFor(a.fields, companyId, 'action')};
        if (a.postAction == null) {
          await api0.update(path, body);
        } else {
          await api0.action('$path/${a.postAction}', body);
        }
      }

      final editFields = spec.editFields ?? spec.createFields;
      if (editFields.isNotEmpty) {
        final edit = payloadFor(editFields.where((f) => f.kind == FieldKind.text).toList(), companyId, 'edited');
        if (edit.isNotEmpty) {
          await api0.update(path, edit);
          final after = await api0.one(path);
          for (final k in edit.keys) {
            expect(text(after[k]), contains('edited'), reason: '${spec.id}.$k edit not saved');
          }
        }
      }

      if (spec.reviewType != null) {
        final review = await staff.create('reviews', {'entityType': spec.reviewType, 'entityId': id, 'status': 'CHANGES_REQUESTED', 'comment': 'Mobile test'});
        expect(review['status'], 'CHANGES_REQUESTED');
        expect((await api0.list('reviews', query: {'entityType': spec.reviewType, 'entityId': id})).single['comment'], 'Mobile test');
        await expectLater(staff.remove(path), throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)));
      }
      await api0.remove(path);
      await expectLater(api0.one(path), throwsA(isA<ApiException>()));
    }, skip: skip);
  }

  test('inspection checklist: template, apply, results, corrective actions', () async {
    final tpl = await api.create('checklists', {
      'name': 'Mobile test checklist',
      'sector': '',
      'items': [
        {'text': 'Guard rails fitted', 'category': 'Height', 'mandatory': true},
        {'text': 'Signage visible', 'category': null, 'mandatory': false},
      ],
    });
    final ins = await api.scheduleInspection(employerId: companyId, type: 'routine', date: DateTime.now());
    final items0 = items(await api.action('inspections/${ins.id}/checklist', {'templateId': tpl['id']}));
    expect(items0.length, 2);
    final summary = obj(await api.client.patch('inspections/${ins.id}/checklist', {
      'results': [
        {'id': items0[0]['id'], 'result': 'FAIL', 'notes': 'Missing on level 2'},
        {'id': items0[1]['id'], 'result': 'PASS', 'notes': ''},
      ],
      'createActions': true,
    }))!;
    expect(summary['complianceScore'], 50.0);
    expect(summary['actionsCreated'], 1);
    final actions = (await api.correctiveActions()).where((a) => a.sourceReference == ins.reference).toList();
    expect(actions, hasLength(1));
    await api.remove('corrective-actions/${actions.single.id}');
    await api.remove('inspections/${ins.id}');
    await api.update('checklists/${tpl['id']}', {'active': false});
    await api.remove('checklists/${tpl['id']}');
  }, skip: skip);

  test('offline checklist results are sent when the connection returns', () async {
    SharedPreferences.setMockInitialValues({});
    final tpl = await api.create('checklists', {'name': 'Mobile offline test', 'sector': '', 'items': ['Fire extinguisher serviced', 'Exit clear']});
    final ins = await api.scheduleInspection(employerId: companyId, type: 'routine', date: DateTime.now());
    final list = items(await api.action('inspections/${ins.id}/checklist', {'templateId': tpl['id']}));
    // Saved while offline (queued), then synced.
    await OfflineQueue.queueResults(ins.id, {
      'results': [
        {'id': list[0]['id'], 'result': 'PASS', 'notes': ''},
        {'id': list[1]['id'], 'result': 'FAIL', 'notes': 'Blocked by pallets'},
      ],
      'createActions': false,
    });
    final summary = await OfflineQueue.sync(api, ins.id);
    expect(summary!['complianceScore'], 50.0);
    expect(await OfflineQueue.pending(ins.id), isNull, reason: 'sent results leave the queue');
    expect((await OfflineQueue.cachedChecklist(ins.id))!.firstWhere((i) => i['id'] == list[1]['id'])['notes'], 'Blocked by pallets');
    await api.remove('inspections/${ins.id}');
    await api.update('checklists/${tpl['id']}', {'active': false});
    await api.remove('checklists/${tpl['id']}');
  }, skip: skip);

  test('permit application, decision and withdrawal', () async {
    final company = await signIn('employer@company.com', 'Regress#E1x');
    final app = await company.create('permits', payloadFor(permitsSpec.companyCreateFields!, companyId, 'apply'));
    expect(app['status'], 'PENDING');
    final approve = permitsSpec.actions.firstWhere((a) => a.label == 'Approve application');
    final granted = await api.update('permits/${app['id']}', {...approve.fixed, ...payloadFor(approve.fields, companyId, 'ok')});
    expect(granted['status'], 'ACTIVE');
    final app2 = await company.create('permits', payloadFor(permitsSpec.companyCreateFields!, companyId, 'apply2'));
    await company.remove('permits/${app2['id']}'); // withdraw
    await api.remove('permits/${app['id']}');
  }, skip: skip);

  test('review status for lists and the company home', () async {
    final company = await signIn('employer@company.com', 'Regress#E1x');
    final rec = await company.create('hazardous-materials', {'name': 'Mobile review test', 'hazardLevel': 'LOW'});
    await api.create('reviews', {'entityType': 'HAZARDOUS_MATERIAL', 'entityId': rec['id'], 'status': 'CHANGES_REQUESTED', 'comment': 'Label it'});
    final latest = await company.list('reviews/latest', query: {'entityType': 'HAZARDOUS_MATERIAL'});
    expect(latest.firstWhere((r) => r['entityId'] == rec['id'])['status'], 'CHANGES_REQUESTED');
    expect(integer((await company.one('reviews/summary'))['HAZARDOUS_MATERIAL']), greaterThanOrEqualTo(1));
    await company.remove('hazardous-materials/${rec['id']}');
  }, skip: skip);

  test('company registers its own device', () async {
    final company = await signIn('employer@company.com', 'Regress#E1x');
    final reg = obj(await company.client.post('iot/devices', {'name': 'Mobile company sensor', 'deviceType': 'NOISE_METER'}))!;
    expect(text(reg['apiKey']), isNotEmpty);
    await api.remove('iot/devices/${obj(reg['device'])!['id']}');
  }, skip: skip);

  test('staff create forms: complaint, enforcement, corrective action', () async {
    final c = await api.create('complaints', {
      'employerId': companyId, 'type': 'lack_of_ppe', 'urgency': 'high', 'description': 'Mobile test complaint',
      'isAnonymous': true, 'isRetaliationConcern': false,
    });
    final e = await api.create('enforcement', {
      'employerId': companyId, 'type': 'improvement_notice', 'description': 'Mobile test violation', 'penalty': 0,
      'dueDate': DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10), 'notes': 'n',
    });
    expect(text(e['actionType']), 'improvement_notice');
    final a = await api.create('corrective-actions', {
      'employerId': companyId, 'title': 'Mobile test action', 'priority': 'high', 'sourceType': 'OTHER',
      'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
    });
    await api.remove('complaints/${c['id']}');
    await api.remove('enforcement/${e['id']}');
    await api.remove('corrective-actions/${a['id']}');
  }, skip: skip);

  test('company: register with portal account, edit, sites, delete', () async {
    final required = {
      for (final f in companyProfileFields.where((f) => f.required)) f.key: sample(f, companyId, 'reg'),
    };
    required['registrationNumber'] = 'MOB-${DateTime.now().millisecondsSinceEpoch}';
    required['email'] = 'mobile.company.${DateTime.now().millisecondsSinceEpoch}@example.com';
    final res = obj(await api.client.post('employers/register', {
      'company': {...required, 'hazardCategories': 'PHYSICAL,CHEMICAL', 'unionRecognised': true},
      'sites': const [],
      'portalUser': {'firstName': 'Mobile', 'lastName': 'Portal', 'email': 'mobile.portal.${DateTime.now().millisecondsSinceEpoch}@example.com'},
    }))!;
    final id = text(obj(res['employer'])!['id']);
    expect(obj(res['portalUser'])?['invitation'], isNotNull);

    await api.update('employers/$id', {'tradingName': 'Mobile Trading', 'riskLevel': 'HIGH'});
    final site = await api.create('employers/$id/sites', {'name': 'Mobile site', 'siteType': 'FACTORY', 'workers': 12, 'district': 'Lusaka'});
    await api.update('employers/$id/sites/${site['id']}', {'workers': 15});
    expect(items(await api.client.get('employers/$id/sites')).single['workers'], 15);
    final c = await api.company(id);
    expect(c.raw['tradingName'], 'Mobile Trading');
    expect(c.raw['hazardCategories'], 'PHYSICAL,CHEMICAL');
    final portal = (await api.list('users')).firstWhere((u) => nestedId(u['employer']) == id);
    await api.remove('users/${portal['id']}');
    await api.remove('employers/$id/sites/${site['id']}');
    await api.client.delete('employers/$id?confirm=${c.registrationNumber}');
  }, skip: skip);

  test('company user edits only their own editable fields', () async {
    final company = await signIn('employer@company.com', 'Regress#E1x');
    final mine = await company.myCompany();
    final editable = companyProfileFields.where((f) => f.employerEditable && f.key == 'emergencyContactPhone').single;
    await company.updateMyCompany({editable.key: '+260977000111'});
    expect((await company.myCompany()).emergencyContactPhone, '+260977000111');
    await expectLater(company.updateMyCompany({'riskLevel': 'LOW', 'name': 'Hacked'}).then((c) => c.name), completion(mine.name));
  }, skip: skip);

  test('users: create officer, edit, reset, sessions, deactivate, delete', () async {
    final email = 'mobile.user.${DateTime.now().millisecondsSinceEpoch}@example.com';
    final res = obj(await api.client.post('users', {'firstName': 'Mobile', 'lastName': 'Officer', 'email': email, 'role': 'OFFICER'}))!;
    expect(obj(res['invitation']), isNotNull);
    final id = text(obj(res['user'])?['id'] ?? res['id']);
    await api.update('users/$id', {'department': 'Field', 'role': 'ADMIN'});
    expect(text(obj((await api.one('users/$id'))['role'])?['name']), 'ADMIN');
    expect(obj(await api.action('users/$id/reset-password'))?['expiresAt'], isNotNull); // invitation fields, unwrapped
    await api.action('users/$id/sessions/end');
    await api.client.patch('users/$id/deactivate');
    await api.client.patch('users/$id/activate');
    await api.remove('users/$id');
  }, skip: skip);

  test('audit log, settings, reports, schedules', () async {
    final page = obj(await api.client.get('audit-logs', query: {'page': 1, 'size': 5, 'category': 'security'}))!;
    expect(page['data'], isA<List>());
    expect(text(obj(await api.client.get('audit-logs/verify'))!['status']), 'VERIFIED');
    final first = items(page).isEmpty ? null : items(page).first;
    if (first != null) expect((await api.one('audit-logs/${first['id']}'))['hashValid'], isTrue);

    await api.update('agency/security', {'idleMinutes': 45});
    expect(items((await api.one('agency/security'))['fields']).firstWhere((f) => f['key'] == 'idleMinutes')['value'], 45);
    await api.update('agency/security', {'idleMinutes': ''});
    final profile = await api.one('agency/profile');
    await api.update('agency/profile', {'contactPhone': '+260211000000'});
    await api.update('agency/profile', {'contactPhone': profile['contactPhone'] ?? ''});

    final report = await api.create('reports', {'type': 'executive', 'dateFrom': '2026-01-01', 'dateTo': '2026-12-31'});
    await api.update('reports/${report['id']}', {'recommendations': 'Mobile test'});
    await api.action('reports/${report['id']}/regenerate');
    expect((await api.client.getBytes('reports/${report['id']}/export')).length, greaterThan(50));
    await api.remove('reports/${report['id']}');
    final schedule = await api.create('reports/schedules', {'type': 'incidents', 'frequency': 'MONTHLY'});
    final ran = obj(await api.action('reports/schedules/${schedule['id']}/run'))!;
    await api.update('reports/schedules/${schedule['id']}', {'active': false});
    await api.remove('reports/schedules/${schedule['id']}');
    await api.remove('reports/${ran['id']}');
  }, skip: skip);

  test('analytics, calendar and IoT device lifecycle', () async {
    for (final p in ['analytics/injury-rates', 'analytics/sector-compliance', 'analytics/district-analysis', 'analytics/top-risk-employers',
      'analytics/incident-trends', 'analytics/inspection-performance']) {
      expect(await api.one(p), isNotEmpty, reason: p);
    }
    expect(await api.list('analytics/calendar', query: {'from': '2026-01-01', 'to': '2026-12-31'}), isA<List>());

    final reg = obj(await api.client.post('iot/devices', {
      'name': 'Mobile test gas monitor', 'deviceType': 'GAS_DETECTOR', 'employerId': companyId, 'zone': 'Test zone', 'reportingIntervalSeconds': 60,
    }))!;
    expect(text(reg['apiKey']), isNotEmpty);
    final id = text(obj(reg['device'])!['id']);
    expect((await api.one('iot/devices/$id/detail'))['metrics'], isA<List>());
    await api.update('iot/devices/$id', {'status': 'DISABLED'});
    expect(text(obj(await api.action('iot/devices/$id/rotate-key'))!['apiKey']), isNot(reg['apiKey']));
    await api.remove('iot/devices/$id');
  }, skip: skip);

  test('platform console and support mode', () async {
    final sa = await signIn('superadmin@ohs-platform.local', const String.fromEnvironment('OHS_SA_PASSWORD', defaultValue: 'Regress#S1x'));
    final tenants = await sa.list('platform/tenants');
    final agency = tenants.firstWhere((t) => t['code'] == 'regression');
    expect(await sa.list('platform/users'), isNotEmpty);
    expect(await sa.list('platform/sessions'), isNotEmpty);
    expect(await sa.list('platform/employers'), isNotEmpty);
    expect(obj(await sa.client.get('platform/audit', query: {'size': 5}))!['data'], isA<List>());
    expect(text(obj(await sa.client.get('platform/audit/verify', query: {'agencyId': agency['id']}))!['status']), 'VERIFIED');

    // Support mode: the same account works inside the agency as its administrator.
    expect(await sa.incidents(), isEmpty, reason: 'outside an agency the super-admin sees no agency records');
    sa.client.actingTenant = text(agency['id']);
    expect(await sa.incidents(), isNotEmpty);
    expect(await sa.list('users'), isNotEmpty);
    sa.client.actingTenant = null;
  }, skip: skip);
}
