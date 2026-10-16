import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import 'format.dart';

/// A small coloured label for statuses, severities and priorities.
class Tag extends StatelessWidget {
  const Tag(this.value, {super.key, this.label, this.color});

  final String? value;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? toneOf(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label ?? humanize(value),
          style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
    );
  }
}

/// Loads data with a spinner, an error with retry, and pull-to-refresh.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder, this.empty});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  /// Shown instead of [builder] when the loaded value is an empty list.
  final Widget? empty;

  @override
  State<Loader<T>> createState() => LoaderState<T>();
}

class LoaderState<T> extends State<Loader<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> reload() async {
    final next = widget.load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // shown by the builder
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return ErrorView(error: snap.error!, onRetry: reload);
        final data = snap.data as T;
        if (widget.empty != null && data is List && data.isEmpty) {
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(children: [const SizedBox(height: 80), widget.empty!]),
          );
        }
        return widget.builder(context, data, reload);
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is ApiException && (error as ApiException).isOffline;
    final denied = error is ApiException && (error as ApiException).isForbidden;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(offline ? Icons.cloud_off : denied ? Icons.lock_outline : Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(offline ? 'No connection' : denied ? 'Not available to your account' : 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
          ],
        ]),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: muted),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, textAlign: TextAlign.center, style: TextStyle(color: muted)),
        ],
      ]),
    );
  }
}

/// A titled card section used on detail screens.
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 0.8, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 8),
          ...children,
        ]),
      ),
    );
  }
}

/// "Label ........ value" row; hidden when the value is empty.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.copyable = false});

  final String label;
  final String? value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null || v.trim().isEmpty || v == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13))),
        Expanded(child: SelectableText(v, style: const TextStyle(fontSize: 14))),
        if (copyable)
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: v));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
            },
            child: const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.copy, size: 16)),
          ),
      ]),
    );
  }
}

/// A paragraph block with a label, for long text such as descriptions and findings.
class TextBlock extends StatelessWidget {
  const TextBlock(this.label, this.value, {super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
        const SizedBox(height: 3),
        SelectableText(v, style: const TextStyle(height: 1.4)),
      ]),
    );
  }
}

/// A tappable figure on dashboards.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: c, size: 22),
            const Spacer(),
            // Scales down rather than overflowing on small screens or with large accessibility text.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12.5, height: 1.2)),
          ]),
        ),
      ),
    );
  }
}

/// Horizontal bars for a {label: count} breakdown.
class BarBreakdown extends StatelessWidget {
  const BarBreakdown({super.key, required this.items, this.colorFor});

  final List<({String label, num value})> items;
  final Color Function(String label)? colorFor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('No records.', style: TextStyle(color: Theme.of(context).colorScheme.outline));
    }
    final max = items.map((e) => e.value).fold<num>(1, (a, b) => b > a ? b : a);
    final total = items.fold<num>(0, (a, b) => a + b.value);
    return Column(
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 110, child: Text(humanize(i.label), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: i.value / max,
                    minHeight: 10,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    color: colorFor?.call(i.label) ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text('${fmtNum(i.value)}  ${total == 0 ? '' : '${(i.value * 100 / total).round()}%'}',
                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
              ),
            ]),
          ),
      ],
    );
  }
}

/// Vertical bars over time (months), sized to the space available so labels never overflow.
class TrendBars extends StatelessWidget {
  const TrendBars({super.key, required this.items, this.height = 130});

  final List<({String label, num value})> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    final max = items.map((e) => e.value).fold<num>(1, (a, b) => b > a ? b : a);
    final small = TextStyle(fontSize: 9.5, height: 1.1, color: Theme.of(context).colorScheme.outline);
    return SizedBox(
      height: height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final e in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(children: [
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (e.value > 0) Text(fmtNum(e.value), style: small.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: e.value / max,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 3),
                Text(e.label, style: small, maxLines: 1, overflow: TextOverflow.clip),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Search box used above lists.
class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.onChanged, this.hint = 'Search'});

  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search), filled: true),
      ),
    );
  }
}

/// Single-choice filter chips ("All" plus each value).
class FilterChips extends StatelessWidget {
  const FilterChips({super.key, required this.values, required this.selected, required this.onSelected, this.labels});

  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final Map<String, String>? labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(label: const Text('All'), selected: selected == null, onSelected: (_) => onSelected(null)),
          ),
          for (final v in values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(labels?[v] ?? humanize(v)),
                selected: selected == v,
                onSelected: (_) => onSelected(selected == v ? null : v),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- feedback helpers

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Runs an action with a progress dialog; shows the server's message on failure. Returns true on success.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    await action();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      if (success != null) showMessage(context, success);
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      showMessage(context, e.toString(), error: true);
    }
    return false;
  }
}

Future<bool> confirm(BuildContext context, String title, String message, {String action = 'Confirm', bool destructive = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a line or paragraph of text (notes, comments). Returns null when cancelled.
Future<String?> askText(BuildContext context, String title, {String? hint, bool required = false, String action = 'Save'}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: required && controller.text.trim().isEmpty ? null : () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(action),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}
