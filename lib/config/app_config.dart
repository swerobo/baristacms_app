import 'dart:io';

/// App configuration
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://baristacms-api.azurewebsites.net';

  // Azure AD Configuration
  static const String tenantId = '7388d115-29cd-4cde-b8f1-78559e9476ec';
  static const String clientId = '2603d090-e517-46d9-ab77-deb02d5964ca';

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
