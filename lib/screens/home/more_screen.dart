import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../modules/module_screens.dart';
import '../../modules/module_spec.dart';
import '../../modules/specs.dart';
import '../account/account_screen.dart';
import '../actions/actions_screen.dart';
import '../admin/agency_settings_screen.dart';
import '../admin/audit_screen.dart';
import '../admin/users_screen.dart';
import '../companies/companies_screen.dart';
import '../companies/company_tools.dart';
import '../complaints/complaints_screen.dart';
import '../enforcement/enforcement_screen.dart';
import '../inspections/checklist_templates_screen.dart';
import '../inspections/inspections_screen.dart';
import '../intelligence/analytics_screen.dart';
import '../intelligence/compliance_screens.dart';
import '../notifications/notifications_screen.dart';
import '../public/public_report_screen.dart';
import '../reports/reports_screen.dart';

/// One menu entry. [open] returns the screen to push, or runs an action and returns null.
class _Item {
  const _Item(this.section, this.icon, this.title, this.subtitle, this.visible, this.open);

  final String section;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool Function(AppUser me) visible;
  final Future<Widget?> Function(BuildContext context) open;
}

Future<Widget?> Function(BuildContext) _screen(Widget w) => (_) async => w;
Future<Widget?> Function(BuildContext) _module(ModuleSpec s) => (_) async => ModuleListScreen(spec: s);

bool _staff(AppUser me) => me.isStaff;
bool _all(AppUser me) => true;
bool _company(AppUser me) => me.isEmployer;
bool _admin(AppUser me) => me.isAdmin;

/// The full menu, mirroring the web app's sidebar (sections and role rules from its navigation config):
/// company users get their portal items, officers the operational and regulatory work, administrators also
/// user management, audit and settings.
final _items = <_Item>[
  _Item('MY COMPANY', Icons.business_outlined, 'Our company', 'Profile, contacts, sites, compliance', _company,
      _screen(Scaffold(appBar: AppBar(title: const Text('Our company')), body: const CompanyDetailScreen(mine: true)))),

  _Item('MAIN', Icons.account_balance_outlined, 'Government dashboard & analytics', 'National figures, trends, injury rates, risk map',
      (me) => me.isStaff && me.can('analytics:read'), _screen(const AnalyticsScreen())),
  _Item('MAIN', Icons.factory_outlined, 'Employers', 'Register of companies and workplaces', _staff, _screen(const CompaniesScreen())),
  _Item('MAIN', Icons.app_registration, 'Employer registration', 'Register a new company with its full profile',
      (me) => me.isStaff && me.can('employers:write'), (context) async {
    await registerCompany(context);
    return null;
  }),
  _Item('MAIN', Icons.fact_check_outlined, 'Inspections', 'Inspections of your workplaces', _company, _screen(const InspectionsScreen())),
  _Item('MAIN', Icons.checklist, 'Inspection checklists', 'Templates used to score inspections', _staff, _screen(const ChecklistTemplatesScreen())),
  _Item('MAIN', Icons.verified_outlined, 'Compliance tracking', 'Companies by compliance and inspection coverage', _staff,
      _screen(const ComplianceTrackingScreen())),
  _Item('MAIN', Icons.calendar_month_outlined, 'Compliance calendar', 'Inspections, expiries and deadlines by date',
      (me) => me.isStaff && me.can('analytics:read'), _screen(const ComplianceCalendarScreen())),

  _Item('OPERATIONS', Icons.campaign_outlined, 'Complaints', 'Worker and public reports', _staff, _screen(const ComplaintsScreen())),
  _Item('OPERATIONS', Icons.manage_search, 'Accident investigation', 'Root cause, findings and prevention', _all, _module(investigationsSpec)),
  _Item('OPERATIONS', Icons.checklist_rtl, 'Corrective actions', 'What companies must fix, by when', _staff, _screen(const ActionsScreen())),
  _Item('OPERATIONS', Icons.casino_outlined, 'Risk assessments', 'Hazards, likelihood × severity, controls', _all, _module(riskAssessmentsSpec)),
  _Item('OPERATIONS', Icons.gavel_outlined, 'Enforcement', 'Notices, fines and prosecutions', _all, _screen(const EnforcementScreen())),
  _Item('OPERATIONS', Icons.verified_outlined, 'Permits & licences', 'Issue, renew, suspend or revoke', _all, _module(permitsSpec)),
  _Item('OPERATIONS', Icons.local_fire_department_outlined, 'Emergency response', 'Fires, spills, medical emergencies', _all, _module(emergencySpec)),
  _Item('OPERATIONS', Icons.groups_outlined, 'Safety culture', 'Leadership, engagement and reporting scores', _staff, _module(safetyCultureSpec)),

  _Item('HEALTH', Icons.medical_services_outlined, 'Medical surveillance', 'Workers\' medical examinations and fitness',
      (me) => me.isStaff && me.can('medical:read'), _module(medicalSpec)),
  _Item('HEALTH', Icons.build_circle_outlined, 'Equipment certification', 'Boilers, cranes, pressure vessels', _all, _module(equipmentSpec)),
  _Item('HEALTH', Icons.science_outlined, 'Hazardous materials', 'Chemical register, storage and handling', _all, _module(hazmatSpec)),

  _Item('REGULATION', Icons.menu_book_outlined, 'Legal & regulatory documents', 'Acts, regulations, statutory instruments', _all, _module(legislationSpec)),

  _Item('INTELLIGENCE', Icons.description_outlined, 'Reports', 'Generate, review, approve, publish, schedule',
      (me) => me.isStaff && me.can('reports:read'), _screen(const ReportsScreen())),

  _Item('TRAINING', Icons.library_books_outlined, 'Training & resources', 'Guides, checklists and materials', _all, _module(resourcesSpec)),
  _Item('TRAINING', Icons.school_outlined, 'Training programmes', 'Courses, enrolment and completion', _staff, _module(trainingProgramsSpec)),

  _Item('SYSTEM', Icons.people_outline, 'User management', 'Accounts, roles, passwords, devices', _admin, _screen(const UsersScreen())),
  _Item('SYSTEM', Icons.receipt_long_outlined, 'Audit logs', 'Tamper-evident record of every action', _admin, _screen(const AuditScreen())),
  _Item('SYSTEM', Icons.settings_outlined, 'Settings', 'Agency profile and sign-in security', _admin, _screen(const AgencySettingsScreen())),
  _Item('SYSTEM', Icons.notifications_outlined, 'Notifications', 'Alerts about your work', _all, _screen(const NotificationsScreen())),
  _Item('SYSTEM', Icons.campaign_outlined, 'Report a concern anonymously', 'For workers, without signing in', _company, _screen(const PublicReportScreen())),
  _Item('SYSTEM', Icons.person_outline, 'My account', 'Password, devices, server, sign out', _all, _screen(const AccountScreen())),
];

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    final visible = _items.where((i) => i.visible(me)).toList();
    final sections = <String>[];
    for (final i in visible) {
      if (!sections.contains(i.section)) sections.add(i.section);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(children: [
        for (final s in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(s,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
          ),
          for (final i in visible.where((i) => i.section == s))
            ListTile(
              leading: Icon(i.icon),
              title: Text(i.title),
              subtitle: Text(i.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final screen = await i.open(context);
                if (screen != null && context.mounted) await context.push(screen);
              },
            ),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}
