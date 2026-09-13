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

import 'support/fixtures.dart';
import 'support/scripted_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LotteryRepository> buildRepository() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = WebLocalStore();
    await store.open();
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[
        ScriptedProvider(
          label: 'provider-test',
          kind: ProviderKind.backend,
          draws: <DrawRecord>[
            buildMbRecord('2026-09-09'),
            buildMbRecord('2026-09-10'),
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

  testWidgets('ứng dụng khởi động, đồng bộ và hiển thị điều hướng', (
    tester,
  ) async {
    final repository = await buildRepository();

    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: true),
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Top 4'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(await repository.store.countDraws(Region.mienBac), 2);
  });

  testWidgets('chuyển sang tab Top 4 hiển thị bảng xếp hạng', (tester) async {
    final repository = await buildRepository();

    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: false),
    );
    await settle(tester);

    await tester.tap(find.text('Top 4').last);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('TOP 4'), findsWidgets);
  });

  testWidgets('tab Nguồn & cài đặt hiển thị trạng thái database', (
    tester,
  ) async {
    final repository = await buildRepository();

    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: true),
    );
    await settle(tester);

    await tester.tap(find.text('Nguồn & cài đặt').last);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('SQLite'), findsNothing);
    expect(find.textContaining('localStorage'), findsWidgets);
  });

  testWidgets('thẻ tình trạng hệ thống hiển thị nguồn và phiên bản app', (
    tester,
  ) async {
    final repository = await buildRepository();

    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: true),
    );
    await settle(tester);

    await tester.tap(find.text('Nguồn & cài đặt').last);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Tình trạng hệ thống'), findsOneWidget);
    expect(find.text('Ngoại tuyến · Bộ nhớ máy (offline)'), findsOneWidget);
    expect(find.text('Offline'), findsWidgets);
    expect(find.textContaining('localStorage của trình duyệt'), findsWidgets);
    expect(find.text('2.0.0+local'), findsOneWidget);
    expect(find.text('Kiểm tra lại trạng thái'), findsOneWidget);
    expect(
      find.textContaining('Đang dùng dữ liệu ngoại tuyến'),
      findsOneWidget,
    );
  });

  testWidgets('chưa có cache và nguồn lỗi: tổng quan hiện trạng thái trống', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = WebLocalStore();
    await store.open();
    final chain = LotteryProviderChain(
      providers: <LotteryDataProvider>[
        ScriptedProvider(
          label: 'provider-test',
          kind: ProviderKind.backend,
          failure: 'mất mạng',
        ),
        LocalCacheProvider(store: store),
      ],
      store: store,
    );
    final repository = LotteryRepository(store: store, chain: chain);

    await tester.pumpWidget(
      ThongKe24App(repository: repository, initialIsDark: false),
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Chưa có kỳ quay nào cho khu vực đã chọn.'), findsOneWidget);
    expect(find.textContaining('vẫn hiển thị được khi mất mạng'), findsOneWidget);
    expect(await repository.store.countDraws(Region.mienBac), 0);
  });
}
