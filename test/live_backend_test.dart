// Renders the real screens against a running OHS backend (skipped unless a URL is given):
//
//   flutter test test/live_backend_test.dart --dart-define=OHS_LIVE_URL=http://localhost:8081
//
// Uses the regression fixture accounts of a TEST backend. Read-only.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app_scaffold/app/session.dart';
import 'package:flutter_app_scaffold/data/fields.dart';
import 'package:flutter_app_scaffold/modules/module_screens.dart';
import 'package:flutter_app_scaffold/modules/specs.dart';
import 'package:flutter_app_scaffold/screens/admin/agency_settings_screen.dart';
import 'package:flutter_app_scaffold/screens/admin/audit_screen.dart';
import 'package:flutter_app_scaffold/screens/admin/users_screen.dart';
import 'package:flutter_app_scaffold/screens/home/more_screen.dart';
import 'package:flutter_app_scaffold/screens/inspections/checklist_templates_screen.dart';
import 'package:flutter_app_scaffold/screens/intelligence/analytics_screen.dart';
import 'package:flutter_app_scaffold/screens/intelligence/compliance_screens.dart';
import 'package:flutter_app_scaffold/screens/iot/device_screens.dart';
import 'package:flutter_app_scaffold/screens/platform/platform_screens.dart';
import 'package:flutter_app_scaffold/screens/reports/report_tools.dart';
import 'package:flutter_app_scaffold/screens/reports/reports_screen.dart';
import 'package:flutter_app_scaffold/screens/actions/actions_screen.dart';
import 'package:flutter_app_scaffold/screens/companies/companies_screen.dart';
import 'package:flutter_app_scaffold/screens/complaints/complaints_screen.dart';
import 'package:flutter_app_scaffold/screens/home/home_shell.dart';
import 'package:flutter_app_scaffold/screens/incidents/incidents_screen.dart';
import 'package:flutter_app_scaffold/screens/iot/alerts_screen.dart';
import 'package:flutter_app_scaffold/screens/notifications/notifications_screen.dart';
import 'package:flutter_app_scaffold/screens/public/public_report_screen.dart';
import 'package:flutter_app_scaffold/ui/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const liveUrl = String.fromEnvironment('OHS_LIVE_URL');

void main() {
  // flutter_test replaces HTTP with a fake that answers 400; these tests need the real network.
  setUpAll(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({}); // device preferences have no plugin in tests
  });

  Future<SessionController> signIn(WidgetTester tester, String email, String password) async {
    final session = SessionController();
    addTearDown(session.dispose); // stops the background notification poll
    await tester.runAsync(() async {
      await session.setServerUrl(liveUrl);
      await session.signIn(email, password);
    });
    return session;
  }

  /// Pumps [screen], lets its network calls finish in real time, and fails on any rendering error.
  Future<void> show(WidgetTester tester, SessionController session, Widget screen, [void Function()? checks, Size size = const Size(412, 915)]) async {
    await tester.binding.setSurfaceSize(size); // a typical phone unless a check needs the whole page laid out
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: session,
      child: MaterialApp(theme: buildTheme(Brightness.light), home: screen),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'still loading');
    expect(find.text('Something went wrong'), findsNothing);
    checks?.call();
    // Let the HTTP client's keep-alive timers (created on the test clock) expire before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
  }


  group('officer', skip: liveUrl.isEmpty ? 'set --dart-define=OHS_LIVE_URL to run' : null, () {
    testWidgets('dashboard shows live figures', (tester) async {
      final s = await signIn(tester, 'officer@ohs.gov.zm', 'Regress#O1x');
      await show(tester, s, const HomeShell(), () {
        expect(find.text('Incidents this month'), findsOneWidget);
        expect(find.textContaining('Hello,'), findsOneWidget);
      });
    });

    testWidgets('incidents list', (tester) async {
      final s = await signIn(tester, 'officer@ohs.gov.zm', 'Regress#O1x');
      await show(tester, s, const IncidentsScreen(), () {
        expect(find.textContaining('records'), findsOneWidget);
        expect(find.text('Report incident'), findsOneWidget);
      });
    });

    testWidgets('hazard alerts', (tester) async {
      final s = await signIn(tester, 'officer@ohs.gov.zm', 'Regress#O1x');
      await show(tester, s, const AlertsScreen(), () => expect(find.text('Alerts'), findsOneWidget));
    });

    testWidgets('companies, complaints, actions, notifications', (tester) async {
      final s = await signIn(tester, 'officer@ohs.gov.zm', 'Regress#O1x');
      for (final screen in const [CompaniesScreen(), ComplaintsScreen(), ActionsScreen(), NotificationsScreen()]) {
        await show(tester, s, screen);
      }
      await show(tester, s, const CompaniesScreen(), () => expect(find.text('Zambia Copper Mining Ltd'), findsOneWidget));
    });
  });

  group('company user', skip: liveUrl.isEmpty ? 'set --dart-define=OHS_LIVE_URL to run' : null, () {
    testWidgets('home shows only their company', (tester) async {
      final s = await signIn(tester, 'employer@company.com', 'Regress#E1x');
      await show(tester, s, const HomeShell(), () {
        expect(find.text('Zambia Copper Mining Ltd'), findsOneWidget);
        expect(find.text('Open actions'), findsOneWidget);
        expect(find.text('Dashboard'), findsNothing, reason: 'company users get the company navigation');
      });
    });
  });

  group('public', skip: liveUrl.isEmpty ? 'set --dart-define=OHS_LIVE_URL to run' : null, () {
    testWidgets('report form loads agencies without an account', (tester) async {
      final s = SessionController();
      await tester.runAsync(() => s.setServerUrl(liveUrl));
      await show(tester, s, const PublicReportScreen(), () {
        expect(find.text('Agency *'), findsOneWidget);
        expect(find.text('Send report'), findsOneWidget);
      });
    });
  });

  group('every screen renders with live data', skip: liveUrl.isEmpty ? 'set --dart-define=OHS_LIVE_URL to run' : null, () {
    final specs = [
      investigationsSpec, riskAssessmentsSpec, permitsSpec, emergencySpec, safetyCultureSpec, medicalSpec,
      equipmentSpec, hazmatSpec, legislationSpec, trainingProgramsSpec, resourcesSpec,
    ];

    testWidgets('module lists and a detail of each (administrator)', (tester) async {
      final s = await signIn(tester, 'admin@ohs.gov.zm', 'Regress#A1x');
      final api = s.api;
      late String companyId;
      final created = <String, String>{};
      await tester.runAsync(() async {
        companyId = (await api.companies()).first.id;
        for (final spec in specs) {
          final body = {
            ...spec.createExtras,
            if (spec.id == 'training') 'url': 'https://example.com/guide',
            for (final f in spec.createFields)
              if (f.required || f.initial != null)
                f.key: f.kind == FieldKind.company
                    ? companyId
                    : f.kind == FieldKind.date
                        ? '2026-12-31'
                        : f.initial ?? (f.options?.first.$1 ?? 'Render test ${spec.id}'),
          };
          created[spec.id] = spec.idOf(await api.create(spec.path, body));
        }
      });
      for (final spec in specs) {
        await show(tester, s, ModuleListScreen(spec: spec), () => expect(find.text(spec.title), findsOneWidget));
        await show(tester, s, ModuleDetailScreen(spec: spec, id: created[spec.id]!), () => expect(find.text('DETAILS'), findsOneWidget));
      }
      await tester.runAsync(() async {
        for (final spec in specs) {
          await api.remove('${spec.path}/${created[spec.id]}');
        }
      });
    });

    testWidgets('administrator screens', (tester) async {
      final s = await signIn(tester, 'admin@ohs.gov.zm', 'Regress#A1x');
      for (final screen in const <Widget>[
        MoreScreen(), AnalyticsScreen(), ComplianceCalendarScreen(), ComplianceTrackingScreen(), UsersScreen(), AuditScreen(),
        AgencySettingsScreen(), ChecklistTemplatesScreen(), ReportsScreen(), ReportSchedulesScreen(),
      ]) {
        await show(tester, s, screen);
      }
      await show(tester, s, const MoreScreen(), () {
        expect(find.text('User management'), findsOneWidget);
        expect(find.text('Employer registration'), findsOneWidget);
      }, const Size(412, 3200));
    });

    testWidgets('IoT device detail', (tester) async {
      final s = await signIn(tester, 'officer@ohs.gov.zm', 'Regress#O1x');
      late String id;
      await tester.runAsync(() async => id = (await s.api.devices()).first.id);
      await show(tester, s, DeviceDetailScreen(id: id), () => expect(find.textContaining('READINGS'), findsOneWidget));
    });

    testWidgets('officer menu hides administration', (tester) async {
      final s = await signIn(tester, 'officer@ohs.gov.zm', 'Regress#O1x');
      await show(tester, s, const MoreScreen(), () {
        expect(find.text('User management'), findsNothing);
        expect(find.text('Audit logs'), findsNothing);
        expect(find.text('Compliance tracking'), findsOneWidget);
      }, const Size(412, 3200));
    });

    testWidgets('company user menu is the company portal', (tester) async {
      final s = await signIn(tester, 'employer@company.com', 'Regress#E1x');
      await show(tester, s, const MoreScreen(), () {
        expect(find.text('Our company'), findsOneWidget);
        expect(find.text('Complaints'), findsNothing);
        expect(find.text('Employers'), findsNothing);
        expect(find.text('Medical surveillance'), findsNothing);
        expect(find.text('Permits & licences'), findsOneWidget);
      }, const Size(412, 3200));
      await show(tester, s, ModuleListScreen(spec: permitsSpec), () => expect(find.text('New permit'), findsNothing));
    });

    testWidgets('platform console', (tester) async {
      final s = await signIn(tester, 'superadmin@ohs-platform.local', 'Regress#S1x');
      await show(tester, s, const PlatformShell(), () => expect(find.text('Agencies'), findsWidgets));
      await show(tester, s, const PlatformUsersScreen());
      await show(tester, s, const PlatformSessionsScreen());
      await show(tester, s, const PlatformCompaniesScreen());
    });
  });
}
