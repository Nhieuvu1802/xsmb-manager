import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb_manager/src/core/config/api_config.dart';
import 'package:xsmb_manager/src/core/config/app_config.dart';

void main() {
  test('API production mặc định là Cloudflare Worker kèm /v1', () {
    expect(
      ApiConfig.baseUrl,
      'https://xsmb-api.nhieuvu1802.workers.dev/v1',
    );
    expect(AppConfig.defaultApiBaseUrl, ApiConfig.baseUrl);
    expect(ApiConfig.apiVersion, 'v1');
    expect(ApiConfig.versionPath, '/v1');
    expect(ApiConfig.host, ApiConfig.workerHost);
    expect(ApiConfig.isDefaultEndpoint, isTrue);
    expect(ApiConfig.isPlannedEndpoint, isFalse);
  });

  test('endpoint được ghép từ baseUrl duy nhất, không hard-code host', () {
    const host = 'https://xsmb-api.nhieuvu1802.workers.dev/v1';
    expect(ApiConfig.health().toString(), '$host/health');
    expect(ApiConfig.publicConfig().toString(), '$host/config');
    expect(ApiConfig.manifest().toString(), '$host/manifest');
    expect(ApiConfig.latest('xsmb').toString(), '$host/xsmb/latest');
    expect(
      ApiConfig.latest('xsmn', days: 7).toString(),
      '$host/xsmn/latest?days=7',
    );
    expect(ApiConfig.byDate('xsmb', '2026-09-12').toString(), '$host/xsmb/2026-09-12');
    expect(
      ApiConfig.history('xsmn', start: '2026-09-01', end: '2026-09-12').toString(),
      '$host/xsmn/history?start=2026-09-01&end=2026-09-12',
    );
    expect(ApiConfig.history('xsmb', days: 3).toString(), '$host/xsmb/history?days=3');
  });

  test('URL host chưa có version được nâng cấp tự động lên /v1', () {
    expect(
      ApiConfig.normalizeBaseUrl('http://10.0.2.2:8000/'),
      'http://10.0.2.2:8000/v1',
    );
    expect(
      AppConfig.normalizeApiBaseUrl('https://xsmb-api.nhieuvu1802.workers.dev//'),
      'https://xsmb-api.nhieuvu1802.workers.dev/v1',
    );
  });

  test('từ chối URL không phải API v1', () {
    expect(
      () => AppConfig.normalizeApiBaseUrl('https://example.com/api/v2'),
      throwsFormatException,
    );
    expect(
      () => ApiConfig.normalizeBaseUrl('not a url'),
      throwsFormatException,
    );
  });

  test('đổi sang api.vvn.freedev.app chỉ cần đổi cấu hình, không đổi logic', () {
    expect(
      ApiConfig.normalizeBaseUrl(ApiConfig.plannedBaseUrl),
      'https://api.vvn.freedev.app/v1',
    );
    expect(ApiConfig.plannedHost, 'api.vvn.freedev.app');
  });

  test('GitHub fallback lấy từ ApiConfig và không chứa credential', () {
    expect(
      AppConfig.defaultGitHubPublicDataBaseUrl,
      'https://raw.githubusercontent.com/Nhieuvu1802/xsmb-manager/main/public-data',
    );
    expect(
      AppConfig.defaultGitHubPublicDataBaseUrl.contains('@'),
      isFalse,
      reason: 'URL công khai không được chứa user/token',
    );
  });
}

