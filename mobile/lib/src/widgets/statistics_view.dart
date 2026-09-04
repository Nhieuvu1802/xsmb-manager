import 'package:flutter/material.dart';

import '../models/lottery_result.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({
    required this.results,
    required this.regionLabel,
    super.key,
  });

  final List<LotteryResult> results;
  final String regionLabel;

  @override
  Widget build(BuildContext context) {
    final entries = lotoFrequency(results).entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value) != 0
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    final top = entries.take(20).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tần suất $regionLabel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text('${results.length} số trong khoảng đang chọn'),
              ],
            ),
          ),
        ),
        if (top.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Chưa đủ dữ liệu để thống kê.')),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < top.length; index++)
                    SizedBox(
                      width: 74,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              Text(
                                '#${index + 1}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                top[index].key,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text('${top[index].value} lần'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tần suất chỉ mô tả dữ liệu lịch sử, không phải cam kết hoặc xác suất trúng trong tương lai.',
            ),
          ),
        ),
      ],
    );
  }
}
