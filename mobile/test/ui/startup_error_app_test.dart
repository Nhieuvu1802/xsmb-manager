/// Test cho lưới an toàn chống "màn hình trắng".
///
/// Lỗi thật đã gặp: `main()` ném exception trước `runApp()` (SQLite mở thất bại)
/// nên Windows không có frame Flutter nào ⇒ người dùng chỉ thấy nền trắng và
/// không có thông tin gì. Các test dưới đây chốt hành vi: lỗi khởi động phải
/// hiện thành chữ đọc được, có nút thử lại, và khôi phục được khi thử lại.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/ui/startup_error_app.dart';

void main() {
  testWidgets('lỗi khởi động hiện thành màn hình đọc được', (tester) async {
    await tester.pumpWidget(
      StartupFailureApp(
        error: StateError('không mở được SQLite (xsmb_manager.db)'),
        stackTrace: StackTrace.current,
        bootstrap: () async =>
            const MaterialApp(home: Scaffold(body: Text('giao diện chính'))),
      ),
    );

    expect(find.text('Không khởi động được'), findsOneWidget);
    expect(
      find.textContaining('không mở được SQLite'),
      findsWidgets,
      reason:
          'Nguyên nhân phải hiện cho người dùng (release không có red screen)',
    );
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('thử lại thành công thì hiện giao diện chính', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      StartupFailureApp(
        error: StateError('lần đầu lỗi'),
        stackTrace: StackTrace.current,
        bootstrap: () async {
          attempts += 1;
          return const MaterialApp(
            home: Scaffold(body: Text('giao diện chính')),
          );
        },
      ),
    );

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(find.text('giao diện chính'), findsOneWidget);
    expect(find.text('Không khởi động được'), findsNothing);
  });

  testWidgets('thử lại vẫn lỗi thì cập nhật thông báo mới', (tester) async {
    await tester.pumpWidget(
      StartupFailureApp(
        error: StateError('lỗi lần 1'),
        stackTrace: StackTrace.current,
        bootstrap: () async => StartupFailureApp(
          error: StateError('lỗi lần 2'),
          stackTrace: StackTrace.current,
          bootstrap: () async => throw StateError('không dùng tới'),
        ),
      ),
    );

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.textContaining('lỗi lần 2'), findsWidgets);
    expect(find.textContaining('lỗi lần 1'), findsNothing);
  });

  testWidgets('bootstrap ném lỗi thì hiện lỗi đó, không treo app', (
    tester,
  ) async {
    await tester.pumpWidget(
      StartupFailureApp(
        error: StateError('lỗi gốc'),
        stackTrace: StackTrace.current,
        bootstrap: () async => throw ArgumentError('bootstrap nổ'),
      ),
    );

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.textContaining('bootstrap nổ'), findsWidgets);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
