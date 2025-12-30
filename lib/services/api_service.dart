import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/module.dart';
import '../models/record.dart';
import 'auth_service.dart';

class ApiService {
  final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService) : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Always get the latest base URL from config
        options.baseUrl = AppConfig.apiBaseUrl;

        try {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('Error getting token: $e');
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 errors by redirecting to login
        if (error.response?.statusCode == 401) {
          _authService.signOut();
        }
        // Wrap network errors with more context
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.receiveTimeout) {
          debugPrint('Network error: ${error.type} - ${error.message}');
        }
        return handler.next(error);
      },
    ));
  }

  /// Wraps API calls with consistent error handling
  Future<T> _safeCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout - server not reachable');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error - check network settings');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server took too long to respond');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Not found');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('API error: $e');
      rethrow;
    }
  }

  /// Test connection to the API server
  static Future<ConnectionTestResult> testConnection(String baseUrl) async {
    final testDio = Dio();
    testDio.options.connectTimeout = const Duration(seconds: 5);
    testDio.options.receiveTimeout = const Duration(seconds: 5);

    try {
      final response = await testDio.get('$baseUrl/api/health');
      if (response.statusCode == 200) {
        return ConnectionTestResult(success: true, message: 'Connected successfully');
      }
      return ConnectionTestResult(success: false, message: 'Server returned status ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return ConnectionTestResult(success: false, message: 'Connection timeout - server not reachable');
      } else if (e.type == DioExceptionType.connectionError) {
        return ConnectionTestResult(success: false, message: 'Connection error - check IP and port');
      }
      return ConnectionTestResult(success: false, message: 'Error: ${e.message}');
    } catch (e) {
      return ConnectionTestResult(success: false, message: 'Error: $e');
    }
  }

  // ============ MODULES ============

  /// Get all modules enabled for the mobile app
  Future<List<Module>> getAppModules() async {
    return _safeCall(() async {
      final response = await _dio.get('/api/modules/app');
      return (response.data as List)
          .map((json) => Module.fromJson(json))
          .toList();
    });
  }

  /// Get a module by name with its fields
  Future<Module> getModule(String name) async {
    return _safeCall(() async {
      final response = await _dio.get('/api/modules/$name');
      return Module.fromJson(response.data);
    });
  }

  // ============ RECORDS ============

  /// Get all records for a module
  Future<List<ModuleRecord>> getRecords(String moduleName,
      {String? search}) async {
    return _safeCall(() async {
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
    });
  }

  /// Get a single record by ID
  Future<ModuleRecord> getRecord(String moduleName, int id) async {
    return _safeCall(() async {
      final response = await _dio.get('/api/m/$moduleName/records/$id');
      return ModuleRecord.fromJson(response.data);
    });
  }

  /// Create a new record
  Future<ModuleRecord> createRecord(
      String moduleName, Map<String, dynamic> data) async {
    return _safeCall(() async {
      final response = await _dio.post(
        '/api/m/$moduleName/records',
        data: {
          ...data,
          'createdBy': _authService.userEmail,
        },
      );
      return ModuleRecord.fromJson(response.data);
    });
  }

  /// Update a record
  Future<ModuleRecord> updateRecord(
      String moduleName, int id, Map<String, dynamic> data) async {
    return _safeCall(() async {
      final response = await _dio.put(
        '/api/m/$moduleName/records/$id',
        data: {
          ...data,
          'updatedBy': _authService.userEmail,
        },
      );
      return ModuleRecord.fromJson(response.data);
    });
  }

  /// Delete a record
  Future<void> deleteRecord(String moduleName, int id) async {
    return _safeCall(() async {
      await _dio.delete('/api/m/$moduleName/records/$id');
    });
  }

  /// Search records by ID (for barcode scanner)
  Future<ModuleRecord?> findRecordById(String moduleName, int id) async {
    try {
      return await getRecord(moduleName, id);
    } catch (e) {
      debugPrint('findRecordById error: $e');
      return null;
    }
  }

  // ============ IMAGES ============

  /// Upload an image to a record (base64 encoded)
  Future<Map<String, dynamic>> uploadImage(
      String moduleName, int recordId, String base64Image) async {
    return _safeCall(() async {
      final response = await _dio.post(
        '/api/m/$moduleName/records/$recordId/images',
        data: {
          'image': base64Image,
          'createdBy': _authService.userEmail,
        },
      );
      return response.data;
    });
  }

  /// Delete an image from a record
  Future<void> deleteImage(String moduleName, int recordId, int imageId) async {
    return _safeCall(() async {
      await _dio.delete('/api/m/$moduleName/records/$recordId/images/$imageId');
    });
  }
}

/// Result of a connection test
class ConnectionTestResult {
  final bool success;
  final String message;

  ConnectionTestResult({required this.success, required this.message});
}
