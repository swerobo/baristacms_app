import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/module.dart';
import '../models/record.dart';
import 'auth_service.dart';

class ApiService {
  final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService) : _dio = Dio() {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 errors by redirecting to login
        if (error.response?.statusCode == 401) {
          _authService.signOut();
        }
        return handler.next(error);
      },
    ));
  }

  // ============ MODULES ============

  /// Get all modules enabled for the mobile app
  Future<List<Module>> getAppModules() async {
    final response = await _dio.get('/api/modules/app');
    return (response.data as List)
        .map((json) => Module.fromJson(json))
        .toList();
  }

  /// Get a module by name with its fields
  Future<Module> getModule(String name) async {
    final response = await _dio.get('/api/modules/$name');
    return Module.fromJson(response.data);
  }

  // ============ RECORDS ============

  /// Get all records for a module
  Future<List<ModuleRecord>> getRecords(String moduleName,
      {String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _dio.get(
      '/api/m/$moduleName/records',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return (response.data as List)
        .map((json) => ModuleRecord.fromJson(json))
        .toList();
  }

  /// Get a single record by ID
  Future<ModuleRecord> getRecord(String moduleName, int id) async {
    final response = await _dio.get('/api/m/$moduleName/records/$id');
    return ModuleRecord.fromJson(response.data);
  }

  /// Create a new record
  Future<ModuleRecord> createRecord(
      String moduleName, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/m/$moduleName/records',
      data: {
        ...data,
        'createdBy': _authService.userEmail,
      },
    );
    return ModuleRecord.fromJson(response.data);
  }

  /// Update a record
  Future<ModuleRecord> updateRecord(
      String moduleName, int id, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '/api/m/$moduleName/records/$id',
      data: {
        ...data,
        'updatedBy': _authService.userEmail,
      },
    );
    return ModuleRecord.fromJson(response.data);
  }

  /// Delete a record
  Future<void> deleteRecord(String moduleName, int id) async {
    await _dio.delete('/api/m/$moduleName/records/$id');
  }

  /// Search records by ID (for barcode scanner)
  Future<ModuleRecord?> findRecordById(String moduleName, int id) async {
    try {
      return await getRecord(moduleName, id);
    } catch (e) {
      return null;
    }
  }
}
