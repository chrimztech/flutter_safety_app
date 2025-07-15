// pages/dashboard_page.dart
import 'package:flutter/material.dart';
import '../pages/safety_talks_page.dart';
import 'incident_reporting_page.dart';
import 'risk_assessment_page.dart';
import 'training_management_page.dart';
import 'compliance_tracking_page.dart';
import 'hazard_detection_page.dart';
import 'analytics_page.dart';
import 'virtualisation_page.dart';
import 'safety_page.dart';
import 'emergency_page.dart';
import 'calendar.dart';
import 'user_profile_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'quickaccess_bar.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  List<Map<String, String>> calendarEvents = [
    {
      "title": "Safety Training",
      "date": DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      "description": "Mandatory training on ladder safety.",
    },
    {
      "title": "Hazard Inspection",
      "date": DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      "description": "Quarterly workplace hazard inspection.",
    },
  ];

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildTimelineListTile(BuildContext context, Map<String, String> event) {
    String formattedDate = event["date"] ?? "";
    try {
      formattedDate = DateFormat.yMMMMd().format(DateTime.parse(event["date"]!));
    } catch (_) {}

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(Icons.circle, size: 14, color: Colors.deepOrange.shade400),
                Container(width: 3, height: 52, color: Colors.deepOrange.shade100),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event["title"] ?? "No Title",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("$formattedDate — ${event["description"] ?? ''}",
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, IconData icon, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridAccessCard(BuildContext context) {
    final gridItems = [
      {"icon": Icons.warning, "label": "Safety Talks", "page": const SafetyTalksPage()},
      {"icon": Icons.analytics, "label": "Analytics", "page": const AnalyticsPage()},
      {"icon": Icons.dangerous, "label": "Hazard Detection", "page": const HazardDetectionPage()},
      {"icon": Icons.school, "label": "Training Management", "page": const TrainingManagementPage()},
      {"icon": Icons.safety_check, "label": "Safety Sheets", "page": const SafetySheetsPage()},
      {"icon": Icons.calendar_today, "label": "Calendar", "page": const CalendarPage()},
      {"icon": Icons.warning_amber, "label": "Risk Assessment", "page": const RiskAssessmentPage()},
      {"icon": Icons.report_problem, "label": "Incident Reporting", "page": const IncidentReportingPage()},
      {"icon": Icons.track_changes, "label": "Compliance Tracking", "page": const ComplianceTrackingPage()},
      {"icon": Icons.memory, "label": "Virtualization", "page": const VirtualizationPage()},
      {"icon": Icons.contact_phone, "label": "Emergency", "page": const EmergencyPage()},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: gridItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final item = gridItems[index];
          return _buildGridItem(item['label'] as String, item['icon'] as IconData, item['page'] as Widget);
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("Home", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: kToolbarHeight / 2),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 28, color: Colors.white),
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfilePage()));
            } else if (value == 'settings') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            } else if (value == 'logout') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text('Profile')),
            PopupMenuItem(value: 'settings', child: Text('Settings')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${getGreeting()},",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 6),
            _buildGridAccessCard(context),
            const SizedBox(height: 24),
            Text("Upcoming Events",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.primary)),
            const SizedBox(height: 12),
            if (calendarEvents.isEmpty)
              Center(child: Text("No upcoming events.", style: Theme.of(context).textTheme.bodyMedium))
            else
              ...calendarEvents.map((event) => _buildTimelineListTile(context, event)).toList(),
          ],
        ),
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Home'),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final drawerItems = [
      {"label": "Risk Assessment", "icon": Icons.warning_amber, "page": const RiskAssessmentPage()},
      {"label": "Training Management", "icon": Icons.school, "page": const TrainingManagementPage()},
      {"label": "Compliance Tracking", "icon": Icons.track_changes, "page": const ComplianceTrackingPage()},
      {"label": "Incident Reporting", "icon": Icons.report_problem, "page": const IncidentReportingPage()},
      {"label": "Hazard Detection", "icon": Icons.dangerous, "page": const HazardDetectionPage()},
      {"label": "Analytics", "icon": Icons.analytics, "page": const AnalyticsPage()},
      {"label": "Virtualization", "icon": Icons.memory, "page": const VirtualizationPage()},
      {"label": "Safety Talks", "icon": Icons.record_voice_over, "page": const SafetyTalksPage()},
      {"label": "Emergency", "icon": Icons.contact_phone, "page": const EmergencyPage()},
      {"label": "Safety Sheets", "icon": Icons.safety_check, "page": const SafetySheetsPage()},
      {"label": "Calendar", "icon": Icons.calendar_today, "page": const CalendarPage()},
    ];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 12),
                const Text("Environmental Safety App",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...drawerItems.map((item) => ListTile(
                leading: Icon(item['icon'] as IconData, color: Colors.blue),
                title: Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => item['page'] as Widget));
                },
              )),
        ],
      ),
    );
  }
}
