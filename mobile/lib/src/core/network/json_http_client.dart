/// HTTP client nhỏ: timeout, retry có giới hạn, log và thống kê độ trễ.
///
/// Mọi provider đều đi qua lớp này nên hành vi mạng (timeout, số lần thử,
/// User-Agent, logging) được kiểm soát ở một chỗ.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../logging/app_logger.dart';

/// Lỗi mạng đã được chuẩn hoá cho tầng provider.
class NetworkException implements Exception {
  const NetworkException(this.message, {this.statusCode, this.attempts = 1});

  final String message;
  final int? statusCode;
  final int attempts;

  /// Lỗi có khả năng tự khỏi (nên thử nguồn kế tiếp) hay không.
  bool get isRetryable =>
      statusCode == null || statusCode! >= 500 || statusCode == 429;

  @override
  String toString() =>
      'NetworkException($message${statusCode == null ? '' : ', status=$statusCode'}, attempts=$attempts)';
}

class HttpJsonResponse {
  const HttpJsonResponse({
    required this.body,
    required this.statusCode,
    required this.latencyMs,
    required this.attempts,
    required this.uri,
  });

  final dynamic body;
  final int statusCode;
  final int latencyMs;
  final int attempts;
  final Uri uri;
}

class JsonHttpClient {
  JsonHttpClient({
    http.Client? client,
    AppLogger? logger,
    Duration? timeout,
    int? maxAttempts,
    this.userAgent = AppConfig.userAgent,
  }) : _client = client ?? http.Client(),
       _logger = logger ?? appLogger,
       timeout = timeout ?? AppConfig.requestTimeout,
       maxAttempts = maxAttempts ?? AppConfig.maxAttempts;

  final http.Client _client;
  final AppLogger _logger;
  final Duration timeout;
  final int maxAttempts;
  final String userAgent;

  /// GET JSON, retry khi lỗi mạng/timeout/5xx.
  Future<HttpJsonResponse> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await _get(uri, headers: headers);
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      throw NetworkException(
        'Phản hồi không phải JSON hợp lệ từ ${uri.host}: $error',
        statusCode: response.statusCode,
        attempts: response.attempts,
      );
    }
    return HttpJsonResponse(
      body: decoded,
      statusCode: response.statusCode,
      latencyMs: response.latencyMs,
      attempts: response.attempts,
      uri: uri,
    );
  }

  /// GET văn bản (HTML/CSV) với cùng cơ chế retry.
  Future<HttpTextResponse> getText(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await _get(uri, headers: headers);
    return HttpTextResponse(
      body: utf8.decode(response.bodyBytes, allowMalformed: true),
      statusCode: response.statusCode,
      latencyMs: response.latencyMs,
      attempts: response.attempts,
      uri: uri,
    );
  }

  void close() => _client.close();

  Future<_RawResponse> _get(Uri uri, {Map<String, String>? headers}) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json, text/html;q=0.9, */*;q=0.8',
      'User-Agent': userAgent,
      ...?headers,
    };
    Object? lastError;
    var attempts = 0;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      attempts = attempt;
      final started = DateTime.now();
      try {
        final response = await _client
            .get(uri, headers: requestHeaders)
            .timeout(timeout);
        final latency = DateTime.now().difference(started).inMilliseconds;
        if (response.statusCode >= 500 || response.statusCode == 429) {
          lastError = NetworkException(
            'Máy chủ trả về ${response.statusCode}',
            statusCode: response.statusCode,
            attempts: attempt,
          );
          _logger.warning(
            'http',
            'GET $uri → ${response.statusCode} (${latency}ms, lần $attempt)',
          );
        } else if (response.statusCode < 200 || response.statusCode >= 300) {
          _logger.warning(
            'http',
            'GET $uri → ${response.statusCode} (${latency}ms)',
          );
          throw NetworkException(
            'Yêu cầu thất bại với mã ${response.statusCode}',
            statusCode: response.statusCode,
            attempts: attempt,
          );
        } else {
          _logger.debug(
            'http',
            'GET $uri → ${response.statusCode} (${latency}ms, lần $attempt)',
          );
          return _RawResponse(
            bodyBytes: response.bodyBytes,
            statusCode: response.statusCode,
            latencyMs: latency,
            attempts: attempt,
          );
        }
      } on TimeoutException {
        lastError = NetworkException(
          'Hết thời gian chờ sau ${timeout.inSeconds}s',
          attempts: attempt,
        );
        _logger.warning('http', 'GET $uri → timeout (lần $attempt)');
      } on SocketException catch (error) {
        lastError = NetworkException(
          'Không kết nối được ${uri.host}: ${error.message}',
          attempts: attempt,
        );
        _logger.warning('http', 'GET $uri → lỗi socket (lần $attempt)');
      } on http.ClientException catch (error) {
        lastError = NetworkException(
          'Lỗi HTTP client: ${error.message}',
          attempts: attempt,
        );
        _logger.warning('http', 'GET $uri → ClientException (lần $attempt)');
      }
      if (attempt < maxAttempts) {
        await Future<void>.delayed(AppConfig.retryDelay);
      }
    }

    if (lastError is NetworkException) {
      throw NetworkException(
        lastError.message,
        statusCode: lastError.statusCode,
        attempts: attempts,
      );
    }
    throw NetworkException('Không gọi được $uri', attempts: attempts);
  }
}

class HttpTextResponse {
  const HttpTextResponse({
    required this.body,
    required this.statusCode,
    required this.latencyMs,
    required this.attempts,
    required this.uri,
  });

  final String body;
  final int statusCode;
  final int latencyMs;
  final int attempts;
  final Uri uri;
}

class _RawResponse {
  const _RawResponse({
    required this.bodyBytes,
    required this.statusCode,
    required this.latencyMs,
    required this.attempts,
  });

  final List<int> bodyBytes;
  final int statusCode;
  final int latencyMs;
  final int attempts;
}
