/// Azure AD / Microsoft Entra configuration for MSAL authentication
class AuthConfig {
  // Azure AD Tenant ID
  static const String tenantId = '7388d115-29cd-4cde-b8f1-78559e9476ec';

  // Azure AD Client ID (Application ID) - Must match backend AZURE_CLIENT_ID
  static const String clientId = '780ae31c-468a-45ba-8a5a-976ecbe1063d';

  // Redirect URI for mobile app (iOS) - must match bundle ID
  static const String redirectUri = 'msauth.com.baristacms.baristacmsApp://auth';

  // Authority URL
  static String get authority => 'https://login.microsoftonline.com/$tenantId';

  // Scopes required for authentication
  // Note: openid, profile, offline_access are added automatically by MSAL
  static const List<String> scopes = [
    'User.Read',
  ];
}
