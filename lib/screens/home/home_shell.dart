import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../app/context_ext.dart';
import '../../app/session.dart';
import '../actions/actions_screen.dart';
import '../incidents/incidents_screen.dart';
import '../inspections/inspections_screen.dart';
import '../iot/alerts_screen.dart';
import 'company_home.dart';
import 'more_screen.dart';
import 'staff_dashboard.dart';

/// Bottom navigation, different for agency staff and company users.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = context.me;
    final tabs = me.isEmployer
        ? const <(IconData, IconData, String, Widget)>[
            (Icons.home_outlined, Icons.home, 'Home', CompanyHome()),
            (Icons.report_problem_outlined, Icons.report_problem, 'Incidents', IncidentsScreen()),
            (Icons.checklist_rtl_outlined, Icons.checklist_rtl, 'Actions', ActionsScreen()),
            (Icons.sensors_outlined, Icons.sensors, 'Alerts', AlertsScreen()),
            (Icons.menu, Icons.menu, 'More', MoreScreen()),
          ]
        : const <(IconData, IconData, String, Widget)>[
            (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', StaffDashboard()),
            (Icons.report_problem_outlined, Icons.report_problem, 'Incidents', IncidentsScreen()),
            (Icons.fact_check_outlined, Icons.fact_check, 'Inspections', InspectionsScreen()),
            (Icons.sensors_outlined, Icons.sensors, 'Alerts', AlertsScreen()),
            (Icons.menu, Icons.menu, 'More', MoreScreen()),
          ];
    final session = context.watch<SessionController>();
    final stack = IndexedStack(index: _index, children: [for (final t in tabs) t.$4]);
    return Scaffold(
      // Platform super-admin working inside an agency: always visible, with the way back.
      body: session.supportMode
          ? Column(children: [
              Material(
                color: Colors.amber.shade700,
                child: SafeArea(
                  bottom: false,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.support_agent, color: Colors.black87),
                    title: Text('Support mode: ${session.supportAgencyName}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                    subtitle: const Text("Everything you do is recorded in this agency's audit log", style: TextStyle(color: Colors.black87)),
                    trailing: TextButton(onPressed: session.exitAgency, child: const Text('Exit', style: TextStyle(color: Colors.black87))),
                  ),
                ),
              ),
              Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: stack)),
            ])
          : stack,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: t.$3)],
      ),
    );
  }
}
