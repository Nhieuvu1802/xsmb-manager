import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xsmb_manager/src/services/api_client.dart';

void main() {
  test('normalizes a valid API URL', () {
    expect(
      ApiClient.normalizeApiBaseUrl(' https://api.example.com/ '),
      'https://api.example.com',
    );
  });

  test('rejects an invalid API URL', () {
    expect(
      () => ApiClient.normalizeApiBaseUrl('api.example.com'),
      throwsFormatException,
    );
  });

  test('checks the API health endpoint', () async {
    final client = ApiClient(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response('{"status":"ok"}', 200);
      }),
    );

    await client.checkHealth();
    client.close();
  });

  test('does not send credentials over public plain HTTP', () async {
    final client = ApiClient(
      baseUrl: 'http://api.example.com',
      client: MockClient((request) async => http.Response('{}', 200)),
    );

    await expectLater(
      client.login('admin', 'password'),
      throwsA(isA<ApiException>()),
    );
    client.close();
  });
}
