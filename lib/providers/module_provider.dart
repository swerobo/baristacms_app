import 'package:flutter/foundation.dart';
import '../models/module.dart';
import '../services/api_service.dart';

class ModuleProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Module> _modules = [];
  Module? _currentModule;
  bool _isLoading = false;
  String? _error;

  List<Module> get modules => _modules;
  Module? get currentModule => _currentModule;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ModuleProvider(this._apiService);

  Future<void> loadModules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _modules = await _apiService.getAppModules();
    } catch (e) {
      _error = 'Failed to load modules: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadModule(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentModule = await _apiService.getModule(name);
    } catch (e) {
      _error = 'Failed to load module: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCurrentModule(Module? module) {
    _currentModule = module;
    notifyListeners();
  }
}
