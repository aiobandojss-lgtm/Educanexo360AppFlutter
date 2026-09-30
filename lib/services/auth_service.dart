// lib/services/auth_service.dart
import 'dart:async';
import '../utils/logger.dart';
import '../models/usuario.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'permission_service.dart';
import 'fcm_service.dart';
import 'perfil_rol_service.dart';
import 'session_generation.dart';
import '../utils/file_helper.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Usuario actual
  Usuario? _currentUser;
  Usuario? get currentUser => _currentUser;

  // ==========================================
  // LOGIN
  // ==========================================

  /// Iniciar sesión
  Future<AuthResponse> login(String email, String password) async {
    try {
      dlog('\n🔐 === INICIANDO LOGIN ===');
      dlog('📧 Email: $email');

      // Limpiar cualquier sesión anterior (solo local, sin red)
      await clearLocalSession();

      // Hacer petición de login
      final response = await apiService.post(
        AppConfig.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      dlog('📦 Respuesta del backend recibida');

      // Verificar respuesta
      if (response['success'] != true) {
        throw AuthException('Credenciales incorrectas');
      }

      final data = response['data'];

      // Extraer tokens (tu backend usa estructura: tokens.access.token)
      final tokens = data['tokens'];
      final accessToken = tokens['access']['token'] as String;
      final refreshToken = tokens['refresh']['token'] as String;

      dlog('🔑 Tokens extraídos:');
      dlog('   Access: ${accessToken.substring(0, 20)}...');
      dlog('   Refresh: ${refreshToken.substring(0, 20)}...');

      // Guardar tokens: PRIMERO el refresh. Si un 401 llega entre las dos
      // escrituras, ver un access token sin refresh se trataría como sesión
      // anómala y se borraría el login recién hecho.
      await StorageService.saveRefreshToken(refreshToken);
      await StorageService.saveToken(accessToken);
      dlog('✅ Tokens guardados en storage');

      // Crear objeto Usuario desde la respuesta
      final userJson = data['user'];
      final user = Usuario.fromJson(userJson);

      // Guardar usuario
      await StorageService.saveUser(user);
      _currentUser = user;
      dlog('✅ Usuario guardado: ${user.nombre} ${user.apellidos}');

      // Actualizar PermissionService con el usuario actual
      PermissionService.setCurrentUser(user);
      dlog('✅ PermissionService actualizado');

      // Inicializar FCM y registrar token en backend. El registro no bloquea
      // el login: depende de Firebase y de la red (errores ya se ignoran)
      await FcmService.instance.initialize();
      unawaited(FcmService.instance.registerTokenToBackend());
      dlog('✅ FCM inicializado, registro de token en segundo plano');

      dlog('🎉 Login exitoso\n');

      return AuthResponse(
        success: true,
        user: user,
        token: accessToken,
        refreshToken: refreshToken,
        message: 'Inicio de sesión exitoso',
      );
    } on ApiException catch (e) {
      dlog('❌ Error de API: ${e.message}');
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      dlog('❌ Error inesperado: $e');
      return AuthResponse(
        success: false,
        message: mensajeDeError(e, 'Error al iniciar sesión'),
      );
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  /// Limpia la sesión local: storage, usuario actual, permisos y cachés.
  /// No hace llamadas de red.
  Future<void> clearLocalSession() async {
    // Invalida toda respuesta de red que siga en vuelo de la sesión anterior
    SessionGeneration.next();
    await StorageService.clearAll();
    _currentUser = null;
    PermissionService.clearCurrentUser();
    PerfilRolService.limpiarCache();
    // Documentos descargados del usuario anterior
    await FileHelper.clearDownloads();
    // Segundo incremento: una petición iniciada durante esta limpieza (p. ej.
    // un refresco de pantalla) tampoco debe entregar su respuesta
    SessionGeneration.next();
  }

  /// Cerrar sesión: primero se limpia todo lo local y después se avisa al
  /// servidor en segundo plano. Así las llamadas de red no bloquean la UI
  /// ni pueden borrar los datos de un login que ocurra justo después.
  /// [accessTokenOverride]: token de la sesión que se cierra cuando el storage
  /// ya se borró (sesión expirada), para desvincular el token FCM.
  Future<void> logout({bool silent = false, String? accessTokenOverride}) async {
    // Antes de cualquier await: las respuestas en vuelo de esta sesión (p. ej.
    // el 401 que disparó la expiración) se descartan en vez de llegar a la UI.
    // onSessionExpired llega aquí de forma síncrona hasta el primer await.
    SessionGeneration.next();
    try {
      if (!silent) dlog('\n🚪 === CERRANDO SESIÓN ===');

      // Capturar el token antes de borrarlo (desvinculación FCM, Fase 1)
      final accessToken =
          accessTokenOverride ?? await StorageService.getToken();

      await clearLocalSession();

      // Invalidar el token push del dispositivo para que no lleguen
      // notificaciones del usuario anterior
      unawaited(FcmService.instance.unregisterDevice(accessToken: accessToken));
      unawaited(_notifyServerLogout(silent: silent));

      if (!silent) dlog('✅ Sesión cerrada correctamente\n');
    } catch (e) {
      if (!silent) dlog('❌ Error cerrando sesión: $e\n');
      rethrow;
    }
  }

  /// Llamadas de red del logout (no bloqueantes, errores ignorados)
  Future<void> _notifyServerLogout({bool silent = false}) async {
    try {
      await apiService.post(AppConfig.authLogout);
    } catch (e) {
      // Ignorar errores del backend en logout
      if (!silent) dlog('⚠️ Error en logout del backend (ignorado): $e');
    }
  }

  // ==========================================
  // VERIFICAR SESIÓN
  // ==========================================

  /// Verificar si hay una sesión válida
  Future<bool> checkSession() async {
    try {
      dlog('\n🔍 === VERIFICANDO SESIÓN ===');

      // Verificar si hay token y usuario guardados
      final hasSession = await StorageService.hasValidSession();

      if (!hasSession) {
        dlog('❌ No hay sesión guardada\n');
        return false;
      }

      // Recuperar usuario del storage
      final user = await StorageService.getUser();

      if (user == null) {
        dlog('❌ No se pudo recuperar usuario\n');
        return false;
      }

      // Actualizar estado
      _currentUser = user;
      PermissionService.setCurrentUser(user);

      dlog('✅ Sesión válida encontrada');
      dlog('👤 Usuario: ${user.nombre} ${user.apellidos} (${user.tipo})');
      dlog(
          '🎯 Permisos cargados: ${PermissionService.getUserPermissions().length}\n');

      // Inicializar FCM y registrar/refrescar token (sesión restaurada al abrir la app)
      FcmService.instance.initialize().then((_) {
        FcmService.instance.registerTokenToBackend();
      }).catchError((_) {});

      return true;
    } catch (e) {
      dlog('❌ Error verificando sesión: $e\n');
      return false;
    }
  }

  // ==========================================
  // ACTUALIZAR USUARIO
  // ==========================================

  /// Actualizar datos del usuario actual
  Future<Usuario> updateUser(
    String userId, {
    String? nombre,
    String? apellidos,
    String? email,
    String? telefono,
  }) async {
    try {
      dlog('\n🔄 === ACTUALIZANDO USUARIO ===');

      final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (apellidos != null) data['apellidos'] = apellidos;
      if (email != null) data['email'] = email;
      if (telefono != null) {
        data['perfil'] = {'telefono': telefono};
      }

      final response = await apiService.put(
        AppConfig.usuarioUpdate(userId),
        data: data,
      );

      if (response['success'] != true) {
        throw AuthException('Error actualizando usuario');
      }

      final updatedUser = Usuario.fromJson(response['data']);

      // Actualizar storage y estado
      await StorageService.saveUser(updatedUser);
      _currentUser = updatedUser;
      PermissionService.setCurrentUser(updatedUser);

      dlog('✅ Usuario actualizado correctamente\n');

      return updatedUser;
    } on ApiException catch (e) {
      dlog('❌ Error de API: ${e.message}\n');
      rethrow;
    }
  }

  // ==========================================
  // CAMBIAR CONTRASEÑA
  // ==========================================

  /// Cambiar contraseña del usuario actual
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      dlog('\n🔒 === CAMBIANDO CONTRASEÑA ===');

      final response = await apiService.post(
        AppConfig.usuarioChangePassword(userId),
        data: {
          'passwordActual': currentPassword,
          'nuevaPassword': newPassword,
        },
      );

      if (response['success'] != true) {
        throw AuthException(
            response['message'] ?? 'Error cambiando contraseña');
      }

      dlog('✅ Contraseña cambiada exitosamente\n');
    } on ApiException catch (e) {
      dlog('❌ Error de API: ${e.message}\n');
      throw AuthException(e.message);
    }
  }

  // ==========================================
  // RECUPERAR CONTRASEÑA
  // ==========================================

  /// Solicitar recuperación de contraseña
  Future<void> forgotPassword(String email) async {
    try {
      dlog('\n📧 === RECUPERAR CONTRASEÑA ===');
      dlog('Email: $email');

      final response = await apiService.post(
        AppConfig.authForgotPassword,
        data: {'email': email},
      );

      if (response['success'] != true) {
        throw AuthException(
            response['message'] ?? 'Error solicitando recuperación');
      }

      dlog('✅ Email de recuperación enviado\n');
    } on ApiException catch (e) {
      dlog('❌ Error de API: ${e.message}\n');
      throw AuthException(e.message);
    }
  }

  /// Restablecer contraseña con token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      dlog('\n🔐 === RESTABLECER CONTRASEÑA ===');

      final response = await apiService.post(
        AppConfig.authResetPassword,
        data: {
          'token': token,
          'password': newPassword,
        },
      );

      if (response['success'] != true) {
        throw AuthException(
            response['message'] ?? 'Error restableciendo contraseña');
      }

      dlog('✅ Contraseña restablecida exitosamente\n');
    } on ApiException catch (e) {
      dlog('❌ Error de API: ${e.message}\n');
      throw AuthException(e.message);
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Verificar si el usuario está autenticado
  bool get isAuthenticated => _currentUser != null;

  /// Obtener ID del usuario actual
  String? get currentUserId => _currentUser?.id;

  /// Obtener tipo/rol del usuario actual
  UserRole? get currentUserRole => _currentUser?.tipo;

  /// Debug: mostrar estado actual de autenticación
  void debugState() {
    dlog('\n👤 ===== AUTH SERVICE DEBUG =====');
    dlog('Autenticado: ${isAuthenticated ? "SÍ" : "NO"}');
    if (_currentUser != null) {
      dlog('Usuario: ${_currentUser!.nombre} ${_currentUser!.apellidos}');
      dlog('Email: ${_currentUser!.email}');
      dlog('Rol: ${_currentUser!.tipo}');
      dlog('ID: ${_currentUser!.id}');
      dlog('Escuela: ${_currentUser!.escuelaId ?? "N/A"}');
      dlog('Permisos: ${PermissionService.getUserPermissions().length}');
    }
    dlog('===============================\n');
  }
}

// ==========================================
// EXCEPCIÓN PERSONALIZADA
// ==========================================

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

// Singleton instance
final authService = AuthService();
