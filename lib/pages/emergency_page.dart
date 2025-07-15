import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  static const List<_EmergencyContact> _contacts = [
    _EmergencyContact('Fire Department', '101', Icons.local_fire_department, Colors.red),
    _EmergencyContact('Police', '999', Icons.local_police, Colors.blue),
    _EmergencyContact('Ambulance', '102', Icons.medical_services, Colors.green),
    _EmergencyContact('Safety Officer', '555-1234', Icons.person, Colors.orange),
  ];

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color.fromRGBO(9, 28, 197, 1),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: contact.color.withOpacity(0.2),
                child: Icon(contact.icon, color: contact.color),
              ),
              title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(contact.number),
              trailing: ElevatedButton.icon(
                onPressed: () => _callNumber(contact.number),
                icon: const Icon(Icons.call),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: contact.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyContact {
  final String name;
  final String number;
  final IconData icon;
  final Color color;
  const _EmergencyContact(this.name, this.number, this.icon, this.color);
}
