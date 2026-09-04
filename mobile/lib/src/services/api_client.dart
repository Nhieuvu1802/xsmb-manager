import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lottery_result.dart';

const defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

enum LotteryRegion { mb, mn }

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String baseUrl = defaultApiBaseUrl, http.Client? client})
      : baseUrl = normalizeApiBaseUrl(baseUrl),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static String normalizeApiBaseUrl(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'URL API phải bắt đầu bằng http:// hoặc https:// và có tên máy chủ.',
      );
    }
    return normalized;
  }

  Future<void> checkHealth() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 8));
    final body = _decode(response);
    if (body is! Map<String, dynamic> || body['status'] != 'ok') {
      throw const ApiException('Máy chủ không trả về trạng thái sẵn sàng.');
    }
  }

  Future<List<LotteryResult>> getResults(
    LotteryRegion region, {
    required DateTime start,
    required DateTime end,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/draws/${region.name}')
        .replace(queryParameters: {'start': _date(start), 'end': _date(end)});
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 15));
    final body = _decode(response);
    if (body is! List) {
      throw const ApiException('API trả về dữ liệu không hợp lệ.');
    }
    return body
        .map((item) => LotteryResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> login(String username, String password) async {
    _requireProtectedCredentials();
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/token'),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    ).timeout(const Duration(seconds: 15));
    final body = _decode(response);
    if (body is! Map<String, dynamic> || body['access_token'] is! String) {
      throw const ApiException('API không trả về access token.');
    }
    return body['access_token'] as String;
  }

  Future<int> synchronize(
    LotteryRegion region, {
    required DateTime start,
    required DateTime end,
    required String token,
  }) async {
    _requireProtectedCredentials();
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/v1/sync/${region.name}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'start_date': _date(start),
            'end_date': _date(end),
          }),
        )
        .timeout(const Duration(seconds: 45));
    final body = _decode(response);
    if (body is! Map<String, dynamic>) {
      throw const ApiException('API trả về dữ liệu đồng bộ không hợp lệ.');
    }
    return body['saved'] as int? ?? 0;
  }

  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      body = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map<String, dynamic> ? body['detail'] : null;
      throw ApiException(
        detail is String ? detail : 'API trả về lỗi ${response.statusCode}.',
      );
    }
    return body;
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  void _requireProtectedCredentials() {
    final uri = Uri.parse(baseUrl);
    if (uri.scheme == 'https' || _isPrivateOrLoopback(uri.host)) return;
    throw const ApiException(
      'Đăng nhập và đồng bộ chỉ được phép qua HTTPS hoặc mạng nội bộ.',
    );
  }

  bool _isPrivateOrLoopback(String host) {
    if (host == 'localhost' || host == '::1') return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        first == 127 ||
        (first == 192 && second == 168) ||
        (first == 172 && second >= 16 && second <= 31);
  }

  void close() => _client.close();
}
