import '../services/settings_service.dart';

/// App configuration
class AppConfig {
  // Reference to settings service for dynamic values
  static SettingsService? _settingsService;

  static void setSettingsService(SettingsService service) {
    _settingsService = service;
  }

  // Fallback values (used before settings are loaded)
  static const String _defaultApiUrl = 'https://baristacms-api.azurewebsites.net';
  static const String _defaultTenantId = '7388d115-29cd-4cde-b8f1-78559e9476ec';
  static const String _defaultClientId = '780ae31c-468a-45ba-8a5a-976ecbe1063d';
  static const String _defaultLocalServerIp = '192.168.68.109';

  // API Configuration - reads from settings if available
  static String get apiBaseUrl {
    final settings = _settingsService?.settings;
    if (settings != null) {
      if (settings.useLocalApi) {
        return 'http://${settings.localServerIp}:${settings.localServerPort}';
      }
      return settings.apiUrl;
    }
    return _defaultApiUrl;
  }

  static String get localServerIp {
    return _settingsService?.settings.localServerIp ?? _defaultLocalServerIp;
  }

  static int get localServerPort {
    return _settingsService?.settings.localServerPort ?? 3001;
  }

  static bool get useLocalApi {
    return _settingsService?.settings.useLocalApi ?? false;
  }

  // Azure AD Configuration - reads from settings if available
  static String get tenantId {
    return _settingsService?.settings.tenantId ?? _defaultTenantId;
  }

  static String get clientId {
    return _settingsService?.settings.clientId ?? _defaultClientId;
  }

  // Redirect URI - MSAL standard format
  // This must match exactly what's configured in Azure AD
  static String get redirectUri {
    return 'msal$clientId://auth';
  }

  // Scopes for API access
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];
}
