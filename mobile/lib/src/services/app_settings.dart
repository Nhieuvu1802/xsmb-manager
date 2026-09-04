import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AppSettings {
  static const _apiBaseUrlKey = 'xsmb-manager:api-base-url';

  Future<String> loadApiBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_apiBaseUrlKey) ?? defaultApiBaseUrl;
  }

  Future<void> saveApiBaseUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _apiBaseUrlKey,
      ApiClient.normalizeApiBaseUrl(value),
    );
  }
}
