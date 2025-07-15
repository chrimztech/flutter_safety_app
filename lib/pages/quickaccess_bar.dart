// pages/quickaccess_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_app_scaffold/pages/compliance_tracking_page.dart';
import 'package:flutter_app_scaffold/pages/risk_assessment_page.dart';
import 'package:flutter_app_scaffold/pages/training_management_page.dart';
import '../../pages/dashboard_page.dart';

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final Widget page;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}

class QuickAccessBar extends StatelessWidget {
  final String currentLabel;

  const QuickAccessBar({
    Key? key,
    required this.currentLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem(icon: Icons.home_outlined, label: 'Home', page: const DashboardPage()),
      _QuickAccessItem(icon: Icons.shield_outlined, label: 'Risk', page: const RiskAssessmentPage()),
      _QuickAccessItem(icon: Icons.school_outlined, label: 'Training', page: const TrainingManagementPage()),
      _QuickAccessItem(icon: Icons.fact_check_outlined, label: 'Compliance', page: const ComplianceTrackingPage()),
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return SafeArea(
      top: false,
      child: Container(
        height: isSmallScreen ? 70 : 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isSelected = item.label == currentLabel;
            return GestureDetector(
              onTap: () {
                if (!isSelected) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => item.page),
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 24,
                    color: isSelected ? Colors.lightBlueAccent : colorScheme.onSurface,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: isSelected ? Colors.blueAccent : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
