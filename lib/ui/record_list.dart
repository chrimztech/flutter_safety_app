import 'package:flutter/material.dart';

import 'widgets.dart';

/// A searchable, filterable list of records loaded from the backend, with pull-to-refresh.
///
/// The backend returns each agency's (or company's) full list, so searching and filtering happen on the device.
class RecordList<T> extends StatefulWidget {
  const RecordList({
    super.key,
    required this.load,
    required this.searchText,
    required this.tile,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    this.filterValues = const [],
    this.filterOf,
    this.filterLabels,
    this.initialFilter,
    this.searchHint = 'Search',
    this.header,
  });

  final Future<List<T>> Function() load;
  final String Function(T item) searchText;
  final Widget Function(BuildContext context, T item, Future<void> Function() reload) tile;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;
  final List<String> filterValues;
  final String Function(T item)? filterOf;
  final Map<String, String>? filterLabels;
  final String? initialFilter;
  final String searchHint;

  /// Optional summary shown above the list (counts etc.).
  final Widget Function(List<T> all)? header;

  @override
  State<RecordList<T>> createState() => RecordListState<T>();
}

class RecordListState<T> extends State<RecordList<T>> {
  final _loader = GlobalKey<LoaderState<List<T>>>();
  String _query = '';
  late String? _filter = widget.initialFilter;

  Future<void> reload() async => _loader.currentState?.reload();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SearchBox(hint: widget.searchHint, onChanged: (v) => setState(() => _query = v.toLowerCase())),
      if (widget.filterValues.isNotEmpty && widget.filterOf != null)
        FilterChips(values: widget.filterValues, selected: _filter, labels: widget.filterLabels, onSelected: (v) => setState(() => _filter = v)),
      Expanded(
        child: Loader<List<T>>(
          key: _loader,
          load: widget.load,
          builder: (context, all, reload) {
            final shown = all.where((item) {
              if (_filter != null && widget.filterOf != null && widget.filterOf!(item).toLowerCase() != _filter!.toLowerCase()) return false;
              return _query.isEmpty || widget.searchText(item).toLowerCase().contains(_query);
            }).toList();
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: shown.length + 1 + (shown.isEmpty ? 1 : 0),
                separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (widget.header != null) widget.header!(all),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Text(
                          shown.length == all.length ? '${all.length} records' : '${shown.length} of ${all.length} records',
                          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                        ),
                      ),
                    ]);
                  }
                  if (shown.isEmpty) {
                    return EmptyView(
                      icon: widget.emptyIcon,
                      title: all.isEmpty ? widget.emptyTitle : 'Nothing matches',
                      message: all.isEmpty ? widget.emptyMessage : 'Try another search or filter.',
                    );
                  }
                  return widget.tile(context, shown[i - 1], reload);
                },
              ),
            );
          },
        ),
      ),
    ]);
  }
}
