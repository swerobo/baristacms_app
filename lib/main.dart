import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'providers/module_provider.dart';
import 'providers/record_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/records_list_screen.dart';
import 'screens/record_detail_screen.dart';
import 'screens/record_edit_screen.dart';
import 'screens/settings_screen.dart';

// Create AuthService instance globally so we can access its navigatorKey
final authService = AuthService();
final settingsService = SettingsService();

void main() async {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Catch async errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Load settings before app starts
      await settingsService.loadSettings();
      // Set settings service in AppConfig for dynamic values
      AppConfig.setSettingsService(settingsService);
      runApp(const BaristaCMSApp());
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

class BaristaCMSApp extends StatelessWidget {
  const BaristaCMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Settings Service (must be first for theme)
        ChangeNotifierProvider.value(value: settingsService),

        // Auth Service
        ChangeNotifierProvider.value(value: authService),

        // API Service (depends on AuthService)
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService),
        ),

        // Module Provider (depends on ApiService)
        ChangeNotifierProxyProvider<ApiService, ModuleProvider>(
          create: (_) => ModuleProvider(ApiService(authService)),
          update: (_, apiService, previous) =>
              previous ?? ModuleProvider(apiService),
        ),

        // Record Provider (depends on ApiService)
        ChangeNotifierProxyProvider<ApiService, RecordProvider>(
          create: (_) => RecordProvider(ApiService(authService)),
          update: (_, apiService, previous) =>
              previous ?? RecordProvider(apiService),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          final themeColor = Color(settings.settings.themeColor.colorValue);
          return MaterialApp(
            key: ValueKey(settings.settings.themeColor),
            title: 'BaristaCMS',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: _buildTheme(Brightness.light, themeColor),
            darkTheme: _buildTheme(Brightness.dark, themeColor),
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/records': (context) => const RecordsListScreen(),
              '/record-detail': (context) => const RecordDetailScreen(),
              '/record-edit': (context) => const RecordEditScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness, Color seedColor) {
    final isDark = brightness == Brightness.dark;
    // Create a slightly darker version of the seed color for app bar
    final appBarColor = HSLColor.fromColor(seedColor)
        .withLightness(
          (HSLColor.fromColor(seedColor).lightness * 0.7).clamp(0.0, 1.0),
        )
        .toColor();
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.grey.shade900 : appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}

/// Splash screen with logo
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/barista-logo.png',
              width: 300,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper that checks authentication state and redirects accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const SplashScreen();
        }

        if (authService.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
