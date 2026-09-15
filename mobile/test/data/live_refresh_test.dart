import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/core/utils/lottery_dates.dart';

void main() {
  test('poll 45 giây trong giờ quay Việt Nam', () {
    expect(
      liveRefreshInterval(now: DateTime.utc(2026, 9, 15, 10, 30)),
      const Duration(seconds: 45),
    );
  });

  test('giảm còn mỗi 30 phút ngoài giờ quay', () {
    expect(
      liveRefreshInterval(now: DateTime.utc(2026, 9, 15, 2)),
      const Duration(minutes: 30),
    );
  });
}
