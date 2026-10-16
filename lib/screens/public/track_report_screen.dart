import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/json.dart';
import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';

/// Check the progress of a public report with its reference number and tracking code.
class TrackReportScreen extends StatefulWidget {
  const TrackReportScreen({super.key});

  @override
  State<TrackReportScreen> createState() => _TrackReportScreenState();
}

class _TrackReportScreenState extends State<TrackReportScreen> {
  final _reference = TextEditingController();
  final _code = TextEditingController();
  List<Agency> _agencies = const [];
  Agency? _agency;
  Json? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.api.agencies().then((list) {
      if (mounted) {
        setState(() {
          _agencies = list;
          if (list.length == 1) _agency = list.first;
        });
      }
    }).catchError((Object e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    });
  }

  Future<void> _track() async {
    if (_agency == null || _reference.text.trim().isEmpty || _code.text.trim().isEmpty) {
      showMessage(context, 'Choose the agency and enter both the reference and the tracking code', error: true);
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final r = await context.api.trackComplaint(_agency!.code, _reference.text, _code.text);
      setState(() => _result = r);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Track a report')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<Agency>(
          initialValue: _agency,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Agency'),
          items: [for (final a in _agencies) DropdownMenuItem(value: a, child: Text(a.name))],
          onChanged: (a) => setState(() => _agency = a),
        ),
        const SizedBox(height: 14),
        TextField(controller: _reference, decoration: const InputDecoration(labelText: 'Reference number (e.g. CMP-1A2B3C4D)')),
        const SizedBox(height: 14),
        TextField(controller: _code, decoration: const InputDecoration(labelText: 'Tracking code')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _track, child: Text(_busy ? 'Checking...' : 'Check progress')),
        if (r != null) ...[
          const SizedBox(height: 20),
          Section(title: 'Progress', trailing: Tag(str(r['status'])), children: [
            InfoRow('Reference', str(r['referenceNumber'])),
            InfoRow('Received', fmtDate(date(r['createdAt'] ?? r['submittedAt']))),
            InfoRow('Last update', fmtDate(date(r['updatedAt']))),
            TextBlock('Status', str(r['statusMessage'])),
            TextBlock('Outcome', str(r['resolution'] ?? r['resolutionNotes'])),
          ]),
        ],
      ]),
    );
  }
}
