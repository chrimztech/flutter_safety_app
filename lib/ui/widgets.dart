import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import 'format.dart';
import 'theme.dart';

/// A small coloured label for statuses, severities and priorities (the web's .badge).
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
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.32)),
      ),
      child: Text((label ?? humanize(value)).toUpperCase(),
          style: TextStyle(fontFamily: mono, color: c, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
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
    final c = offline ? OhsColors.amber : denied ? OhsColors.text3 : OhsColors.red;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: tintBox(c, radius: 18),
            child: Icon(offline ? Icons.cloud_off : denied ? Icons.lock_outline : Icons.error_outline, size: 32, color: c),
          ),
          const SizedBox(height: 14),
          Text(offline ? 'No connection' : denied ? 'Not available to your account' : 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: OhsColors.text2)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Try again')),
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OhsColors.bg2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OhsColors.border),
          ),
          child: Icon(icon, size: 32, color: OhsColors.text3),
        ),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: OhsColors.text2)),
        ],
      ]),
    );
  }
}

/// A titled panel used on detail screens (the web's .card with a .card-header).
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: EdgeInsets.fromLTRB(16, trailing == null ? 13 : 5, trailing == null ? 16 : 6, trailing == null ? 12 : 5),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: OhsColors.border))),
          child: Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: OhsColors.text1, letterSpacing: -0.1)),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ]),
    );
  }
}

/// "Label ........ value" row (the web's .stat-row); hidden when the value is empty.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.copyable = false});

  final String label;
  final String? value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null || v.trim().isEmpty || v == '—') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: OhsColors.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: OhsColors.text2, fontSize: 13))),
        Expanded(child: SelectableText(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        if (copyable)
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: v));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
            },
            child: const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.copy, size: 16, color: OhsColors.text3)),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontFamily: mono, color: OhsColors.text3, fontSize: 10.5, letterSpacing: 0.6)),
        const SizedBox(height: 4),
        SelectableText(v, style: const TextStyle(height: 1.45, color: OhsColors.text1)),
      ]),
    );
  }
}

/// A tappable figure on dashboards (the web's .kpi-card: accent bar, mono label, large figure, icon chip, corner glow).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? OhsColors.blue;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0)]),
              ),
            ),
          ),
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, color: c)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(label.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: mono, color: OhsColors.text3, fontSize: 9.5, height: 1.25, letterSpacing: 0.5)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: c, size: 16),
                ),
              ]),
              const Spacer(),
              // Scales down rather than overflowing on small screens or with large accessibility text.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: OhsColors.text1)),
              ),
            ]),
          ),
        ]),
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
      return const Text('No records.', style: TextStyle(color: OhsColors.text3));
    }
    final max = items.map((e) => e.value).fold<num>(1, (a, b) => b > a ? b : a);
    final total = items.fold<num>(0, (a, b) => a + b.value);
    return Column(
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(
                  width: 110,
                  child: Text(humanize(i.label), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: OhsColors.text2))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: i.value / max,
                    minHeight: 8,
                    backgroundColor: OhsColors.bg3,
                    color: colorFor?.call(i.label) ?? OhsColors.blue,
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text('${fmtNum(i.value)}  ${total == 0 ? '' : '${(i.value * 100 / total).round()}%'}',
                    textAlign: TextAlign.right, style: const TextStyle(fontFamily: mono, fontSize: 11.5, color: OhsColors.text2)),
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
    const small = TextStyle(fontFamily: mono, fontSize: 9, height: 1.1, color: OhsColors.text3);
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
                    if (e.value > 0) Text(fmtNum(e.value), style: small.copyWith(color: OhsColors.text1)),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: e.value / max,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [OhsColors.blueBright, Color(0xFF236BA9)]),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
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
        decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search)),
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

/// The web's .welcome-banner: a gradient header with an eyebrow, a title and a line of context.
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.eyebrow, required this.title, this.subtitle, this.trailing});

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OhsColors.borderHi),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15365A), Color(0xFF0F2540), Color(0xFF0B1A2D)],
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow.toUpperCase(),
                style: const TextStyle(fontFamily: mono, fontSize: 10, letterSpacing: 1.1, color: OhsColors.blueBright)),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15)),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(subtitle!, style: const TextStyle(color: OhsColors.text2, fontSize: 13, height: 1.35)),
            ],
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ]),
    );
  }
}

/// The web's .btn-primary: a blue gradient, full width, for the main action on a screen.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.onPressed, required this.child, this.height = 50});

  final VoidCallback? onPressed;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: OhsColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OhsColors.blueBright.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: OhsColors.blue.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Center(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.1),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app bar title on the home tabs: the web sidebar's gradient logo mark beside a title and a mono subtitle.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const BrandMark(),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          if (subtitle != null)
            Text(subtitle!.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: mono, fontSize: 9.5, letterSpacing: 0.7, color: OhsColors.text3)),
        ]),
      ),
    ]);
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OhsColors.blue, OhsColors.cyan]),
        boxShadow: [BoxShadow(color: OhsColors.blue.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Icon(Icons.health_and_safety, color: Colors.white, size: size * 0.58),
    );
  }
}

/// A tinted note box (the web's .alert-info / -warning / -danger).
class NoteBox extends StatelessWidget {
  const NoteBox({super.key, required this.color, required this.icon, required this.child, this.action});

  final Color color;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: tintBox(color),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: DefaultTextStyle.merge(style: const TextStyle(color: OhsColors.text1, fontSize: 13, height: 1.35), child: child)),
        if (action != null) action!,
      ]),
    );
  }
}

// ---------------------------------------------------------------- feedback helpers

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: error ? Colors.white : OhsColors.text1)),
      backgroundColor: error ? const Color(0xFFB4374F) : null,
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
      content: Text(message, style: const TextStyle(color: OhsColors.text2)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: const Color(0xFFB4374F)) : null,
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
