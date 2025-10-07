// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';

/// Provider para gestión del estado de autenticación
/// Wrapper sobre AuthService con notificaciones automáticas a la UI
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = authService;

  // Estados
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Usuario? _currentUser;
  String? _errorMessage;

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
    _setLoading(true);
    try {
      final hasSession = await _authService.checkSession();
      _isAuthenticated = hasSession;
      _currentUser = _authService.currentUser;
      _errorMessage = null;

      if (hasSession) {
        print('🔐 AuthProvider: Sesión existente encontrada');
        print('   Usuario: ${_currentUser?.nombreCompleto}');
        print('   Rol: ${_currentUser?.tipo.value}');
      } else {
        print('🔐 AuthProvider: No hay sesión activa');
      }
    } catch (e) {
      _errorMessage = 'Error al verificar sesión: $e';
      print('❌ AuthProvider: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 AuthProvider: Intentando login...');
      print('   Email: $email');

      final response = await _authService.login(email, password);

      if (response.success) {
        _isAuthenticated = true;
        _currentUser = _authService.currentUser;
        print('✅ AuthProvider: Login exitoso');
        print('   Usuario: ${_currentUser?.nombreCompleto}');
        print('   Rol: ${_currentUser?.tipo.value}');
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Credenciales incorrectas';
        print('❌ AuthProvider: $_errorMessage');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('❌ AuthProvider: Error en login - $_errorMessage');
      _setLoading(false);
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      print('🔐 AuthProvider: Cerrando sesión...');
      await _authService.logout();
      _isAuthenticated = false;
      _currentUser = null;
      _clearError();
      print('✅ AuthProvider: Sesión cerrada');
    } catch (e) {
      print('❌ AuthProvider: Error en logout - $e');
    } finally {
      _setLoading(false);
    }
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
      print('✅ AuthProvider: Usuario actualizado');
    } catch (e) {
      print('❌ AuthProvider: Error al actualizar usuario - $e');
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

      print('✅ AuthProvider: Contraseña cambiada');
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('❌ AuthProvider: Error al cambiar contraseña - $_errorMessage');
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

      print('✅ AuthProvider: Email de recuperación enviado');
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      print('❌ AuthProvider: Error en recuperación - $_errorMessage');
      _setLoading(false);
      return false;
    }
  }

  // === MÉTODOS PRIVADOS ===

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
    print('\n📱 === AUTH PROVIDER STATE ===');
    print('Autenticado: $_isAuthenticated');
    print('Cargando: $_isLoading');
    print('Usuario: ${_currentUser?.nombreCompleto ?? "ninguno"}');
    print('Rol: ${_currentUser?.tipo.value ?? "ninguno"}');
    print('Error: ${_errorMessage ?? "ninguno"}');
    print('============================\n');
  }
}
