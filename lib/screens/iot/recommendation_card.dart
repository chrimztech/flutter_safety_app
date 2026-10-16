import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../ui/format.dart';
import '../../ui/widgets.dart';

/// An AI prevention recommendation, with actions ordered by the hierarchy of controls.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard(this.r, {super.key});

  final Recommendation r;

  static const _levelIcons = {
    'ELIMINATION': Icons.block,
    'SUBSTITUTION': Icons.swap_horiz,
    'ENGINEERING': Icons.engineering,
    'ADMINISTRATIVE': Icons.assignment_outlined,
    'PPE': Icons.masks_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Tag(r.priority, label: '${humanize(r.priority)} priority'),
            const SizedBox(width: 6),
            Flexible(child: Text(humanize(r.category), style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.outline))),
            if (r.confidence != null) ...[
              const Spacer(),
              Text('${(r.confidence! * 100).round()}% confidence', style: const TextStyle(fontSize: 11.5)),
            ],
          ]),
          const SizedBox(height: 8),
          Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(r.rationale, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (r.actions.isNotEmpty) const SizedBox(height: 8),
          for (final a in r.actions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_levelIcons[a.level.toUpperCase()] ?? Icons.check_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${humanize(a.level)}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: a.action),
                  ])),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}
