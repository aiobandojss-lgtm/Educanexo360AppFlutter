// lib/services/auth_service.dart
import '../models/usuario.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'permission_service.dart';

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
      print('\n🔐 === INICIANDO LOGIN ===');
      print('📧 Email: $email');

      // Limpiar cualquier sesión anterior
      await logout(silent: true);

      // Hacer petición de login
      final response = await apiService.post(
        AppConfig.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('📦 Respuesta del backend recibida');

      // Verificar respuesta
      if (response['success'] != true) {
        throw AuthException('Credenciales incorrectas');
      }

      final data = response['data'];

      // Extraer tokens (tu backend usa estructura: tokens.access.token)
      final tokens = data['tokens'];
      final accessToken = tokens['access']['token'] as String;
      final refreshToken = tokens['refresh']['token'] as String;

      print('🔑 Tokens extraídos:');
      print('   Access: ${accessToken.substring(0, 20)}...');
      print('   Refresh: ${refreshToken.substring(0, 20)}...');

      // Guardar tokens
      await StorageService.saveToken(accessToken);
      await StorageService.saveRefreshToken(refreshToken);
      print('✅ Tokens guardados en storage');

      // Crear objeto Usuario desde la respuesta
      final userJson = data['user'];
      final user = Usuario.fromJson(userJson);

      // Guardar usuario
      await StorageService.saveUser(user);
      _currentUser = user;
      print('✅ Usuario guardado: ${user.nombre} ${user.apellidos}');

      // Actualizar PermissionService con el usuario actual
      PermissionService.setCurrentUser(user);
      print('✅ PermissionService actualizado');

      print('🎉 Login exitoso\n');

      return AuthResponse(
        success: true,
        user: user,
        token: accessToken,
        refreshToken: refreshToken,
        message: 'Inicio de sesión exitoso',
      );
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.message}');
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      print('❌ Error inesperado: $e');
      return AuthResponse(
        success: false,
        message: 'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  /// Cerrar sesión
  Future<void> logout({bool silent = false}) async {
    try {
      if (!silent) print('\n🚪 === CERRANDO SESIÓN ===');

      // Intentar llamar al endpoint de logout (opcional)
      try {
        await apiService.post(AppConfig.authLogout);
      } catch (e) {
        // Ignorar errores del backend en logout
        if (!silent) print('⚠️ Error en logout del backend (ignorado): $e');
      }

      // Limpiar storage local
      await StorageService.clearAll();

      // Limpiar usuario actual
      _currentUser = null;

      // Limpiar PermissionService
      PermissionService.clearCurrentUser();

      if (!silent) print('✅ Sesión cerrada correctamente\n');
    } catch (e) {
      if (!silent) print('❌ Error cerrando sesión: $e\n');
      rethrow;
    }
  }

  // ==========================================
  // VERIFICAR SESIÓN
  // ==========================================

  /// Verificar si hay una sesión válida
  Future<bool> checkSession() async {
    try {
      print('\n🔍 === VERIFICANDO SESIÓN ===');

      // Verificar si hay token y usuario guardados
      final hasSession = await StorageService.hasValidSession();

      if (!hasSession) {
        print('❌ No hay sesión guardada\n');
        return false;
      }

      // Recuperar usuario del storage
      final user = await StorageService.getUser();

      if (user == null) {
        print('❌ No se pudo recuperar usuario\n');
        return false;
      }

      // Actualizar estado
      _currentUser = user;
      PermissionService.setCurrentUser(user);

      print('✅ Sesión válida encontrada');
      print('👤 Usuario: ${user.nombre} ${user.apellidos} (${user.tipo})');
      print(
          '🎯 Permisos cargados: ${PermissionService.getUserPermissions().length}\n');

      return true;
    } catch (e) {
      print('❌ Error verificando sesión: $e\n');
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
      print('\n🔄 === ACTUALIZANDO USUARIO ===');

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

      print('✅ Usuario actualizado correctamente\n');

      return updatedUser;
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.message}\n');
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
      print('\n🔒 === CAMBIANDO CONTRASEÑA ===');

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

      print('✅ Contraseña cambiada exitosamente\n');
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.message}\n');
      throw AuthException(e.message);
    }
  }

  // ==========================================
  // RECUPERAR CONTRASEÑA
  // ==========================================

  /// Solicitar recuperación de contraseña
  Future<void> forgotPassword(String email) async {
    try {
      print('\n📧 === RECUPERAR CONTRASEÑA ===');
      print('Email: $email');

      final response = await apiService.post(
        AppConfig.authForgotPassword,
        data: {'email': email},
      );

      if (response['success'] != true) {
        throw AuthException(
            response['message'] ?? 'Error solicitando recuperación');
      }

      print('✅ Email de recuperación enviado\n');
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.message}\n');
      throw AuthException(e.message);
    }
  }

  /// Restablecer contraseña con token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      print('\n🔐 === RESTABLECER CONTRASEÑA ===');

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

      print('✅ Contraseña restablecida exitosamente\n');
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.message}\n');
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
  void debugPrint() {
    print('\n👤 ===== AUTH SERVICE DEBUG =====');
    print('Autenticado: ${isAuthenticated ? "SÍ" : "NO"}');
    if (_currentUser != null) {
      print('Usuario: ${_currentUser!.nombre} ${_currentUser!.apellidos}');
      print('Email: ${_currentUser!.email}');
      print('Rol: ${_currentUser!.tipo}');
      print('ID: ${_currentUser!.id}');
      print('Escuela: ${_currentUser!.escuelaId ?? "N/A"}');
      print('Permisos: ${PermissionService.getUserPermissions().length}');
    }
    print('===============================\n');
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
