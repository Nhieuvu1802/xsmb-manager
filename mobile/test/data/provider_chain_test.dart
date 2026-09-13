import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/data/providers/provider_chain.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';

import '../support/fixtures.dart';
import '../support/scripted_provider.dart';

void main() {
  final start = DateTime.utc(2026, 9, 1);
  final end = DateTime.utc(2026, 9, 3);

  test('nguồn đầu lỗi thì dùng nguồn kế tiếp', () async {
    final primary = ScriptedProvider(
      label: 'primary',
      kind: ProviderKind.backend,
      failure: 'hết thời gian chờ',
    );
    final secondary = ScriptedProvider(
      label: 'secondary',
      kind: ProviderKind.github,
      draws: <DrawRecord>[buildMbRecord('2026-09-03')],
    );
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[primary, secondary],
    );

    final outcome = await chain.fetchRange(
      region: Region.mienBac,
      start: start,
      end: end,
    );

    expect(outcome.hasData, isTrue);
    expect(outcome.usedProvider, 'secondary');
    expect(primary.calls, 1);
    expect(secondary.calls, 1);
    expect(outcome.attempts.first.ok, isFalse);
    expect(outcome.attempts.last.ok, isTrue);
  });

  test('nguồn trả về rỗng cũng bị coi là thất bại', () async {
    final empty = ScriptedProvider(
      label: 'empty',
      kind: ProviderKind.backend,
      draws: const <DrawRecord>[],
    );
    final backup = ScriptedProvider(
      label: 'backup',
      kind: ProviderKind.github,
      draws: <DrawRecord>[buildMbRecord('2026-09-02')],
    );
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[empty, backup],
    );

    final outcome = await chain.fetchByDate(region: Region.mienBac, date: end);

    expect(outcome.usedProvider, 'backup');
    expect(empty.calls, 1);
  });

  test('tất cả nguồn lỗi thì không có kết quả', () async {
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[
        ScriptedProvider(
          label: 'a',
          kind: ProviderKind.backend,
          failure: 'lỗi A',
        ),
        ScriptedProvider(
          label: 'b',
          kind: ProviderKind.github,
          failure: 'lỗi B',
        ),
      ],
    );

    final outcome = await chain.fetchLatest(region: Region.mienBac);

    expect(outcome.result, isNull);
    expect(outcome.hasData, isFalse);
    expect(outcome.attempts.length, 2);
  });

  test('nguồn không khả dụng bị bỏ qua nhưng vẫn được ghi nhận', () async {
    final offline = ScriptedProvider(
      label: 'github-off',
      kind: ProviderKind.github,
      available: false,
      draws: <DrawRecord>[buildMbRecord('2026-09-01')],
    );
    final usable = ScriptedProvider(
      label: 'backend',
      kind: ProviderKind.backend,
      draws: <DrawRecord>[buildMbRecord('2026-09-01')],
    );
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[offline, usable],
    );

    final outcome = await chain.fetchLatest(region: Region.mienBac);

    expect(offline.calls, 0);
    expect(outcome.usedProvider, 'backend');
    expect(outcome.attempts.first.message, 'provider giả');
  });

  test(
    'cache rỗng ở cuối chuỗi vẫn trả outcome để UI biết đang offline',
    () async {
      final cache = ScriptedProvider(
        label: 'cache',
        kind: ProviderKind.cache,
        draws: const <DrawRecord>[],
      );
      final chain = LotteryProviderChain(
        providers: <LotteryDataProvider>[
          ScriptedProvider(
            label: 'backend',
            kind: ProviderKind.backend,
            failure: 'mất mạng',
          ),
          cache,
        ],
      );

      final outcome = await chain.fetchLatest(region: Region.mienNam);

      expect(outcome.result, isNotNull);
      expect(outcome.isEmptySuccess, isTrue);
      expect(outcome.usedProvider, 'cache');
    },
  );

  test('describeSources phản ánh trạng thái từng nguồn', () {
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[
        ScriptedProvider(label: 'backend', kind: ProviderKind.backend),
        ScriptedProvider(
          label: 'github',
          kind: ProviderKind.github,
          available: false,
        ),
      ],
    );

    final sources = chain.describeSources();

    expect(sources.length, 2);
    expect(sources.first.available, isTrue);
    expect(sources.first.kindLabel, 'API của dự án');
    expect(sources.last.available, isFalse);
    expect(sources.last.kindLabel, 'GitHub backup');
  });
}
