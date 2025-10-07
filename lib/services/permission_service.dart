// lib/services/permission_service.dart

/// ⭐ SERVICIO CRÍTICO DE PERMISOS - VERSIÓN CORREGIDA
///
/// Permisos actualizados según implementación de React Native en producción

import '../models/usuario.dart';

class PermissionService {
  // ==========================================
  // MAPEO ROL → PERMISOS (Sistema actual)
  // CORREGIDO según React Native en producción
  // ==========================================

  static const Map<String, List<String>> _rolePermissions = {
    'SUPER_ADMIN': [
      'mensajes.enviar',
      'mensajes.enviar_masivo',
      'mensajes.ver_todos',
      'mensajes.eliminar',
      'calificaciones.ver',
      'calificaciones.ver_todas',
      'calificaciones.crear',
      'calificaciones.editar',
      'calificaciones.eliminar',
      'calificaciones.reportes',
      'usuarios.ver',
      'usuarios.crear',
      'usuarios.editar',
      'usuarios.eliminar',
      'usuarios.cambiar_password',
      'cursos.ver',
      'cursos.crear',
      'cursos.editar',
      'cursos.eliminar',
      'cursos.gestionar_estudiantes',
      'calendario.ver',
      'calendario.crear',
      'calendario.editar',
      'calendario.eliminar',
      'asistencia.ver',
      'asistencia.registrar',
      'asistencia.editar',
      'asistencia.reportes',
      'anuncios.ver',
      'anuncios.crear',
      'anuncios.editar',
      'anuncios.eliminar',
      'config.escuela',
      'config.periodos',
      'config.roles',
    ],
    'ADMIN': [
      'mensajes.enviar',
      'mensajes.enviar_masivo',
      'mensajes.ver_todos',
      'calificaciones.ver_todas',
      'calificaciones.crear',
      'calificaciones.editar',
      'calificaciones.reportes',
      'usuarios.ver',
      'usuarios.crear',
      'usuarios.editar',
      'cursos.ver',
      'cursos.crear',
      'cursos.editar',
      'cursos.gestionar_estudiantes',
      'calendario.ver',
      'calendario.crear',
      'calendario.editar',
      'asistencia.ver',
      'asistencia.registrar',
      'asistencia.reportes',
      'anuncios.ver',
      'anuncios.crear', // ✅ ADMIN puede crear
      'anuncios.editar', // ✅ ADMIN puede editar
      'anuncios.eliminar', // ✅ ADMIN puede eliminar
      'config.escuela',
      'config.periodos',
    ],
    'RECTOR': [
      'mensajes.enviar',
      'mensajes.enviar_masivo',
      'mensajes.ver_todos',
      'calificaciones.ver_todas',
      'calificaciones.reportes',
      'usuarios.ver',
      'cursos.ver',
      'calendario.ver',
      'calendario.crear',
      'calendario.editar',
      'asistencia.ver',
      'asistencia.reportes',
      'anuncios.ver',
      'anuncios.crear', // ✅ RECTOR puede crear
      'anuncios.editar', // ✅ RECTOR puede editar
      'config.periodos',
    ],
    'COORDINADOR': [
      'mensajes.enviar',
      'mensajes.enviar_masivo',
      'calificaciones.ver_todas',
      'calificaciones.reportes',
      'usuarios.ver',
      'cursos.ver',
      'cursos.gestionar_estudiantes',
      'calendario.ver',
      'calendario.crear',
      'calendario.editar',
      'asistencia.ver',
      'asistencia.registrar',
      'asistencia.editar',
      'asistencia.reportes',
      'anuncios.ver',
      // ⚠️ COORDINADOR NO puede crear anuncios en producción
      'anuncios.editar', // ✅ COORDINADOR puede editar
    ],
    'ADMINISTRATIVO': [
      'mensajes.enviar',
      'usuarios.ver',
      'cursos.ver',
      'calendario.ver',
      'asistencia.ver',
      'anuncios.ver',
      'anuncios.crear', // ✅ ADMINISTRATIVO puede crear
      // ⚠️ ADMINISTRATIVO NO puede editar anuncios
    ],
    'DOCENTE': [
      'mensajes.enviar',
      'mensajes.enviar_masivo',
      'calificaciones.ver',
      'calificaciones.crear',
      'calificaciones.editar',
      'calendario.ver',
      'calendario.crear',
      'asistencia.ver',
      'asistencia.registrar',
      'anuncios.ver',
      'anuncios.crear', // ✅ DOCENTE puede crear
      'anuncios.editar', // ✅ DOCENTE puede editar
    ],
    'ESTUDIANTE': [
      'mensajes.enviar',
      'calificaciones.ver',
      'calendario.ver',
      'asistencia.ver',
      'anuncios.ver',
    ],
    'ACUDIENTE': [
      'mensajes.enviar',
      'calificaciones.ver',
      'calendario.ver',
      'asistencia.ver',
      'anuncios.ver',
    ],
  };

  // Usuario actual (se setea desde AuthService)
  static String? _currentUserRole;
  static List<String>? _currentUserPermissions; // Para sistema futuro

  /// Limpiar usuario (logout)
  static void clearUser() {
    _currentUserRole = null;
    _currentUserPermissions = null;
  }

  // ==========================================
  // MÉTODO PRINCIPAL - LA UI USA SOLO ESTE
  // ==========================================

  /// Verifica si el usuario actual tiene un permiso específico
  ///
  /// Ejemplo:
  /// ```dart
  /// if (PermissionService.canAccess('anuncios.crear')) {
  ///   // Mostrar botón crear anuncio
  /// }
  /// ```
  static bool canAccess(String permission) {
    // Si no hay usuario, no tiene permisos
    if (_currentUserRole == null) return false;

    // AHORA: Usa mapeo local rol → permisos
    final permissions = _rolePermissions[_currentUserRole] ?? [];
    return permissions.contains(permission);

    // DESPUÉS (cuando backend cambie): Solo cambiar a esto ↓
    // return _currentUserPermissions?.contains(permission) ?? false;
  }

  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================

  /// Verifica si tiene AL MENOS UNO de los permisos
  static bool canAccessAny(List<String> permissions) {
    return permissions.any((p) => canAccess(p));
  }

  /// Verifica si tiene TODOS los permisos
  static bool canAccessAll(List<String> permissions) {
    return permissions.every((p) => canAccess(p));
  }

  /// Obtiene lista completa de permisos del usuario actual
  static List<String> getUserPermissions() {
    if (_currentUserRole == null) return [];
    return _rolePermissions[_currentUserRole] ?? [];
  }

  /// Verifica si es administrador (cualquier tipo)
  static bool isAdmin() {
    if (_currentUserRole == null) return false;
    return ['SUPER_ADMIN', 'ADMIN', 'RECTOR'].contains(_currentUserRole);
  }

  /// Verifica si es docente
  static bool isDocente() {
    return _currentUserRole == 'DOCENTE';
  }

  /// Verifica si es estudiante
  static bool isEstudiante() {
    return _currentUserRole == 'ESTUDIANTE';
  }

  /// Verifica si es acudiente
  static bool isAcudiente() {
    return _currentUserRole == 'ACUDIENTE';
  }

  /// Debug: Ver estado actual
  static void debugPermissions() {
    print('🔍 === PERMISSION SERVICE DEBUG ===');
    print('Current Role: $_currentUserRole');
    print('Permissions: ${getUserPermissions().length}');
    print('Is Admin: ${isAdmin()}');
    print('================================');
  }

  // ==========================================
  // GESTIÓN DE USUARIO ACTUAL
  // ==========================================

  static Usuario? _currentUser;

  /// Establecer usuario actual (llamado desde AuthService)
  static void setCurrentUser(Usuario user) {
    _currentUser = user;
    _currentUserRole = user.tipo.toString().split('.').last.toUpperCase();
    _currentUserPermissions = user.permisos;
    print(
        '✅ PermissionService - Usuario establecido: ${user.nombre} (${user.tipo})');
  }

  /// Limpiar usuario actual
  static void clearCurrentUser() {
    _currentUser = null;
    print('🧹 PermissionService - Usuario limpiado');
  }

  /// Obtener usuario actual
  static Usuario? getCurrentUser() => _currentUser;
}
