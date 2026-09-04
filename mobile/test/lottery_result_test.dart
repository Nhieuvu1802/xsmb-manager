import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/models/lottery_result.dart';

void main() {
  test('parses API result and computes loto frequency', () {
    final result = LotteryResult.fromJson({
      'draw_date': '2026-09-04',
      'province': 'An Giang',
      'prize': 'Đặc biệt',
      'position': 1,
      'full_number': '123456',
      'loto2': '56',
    });

    expect(result.province, 'An Giang');
    expect(result.toJson()['full_number'], '123456');
    expect(lotoFrequency([result, result]), {'56': 2});
  });
}
