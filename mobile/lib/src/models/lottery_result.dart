class LotteryResult {
  const LotteryResult({
    required this.drawDate,
    required this.prize,
    required this.position,
    required this.fullNumber,
    required this.loto2,
    this.province,
  });

  final String drawDate;
  final String prize;
  final int position;
  final String fullNumber;
  final String loto2;
  final String? province;

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      drawDate: json['draw_date'] as String,
      prize: json['prize'] as String,
      position: json['position'] as int,
      fullNumber: json['full_number'] as String,
      loto2: json['loto2'] as String,
      province: json['province'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'draw_date': drawDate,
        'prize': prize,
        'position': position,
        'full_number': fullNumber,
        'loto2': loto2,
        if (province != null) 'province': province,
      };
}

Map<String, int> lotoFrequency(Iterable<LotteryResult> results) {
  final counts = <String, int>{};
  for (final result in results) {
    counts.update(result.loto2, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}
