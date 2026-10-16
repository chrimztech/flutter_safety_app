import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';

/// Searchable company selector for officers (the agency's registered companies).
class CompanyPicker extends StatelessWidget {
  const CompanyPicker({super.key, required this.value, required this.onChanged, this.label = 'Company *'});

  final CompanyRef? value;
  final ValueChanged<CompanyRef?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<CompanyRef>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _CompanySearchSheet(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.arrow_drop_down)),
        child: Text(value?.name ?? 'Choose a company', style: value == null ? TextStyle(color: Theme.of(context).hintColor) : null),
      ),
    );
  }
}

class _CompanySearchSheet extends StatefulWidget {
  const _CompanySearchSheet();

  @override
  State<_CompanySearchSheet> createState() => _CompanySearchSheetState();
}

class _CompanySearchSheetState extends State<_CompanySearchSheet> {
  late final Future<List<Company>> _companies = context.api.companies();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search companies', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Company>>(
            future: _companies,
            builder: (context, snap) {
              if (!snap.hasData) {
                return snap.hasError ? Center(child: Text(snap.error.toString())) : const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!
                  .where((c) => '${c.name} ${c.registrationNumber ?? ''} ${c.district ?? ''}'.toLowerCase().contains(_q))
                  .toList();
              return ListView.builder(
                controller: scroll,
                itemCount: list.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(list[i].name),
                  subtitle: Text([list[i].registrationNumber, list[i].district, list[i].sector].whereType<String>().join(' · ')),
                  onTap: () => Navigator.pop(context, CompanyRef(list[i].id, list[i].name)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
