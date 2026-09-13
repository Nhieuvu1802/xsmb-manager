import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/data/providers/xoso_html_parser.dart';

/// Sinh HTML XSMB mô phỏng đúng cấu trúc `id="mb_prizeXX_itemN"`.
String buildMbHtml(Map<String, List<String>> prizes) {
  const codes = <String, String>{
    'Đặc biệt': 'DB',
    'Giải nhất': '1',
    'Giải nhì': '2',
    'Giải ba': '3',
    'Giải tư': '4',
    'Giải năm': '5',
    'Giải sáu': '6',
    'Giải bảy': '7',
  };
  final buffer = StringBuffer('<table><tbody>');
  prizes.forEach((prize, values) {
    buffer.write('<tr><td>$prize</td><td>');
    for (var index = 0; index < values.length; index += 1) {
      buffer.write(
        '<span id="mb_prize${codes[prize]}_item${index + 1}">${values[index]}</span>',
      );
    }
    buffer.write('</td></tr>');
  });
  buffer.write('</tbody></table>');
  return buffer.toString();
}

/// Sinh HTML XSMN nhiều đài với `data-loto` trong từng ô.
String buildMnHtml(
  List<String> stations,
  Map<String, List<List<String>>> rows,
) {
  final buffer = StringBuffer('<table><tbody><tr>');
  buffer.write('<th>Giải</th>');
  for (final station in stations) {
    buffer.write('<th title="Xổ số $station">$station</th>');
  }
  buffer.write('</tr>');
  rows.forEach((prize, perStation) {
    buffer.write('<tr><td>$prize</td>');
    for (final values in perStation) {
      buffer.write('<td>');
      for (final value in values) {
        buffer.write('<span data-loto="$value">$value</span>');
      }
      buffer.write('</td>');
    }
    buffer.write('</tr>');
  });
  buffer.write('</tbody></table>');
  return buffer.toString();
}

void main() {
  test('parser XSMB đọc đủ 27 số theo cấu trúc id', () {
    final prizes = <String, List<String>>{
      'Đặc biệt': <String>['12345'],
      'Giải nhất': <String>['67890'],
      'Giải nhì': <String>['11111', '22222'],
      'Giải ba': <String>['33333', '44444', '55555', '66666', '77777', '88888'],
      'Giải tư': <String>['1234', '5678', '9012', '3456'],
      'Giải năm': <String>['2345', '6789', '0123', '4567', '8901', '2345'],
      'Giải sáu': <String>['123', '456', '789'],
      'Giải bảy': <String>['12', '34', '56', '78'],
    };

    final parsed = parseXsmbHtml(buildMbHtml(prizes));

    expect(parsed.length, 27);
    expect(parsed.where((item) => item.prize == 'Đặc biệt').length, 1);
    expect(parsed.firstWhere((item) => item.prize == 'Đặc biệt').lastTwo, '45');
    expect(
      parsed
          .where((item) => item.prize == 'Giải bảy')
          .map((item) => item.lastTwo),
      <String>['12', '34', '56', '78'],
    );
  });

  test('parser XSMB trả rỗng với HTML không có kết quả', () {
    expect(
      parseXsmbHtml('<html><body>Đang cập nhật</body></html>').isEmpty,
      true,
    );
  });

  test('parser XSMN tách đúng nhiều đài theo cột', () {
    final rows = <String, List<List<String>>>{
      '8': <List<String>>[
        <String>['12'],
        <String>['34'],
        <String>['56'],
      ],
      '7': <List<String>>[
        <String>['123'],
        <String>['456'],
        <String>['789'],
      ],
      '6': <List<String>>[
        <String>['1111', '2222', '3333'],
        <String>['4444', '5555', '6666'],
        <String>['7777', '8888', '9999'],
      ],
      '5': <List<String>>[
        <String>['1010'],
        <String>['2020'],
        <String>['3030'],
      ],
      '4': <List<String>>[
        <String>['10001', '10002', '10003', '10004', '10005', '10006', '10007'],
        <String>['20001', '20002', '20003', '20004', '20005', '20006', '20007'],
        <String>['30001', '30002', '30003', '30004', '30005', '30006', '30007'],
      ],
      '3': <List<String>>[
        <String>['55555', '66666'],
        <String>['77777', '88888'],
        <String>['99999', '12345'],
      ],
      '2': <List<String>>[
        <String>['11111'],
        <String>['22222'],
        <String>['33333'],
      ],
      '1': <List<String>>[
        <String>['44444'],
        <String>['55555'],
        <String>['66666'],
      ],
      'ĐB': <List<String>>[
        <String>['123456'],
        <String>['234567'],
        <String>['345678'],
      ],
    };

    final parsed = parseXsmnHtml(
      buildMnHtml(<String>['An Giang', 'Bình Thuận', 'Cà Mau'], rows),
    );

    expect(parsed.keys.toSet(), <String>{'An Giang', 'Bình Thuận', 'Cà Mau'});
    for (final entry in parsed.entries) {
      expect(entry.value.length, 18, reason: entry.key);
    }
    expect(
      parsed['An Giang']!
          .firstWhere((item) => item.prize == 'Đặc biệt')
          .lastTwo,
      '56',
    );
    expect(
      parsed['Cà Mau']!.firstWhere((item) => item.prize == 'Giải tám').lastTwo,
      '56',
    );
  });

  test('parser XSMN trả rỗng khi bảng không có mã giải', () {
    expect(
      parseXsmnHtml(
        '<table><tr><td>Không có dữ liệu</td></tr></table>',
      ).isEmpty,
      true,
    );
  });
}
