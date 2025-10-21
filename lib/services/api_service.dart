// lib/services/api_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  bool _isRefreshing = false;
  final List<Function> _refreshSubscribers = [];

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  // ==========================================
  // CONFIGURACIÓN DE INTERCEPTORS
  // ==========================================

  void _setupInterceptors() {
    // REQUEST INTERCEPTOR - Agregar token automáticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Obtener token del storage
          final token = await StorageService.getToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('📤 ${options.method} ${options.path} (con token)');
          } else {
            print('📤 ${options.method} ${options.path} (sin token)');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print(
              '❌ Error ${error.response?.statusCode} ${error.requestOptions.path}');

          // Si es 401 (no autorizado) y no es la ruta de login
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login')) {
            // Intentar refresh token
            final newToken = await _handleTokenRefresh();

            if (newToken != null) {
              // Reintentar request original con nuevo token
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';

              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ==========================================
  // MANEJO DE REFRESH TOKEN
  // ==========================================

  Future<String?> _handleTokenRefresh() async {
    if (_isRefreshing) {
      // Si ya se está refrescando, esperar
      return await _waitForRefresh();
    }

    _isRefreshing = true;

    try {
      print('🔄 Refrescando token...');

      final refreshToken = await StorageService.getRefreshToken();

      if (refreshToken == null) {
        print('❌ No hay refresh token');
        await _clearAuthAndNotify();
        return null;
      }

      // Llamar al endpoint de refresh token
      final response = await _dio.post(
        AppConfig.authRefreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success']) {
        final newToken = response.data['data']['token'] as String;
        await StorageService.saveToken(newToken);

        print('✅ Token refrescado exitosamente');

        // Notificar a subscribers que el token está listo
        _notifyRefreshSubscribers(newToken);

        return newToken;
      } else {
        await _clearAuthAndNotify();
        return null;
      }
    } catch (e) {
      print('❌ Error refrescando token: $e');
      await _clearAuthAndNotify();
      return null;
    } finally {
      _isRefreshing = false;
      _refreshSubscribers.clear();
    }
  }

  Future<String?> _waitForRefresh() async {
    final completer = Completer<String?>();
    _refreshSubscribers.add((String? token) {
      completer.complete(token);
    });
    return completer.future;
  }

  void _notifyRefreshSubscribers(String token) {
    for (var callback in _refreshSubscribers) {
      callback(token);
    }
  }

  Future<void> _clearAuthAndNotify() async {
    await StorageService.clearAll();
    // Aquí podrías emitir un evento para que la app redirija al login
    print('🚪 Sesión expirada - redirigir a login');
  }

  // ==========================================
  // MÉTODOS HTTP PRINCIPALES
  // ==========================================

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST con FormData (para subir archivos)
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData,
  ) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==========================================
  // MANEJO DE RESPUESTAS Y ERRORES
  // ==========================================

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    // Si la respuesta no es un Map, intentar convertirla
    return {
      'success': true,
      'data': response.data,
      'message': 'Success',
    };
  }

  Exception _handleError(DioException error) {
    print('🔍 Error details:');
    print('   Type: ${error.type}');
    print('   Message: ${error.message}');
    print('   Response: ${error.response?.data}');

    if (error.response != null) {
      // Error de respuesta del servidor
      final data = error.response!.data;
      final message = data is Map
          ? data['message'] ?? 'Error del servidor'
          : 'Error del servidor';
      final statusCode = error.response!.statusCode ?? 0;

      return ApiException(
        message: message,
        statusCode: statusCode,
        data: data,
      );
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Tiempo de espera agotado. Verifica tu conexión.',
        statusCode: 0,
      );
    } else if (error.type == DioExceptionType.unknown) {
      return ApiException(
        message:
            'No se pudo conectar con el servidor. Verifica tu conexión a internet.',
        statusCode: 0,
      );
    } else {
      return ApiException(
        message: error.message ?? 'Error desconocido',
        statusCode: 0,
      );
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Verificar conectividad con el backend
  Future<bool> checkConnection() async {
    try {
      print('🔍 Verificando conexión con backend...');
      final response = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      print('✅ Backend disponible');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend no disponible: $e');
      return false;
    }
  }

  // Agregar al final de la clase ApiService
  Future<Response> download(String endpoint, String savePath) async {
    try {
      print('⬇️ Descargando archivo...');
      print('   Endpoint: $endpoint');
      print('   Destino: $savePath');

      final response = await _dio.download(
        endpoint,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('📥 Progreso: $progress%');
          }
        },
      );

      print('✅ Descarga completada');
      return response;
    } catch (e) {
      print('❌ Error en descarga: $e');
      rethrow;
    }
  }

  /// Limpiar caché de Dio
  void clearCache() {
    _dio.interceptors.clear();
    _setupInterceptors();
  }
}

// ==========================================
// EXCEPCIÓN PERSONALIZADA
// ==========================================

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

// Singleton instance
final apiService = ApiService();
