import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Available theme colors
enum ThemeColor {
  barista('Barista Brown', 0xFFB97738),
  blue('Ocean Blue', 0xFF1976D2),
  teal('Teal', 0xFF009688),
  purple('Purple', 0xFF7B1FA2),
  green('Forest Green', 0xFF388E3C),
  red('Ruby Red', 0xFFC62828),
  orange('Sunset Orange', 0xFFE65100),
  indigo('Indigo', 0xFF303F9F);

  final String displayName;
  final int colorValue;
  const ThemeColor(this.displayName, this.colorValue);
}

class AppSettings {
  final String apiUrl;
  final String localServerIp;
  final int localServerPort;
  final String tenantId;
  final String clientId;
  final bool useLocalApi;
  final bool darkMode;
  final ThemeColor themeColor;

  AppSettings({
    required this.apiUrl,
    required this.localServerIp,
    required this.localServerPort,
    required this.tenantId,
    required this.clientId,
    required this.useLocalApi,
    required this.darkMode,
    required this.themeColor,
  });

  // Default settings
  factory AppSettings.defaults() {
    return AppSettings(
      apiUrl: 'https://baristacms-api.azurewebsites.net',
      localServerIp: '192.168.68.109',
      localServerPort: 3001,
      tenantId: '7388d115-29cd-4cde-b8f1-78559e9476ec',
      clientId: '780ae31c-468a-45ba-8a5a-976ecbe1063d',
      useLocalApi: false,
      darkMode: false,
      themeColor: ThemeColor.barista,
    );
  }

  AppSettings copyWith({
    String? apiUrl,
    String? localServerIp,
    int? localServerPort,
    String? tenantId,
    String? clientId,
    bool? useLocalApi,
    bool? darkMode,
    ThemeColor? themeColor,
  }) {
    return AppSettings(
      apiUrl: apiUrl ?? this.apiUrl,
      localServerIp: localServerIp ?? this.localServerIp,
      localServerPort: localServerPort ?? this.localServerPort,
      tenantId: tenantId ?? this.tenantId,
      clientId: clientId ?? this.clientId,
      useLocalApi: useLocalApi ?? this.useLocalApi,
      darkMode: darkMode ?? this.darkMode,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}

class SettingsService extends ChangeNotifier {
  static Database? _database;
  AppSettings _settings = AppSettings.defaults();

  AppSettings get settings => _settings;
  bool get darkMode => _settings.darkMode;
  ThemeMode get themeMode => _settings.darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'baristacms_settings.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        // Insert default settings
        final defaults = AppSettings.defaults();
        await db.insert('settings', {'key': 'api_url', 'value': defaults.apiUrl});
        await db.insert('settings', {'key': 'local_server_ip', 'value': defaults.localServerIp});
        await db.insert('settings', {'key': 'local_server_port', 'value': defaults.localServerPort.toString()});
        await db.insert('settings', {'key': 'tenant_id', 'value': defaults.tenantId});
        await db.insert('settings', {'key': 'client_id', 'value': defaults.clientId});
        await db.insert('settings', {'key': 'use_local_api', 'value': defaults.useLocalApi ? '1' : '0'});
        await db.insert('settings', {'key': 'dark_mode', 'value': defaults.darkMode ? '1' : '0'});
        await db.insert('settings', {'key': 'theme_color', 'value': defaults.themeColor.name});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        final defaults = AppSettings.defaults();
        if (oldVersion < 2) {
          // Add local_server_ip setting
          await db.insert('settings', {'key': 'local_server_ip', 'value': defaults.localServerIp},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        if (oldVersion < 3) {
          // Add local_server_port setting
          await db.insert('settings', {'key': 'local_server_port', 'value': defaults.localServerPort.toString()},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        if (oldVersion < 4) {
          // Add theme_color setting
          await db.insert('settings', {'key': 'theme_color', 'value': defaults.themeColor.name},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      },
    );
  }

  Future<void> loadSettings() async {
    final db = await database;
    final rows = await db.query('settings');

    String apiUrl = AppSettings.defaults().apiUrl;
    String localServerIp = AppSettings.defaults().localServerIp;
    int localServerPort = AppSettings.defaults().localServerPort;
    String tenantId = AppSettings.defaults().tenantId;
    String clientId = AppSettings.defaults().clientId;
    bool useLocalApi = AppSettings.defaults().useLocalApi;
    bool darkMode = AppSettings.defaults().darkMode;
    ThemeColor themeColor = AppSettings.defaults().themeColor;

    for (final row in rows) {
      final key = row['key'] as String;
      final value = row['value'] as String;

      switch (key) {
        case 'api_url':
          apiUrl = value;
          break;
        case 'local_server_ip':
          localServerIp = value;
          break;
        case 'local_server_port':
          localServerPort = int.tryParse(value) ?? 3001;
          break;
        case 'tenant_id':
          tenantId = value;
          break;
        case 'client_id':
          clientId = value;
          break;
        case 'use_local_api':
          useLocalApi = value == '1';
          break;
        case 'dark_mode':
          darkMode = value == '1';
          break;
        case 'theme_color':
          themeColor = ThemeColor.values.firstWhere(
            (c) => c.name == value,
            orElse: () => ThemeColor.barista,
          );
          break;
      }
    }

    _settings = AppSettings(
      apiUrl: apiUrl,
      localServerIp: localServerIp,
      localServerPort: localServerPort,
      tenantId: tenantId,
      clientId: clientId,
      useLocalApi: useLocalApi,
      darkMode: darkMode,
      themeColor: themeColor,
    );

    notifyListeners();
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.update(
      'settings',
      {'value': value},
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> setApiUrl(String url) async {
    await updateSetting('api_url', url);
    _settings = _settings.copyWith(apiUrl: url);
    notifyListeners();
  }

  Future<void> setLocalServerIp(String ip) async {
    await updateSetting('local_server_ip', ip);
    _settings = _settings.copyWith(localServerIp: ip);
    notifyListeners();
  }

  Future<void> setLocalServerPort(int port) async {
    await updateSetting('local_server_port', port.toString());
    _settings = _settings.copyWith(localServerPort: port);
    notifyListeners();
  }

  Future<void> setTenantId(String tenantId) async {
    await updateSetting('tenant_id', tenantId);
    _settings = _settings.copyWith(tenantId: tenantId);
    notifyListeners();
  }

  Future<void> setClientId(String clientId) async {
    await updateSetting('client_id', clientId);
    _settings = _settings.copyWith(clientId: clientId);
    notifyListeners();
  }

  Future<void> setUseLocalApi(bool useLocal) async {
    await updateSetting('use_local_api', useLocal ? '1' : '0');
    _settings = _settings.copyWith(useLocalApi: useLocal);
    notifyListeners();
  }

  Future<void> setDarkMode(bool darkMode) async {
    await updateSetting('dark_mode', darkMode ? '1' : '0');
    _settings = _settings.copyWith(darkMode: darkMode);
    notifyListeners();
  }

  Future<void> setThemeColor(ThemeColor color) async {
    await updateSetting('theme_color', color.name);
    _settings = _settings.copyWith(themeColor: color);
    notifyListeners();
  }

  Future<void> saveAllSettings(AppSettings newSettings) async {
    await setApiUrl(newSettings.apiUrl);
    await setLocalServerIp(newSettings.localServerIp);
    await setLocalServerPort(newSettings.localServerPort);
    await setTenantId(newSettings.tenantId);
    await setClientId(newSettings.clientId);
    await setUseLocalApi(newSettings.useLocalApi);
    await setDarkMode(newSettings.darkMode);
    await setThemeColor(newSettings.themeColor);
  }
}
