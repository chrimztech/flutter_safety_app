import 'package:flutter/material.dart';

import '../../app/context_ext.dart';
import '../../data/fields.dart';
import '../../data/json.dart';
import '../../ui/dynamic_form.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';

/// The inspectorate's reviews of a record the company keeps itself. Companies read them; OHS staff add one
/// (accepted, changes requested with what to change, or noted) and the company is notified.
class ReviewSection extends StatefulWidget {
  const ReviewSection({super.key, required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  late Future<List<Json>> _reviews = _load();

  Future<List<Json>> _load() => context.api.list('reviews', query: {'entityType': widget.entityType, 'entityId': widget.entityId});

  static const _labels = {'ACCEPTED': 'Accepted', 'CHANGES_REQUESTED': 'Changes requested', 'NOTED': 'Noted'};

  Future<void> _add() async {
    final api = context.api;
    final saved = await context.push<Object?>(FormScreen(
      title: 'Regulator review',
      intro: 'The company is notified. Ask for changes when the record does not meet the requirements.',
      sections: const [
        FieldSection('', '', '', [
          FieldSpec('status', 'Outcome', FieldKind.choice, required: true, initial: 'ACCEPTED',
              options: [('ACCEPTED', 'Accepted'), ('CHANGES_REQUESTED', 'Changes requested'), ('NOTED', 'Noted')]),
          FieldSpec('comment', 'Comment', FieldKind.multiline, help: 'Required when asking for changes: say what the company must change'),
        ]),
      ],
      submitLabel: 'Record review',
      onSubmit: (p) => api.create('reviews', {...p, 'entityType': widget.entityType, 'entityId': widget.entityId}),
    ));
    if (saved != null && mounted) {
      showMessage(context, 'Review recorded');
      setState(() => _reviews = _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.me.isStaff;
    return Section(
      title: 'Regulator review',
      trailing: staff ? TextButton.icon(onPressed: _add, icon: const Icon(Icons.rate_review_outlined, size: 18), label: const Text('Review')) : null,
      children: [
        FutureBuilder<List<Json>>(
          future: _reviews,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
            if (snap.hasError) return Text(snap.error.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error));
            final list = snap.data!;
            if (list.isEmpty) {
              return Text('Not reviewed by the inspectorate yet.', style: TextStyle(color: Theme.of(context).colorScheme.outline));
            }
            return Column(children: [
              for (final r in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Tag(text(r['status']) == 'ACCEPTED' ? 'LOW' : text(r['status']) == 'CHANGES_REQUESTED' ? 'HIGH' : 'REPORTED',
                      label: _labels[text(r['status'])] ?? text(r['status'])),
                  title: Text(text(r['comment'], 'No comment')),
                  subtitle: Text('${text(r['reviewerName'])} · ${fmtDateTime(date(r['reviewedAt']))}'),
                ),
            ]);
          },
        ),
      ],
    );
  }
}
