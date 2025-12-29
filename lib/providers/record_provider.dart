import 'package:flutter/foundation.dart';
import '../models/record.dart';
import '../services/api_service.dart';

class RecordProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<ModuleRecord> _records = [];
  ModuleRecord? _currentRecord;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _currentModuleName;

  List<ModuleRecord> get records => _records;
  ModuleRecord? get currentRecord => _currentRecord;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Filtered records based on search query
  List<ModuleRecord> get filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final query = _searchQuery.toLowerCase();
    return _records.where((r) =>
        r.name.toLowerCase().contains(query) ||
        r.status.toLowerCase().contains(query)).toList();
  }

  RecordProvider(this._apiService);

  Future<void> loadRecords(String moduleName) async {
    _isLoading = true;
    _error = null;
    _currentModuleName = moduleName;
    notifyListeners();

    try {
      _records = await _apiService.getRecords(moduleName);
    } catch (e) {
      _error = 'Failed to load records: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecord(String moduleName, int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRecord = await _apiService.getRecord(moduleName, id);
    } catch (e) {
      _error = 'Failed to load record: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ModuleRecord?> findRecordById(String moduleName, int id) async {
    try {
      return await _apiService.findRecordById(moduleName, id);
    } catch (e) {
      debugPrint('Error finding record: $e');
      return null;
    }
  }

  Future<bool> createRecord(String moduleName, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newRecord = await _apiService.createRecord(moduleName, data);
      _records.insert(0, newRecord);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create record: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecord(
      String moduleName, int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedRecord = await _apiService.updateRecord(moduleName, id, data);
      final index = _records.indexWhere((r) => r.id == id);
      if (index != -1) {
        _records[index] = updatedRecord;
      }
      _currentRecord = updatedRecord;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update record: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(String moduleName, int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteRecord(moduleName, id);
      _records.removeWhere((r) => r.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete record: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setCurrentRecord(ModuleRecord? record) {
    _currentRecord = record;
    notifyListeners();
  }
}
