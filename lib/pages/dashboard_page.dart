// pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import your pages (assuming these paths are correct)
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final String _userName = "John Doe";

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
    {
      "title": "First Aid Refresher",
      "date": DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      "description": "Annual first aid certification renewal.",
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event, color: Theme.of(context).colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event["title"] ?? "No Title",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event["description"] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, IconData icon, Widget page) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridAccessCard(BuildContext context) {
    final gridItems = [
      {"icon": Icons.record_voice_over, "label": "Safety Talks", "page": const SafetyTalksPage()},
      {"icon": Icons.analytics, "label": "Analytics", "page": const AnalyticsPage()},
      {"icon": Icons.dangerous, "label": "Hazard Detection", "page": const HazardDetectionPage()},
      {"icon": Icons.safety_check, "label": "Safety Sheets", "page": const SafetySheetsPage()},
      {"icon": Icons.calendar_today, "label": "Calendar", "page": const CalendarPage()},
      {"icon": Icons.report_problem, "label": "Incident Reporting", "page": const IncidentReportingPage()},
      {"icon": Icons.memory, "label": "Virtualization", "page": const VirtualizationPage()},
      {"icon": Icons.contact_phone, "label": "Emergency", "page": const EmergencyContactsPage()},
      {"icon": Icons.person, "label": "Profile", "page": const UserProfilePage()},
      {"icon": Icons.gavel, "label": "Compliance", "page": const ComplianceTrackingPage()},
      {"icon": Icons.military_tech, "label": "Risk Assessment", "page": const RiskAssessmentPage()},
      {"icon": Icons.school, "label": "Training", "page": const TrainingManagementPage()},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: gridItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.95,
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getGreeting(),
                      style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white30,
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
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
            ),
          ),
        ),
      ),
    );
  }

  // Modified _buildDrawer to accept currentRouteLabel
  Widget _buildDrawer(BuildContext context, String currentRouteLabel) {
    final drawerItems = [
      {"label": "Home", "icon": Icons.home, "page": const DashboardPage()}, // Added Home to drawer items
      {"label": "Risk Assessment", "icon": Icons.warning_amber, "page": const RiskAssessmentPage()},
      {"label": "Training Management", "icon": Icons.school, "page": const TrainingManagementPage()},
      {"label": "Compliance Tracking", "icon": Icons.track_changes, "page": const ComplianceTrackingPage()},
      {"label": "Incident Reporting", "icon": Icons.report_problem, "page": const IncidentReportingPage()},
      {"label": "Hazard Detection", "icon": Icons.dangerous, "page": const HazardDetectionPage()},
      {"label": "Analytics", "icon": Icons.analytics, "page": const AnalyticsPage()},
      {"label": "Virtualization", "icon": Icons.memory, "page": const VirtualizationPage()},
      {"label": "Safety Talks", "icon": Icons.record_voice_over, "page": const SafetyTalksPage()},
      {"label": "Emergency", "icon": Icons.contact_phone, "page": const EmergencyContactsPage()},
      {"label": "Safety Sheets", "icon": Icons.safety_check, "page": const SafetySheetsPage()},
      {"label": "Calendar", "icon": Icons.calendar_today, "page": const CalendarPage()},
    ];

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.shield, size: 40, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Environmental Safety App",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Your safety companion",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...drawerItems.map((item) => ListTile(
                      leading: Icon(item['icon'] as IconData, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      title: Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => item['page'] as Widget));
                      },
                      // Corrected: Compare item['label'] with the passed currentRouteLabel
                      selected: item['label'] == currentRouteLabel,
                      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      selectedColor: Theme.of(context).colorScheme.primary,
                    )),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfilePage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      // Pass the current label 'Home' to the drawer
      drawer: _buildDrawer(context, 'Home'),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.surface, colorScheme.background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, kToolbarHeight * 2.2, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Explore your dashboard",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 24),
                _buildGridAccessCard(context),
                const SizedBox(height: 30),
                Text(
                  "Upcoming Events",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                if (calendarEvents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No upcoming events scheduled.",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else
                  ...calendarEvents.map((event) => _buildTimelineListTile(context, event)).toList(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Home'),
    );
  }
}