// lib/services/usuario_service.dart
import '../config/app_config.dart';
import '../models/usuario.dart';
import 'api_service.dart';

/// Servicio para gestión de usuarios
/// Equivalente a userService.ts de React Native
class UsuarioService {
  final ApiService _apiService = apiService;

  // ==========================================
  // OBTENER USUARIOS
  // ==========================================

  /// Obtener lista de usuarios (con filtros opcionales)
  Future<List<Usuario>> getUsers({
    UserRole? tipo,
    String? query,
  }) async {
    try {
      print('👥 UsuarioService: Obteniendo usuarios...');

      final queryParams = <String, dynamic>{};
      if (tipo != null) queryParams['tipo'] = tipo.value;
      if (query != null && query.isNotEmpty) queryParams['q'] = query;

      final response = await _apiService.get(
        AppConfig.usuarios,
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final users = data.map((json) => Usuario.fromJson(json)).toList();
        print('✅ ${users.length} usuarios obtenidos');
        return users;
      }

      return [];
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      rethrow;
    }
  }

  /// Obtener usuario por ID
  Future<Usuario> getUserById(String userId) async {
    try {
      print('👤 UsuarioService: Obteniendo usuario $userId...');

      final response = await _apiService.get(
        AppConfig.usuarioDetail(userId),
      );

      if (response['success'] == true) {
        final user = Usuario.fromJson(response['data']);
        print('✅ Usuario obtenido: ${user.nombreCompleto}');
        return user;
      }

      throw Exception('Usuario no encontrado');
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      rethrow;
    }
  }

  // ==========================================
  // ACTUALIZAR USUARIO
  // ==========================================

  /// Actualizar datos de usuario
  Future<Usuario> updateUser(
    String userId, {
    String? nombre,
    String? apellidos,
    String? email,
    String? telefono,
  }) async {
    try {
      print('✏️ UsuarioService: Actualizando usuario $userId...');

      final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (apellidos != null) data['apellidos'] = apellidos;
      if (email != null) data['email'] = email;
      if (telefono != null) {
        data['perfil'] = {'telefono': telefono};
      }

      final response = await _apiService.put(
        AppConfig.usuarioUpdate(userId),
        data: data,
      );

      if (response['success'] == true) {
        final updatedUser = Usuario.fromJson(response['data']);
        print('✅ Usuario actualizado: ${updatedUser.nombreCompleto}');
        return updatedUser;
      }

      throw Exception('Error actualizando usuario');
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      rethrow;
    }
  }

  // ==========================================
  // CAMBIAR CONTRASEÑA
  // ==========================================

  /// Cambiar contraseña de usuario
  /// Replica la lógica de userService.ts con dos estrategias
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔒 UsuarioService: Cambiando contraseña para usuario $userId...');

      final data = {
        'passwordActual': currentPassword,
        'nuevaPassword': newPassword,
      };

      final response = await _apiService.post(
        AppConfig.usuarioChangePassword(userId),
        data: data,
      );

      if (response['success'] == true) {
        print('✅ Contraseña cambiada exitosamente');
        return;
      }

      throw Exception(response['message'] ?? 'Error cambiando contraseña');
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      rethrow;
    }
  }

  // ==========================================
  // CREAR USUARIO (ADMIN)
  // ==========================================

  /// Crear nuevo usuario (solo ADMIN)
  Future<Usuario> createUser({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
    required UserRole tipo,
    required String escuelaId,
    String? telefono,
    UserStatus estado = UserStatus.activo,
  }) async {
    try {
      print('➕ UsuarioService: Creando usuario $email...');

      final data = {
        'nombre': nombre,
        'apellidos': apellidos,
        'email': email,
        'password': password,
        'tipo': tipo.value,
        'estado': estado.value,
        'escuelaId': escuelaId,
        if (telefono != null) 'perfil': {'telefono': telefono},
      };

      final response = await _apiService.post(
        AppConfig.authRegister,
        data: data,
      );

      if (response['success'] == true) {
        final newUser = Usuario.fromJson(response['data']);
        print('✅ Usuario creado: ${newUser.nombreCompleto}');
        return newUser;
      }

      throw Exception('Error creando usuario');
    } catch (e) {
      print('❌ Error creando usuario: $e');
      rethrow;
    }
  }

  // ==========================================
  // DESACTIVAR USUARIO
  // ==========================================

  /// Desactivar usuario (soft delete)
  Future<void> deactivateUser(String userId) async {
    try {
      print('🚫 UsuarioService: Desactivando usuario $userId...');

      await _apiService.delete(
        AppConfig.usuarioDelete(userId),
      );

      print('✅ Usuario desactivado');
    } catch (e) {
      print('❌ Error desactivando usuario: $e');
      rethrow;
    }
  }

  // ==========================================
  // ESTUDIANTES ASOCIADOS (ACUDIENTE)
  // ==========================================

  /// Obtener estudiantes asociados a un acudiente
  Future<List<Usuario>> getAssociatedStudents(String acudienteId) async {
    try {
      print('🎓 UsuarioService: Obteniendo estudiantes asociados...');

      final response = await _apiService.get(
        AppConfig.usuarioAssociatedStudents(acudienteId),
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final students = data.map((json) => Usuario.fromJson(json)).toList();
        print('✅ ${students.length} estudiantes asociados');
        return students;
      }

      return [];
    } catch (e) {
      print('⚠️ Error obteniendo estudiantes asociados: $e');
      // Retornar array vacío en lugar de error (como en RN)
      return [];
    }
  }
}

// Singleton instance
final usuarioService = UsuarioService();
