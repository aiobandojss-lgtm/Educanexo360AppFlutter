// lib/providers/auth_provider.dart
import '../utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/api_service.dart';

/// Provider para gestión del estado de autenticación
/// Wrapper sobre AuthService con notificaciones automáticas a la UI
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = authService;

  // Estados
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Usuario? _currentUser;
  String? _errorMessage;

  /// Callback para limpiar el estado de los demás providers al cerrar sesión
  /// o al expirar la sesión. Se asigna en main.dart.
  VoidCallback? onSessionCleared;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Usuario? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  // Getter para permisos (acceso rápido)
  bool canAccess(String permission) {
    return PermissionService.canAccess(permission);
  }

  /// Constructor
  AuthProvider() {
    _initializeAuth();
  }

  /// Inicializar - verificar si hay sesión guardada
  Future<void> _initializeAuth() async {
    // Registrar callback para cuando el token expire y no se pueda renovar.
    // ApiService lo invoca desde _clearAuthAndNotify() tras un 401 irrecuperable.
    ApiService.onSessionExpired =
        (tokenExpirado) => _handleSessionExpired(tokenExpirado);

    _setLoading(true);
    try {
      final hasSession = await _authService.checkSession();
      _isAuthenticated = hasSession;
      _currentUser = _authService.currentUser;
      _errorMessage = null;

      if (hasSession) {
        dlog('🔐 AuthProvider: Sesión existente encontrada');
        dlog('   Usuario: ${_currentUser?.nombreCompleto}');
        dlog('   Rol: ${_currentUser?.tipo.value}');
      } else {
        dlog('🔐 AuthProvider: No hay sesión activa');
      }
    } catch (e) {
      _errorMessage = mensajeDeError(e, 'Error al verificar sesión');
      dlog('❌ AuthProvider: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      dlog('🔐 AuthProvider: Intentando login...');
      dlog('   Email: $email');

      final response = await _authService.login(email, password);

      if (response.success) {
        _isAuthenticated = true;
        _currentUser = _authService.currentUser;
        dlog('✅ AuthProvider: Login exitoso');
        dlog('   Usuario: ${_currentUser?.nombreCompleto}');
        dlog('   Rol: ${_currentUser?.tipo.value}');
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Credenciales incorrectas';
        dlog('❌ AuthProvider: $_errorMessage');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      dlog('❌ AuthProvider: Error en login - $_errorMessage');
      _setLoading(false);
      return false;
    }
  }

  /// Logout — limpia almacenamiento y estado local antes de notificar a la UI.
  /// Las llamadas de red del logout corren en segundo plano (AuthService).
  Future<void> logout() async {
    dlog('🔐 AuthProvider: Cerrando sesión...');
    try {
      await _authService.logout();
    } catch (e) {
      dlog('⚠️ AuthProvider: Error limpiando la sesión local - $e');
    }
    _resetSessionState(); // GoRouter redirige a /login
  }

  /// Actualizar usuario (después de editar perfil)
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = await _authService.updateUser(
        _currentUser!.id,
      );
      _currentUser = updatedUser;
      notifyListeners();
      dlog('✅ AuthProvider: Usuario actualizado');
    } catch (e) {
      dlog('❌ AuthProvider: Error al actualizar usuario - $e');
    }
  }

  /// Cambiar contraseña
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(
        userId: _currentUser!.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      dlog('✅ AuthProvider: Contraseña cambiada');
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      dlog('❌ AuthProvider: Error al cambiar contraseña - $_errorMessage');
      _setLoading(false);
      return false;
    }
  }

  /// Recuperar contraseña
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.forgotPassword(email);

      dlog('✅ AuthProvider: Email de recuperación enviado');
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      dlog('❌ AuthProvider: Error en recuperación - $_errorMessage');
      _setLoading(false);
      return false;
    }
  }

  // === MÉTODOS PRIVADOS ===

  /// Maneja la expiración de sesión invocada por ApiService.
  /// Limpia el estado y notifica al GoRouter para redirigir al login.
  Future<void> _handleSessionExpired(String? tokenExpirado) async {
    try {
      // El storage ya se borró: se pasa el token capturado por ApiService
      await _authService.logout(silent: true, accessTokenOverride: tokenExpirado);
    } catch (e) {
      dlog('⚠️ AuthProvider: Error limpiando la sesión expirada - $e');
    }
    _resetSessionState();
    dlog('🚪 AuthProvider: sesión expirada, redirigiendo a login');
  }

  /// Limpia el estado de autenticación y el de todos los providers
  void _resetSessionState() {
    _isAuthenticated = false;
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    onSessionCleared?.call();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('Connection refused') ||
        errorStr.contains('Failed host lookup')) {
      return 'No se puede conectar al servidor. Verifica tu conexión.';
    }

    if (errorStr.contains('401')) {
      return 'Credenciales incorrectas';
    }

    if (errorStr.contains('403')) {
      return 'Acceso denegado';
    }

    if (errorStr.contains('500')) {
      return 'Error del servidor. Intenta más tarde.';
    }

    if (errorStr.contains('timeout')) {
      return 'La conexión tardó demasiado. Intenta nuevamente.';
    }

    return 'Error inesperado. Intenta nuevamente.';
  }

  /// Debug
  void printDebug() {
    dlog('\n📱 === AUTH PROVIDER STATE ===');
    dlog('Autenticado: $_isAuthenticated');
    dlog('Cargando: $_isLoading');
    dlog('Usuario: ${_currentUser?.nombreCompleto ?? "ninguno"}');
    dlog('Rol: ${_currentUser?.tipo.value ?? "ninguno"}');
    dlog('Error: ${_errorMessage ?? "ninguno"}');
    dlog('============================\n');
  }
}
