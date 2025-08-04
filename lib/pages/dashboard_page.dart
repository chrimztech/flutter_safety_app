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
import 'safety_page.dart'; // Assuming this is SafetySheetsPage
import 'emergency_page.dart'; // Assuming this is EmergencyContactsPage
import 'calendar.dart'; // Assuming this is CalendarPage
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
  final String _userName = "Chrishent Matakala";

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
    } catch (_) {
      formattedDate = "Unknown Date";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
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

  Widget _buildGridItem(String label, IconData icon, Widget page, List<Color> colors) {
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
              colors: colors,
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
              // Wrapped text in Expanded and FittedBox to prevent overflow
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16, // Starting font size, will scale down if needed
                    ),
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
      {"icon": Icons.record_voice_over, "label": "Safety Talks", "page": const SafetyTalksPage(), "colors": [Colors.blue.shade600, Colors.blue.shade800]},
      {"icon": Icons.analytics, "label": "Analytics", "page": const AnalyticsPage(), "colors": [Colors.green.shade600, Colors.green.shade800]},
      {"icon": Icons.dangerous, "label": "Hazard Detection", "page": const HazardDetectionPage(), "colors": [Colors.orange.shade600, Colors.orange.shade800]},
      {"icon": Icons.safety_check, "label": "Safety Sheets", "page": const SafetySheetsPage(), "colors": [Colors.purple.shade600, Colors.purple.shade800]},
      {"icon": Icons.calendar_today, "label": "Calendar", "page": const CalendarPage(), "colors": [Colors.red.shade600, Colors.red.shade800]},
      {"icon": Icons.report_problem, "label": "Incident Reporting", "page": const IncidentReportingPage(), "colors": [Colors.teal.shade600, Colors.teal.shade800]},
      {"icon": Icons.memory, "label": "Virtualization", "page": const VirtualizationPage(), "colors": [Colors.indigo.shade600, Colors.indigo.shade800]},
      {"icon": Icons.contact_phone, "label": "Emergency", "page": const EmergencyContactsPage(), "colors": [Colors.deepOrange.shade600, Colors.deepOrange.shade800]},
      {"icon": Icons.person, "label": "Profile", "page": const UserProfilePage(), "colors": [Colors.cyan.shade600, Colors.cyan.shade800]},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: gridItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.1, // Increased aspect ratio to provide more vertical space
        ),
        itemBuilder: (context, index) {
          final item = gridItems[index];
          return _buildGridItem(
            item['label'] as String,
            item['icon'] as IconData,
            item['page'] as Widget,
            item['colors'] as List<Color>,
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ],
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
      ),
      title: const Text(
        'Dashboard',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
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
    );
  }

  Widget _buildDrawer(BuildContext context, String currentRouteLabel) {
    final drawerItems = [
      {"label": "Home", "icon": Icons.home, "page": const DashboardPage()},
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
          SizedBox(
            height: 200, // Explicitly set height for the header
            child: Stack(
              children: [
                // Background gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Content (Logo and text)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        // Using backgroundImage is the correct way to display an image in CircleAvatar
                        backgroundImage: const AssetImage('assets/logo.png'),
                        onBackgroundImageError: (exception, stackTrace) {
                          // This helps debug if the image path is wrong
                          print('Failed to load logo: $exception');
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Chomene OHSE App",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
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
                      selected: item['label'] == currentRouteLabel,
                      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      selectedColor: Theme.of(context).colorScheme.primary,
                    )),
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
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getGreeting(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      _userName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
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