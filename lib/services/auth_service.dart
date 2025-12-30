import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msal_flutter/msal_flutter.dart';
import '../config/app_config.dart';

/// Authentication type
enum AuthType { none, local, m365 }

/// User info from authentication
class AuthUser {
  final int id;
  final String email;
  final String name;
  final String role;
  final bool mustChangePassword;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.mustChangePassword = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      mustChangePassword: json['must_change_password'] == 1 || json['mustChangePassword'] == true,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';
}

/// Authentication service
/// Supports both local (email/password) and M365 authentication
class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  static const String _tokenKey = 'barista_local_token';
  static const String _authTypeKey = 'barista_auth_type';

  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  AuthType _authType = AuthType.none;
  AuthUser? _currentUser;
  bool _mustChangePassword = false;
  String? _accessToken;
  bool _isLoading = false;
  String? _error;

  // MSAL client for M365 authentication
  PublicClientApplication? _msalClient;

  /// Check if MSAL is supported on this platform
  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  bool get isAuthenticated => _accessToken != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get accessToken => _accessToken;
  AuthType get authType => _authType;
  AuthUser? get currentUser => _currentUser;
  bool get mustChangePassword => _mustChangePassword;

  // Convenience getters for user info
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.name;

  /// Initialize authentication
  Future<void> initialize() async {
    if (_isInitialized) return;

    _initCompleter = Completer<void>();
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize MSAL client on mobile platforms
      if (_isMobilePlatform) {
        try {
          final authority = 'https://login.microsoftonline.com/${AppConfig.tenantId}';
          final iosRedirectUri = 'msauth.com.baristacms.baristacmsApp://auth';
          debugPrint('MSAL: Using tenantId=${AppConfig.tenantId}, clientId=${AppConfig.clientId}');
          _msalClient = await PublicClientApplication.createPublicClientApplication(
            AppConfig.clientId,
            authority: authority,
            iosRedirectUri: iosRedirectUri,
          );
          debugPrint('MSAL client initialized successfully');
        } catch (e) {
          debugPrint('Failed to initialize MSAL client: $e');
        }
      }

      // Try to restore previous session
      await _restoreSession();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isInitialized = true;
      _isLoading = false;
      _initCompleter?.complete();
      notifyListeners();
    }
  }

  /// Wait for initialization to complete
  Future<void> _ensureInitialized() async {
    if (_initCompleter != null) {
      await _initCompleter!.future;
    }
  }

  /// Sign in with email and password (local auth)
  Future<bool> signInWithEmail(String email, String password) async {
    await _ensureInitialized();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      debugPrint('Login response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        final mustChange = data['mustChangePassword'] as bool? ?? false;

        if (token != null && userData != null) {
          _mustChangePassword = mustChange;
          _currentUser = AuthUser.fromJson(userData);
          _currentUser = AuthUser(
            id: _currentUser!.id,
            email: _currentUser!.email,
            name: _currentUser!.name,
            role: _currentUser!.role,
            mustChangePassword: mustChange,
          );
          _authType = AuthType.local;
          _accessToken = token;
          await _saveSession(token, AuthType.local);

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _error = 'Invalid response from server';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _error = 'Invalid email or password';
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout) {
        _error = 'Network error. Please check your connection.';
      } else {
        _error = 'Login failed. Please try again.';
      }
      debugPrint('Local sign in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      debugPrint('Local sign in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Microsoft (M365 auth)
  Future<bool> signInWithMicrosoft() async {
    await _ensureInitialized();

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Mobile MSAL flow
    if (_isMobilePlatform) {
      if (_msalClient == null) {
        _error = 'MSAL client not initialized. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      try {
        // Acquire token interactively using MSAL
        // Use 'User.Read' scope for Microsoft Graph user info
        const msalScopes = ['User.Read'];
        debugPrint('MSAL: Starting acquireToken...');
        final result = await _msalClient!.acquireToken(msalScopes);
        final token = result;
        debugPrint('MSAL: Token acquired, length: ${token?.length ?? 0}');

        if (token != null && token.isNotEmpty) {
          _authType = AuthType.m365;
          _accessToken = token;
          debugPrint('MSAL: Saving session...');
          await _saveSession(token, AuthType.m365);
          debugPrint('MSAL: Loading current user...');
          await _loadCurrentUser();
          debugPrint('MSAL: User loaded: ${_currentUser?.name}');

          _isLoading = false;
          notifyListeners();
          debugPrint('MSAL: Login complete, returning true');
          return true;
        } else {
          _error = 'Failed to acquire token from Microsoft';
          debugPrint('MSAL: Token was null or empty');
        }
      } on MsalUserCancelledException {
        debugPrint('MSAL: User cancelled login');
        // Don't show error for cancelled login
      } on MsalException catch (e) {
        debugPrint('MSAL MsalException: ${e.runtimeType}');
        debugPrint('MSAL error message: ${e.errorMessage}');
        _error = 'Microsoft login failed: ${e.errorMessage ?? 'Unknown error'}';
      } on PlatformException catch (e) {
        debugPrint('MSAL PlatformException code: ${e.code}');
        debugPrint('MSAL PlatformException message: ${e.message}');
        debugPrint('MSAL PlatformException details: ${e.details}');
        if (e.message?.contains('cancelled') == true ||
            e.message?.contains('canceled') == true) {
          // Don't show error for cancelled login
        } else {
          _error = 'Microsoft login failed: ${e.message ?? 'Unknown error'}';
        }
      } catch (e, stackTrace) {
        debugPrint('MSAL Unknown error type: ${e.runtimeType}');
        debugPrint('MSAL Unknown error: $e');
        debugPrint('MSAL Stack trace: $stackTrace');
        _error = 'Microsoft login failed: $e';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Desktop bypass mode - server should have AUTH_BYPASS=true for testing
    if (AppConfig.useLocalApi) {
      const bypassToken = 'bypass-token';
      _authType = AuthType.m365;
      _accessToken = bypassToken;
      await _saveSession(bypassToken, AuthType.m365);
      await _loadCurrentUser();

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = 'Microsoft login not supported on this platform';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Legacy sign in method (for backward compatibility)
  Future<bool> signIn() async {
    return signInWithMicrosoft();
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_authType == AuthType.m365 && _msalClient != null && _isMobilePlatform) {
        try {
          await _msalClient!.logout();
        } catch (e) {
          debugPrint('MSAL logout error: $e');
        }
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    await _clearSession();

    _isLoading = false;
    notifyListeners();
  }

  /// Change password (for local users)
  Future<bool> changePassword(String? currentPassword, String newPassword) async {
    await _ensureInitialized();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/api/auth/change-password',
        data: {
          if (currentPassword != null) 'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        _mustChangePassword = false;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Failed to change password';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _error = 'Current password is incorrect';
      } else {
        _error = 'Failed to change password. Please try again.';
      }
      debugPrint('Change password error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to change password. Please try again.';
      debugPrint('Change password error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get token for API calls
  Future<String?> getToken() async {
    return _accessToken;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load current user from API
  Future<void> _loadCurrentUser() async {
    debugPrint('_loadCurrentUser: API URL = ${AppConfig.apiBaseUrl}/api/users/me');
    try {
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/api/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      debugPrint('_loadCurrentUser: Response status = ${response.statusCode}');
      if (response.statusCode == 200 && response.data != null) {
        _currentUser = AuthUser.fromJson(response.data as Map<String, dynamic>);
        debugPrint('Loaded user from API: ${_currentUser?.name}');
      }
    } catch (e) {
      debugPrint('Failed to load current user from API: $e');
      // For M365, extract user info from JWT token
      if (_accessToken != null && _authType == AuthType.m365) {
        debugPrint('_loadCurrentUser: Extracting user from MSAL token...');
        _extractUserInfoFromToken(_accessToken!);
        debugPrint('_loadCurrentUser: User extracted: ${_currentUser?.name}');
      }
    }
  }

  /// Extract user info from JWT token (fallback for M365)
  void _extractUserInfoFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        _currentUser = AuthUser(id: 0, email: 'user@example.com', name: 'User', role: 'user');
        return;
      }

      String payload = parts[1];
      switch (payload.length % 4) {
        case 1: payload += '==='; break;
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = json.decode(decoded) as Map<String, dynamic>;

      final name = claims['name'] as String? ?? claims['given_name'] as String? ?? 'User';
      final email = claims['preferred_username'] as String? ??
                    claims['upn'] as String? ??
                    claims['email'] as String? ??
                    'user@example.com';

      _currentUser = AuthUser(id: 0, email: email, name: name, role: 'user');
      debugPrint('Extracted user from JWT: $name <$email>');
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
      _currentUser = AuthUser(id: 0, email: 'user@example.com', name: 'User', role: 'user');
    }
  }

  /// Save session data
  Future<void> _saveSession(String token, AuthType type) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _authTypeKey, value: type.name);
    } catch (e) {
      debugPrint('Could not save session to secure storage: $e');
    }
  }

  /// Restore session from storage
  Future<bool> _restoreSession() async {
    debugPrint('_restoreSession: Starting...');
    try {
      final token = await _storage.read(key: _tokenKey);
      final authTypeStr = await _storage.read(key: _authTypeKey);
      debugPrint('_restoreSession: Found token=${token != null}, authType=$authTypeStr');

      if (token != null) {
        _accessToken = token;
        _authType = AuthType.values.firstWhere(
          (e) => e.name == authTypeStr,
          orElse: () => AuthType.local,
        );
        debugPrint('_restoreSession: Auth type = $_authType');

        // For M365, skip backend verification - just load user from token
        if (_authType == AuthType.m365) {
          debugPrint('_restoreSession: M365 auth, extracting user from token...');
          _extractUserInfoFromToken(token);
          debugPrint('_restoreSession: User extracted: ${_currentUser?.name}');
          return _currentUser != null;
        }

        // Verify token is still valid (local auth only)
        debugPrint('_restoreSession: Verifying local token...');
        final isValid = await _verifyToken();
        debugPrint('_restoreSession: Token valid = $isValid');
        if (isValid) {
          await _loadCurrentUser();
          return true;
        } else {
          await _clearSession();
        }
      }
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
    return false;
  }

  /// Verify current token is still valid
  Future<bool> _verifyToken() async {
    if (_accessToken == null) return false;

    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/api/auth/verify',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Token verification error: $e');
      return false;
    }
  }

  /// Clear session data
  Future<void> _clearSession() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _authTypeKey);
    } catch (e) {
      debugPrint('Secure storage clear error: $e');
    }
    _accessToken = null;
    _currentUser = null;
    _authType = AuthType.none;
    _mustChangePassword = false;
  }
}
