import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _apiUrlController;
  late TextEditingController _localServerIpController;
  late TextEditingController _localServerPortController;
  late TextEditingController _tenantIdController;
  late TextEditingController _clientIdController;
  bool _useLocalApi = false;
  bool _darkMode = false;
  ThemeColor _themeColor = ThemeColor.barista;
  bool _isLoading = false;
  bool _isTesting = false;
  ConnectionTestResult? _testResult;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>().settings;
    _apiUrlController = TextEditingController(text: settings.apiUrl);
    _localServerIpController = TextEditingController(text: settings.localServerIp);
    _localServerPortController = TextEditingController(text: settings.localServerPort.toString());
    _tenantIdController = TextEditingController(text: settings.tenantId);
    _clientIdController = TextEditingController(text: settings.clientId);
    _useLocalApi = settings.useLocalApi;
    _darkMode = settings.darkMode;
    _themeColor = settings.themeColor;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _localServerIpController.dispose();
    _localServerPortController.dispose();
    _tenantIdController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settingsService = context.read<SettingsService>();

      final newSettings = AppSettings(
        apiUrl: _apiUrlController.text.trim(),
        localServerIp: _localServerIpController.text.trim(),
        localServerPort: int.tryParse(_localServerPortController.text.trim()) ?? 3001,
        tenantId: _tenantIdController.text.trim(),
        clientId: _clientIdController.text.trim(),
        useLocalApi: _useLocalApi,
        darkMode: _darkMode,
        themeColor: _themeColor,
      );

      await settingsService.saveAllSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final defaults = AppSettings.defaults();
      setState(() {
        _apiUrlController.text = defaults.apiUrl;
        _localServerIpController.text = defaults.localServerIp;
        _localServerPortController.text = defaults.localServerPort.toString();
        _tenantIdController.text = defaults.tenantId;
        _clientIdController.text = defaults.clientId;
        _useLocalApi = defaults.useLocalApi;
        _darkMode = defaults.darkMode;
        _themeColor = defaults.themeColor;
      });
      await _saveSettings();
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    String testUrl;
    if (_useLocalApi) {
      final ip = _localServerIpController.text.trim();
      final port = _localServerPortController.text.trim();
      testUrl = 'http://$ip:$port';
    } else {
      testUrl = _apiUrlController.text.trim();
    }

    final result = await ApiService.testConnection(testUrl);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Appearance Section
            _buildSectionHeader('Appearance'),
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                secondary: Icon(
                  _darkMode ? Icons.dark_mode : Icons.light_mode,
                  color: _darkMode ? Colors.amber : Colors.orange,
                ),
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  // Apply dark mode immediately
                  context.read<SettingsService>().setDarkMode(value);
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Color(_themeColor.colorValue),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Theme Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ThemeColor.values.map((color) {
                        final isSelected = _themeColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _themeColor = color);
                            // Apply theme color immediately
                            context.read<SettingsService>().setThemeColor(color);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(color.colorValue),
                              shape: BoxShape.circle,
                              border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    width: 3,
                                  )
                                : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _themeColor.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // API Configuration Section
            _buildSectionHeader('API Configuration'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Use Local API'),
                      subtitle: Text(
                        _useLocalApi
                          ? 'Connecting to local development server'
                          : 'Connecting to Azure cloud server',
                      ),
                      secondary: Icon(
                        _useLocalApi ? Icons.computer : Icons.cloud,
                        color: _useLocalApi ? Colors.green : Colors.blue,
                      ),
                      value: _useLocalApi,
                      onChanged: (value) {
                        setState(() => _useLocalApi = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Local Server IP and Port (only shown when Use Local API is ON)
                    if (_useLocalApi) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _localServerIpController,
                              decoration: const InputDecoration(
                                labelText: 'Local Server IP',
                                hintText: '192.168.1.100',
                                prefixIcon: Icon(Icons.router),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_useLocalApi && (value == null || value.isEmpty)) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _localServerPortController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                hintText: '3001',
                                prefixIcon: Icon(Icons.numbers),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_useLocalApi && (value == null || value.isEmpty)) {
                                  return 'Required';
                                }
                                final port = int.tryParse(value ?? '');
                                if (port == null || port < 1 || port > 65535) {
                                  return 'Invalid port';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Mac\'s IP address and server port',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _apiUrlController,
                      decoration: InputDecoration(
                        labelText: 'API URL (Cloud)',
                        hintText: 'https://your-api.azurewebsites.net',
                        prefixIcon: const Icon(Icons.cloud),
                        helperText: _useLocalApi ? 'Used when Local API is OFF' : null,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      enabled: !_useLocalApi,
                      validator: (value) {
                        if (!_useLocalApi && (value == null || value.isEmpty)) {
                          return 'Please enter an API URL';
                        }
                        if (value != null && value.isNotEmpty &&
                            !value.startsWith('http://') && !value.startsWith('https://')) {
                          return 'URL must start with http:// or https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Test Connection Button
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                      label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                    // Test Result
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult!.success
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testResult!.success ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testResult!.success ? Icons.check_circle : Icons.error,
                              color: _testResult!.success ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _testResult!.message,
                                style: TextStyle(
                                  color: _testResult!.success ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Azure AD Configuration Section
            _buildSectionHeader('Azure AD Configuration'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tenantIdController,
                      decoration: const InputDecoration(
                        labelText: 'Tenant ID',
                        hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a Tenant ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clientIdController,
                      decoration: const InputDecoration(
                        labelText: 'Client ID',
                        hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                        prefixIcon: Icon(Icons.key),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a Client ID';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Section
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Changes to API and Azure settings require app restart to take effect.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Settings'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
