import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/models.dart';
import '../../ui/widgets.dart';

/// Report a safety concern without an account. The reporter receives a reference number and a tracking code.
class PublicReportScreen extends StatefulWidget {
  const PublicReportScreen({super.key});

  @override
  State<PublicReportScreen> createState() => _PublicReportScreenState();
}

class _PublicReportScreenState extends State<PublicReportScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  List<Agency>? _agencies;
  List<CompanyRef> _companies = const [];
  Agency? _agency;
  String _urgency = 'normal';
  bool _anonymous = true;
  bool _busy = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  Future<void> _loadAgencies() async {
    try {
      final list = await context.api.agencies();
      setState(() {
        _agencies = list;
        _loadError = null;
        if (list.length == 1) _selectAgency(list.first);
      });
    } catch (e) {
      setState(() => _loadError = e);
    }
  }

  Future<void> _selectAgency(Agency? a) async {
    setState(() {
      _agency = a;
      _companies = const [];
    });
    if (a == null) return;
    try {
      final list = await context.api.publicCompanies(a.code);
      if (mounted && _agency == a) setState(() => _companies = list);
    } catch (_) {
      // The company can still be typed in.
    }
  }

  Future<void> _submit() async {
    if (_agency == null) {
      showMessage(context, 'Choose the agency to report to', error: true);
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final r = await context.api.submitPublicComplaint(
        _agency!.code,
        description: _description.text.trim(),
        urgency: _urgency,
        companyName: _company.text.trim(),
        location: _location.text.trim(),
        anonymous: _anonymous,
        name: _name.text.trim(),
        contact: _contact.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          title: const Text('Report received'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.message),
            const SizedBox(height: 12),
            InfoRow('Reference', r.reference, copyable: true),
            InfoRow('Tracking code', r.trackingCode, copyable: true),
            InfoRow('Agency', _agency!.name),
            const SizedBox(height: 8),
            const Text('Write these down — you need both to check progress. They are not shown again.', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a safety concern')),
      body: _loadError != null
          ? ErrorView(error: _loadError!, onRetry: _loadAgencies)
          : _agencies == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _form,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    const Text('Tell the Occupational Health and Safety inspectorate about unsafe conditions at a workplace. '
                        'You can stay anonymous; your employer will not be told who reported.'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Agency>(
                      initialValue: _agency,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Agency *'),
                      items: [for (final a in _agencies!) DropdownMenuItem(value: a, child: Text('${a.name}${a.country == null ? '' : ' (${a.country})'}'))],
                      onChanged: _selectAgency,
                    ),
                    const SizedBox(height: 14),
                    Autocomplete<String>(
                      optionsBuilder: (v) => v.text.isEmpty
                          ? const Iterable<String>.empty()
                          : _companies.map((c) => c.name).where((n) => n.toLowerCase().contains(v.text.toLowerCase())),
                      onSelected: (v) => _company.text = v,
                      fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
                        controller: controller,
                        focusNode: focus,
                        onChanged: (v) => _company.text = v,
                        decoration: const InputDecoration(labelText: 'Workplace / company', helperText: 'Start typing to pick a registered company'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Where (site, town)')),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _description,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(labelText: 'What is the problem? *', alignLabelWithHint: true),
                      validator: (v) => (v ?? '').trim().length < 10 ? 'Please describe the concern (at least 10 characters)' : null,
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'normal', label: Text('Normal')),
                        ButtonSegment(value: 'high', label: Text('Urgent')),
                        ButtonSegment(value: 'critical', label: Text('Danger to life')),
                      ],
                      selected: {_urgency},
                      onSelectionChanged: (s) => setState(() => _urgency = s.first),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _anonymous,
                      onChanged: (v) => setState(() => _anonymous = v),
                      title: const Text('Stay anonymous'),
                      subtitle: const Text('Turn off to give contact details so an inspector can follow up with you'),
                    ),
                    if (!_anonymous) ...[
                      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Your name')),
                      const SizedBox(height: 14),
                      TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Phone or email')),
                      const SizedBox(height: 14),
                    ],
                    if (_urgency == 'critical')
                      const Card(
                        color: Color(0xFFFFEBEE),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('If someone is in immediate danger, call emergency services first.'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: Text(_busy ? 'Sending...' : 'Send report'),
                    ),
                  ]),
                ),
    );
  }
}
