import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsmb_manager/main.dart';
import 'package:xsmb_manager/src/data/local/web_local_store.dart';
import 'package:xsmb_manager/src/data/models/draw_record.dart';
import 'package:xsmb_manager/src/data/models/sync_report.dart';
import 'package:xsmb_manager/src/data/providers/local_cache_provider.dart';
import 'package:xsmb_manager/src/data/providers/lottery_data_provider.dart';
import 'package:xsmb_manager/src/data/providers/provider_chain.dart';
import 'package:xsmb_manager/src/data/repositories/lottery_repository.dart';
import 'package:xsmb_manager/src/domain/lottery_domain.dart';
import 'package:xsmb_manager/src/ui/widgets.dart';

import '../support/fixtures.dart';
import '../support/scripted_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Repository có sẵn 60 kỳ XSMB để tab "Bộ tính số" có lịch sử thật.
  Future<LotteryRepository> buildRepository({int days = 60}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = WebLocalStore();
    await store.open();
    final end = DateTime.utc(2026, 9, 12);
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[
        ScriptedProvider(
          label: 'provider-test',
          kind: ProviderKind.backend,
          draws: <DrawRecord>[
            for (var offset = days - 1; offset >= 0; offset -= 1)
              buildMbRecord(
                isoOf(end.subtract(Duration(days: offset))),
                seed: 5 + offset * 7919,
              ),
          ],
        ),
        LocalCacheProvider(store: store),
      ],
      store: store,
    );
    return LotteryRepository(store: store, chain: chain);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Mở tab qua ngăn kéo điều hướng (màn hình hẹp không có sidebar).
  Future<void> openSetsTab(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu));
    await settle(tester);
    await tester.tap(find.text('Bộ tính số').last);
    await settle(tester);
  }

  /// Gọi trực tiếp callback của nút theo nhãn.
  ///
  /// Nút có thể nằm ngoài vùng nhìn thấy sau khi trường nhập liệu tự cuộn, nên
  /// gọi callback ổn định hơn là mô phỏng chạm toạ độ.
  Future<void> pressButton(WidgetTester tester, String label) async {
    final finder = find.byWidgetPredicate(
      (widget) => widget is AppButton && widget.label == label,
    );
    expect(finder, findsWidgets, reason: 'Không thấy nút "$label"');
    final button = tester.widget<AppButton>(finder.first);
    button.onPressed?.call();
    await settle(tester);
  }

  testWidgets('tab Bộ tính số sinh bộ số và đối chiếu lịch sử', (tester) async {
    final repository = await buildRepository();
    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: true),
    );
    await settle(tester);
    await openSetsTab(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Sinh bộ số theo lịch sử'), findsOneWidget);
    expect(find.textContaining('Chưa sinh bộ số'), findsOneWidget);

    await pressButton(tester, 'Sinh bộ số');

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Chưa sinh bộ số'), findsNothing);
    expect(find.text('Bộ số so với kỳ vọng lý thuyết'), findsOneWidget);
    expect(find.textContaining('Bộ 1'), findsWidgets);
    expect(
      find.textContaining('bộ nằm trong khoảng tin cậy 95%'),
      findsOneWidget,
    );
  });

  testWidgets('cấu hình sai hiện thông báo thay vì sinh bộ số', (tester) async {
    final repository = await buildRepository();
    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: false),
    );
    await settle(tester);
    await openSetsTab(tester);

    await tester.enterText(find.byType(TextField).first, 'abc, xyz');
    await pressButton(tester, 'Sinh bộ số');
    expect(find.textContaining('Số loại trừ không hợp lệ'), findsOneWidget);

    final all = <String>[
      for (var value = 0; value < 100; value += 1)
        value.toString().padLeft(2, '0'),
    ].join(', ');
    await tester.enterText(find.byType(TextField).first, all);
    await pressButton(tester, 'Sinh bộ số');
    expect(tester.takeException(), isNull);
    expect(find.textContaining('chỉ còn 0 số'), findsOneWidget);
  });

  testWidgets('lưu lần sinh vào database rồi nạp lại đúng cấu hình + seed', (
    tester,
  ) async {
    final repository = await buildRepository();
    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: true),
    );
    await settle(tester);
    await openSetsTab(tester);

    await pressButton(tester, 'Sinh bộ số');

    await pressButton(tester, 'Lưu vào lịch sử');

    final saved = await repository.recentGeneratedRuns(region: Region.mienBac);
    expect(saved.length, 1);
    expect(saved.single.sets.length, saved.single.settings.setCount);
    expect(saved.single.seed, greaterThanOrEqualTo(0));

    expect(find.text('Các lần sinh đã lưu'), findsOneWidget);
    await pressButton(tester, 'Nạp lại cấu hình + seed');

    expect(tester.takeException(), isNull);
    expect(find.textContaining('seed ${saved.single.seed}'), findsWidgets);
  });
}
