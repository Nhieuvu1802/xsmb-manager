import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lottery_result.dart';
import 'api_client.dart';

class ResultCache {
  Future<void> save(LotteryRegion region, List<LotteryResult> results) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(region),
      jsonEncode(results.map((result) => result.toJson()).toList()),
    );
  }

  Future<List<LotteryResult>> load(LotteryRegion region) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(region));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => LotteryResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _key(LotteryRegion region) => 'xsmb-manager:${region.name}:results';
}
