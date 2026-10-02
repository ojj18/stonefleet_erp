import 'package:flutter/material.dart';

class PaginationFooter extends StatelessWidget {
  final int currentPage;
  final int rowsPerPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;

  const PaginationFooter({
    super.key,
    required this.currentPage,
    required this.rowsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  int get pageCount => totalItems == 0 ? 1 : (totalItems / rowsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final safePage = currentPage.clamp(1, pageCount).toInt();
    final start = totalItems == 0 ? 0 : ((safePage - 1) * rowsPerPage) + 1;
    final end = totalItems == 0
        ? 0
        : (safePage * rowsPerPage).clamp(0, totalItems).toInt();

    final visiblePages = <int>{};
    for (var i = 1; i <= pageCount && i <= 7; i++) {
      visiblePages.add(i);
    }
    if (pageCount > 7) {
      visiblePages
        ..add((safePage - 1).clamp(1, pageCount).toInt())
        ..add(safePage)
        ..add((safePage + 1).clamp(1, pageCount).toInt())
        ..add(pageCount);
    }
    final pages = visiblePages.toList()..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE1E5E9))),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Text(
            totalItems == 0
                ? 'Showing 0 of 0'
                : 'Showing $start–$end of $totalItems',
            style: const TextStyle(fontSize: 12, color: Color(0xFF68717D)),
          ),
          const Spacer(),
          const Text(
            'Rows per page',
            style: TextStyle(fontSize: 12, color: Color(0xFF68717D)),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: rowsPerPage,
            underline: const SizedBox.shrink(),
            items: const [10, 25, 50, 100]
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onRowsPerPageChanged(value);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Previous',
            onPressed: safePage > 1 ? () => onPageChanged(safePage - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 20),
          ),
          ..._buildPageButtons(pages, safePage, pageCount),
          IconButton(
            tooltip: 'Next',
            onPressed: safePage < pageCount
                ? () => onPageChanged(safePage + 1)
                : null,
            icon: const Icon(Icons.chevron_right, size: 20),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons(List<int> pages, int current, int count) {
    final widgets = <Widget>[];
    int? previous;
    for (final page in pages) {
      if (previous != null && page - previous > 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('…', style: TextStyle(color: Color(0xFF68717D))),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: 34,
            height: 34,
            child: TextButton(
              onPressed: () => onPageChanged(page),
              style: TextButton.styleFrom(
                backgroundColor: page == current
                    ? const Color(0xFFE8F5E9)
                    : Colors.transparent,
                foregroundColor: page == current
                    ? const Color(0xFF00652C)
                    : const Color(0xFF4E5867),
                padding: EdgeInsets.zero,
              ),
              child: Text('$page'),
            ),
          ),
        ),
      );
      previous = page;
    }
    return widgets;
  }
}
