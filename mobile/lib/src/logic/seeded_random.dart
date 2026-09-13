/// Bộ sinh số giả ngẫu nhiên có seed, khớp chính xác với bản TypeScript
/// (`frontend/lib/statistics.ts`, `frontend/lib/sample-data.ts`).
///
/// Các hàm ở đây tái tạo đúng ngữ nghĩa 32-bit của JavaScript
/// (`Math.imul`, `>>> 0`, `^`) nhưng chỉ dùng phép chia lấy dư và nhân nhỏ để
/// chạy giống nhau trên cả Dart VM (Android/Windows) và dart2js (web) — nơi
/// toán tử bit chỉ an toàn trong phạm vi 32 bit.
library;

const int _twoPow32 = 4294967296;

/// Chuẩn hóa về số nguyên không dấu 32 bit, tương đương `value >>> 0`.
int u32(int value) {
  final remainder = value % _twoPow32;
  return remainder < 0 ? remainder + _twoPow32 : remainder;
}

/// Dịch phải logic trên 32 bit, tương đương `value >>> amount`.
int u32ShiftRight(int value, int amount) => u32(value) ~/ (1 << amount);

/// Nhân 32 bit, tương đương `Math.imul(a, b)` của JavaScript.
int imul32(int a, int b) {
  final left = u32(a);
  final right = u32(b);
  final leftHigh = left ~/ 65536;
  final leftLow = left % 65536;
  final rightHigh = right ~/ 65536;
  final rightLow = right % 65536;
  final low = leftLow * rightLow;
  final middle = ((leftLow * rightHigh + leftHigh * rightLow) % 65536) * 65536;
  return (low + middle) % _twoPow32;
}

/// `mulberry32(seed)` — sinh số mô phỏng có seed cố định.
class Mulberry32 {
  Mulberry32(int seed) : _seed = u32(seed);

  int _seed;

  /// Trả về số thực trong khoảng [0, 1).
  double next() {
    _seed = u32(_seed + 0x6D2B79F5);
    var value = imul32(u32(_seed) ^ u32ShiftRight(_seed, 15), u32(1 | _seed));
    value = u32(
      (value + imul32(u32(value) ^ u32ShiftRight(value, 7), u32(61 | value))) ^
          value,
    );
    return u32(value ^ u32ShiftRight(value, 14)) / _twoPow32;
  }
}

/// Bộ sinh số tuyến tính đồng dư dùng cho mô phỏng Monte Carlo có thể lặp lại.
class LinearCongruential {
  LinearCongruential(int seed) : _state = u32(seed);

  int _state;

  /// Trả về số thực trong khoảng [0, 1).
  double next() {
    _state = (1664525 * _state + 1013904223) % _twoPow32;
    return _state / _twoPow32;
  }
}
