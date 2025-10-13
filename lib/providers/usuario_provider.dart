// lib/providers/usuario_provider.dart
// 👥 PROVIDER DE USUARIOS - Siguiendo patrón de anuncio_provider.dart

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

      print('🔥 Cargando usuarios... (refresh: $refresh, silent: $silent)');

      final usuarios = await _usuarioService.getUsers(
        tipo: _currentFilter,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      // ✅ FIX: Guardar lista completa Y lista filtrada
      _todosLosUsuarios = await _usuarioService.getUsers(); // Sin filtros
      _usuarios = usuarios; // Con filtros aplicados

      _isLoading = false;

      print(
          '✅ Usuarios cargados: ${_usuarios.length} (total: ${_todosLosUsuarios.length})');
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando usuarios: $e');
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

    print('🔄 Cambiando filtro: ${newFilter?.displayName ?? "Todos"}');

    _currentFilter = newFilter;
    _searchQuery = ''; // Limpiar búsqueda al cambiar filtro
    notifyListeners();

    await loadUsuarios(refresh: true);
  }

  // ========================================
  // 🔍 BÚSQUEDA
  // ========================================

  Future<void> search(String query) async {
    print('🔍 Buscando: $query');
    _searchQuery = query;
    notifyListeners();
    await loadUsuarios(refresh: true);
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      print('🧹 Limpiando búsqueda');
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
      print('➕ Creando usuario: $email');

      final usuario = await _usuarioService.createUser(
        nombre: nombre,
        apellidos: apellidos,
        email: email,
        password: password,
        tipo: tipo,
        estado: estado,
        escuelaId: escuelaId,
      );

      print('✅ Usuario creado con ID: ${usuario.id}');

      // Refrescar lista
      await loadUsuarios(refresh: true, silent: false);

      return usuario;
    } catch (e) {
      print('❌ Error creando usuario: $e');
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
      print('✏️ Actualizando usuario: $id');

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

      print('✅ Usuario actualizado');
      notifyListeners();

      return usuario;
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR USUARIO
  // ========================================

  Future<void> deleteUsuario(String id) async {
    try {
      print('🗑️ Eliminando usuario: $id');

      // Optimistic update
      _usuarios.removeWhere((u) => u.id == id);
      notifyListeners();

      await _usuarioService.deactivateUser(id);

      print('✅ Usuario eliminado');
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
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
      print('🔑 Cambiando contraseña...');

      if (currentPassword != null) {
        await _usuarioService.changePassword(
          userId: userId,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      } else {
        throw Exception('Se requiere la contraseña actual');
      }

      print('✅ Contraseña cambiada');
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      rethrow;
    }
  }

  // ========================================
  // 👤 OBTENER USUARIO POR ID
  // ========================================

  Future<Usuario?> getUsuarioById(String id) async {
    try {
      print('🔍 Obteniendo usuario: $id');

      // Buscar en cache local
      final localUsuario = _usuarios.where((u) => u.id == id).firstOrNull;
      if (localUsuario != null) {
        print('✅ Usuario encontrado en cache');
        return localUsuario;
      }

      // Obtener del servidor
      print('📡 Obteniendo del servidor...');
      final usuario =
          await _usuarioService.getUserById(id); // ✅ Correcto: getUserById
      print('✅ Usuario obtenido del servidor');
      return usuario;
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      rethrow;
    }
  }

  // ========================================
  // 👨‍👩‍👧‍👦 ESTUDIANTES ASOCIADOS
  // ========================================

  Future<List<Usuario>> getEstudiantesAsociados(String acudienteId) async {
    try {
      print('🎓 Obteniendo estudiantes asociados...');
      return await _usuarioService.getAssociatedStudents(acudienteId);
    } catch (e) {
      print('❌ Error obteniendo estudiantes asociados: $e');
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
      print('🔍 Buscando estudiantes para asociar...');

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
      print('❌ Error buscando estudiantes: $e');
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
      print('➕ Asociando estudiante: $estudianteId a acudiente: $acudienteId');

      await _usuarioService.asociarEstudiante(
        acudienteId: acudienteId,
        estudianteId: estudianteId,
      );

      print('✅ Estudiante asociado correctamente');
    } catch (e) {
      print('❌ Error asociando estudiante: $e');
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
      print(
          '➖ Desasociando estudiante: $estudianteId de acudiente: $acudienteId');

      await _usuarioService.desasociarEstudiante(
        acudienteId: acudienteId,
        estudianteId: estudianteId,
      );

      print('✅ Estudiante desasociado correctamente');
    } catch (e) {
      print('❌ Error desasociando estudiante: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔄 REFRESCAR
  // ========================================

  Future<void> refresh() async {
    print('🔄 Refrescando lista...');
    await loadUsuarios(refresh: true);
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO
  // ========================================

  void clearState() {
    print('🧹 Limpiando estado del provider');
    _usuarios = [];
    _currentFilter = null;
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }
}
