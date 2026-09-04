import 'package:flutter/material.dart';

class DateFilter extends StatelessWidget {
  const DateFilter({
    required this.start,
    required this.end,
    required this.loading,
    required this.onChange,
    required this.onRefresh,
    super.key,
  });

  final DateTime start;
  final DateTime end;
  final bool loading;
  final void Function(DateTime start, DateTime end) onChange;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'Từ ngày',
                value: start,
                firstDate: DateTime(2000),
                lastDate: end,
                onSelected: (value) => onChange(value, end),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateButton(
                label: 'Đến ngày',
                value: end,
                firstDate: start,
                lastDate: DateTime.now(),
                onSelected: (value) => onChange(start, value),
              ),
            ),
            IconButton.filled(
              tooltip: 'Tra cứu',
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onSelected,
  });

  final String label;
  final DateTime value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (selected != null) onSelected(selected);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(_format(value)),
        ],
      ),
    );
  }

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
