// pages/emergency_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// Assuming quickaccess_bar.dart is in the same 'widgets' directory
// If not, adjust the path (e.g., 'package:your_app_name/widgets/quickaccess_bar.dart')
import 'quickaccess_bar.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  // Data structure for an emergency contact category
  // NOTE: The 'final' keyword allows us to have a list whose contents
  // are created at runtime, even if the elements within the list are const.
  // This resolves the "Arguments of a constant creation must be constant expressions"
  // when using methods like .shadeXXX directly in the list definition.
  static final List<EmergencyCategory> _emergencyCategories = [
    EmergencyCategory(
      name: 'General Emergency Services (Zambia)',
      icon: Icons.call,
      color: Colors.red, // This is a MaterialColor, which is a subtype of Color
      contacts: [
        const _EmergencyContact('Police Emergency', '999', Icons.local_police, Colors.blue),
        const _EmergencyContact('Fire Brigade', '993', Icons.local_fire_department, Colors.red),
        const _EmergencyContact('Ambulance (Medical Emergency)', '991', Icons.medical_services, Colors.green),
      ],
    ),
    EmergencyCategory(
      name: 'Environmental Authorities',
      icon: Icons.eco,
      color: Colors.lightGreen,
      contacts: [
        const _EmergencyContact('ZEMA (Environmental Management)', '+260211254023', Icons.nature_people, Colors.green),
        const _EmergencyContact('Water Utilities (Lusaka)', '+260211252192', Icons.water, Colors.blue),
        const _EmergencyContact('Disaster Management Unit', '+260211251910', Icons.crisis_alert, Colors.orange),
      ],
    ),
    EmergencyCategory(
      name: 'Internal Company/Site Contacts',
      icon: Icons.business,
      color: Colors.blueGrey,
      contacts: [
        // FIX: Replaced Icons.person_safe with a valid icon (Icons.security)
        // FIX: Used Colors.deepOrange.shade700 directly as a const Color
        const _EmergencyContact('Site Safety Officer', '555-1234', Icons.security, Colors.deepOrange),
        const _EmergencyContact('Environmental Manager', '555-5678', Icons.nature_sharp, Colors.green),
        const _EmergencyContact('Facility Manager', '555-9012', Icons.apartment, Colors.purple),
      ],
    ),
    EmergencyCategory(
      name: 'Specialized Response Teams',
      icon: Icons.construction,
      color: Colors.brown,
      contacts: [
        const _EmergencyContact('Hazardous Waste Disposal (Example)', '555-3333', Icons.delete_sweep, Colors.brown),
        const _EmergencyContact('Oil Spill Response (Example)', '555-4444', Icons.oil_barrel, Colors.grey),
      ],
    ),
  ];

  Future<void> _callNumber(BuildContext context, String number) async {
    // Clean number to ensure only digits and '+' are passed to the dialer
    final uri = Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^\d+]'), ''));
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch dialer for $number. Please dial manually.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: Could not launch dialer for $number. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Environmental Emergency Contacts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800, // Stronger, professional color
        elevation: 6,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Critical Link in Environmental Safety',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'In environmental emergencies, rapid and accurate communication is paramount. These contacts ensure immediate response, mitigation, and compliance to protect both people and the planet.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Divider(height: 30, thickness: 1.5, indent: 20, endIndent: 20),
            const SizedBox(height: 16),

            // "What to do" section
            _buildInfoPanel(
              context,
              'Before You Call: Initial Actions',
              Icons.warning_amber,
              Colors.amber, // Use base Color, will be shaded in _buildInfoPanel
              [
                '**Ensure Personal Safety First:** Do not put yourself at risk.',
                '**Isolate the Area:** If safe to do so, prevent further spread.',
                '**Identify the Hazard:** What spilled? How much? Where?',
                '**Note the Location:** Be precise (address, landmarks).',
                '**Stay Calm:** Speak clearly and provide all details requested.',
              ],
            ),
            const SizedBox(height: 24),

            // Dynamically build contact categories
            ..._emergencyCategories.map((category) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    leading: Icon(
                        category.icon,
                        // Safely try to get a shade if it's a MaterialColor, otherwise use the base color
                        color: (category.color is MaterialColor)
                            ? (category.color as MaterialColor).shade800
                            : category.color,
                        size: 30),
                    title: Text(
                      category.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            // Safely try to get a shade if it's a MaterialColor, otherwise use the base color
                            color: (category.color is MaterialColor)
                                ? (category.color as MaterialColor).shade900
                                : category.color,
                          ),
                    ),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    children: category.contacts.map((contact) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _buildContactTile(context, contact),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Emergency'), // Uncommented for consistency
    );
  }

  // Helper function to build individual contact tiles
  Widget _buildContactTile(BuildContext context, _EmergencyContact contact) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: contact.color.withOpacity(0.15),
        radius: 24,
        child: Icon(
            contact.icon,
            // Safely try to get a shade if it's a MaterialColor, otherwise use the base color
            color: (contact.color is MaterialColor)
                ? (contact.color as MaterialColor).shade700
                : contact.color,
            size: 28),
      ),
      title: Text(
        contact.name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.number,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (contact.description != null)
            Text(
              contact.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
      trailing: ElevatedButton.icon(
        onPressed: () => _callNumber(context, contact.number),
        icon: const Icon(Icons.call, size: 20),
        label: const Text('Call', style: TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: contact.color,
          foregroundColor: Colors.white, // Text color for the button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 3,
        ),
      ),
    );
  }

  // Helper function to build an information panel (e.g., "Before You Call")
  Widget _buildInfoPanel(
      BuildContext context, String title, IconData icon, Color color, List<String> bulletPoints) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          // Safely try to get a shade if it's a MaterialColor, otherwise use the base color
                          color: (color is MaterialColor)
                              ? (color as MaterialColor).shade800
                              : color,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.8),
            // Parse Markdown for bold text
            ...bulletPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildMarkdownText(context, point),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Helper to parse simple markdown (bold) for bullet points
  Widget _buildMarkdownText(BuildContext context, String text) {
    final List<TextSpan> spans = [];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: Theme.of(context).textTheme.bodyMedium),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: spans,
              style: Theme.of(context).textTheme.bodyMedium, // Default style
            ),
          ),
        ),
      ],
    );
  }
}

// Data class for an emergency contact
class _EmergencyContact {
  final String name;
  final String number;
  final IconData icon;
  final Color color; // Remains Color for flexibility
  final String? description;

  // Now, _EmergencyContact can be const if all its arguments are const.
  // Colors.deepOrange and Colors.deepOrange.shade700 are both const Colors,
  // so this constructor remains 'const'.
  const _EmergencyContact(this.name, this.number, this.icon, this.color, {this.description});
}

// Data class for an emergency contact category
class EmergencyCategory {
  final String name;
  final IconData icon;
  final Color color; // Remains Color for flexibility
  final List<_EmergencyContact> contacts;

  // EmergencyCategory can also be const if all its arguments (including the list of contacts) are const.
  const EmergencyCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.contacts,
  });
}