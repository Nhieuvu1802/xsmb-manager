import 'package:flutter/material.dart';

import '../models/lottery_result.dart';

const _prizeOrder = [
  'Đặc biệt',
  'Giải nhất',
  'Giải nhì',
  'Giải ba',
  'Giải tư',
  'Giải năm',
  'Giải sáu',
  'Giải bảy',
  'Giải tám',
];

class ResultBoard extends StatelessWidget {
  const ResultBoard({required this.results, super.key});

  final List<LotteryResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Chưa có kết quả trong khoảng ngày đã chọn.'),
        ),
      );
    }
    final groups = <String, List<LotteryResult>>{};
    for (final result in results) {
      final key = '${result.drawDate}|${result.province ?? ''}';
      groups.putIfAbsent(key, () => []).add(result);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final group = groups[keys[index]]!;
        return _DrawCard(results: group, initiallyExpanded: index == 0);
      },
    );
  }
}

class _DrawCard extends StatelessWidget {
  const _DrawCard({required this.results, required this.initiallyExpanded});

  final List<LotteryResult> results;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final first = results.first;
    final title = first.province == null
        ? 'XSMB · ${_displayDate(first.drawDate)}'
        : '${first.province} · ${_displayDate(first.drawDate)}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${results.length} giải/số đã lưu'),
        children: [
          for (final prize in _prizeOrder)
            if (results.any((result) => result.prize == prize))
              _PrizeRow(
                prize: prize,
                values:
                    (results.where((result) => result.prize == prize).toList()
                          ..sort((a, b) => a.position.compareTo(b.position)))
                        .map((result) => result.fullNumber)
                        .toList(),
              ),
        ],
      ),
    );
  }

  String _displayDate(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.prize, required this.values});

  final String prize;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final special = prize == 'Đặc biệt';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: special ? Theme.of(context).colorScheme.errorContainer : null,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              prize,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final value in values)
                  Text(
                    value,
                    style: TextStyle(
                      color:
                          special ? Theme.of(context).colorScheme.error : null,
                      fontSize: special ? 24 : 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
