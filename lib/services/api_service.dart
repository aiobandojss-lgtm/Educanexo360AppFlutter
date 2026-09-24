// lib/services/api_service.dart
import '../utils/logger.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../config/app_config.dart';
import 'session_generation.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;

  // Dio sin interceptores, exclusivo para /auth/refresh-token.
  // Evita que un 401 del refresh vuelva a entrar al manejo de 401 (deadlock).
  late final Dio _refreshDio;

  // Refresh en curso compartido: todos los 401 simultáneos esperan el mismo
  // Future, que siempre se completa (token, null o error).
  Future<String?>? _refreshFuture;

  // Rutas de autenticación que nunca disparan un refresh
  static const List<String> _noRefreshPaths = [
    '/auth/login',
    '/auth/refresh-token',
    '/auth/logout',
  ];

  // Marca en requestOptions.extra para reintentar una sola vez
  static const String _retriedKey = '_retriedAfterRefresh';

  // Generación de sesión con la que se inició cada petición (2B.4)
  static const String _sessionGenKey = '_sessionGeneration';

  /// La petición se inició en una sesión que ya se cerró. Sin marca (p. ej.
  /// cancelada antes de pasar por onRequest) no se considera vieja.
  static bool _isStaleRequest(RequestOptions options) {
    final generation = options.extra[_sessionGenKey];
    return generation != null && generation != SessionGeneration.current;
  }

  static DioException _staleError(RequestOptions options) => DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: const StaleSessionException(),
      );

  static bool _isStaleError(DioException e) =>
      e.error is StaleSessionException;

  /// Respuesta descartada: un Future que nunca se completa. Ni los datos ni
  /// un error de la sesión anterior llegan al provider (clearState ya limpió
  /// su estado y la pantalla que la pidió se cerró al ir al login).
  static Future<T> _discarded<T>() => Completer<T>().future;

  // Subidas multipart: más tiempo que el global de 15 s (redes móviles lentas)
  static const Duration _multipartTimeout = Duration(seconds: 120);

  /// Opciones por petición para multipart; null para el resto (usa globales)
  static Options? _multipartOptions(dynamic data) => data is FormData
      ? Options(
          sendTimeout: _multipartTimeout,
          receiveTimeout: _multipartTimeout,
        )
      : null;

  /// Callback registrado por AuthProvider para manejar sesión expirada.
  /// Se invoca cuando el refreshToken falla y no hay forma de recuperar la sesión.
  static Function? onSessionExpired;

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

    _refreshDio = Dio(BaseOptions(
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

  /// Solo para pruebas: reemplaza el adaptador HTTP de ambas instancias Dio.
  @visibleForTesting
  set httpClientAdapter(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
    _refreshDio.httpClientAdapter = adapter;
  }

  // ==========================================
  // CONFIGURACIÓN DE INTERCEPTORS
  // ==========================================

  void _setupInterceptors() {
    // REQUEST INTERCEPTOR - Agregar token automáticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Marcar la sesión vigente (se conserva en el reintento tras refresh)
          options.extra.putIfAbsent(
              _sessionGenKey, () => SessionGeneration.current);

          // Obtener token del storage
          final token = await StorageService.getToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            dlog('📤 ${options.method} ${options.path} (con token)');
          } else {
            dlog('📤 ${options.method} ${options.path} (sin token)');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          dlog('✅ ${response.statusCode} ${response.requestOptions.path}');
          if (_isStaleRequest(response.requestOptions)) {
            dlog('🗑️ Respuesta de una sesión anterior descartada');
            return handler.reject(_staleError(response.requestOptions));
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          dlog(
              '❌ Error ${error.response?.statusCode} ${error.requestOptions.path}');

          final options = error.requestOptions;

          // Error de una sesión anterior: descartar, nunca intentar refresh
          if (_isStaleRequest(options)) {
            return handler.next(_staleError(options));
          }

          final isAuthPath =
              _noRefreshPaths.any((path) => options.path.contains(path));
          final alreadyRetried = options.extra[_retriedKey] == true;

          // 401 en una ruta normal que aún no se reintentó → intentar refresh
          if (error.response?.statusCode == 401 &&
              !isAuthPath &&
              !alreadyRetried) {
            final String? newToken;
            try {
              newToken = await _refreshAccessToken();
            } on DioException catch (refreshError) {
              // La sesión se cerró mientras se refrescaba: descartar
              if (_isStaleRequest(options)) {
                return handler.next(_staleError(options));
              }
              // Fallo de red/timeout/5xx en el refresh: la sesión se conserva
              // y se propaga el error de red a la petición original
              return handler.next(DioException(
                requestOptions: options,
                response: refreshError.response,
                type: refreshError.type,
                error: refreshError.error,
                message: refreshError.message,
              ));
            }

            // La sesión se cerró mientras se refrescaba: descartar
            if (_isStaleRequest(options)) {
              return handler.next(_staleError(options));
            }

            if (newToken != null) {
              // Reintentar la petición original una sola vez con el nuevo token
              options.headers['Authorization'] = 'Bearer $newToken';
              options.extra[_retriedKey] = true;

              // Un FormData ya enviado no se puede reutilizar: se clona
              // (MultipartFile.fromFile vuelve a leer el archivo desde disco)
              if (options.data is FormData) {
                options.data = (options.data as FormData).clone();
              }

              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
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

  /// Devuelve el nuevo access token, o null si la sesión expiró
  /// (refresh rechazado con 401/403 o success:false).
  /// Lanza DioException si el refresh falla por red, timeout o error del
  /// servidor: en ese caso los tokens se conservan.
  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??=
        _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _doRefresh() async {
    dlog('🔄 Refrescando token...');

    final refreshToken = await StorageService.getRefreshToken();

    if (refreshToken == null) {
      dlog('❌ No hay refresh token');
      await _clearAuthAndNotify(expectedRefreshToken: null);
      return null;
    }

    final Response response;
    try {
      response = await _refreshDio.post(
        AppConfig.authRefreshToken,
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        dlog('❌ Refresh token rechazado ($statusCode) - sesión expirada');
        await _clearAuthAndNotify(expectedRefreshToken: refreshToken);
        return null;
      }
      // Red, timeout o error del servidor: no cerrar sesión
      dlog('⚠️ Refresh falló sin rechazo del servidor (${e.type}) - '
          'se conserva la sesión');
      rethrow;
    }

    final body = response.data;
    if (body is! Map) {
      // Ej.: página HTML de un proxy con 200. No es un rechazo del servidor
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Respuesta de refresh no es JSON',
      );
    }
    if (body['success'] != true) {
      dlog('❌ Refresh respondió success:false - sesión expirada');
      await _clearAuthAndNotify(expectedRefreshToken: refreshToken);
      return null;
    }

    final String newToken;
    final dynamic newRefreshToken;
    try {
      // El backend responde data: { access: {token}, refresh: {token} }
      final tokens = body['data'];
      newToken = tokens['access']['token'] as String;
      newRefreshToken = tokens['refresh']?['token'];
    } catch (e) {
      // Respuesta inesperada del servidor: tratar como error de servidor
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Respuesta de refresh inesperada: $e',
      );
    }

    // Si la sesión cambió mientras se refrescaba (logout y login de otro
    // usuario), no pisar los tokens de la sesión nueva
    if (await StorageService.getRefreshToken() != refreshToken) {
      dlog('⚠️ La sesión cambió durante el refresh - se descarta el resultado');
      return null;
    }

    await StorageService.saveToken(newToken);

    // El backend rota el refresh token en cada renovación
    if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
      await StorageService.saveRefreshToken(newRefreshToken);
    }

    dlog('✅ Token refrescado exitosamente');
    return newToken;
  }

  /// Expira la sesión solo si sigue siendo la que inició el refresh
  /// (mismo refresh token guardado): nunca borra la sesión de otro usuario
  /// que haya iniciado sesión mientras el refresh estaba en curso.
  Future<void> _clearAuthAndNotify(
      {required String? expectedRefreshToken}) async {
    if (await StorageService.getRefreshToken() != expectedRefreshToken) {
      dlog('⚠️ La sesión cambió durante el refresh - no se expira');
      return;
    }
    await StorageService.clearAll();
    dlog('🚪 Sesión expirada - redirigiendo a login');
    onSessionExpired?.call();
  }

  // ==========================================
  // MÉTODOS HTTP PRINCIPALES
  // ==========================================

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      if (_isStaleError(e)) return _discarded();
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      // ✅ LOGS DE DEBUG
      dlog('🌐 ========== POST DEBUG ==========');
      dlog('📍 BaseURL: ${_dio.options.baseUrl}');
      dlog('📍 Endpoint: $endpoint');
      dlog('📍 URL Final: ${_dio.options.baseUrl}$endpoint');
      dlog('📦 Data type: ${data.runtimeType}');
      if (data is Map) {
        dlog('📦 Data keys: ${(data).keys}');
      }
      dlog('==================================\n');

      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: _multipartOptions(data),
        onSendProgress: onSendProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      if (_isStaleError(e)) return _discarded();
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
        options: _multipartOptions(data),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      if (_isStaleError(e)) return _discarded();
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
      if (_isStaleError(e)) return _discarded();
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
      if (_isStaleError(e)) return _discarded();
      throw _handleError(e);
    }
  }

  /// POST con FormData (para subir archivos)
  Future<Map<String, dynamic>> postFormData(
    String endpoint,
    FormData formData, {
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: _multipartTimeout,
          receiveTimeout: _multipartTimeout,
        ),
        onSendProgress: onSendProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      if (_isStaleError(e)) return _discarded();
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
    dlog('🔍 Error details:');
    dlog('   Type: ${error.type}');
    dlog('   Message: ${error.message}');
    dlog('   Response: ${error.response?.data}');

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
      dlog('🔍 Verificando conexión con backend...');
      final response = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      dlog('✅ Backend disponible');
      return response.statusCode == 200;
    } catch (e) {
      dlog('❌ Backend no disponible: $e');
      return false;
    }
  }

  // Agregar al final de la clase ApiService
  Future<Response> download(String endpoint, String savePath) async {
    try {
      dlog('⬇️ Descargando archivo...');
      dlog('   Endpoint: $endpoint');
      dlog('   Destino: $savePath');

      final response = await _dio.download(
        endpoint,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            dlog('📥 Progreso: $progress%');
          }
        },
      );

      dlog('✅ Descarga completada');
      return response;
    } on DioException catch (e) {
      if (_isStaleError(e)) return _discarded();
      dlog('❌ Error en descarga: $e');
      rethrow;
    } catch (e) {
      dlog('❌ Error en descarga: $e');
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

/// Marca de una respuesta que pertenece a una sesión ya cerrada (2B.4)
class StaleSessionException implements Exception {
  const StaleSessionException();

  @override
  String toString() => 'StaleSessionException';
}

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
