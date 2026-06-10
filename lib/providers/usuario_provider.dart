// lib/providers/usuario_provider.dart
// 👥 PROVIDER DE USUARIOS - Siguiendo patrón de anuncio_provider.dart

import '../utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../services/permission_service.dart';

class UsuarioProvider with ChangeNotifier {
  final UsuarioService _usuarioService = UsuarioService();

  // ========================================
  // 📊 ESTADO
  // ========================================

  List<Usuario> _todosLosUsuarios = [];
  List<Usuario> _usuarios = [];
  bool _isLoading = false;
  UserRole? _currentFilter;
  String _searchQuery = '';

  // ========================================
  // 🔍 GETTERS
  // ========================================

  List<Usuario> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  UserRole? get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  // Contadores por rol
  Map<UserRole, int> get usuariosPorRol {
    final map = <UserRole, int>{};
    for (final usuario in _todosLosUsuarios) {
      map[usuario.tipo] = (map[usuario.tipo] ?? 0) + 1;
    }
    return map;
  }

  int get totalUsuarios => _todosLosUsuarios.length;

  // ========================================
  // ⚡ PREPARAR ESTADO DE CARGA (para initState)
  // ========================================

  void prepareLoading() {
    _isLoading = true;
  }

  // ========================================
  // 📋 CARGAR USUARIOS
  // ========================================

  Future<void> loadUsuarios({
    bool refresh = false,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }

      dlog('🔥 Cargando usuarios... (refresh: $refresh, silent: $silent)');

      final usuarios = await _usuarioService.getUsers(
        tipo: _currentFilter,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      // ✅ FIX: Guardar lista completa Y lista filtrada
      _todosLosUsuarios = await _usuarioService.getUsers(); // Sin filtros
      _usuarios = usuarios; // Con filtros aplicados

      _isLoading = false;

      dlog(
          '✅ Usuarios cargados: ${_usuarios.length} (total: ${_todosLosUsuarios.length})');
      notifyListeners();
    } catch (e) {
      dlog('❌ Error cargando usuarios: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 🔄 CAMBIAR FILTRO
  // ========================================

  Future<void> changeFilter(UserRole? newFilter) async {
    if (_currentFilter == newFilter) return;

    dlog('🔄 Cambiando filtro: ${newFilter?.displayName ?? "Todos"}');

    _currentFilter = newFilter;
    _searchQuery = ''; // Limpiar búsqueda al cambiar filtro
    notifyListeners();

    await loadUsuarios(refresh: true);
  }

  // ========================================
  // 🔍 BÚSQUEDA
  // ========================================

  Future<void> search(String query) async {
    dlog('🔍 Buscando: $query');
    _searchQuery = query;
    notifyListeners();
    await loadUsuarios(refresh: true);
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      dlog('🧹 Limpiando búsqueda');
      _searchQuery = '';
      loadUsuarios(refresh: true);
    }
  }

  // ========================================
  // ➕ CREAR USUARIO
  // ========================================

  Future<Usuario> createUsuario({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
    required UserRole tipo,
    required UserStatus estado,
    required String escuelaId,
  }) async {
    try {
      dlog('➕ Creando usuario: $email');

      final usuario = await _usuarioService.createUser(
        nombre: nombre,
        apellidos: apellidos,
        email: email,
        password: password,
        tipo: tipo,
        estado: estado,
        escuelaId: escuelaId,
      );

      dlog('✅ Usuario creado con ID: ${usuario.id}');

      // Refrescar lista
      await loadUsuarios(refresh: true, silent: false);

      return usuario;
    } catch (e) {
      dlog('❌ Error creando usuario: $e');
      rethrow;
    }
  }

  // ========================================
  // ✏️ ACTUALIZAR USUARIO
  // ========================================

  Future<Usuario> updateUsuario({
    required String id,
    String? nombre,
    String? apellidos,
    String? email,
    UserRole? tipo,
    UserStatus? estado,
  }) async {
    try {
      dlog('✏️ Actualizando usuario: $id');

      final usuario = await _usuarioService.updateUser(
        id,
        nombre: nombre,
        apellidos: apellidos,
        email: email,
        tipo: tipo, // ✅ AGREGAR
        estado: estado, // ✅ AGREGAR
      );

      // Actualizar en lista local
      final index = _usuarios.indexWhere((u) => u.id == id);
      if (index != -1) {
        _usuarios[index] = usuario;
      }

      dlog('✅ Usuario actualizado');
      notifyListeners();

      return usuario;
    } catch (e) {
      dlog('❌ Error actualizando usuario: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR USUARIO
  // ========================================

  Future<void> deleteUsuario(String id) async {
    try {
      dlog('🗑️ Eliminando usuario: $id');

      // Optimistic update
      _usuarios.removeWhere((u) => u.id == id);
      notifyListeners();

      await _usuarioService.deactivateUser(id);

      dlog('✅ Usuario eliminado');
    } catch (e) {
      dlog('❌ Error eliminando usuario: $e');
      // Recargar en caso de error
      await loadUsuarios(refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 🔑 CAMBIAR CONTRASEÑA
  // ========================================

  Future<void> changePassword({
    required String userId,
    String? currentPassword,
    required String newPassword,
  }) async {
    try {
      dlog('🔑 Cambiando contraseña...');

      if (currentPassword != null) {
        await _usuarioService.changePassword(
          userId: userId,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      } else {
        throw Exception('Se requiere la contraseña actual');
      }

      dlog('✅ Contraseña cambiada');
    } catch (e) {
      dlog('❌ Error cambiando contraseña: $e');
      rethrow;
    }
  }

  // ========================================
  // 👤 OBTENER USUARIO POR ID
  // ========================================

  Future<Usuario?> getUsuarioById(String id) async {
    try {
      dlog('🔍 Obteniendo usuario: $id');

      // Buscar en cache local
      final localUsuario = _usuarios.where((u) => u.id == id).firstOrNull;
      if (localUsuario != null) {
        dlog('✅ Usuario encontrado en cache');
        return localUsuario;
      }

      // Obtener del servidor
      dlog('📡 Obteniendo del servidor...');
      final usuario =
          await _usuarioService.getUserById(id); // ✅ Correcto: getUserById
      dlog('✅ Usuario obtenido del servidor');
      return usuario;
    } catch (e) {
      dlog('❌ Error obteniendo usuario: $e');
      rethrow;
    }
  }

  // ========================================
  // 👨‍👩‍👧‍👦 ESTUDIANTES ASOCIADOS
  // ========================================

  Future<List<Usuario>> getEstudiantesAsociados(String acudienteId) async {
    try {
      dlog('🎓 Obteniendo estudiantes asociados...');
      return await _usuarioService.getAssociatedStudents(acudienteId);
    } catch (e) {
      dlog('❌ Error obteniendo estudiantes asociados: $e');
      return [];
    }
  }

  // ========================================
  // 🔍 BUSCAR ESTUDIANTES PARA ASOCIAR
  // ========================================

  Future<List<Usuario>> buscarEstudiantesParaAsociar({
    String? query,
  }) async {
    try {
      dlog('🔍 Buscando estudiantes para asociar...');

      // Obtener escuelaId del usuario actual
      final currentUser = PermissionService.getCurrentUser();
      if (currentUser?.escuelaId == null) {
        throw Exception('No se pudo obtener la escuela del usuario actual');
      }

      return await _usuarioService.buscarEstudiantesParaAsociar(
        escuelaId: currentUser!.escuelaId!,
        query: query,
      );
    } catch (e) {
      dlog('❌ Error buscando estudiantes: $e');
      rethrow;
    }
  }

  // ========================================
  // ➕ ASOCIAR ESTUDIANTE
  // ========================================

  Future<void> asociarEstudiante({
    required String acudienteId,
    required String estudianteId,
  }) async {
    try {
      dlog('➕ Asociando estudiante: $estudianteId a acudiente: $acudienteId');

      await _usuarioService.asociarEstudiante(
        acudienteId: acudienteId,
        estudianteId: estudianteId,
      );

      dlog('✅ Estudiante asociado correctamente');
    } catch (e) {
      dlog('❌ Error asociando estudiante: $e');
      rethrow;
    }
  }

  // ========================================
  // ➖ DESASOCIAR ESTUDIANTE
  // ========================================

  Future<void> desasociarEstudiante({
    required String acudienteId,
    required String estudianteId,
  }) async {
    try {
      dlog(
          '➖ Desasociando estudiante: $estudianteId de acudiente: $acudienteId');

      await _usuarioService.desasociarEstudiante(
        acudienteId: acudienteId,
        estudianteId: estudianteId,
      );

      dlog('✅ Estudiante desasociado correctamente');
    } catch (e) {
      dlog('❌ Error desasociando estudiante: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔄 REFRESCAR
  // ========================================

  Future<void> refresh() async {
    dlog('🔄 Refrescando lista...');
    await loadUsuarios(refresh: true);
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO
  // ========================================

  void clearState() {
    dlog('🧹 Limpiando estado del provider');
    _usuarios = [];
    _currentFilter = null;
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }
}
