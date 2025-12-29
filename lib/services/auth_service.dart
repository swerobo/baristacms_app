import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class AuthService extends ChangeNotifier {
  late final AadOAuth _oauth;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Navigator key must be passed to MaterialApp
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _accessToken;
  String? _userEmail;
  String? _userName;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  AuthService() {
    final config = Config(
      tenant: AppConfig.tenantId,
      clientId: AppConfig.clientId,
      scope: AppConfig.scopes.join(' '),
      redirectUri: AppConfig.redirectUri,
      navigatorKey: navigatorKey,
    );
    _oauth = AadOAuth(config);
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check for stored token
      final storedToken = await _storage.read(key: 'access_token');
      if (storedToken != null) {
        _accessToken = storedToken;
        _userEmail = await _storage.read(key: 'user_email');
        _userName = await _storage.read(key: 'user_name');
        _isAuthenticated = true;
      }
    } catch (e) {
      // Secure storage may fail on macOS without proper signing
      // Continue without cached credentials
      debugPrint('Error reading from secure storage (this is OK on macOS): $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _oauth.login();
      final token = await _oauth.getAccessToken();

      if (token != null) {
        _accessToken = token;
        _isAuthenticated = true;

        // Try to store token (may fail on macOS without signing)
        try {
          await _storage.write(key: 'access_token', value: token);
        } catch (e) {
          debugPrint('Could not store token in secure storage: $e');
        }

        // Get user info from token (basic parsing)
        // In production, you'd decode the JWT properly
        _userEmail = 'user@example.com';
        _userName = 'User';

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _oauth.logout();
    } catch (e) {
      debugPrint('OAuth logout error: $e');
    }

    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Secure storage clear error: $e');
    }

    _accessToken = null;
    _userEmail = null;
    _userName = null;
    _isAuthenticated = false;

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_accessToken != null) {
      return _accessToken;
    }

    try {
      final token = await _oauth.getAccessToken();
      if (token != null) {
        _accessToken = token;
        try {
          await _storage.write(key: 'access_token', value: token);
        } catch (e) {
          debugPrint('Could not cache token: $e');
        }
      }
      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
}
