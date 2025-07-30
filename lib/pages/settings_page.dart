// pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs like privacy policy
 
// For demonstration, let's create a simple state management for theme.
// In a real app, you'd use Provider, Riverpod, BLoC, GetX, etc.
// For now, we'll use a StatefulWidget to manage theme locally.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Example settings values (these would typically come from a persistent storage like SharedPreferences)
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false; // Initial state, will be updated by Theme.of(context).brightness
  bool _hapticFeedbackEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize dark mode based on the current theme brightness
    _darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
  }

  // Function to simulate changing the theme (in a real app, this would update your app's theme provider)
  void _toggleTheme(bool newValue) {
    setState(() {
      _darkModeEnabled = newValue;
      // In a real app, you'd notify your app's theme provider here
      // Example: Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      // For this demo, we can just show a snackbar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_darkModeEnabled ? 'Dark mode enabled (UI only)' : 'Light mode enabled (UI only)'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
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
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor, // Use app's primary color
        elevation: 6,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // General Settings Section
          _buildSectionHeader(context, 'General', Icons.settings),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive alerts for important updates and reminders.'),
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                      // Logic to save setting
                    });
                  },
                  activeColor: theme.primaryColor,
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch to a darker theme for less eye strain.'),
                  value: _darkModeEnabled,
                  onChanged: _toggleTheme, // Call our custom toggle function
                  activeColor: theme.primaryColor,
                ),
                SwitchListTile(
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Enable subtle vibrations on interaction.'),
                  value: _hapticFeedbackEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _hapticFeedbackEnabled = value;
                      // Logic to save setting
                    });
                  },
                  activeColor: theme.primaryColor,
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: const Text('English (US)'), // Placeholder
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language settings coming soon!')),
                    );
                    // Navigate to language selection page
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data & Privacy Section
          _buildSectionHeader(context, 'Data & Privacy', Icons.security),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Privacy Policy'),
                  onTap: () => _launchURL('https://www.example.com/privacy'), // Replace with actual URL
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  onTap: () => _launchURL('https://www.example.com/terms'), // Replace with actual URL
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Clear Cache'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared! (Simulated)')),
                    );
                    // Logic to clear app cache
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About Section
          _buildSectionHeader(context, 'About', Icons.info),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App Version'),
                  trailing: Text('1.0.0 (Build 20250730)'), // Dynamic version from pubspec.yaml
                ),
                ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Developed by'),
                  trailing: Text('Your Company/Name'),
                ),
                ListTile(
                  leading: Icon(Icons.copyright),
                  title: Text('Copyright'),
                  trailing: Text('© 2025'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Made with ❤️ in Lusaka, Zambia',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary, // Using primary color for headers
                ),
          ),
        ],
      ),
    );
  }
}