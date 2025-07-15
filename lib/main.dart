// main.dart
import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/incident_reporting_page.dart';
import 'pages/risk_assessment_page.dart';
import 'pages/training_management_page.dart';
import 'pages/compliance_tracking_page.dart';
import 'pages/hazard_detection_page.dart';
import 'pages/analytics_page.dart';
import 'pages/virtualisation_page.dart';
import 'pages/safety_page.dart';
import 'pages/emergency_page.dart';
import 'pages/safety_talks_page.dart';
import 'pages/calendar.dart';
import 'pages/login_page.dart';
import 'pages/user_profile_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Environmental Safety App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      // ✅ Entry screen (temporary for testing Dashboard directly)
      home: const DashboardPage(),

      // ✅ Define named routes here
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const UserProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/incident': (context) => const IncidentReportingPage(),
        '/risk': (context) => const RiskAssessmentPage(),
        '/training': (context) => const TrainingManagementPage(),
        '/compliance': (context) => const ComplianceTrackingPage(),
        '/hazard': (context) => const HazardDetectionPage(),
        '/analytics': (context) => const AnalyticsPage(),
        '/virtualization': (context) => const VirtualizationPage(),
        '/safety': (context) => const SafetySheetsPage(),
        '/emergency': (context) => const EmergencyPage(),
        '/safety-talks': (context) => const SafetyTalksPage(),
        '/calendar': (context) => const CalendarPage(),
      },

      // ✅ Optional: Handle unknown routes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('404 - Page Not Found')),
        ),
      ),
    );
  }
}
