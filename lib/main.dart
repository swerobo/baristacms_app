import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'providers/module_provider.dart';
import 'providers/record_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/records_list_screen.dart';
import 'screens/record_detail_screen.dart';
import 'screens/record_edit_screen.dart';

// Create AuthService instance globally so we can access its navigatorKey
final authService = AuthService();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BaristaCMSApp());
}

class BaristaCMSApp extends StatelessWidget {
  const BaristaCMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Service (must be first as others depend on it)
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
      child: MaterialApp(
        navigatorKey: authService.navigatorKey,
        title: 'BaristaCMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/records': (context) => const RecordsListScreen(),
          '/record-detail': (context) => const RecordDetailScreen(),
          '/record-edit': (context) => const RecordEditScreen(),
        },
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
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (authService.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
