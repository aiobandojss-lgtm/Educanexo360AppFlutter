// lib/services/usuario_service.dart
import '../utils/logger.dart';
import '../config/app_config.dart';
import '../models/usuario.dart';
import 'api_service.dart';

class UsuarioService {
  final ApiService _apiService = apiService;

  Future<List<Usuario>> getUsers({
    UserRole? tipo,
    String? query,
  }) async {
    try {
      dlog('👥 UsuarioService: Obteniendo usuarios...');

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
        dlog('✅ ${users.length} usuarios obtenidos');
        return users;
      }

      return [];
    } catch (e) {
      dlog('❌ Error obteniendo usuarios: $e');
      rethrow;
    }
  }

  Future<Usuario> getUserById(String userId) async {
    try {
      dlog('👤 UsuarioService: Obteniendo usuario $userId...');

      final response = await _apiService.get(
        AppConfig.usuarioDetail(userId),
      );

      if (response['success'] == true) {
        final user = Usuario.fromJson(response['data']);
        dlog('✅ Usuario obtenido: ${user.nombreCompleto}');
        return user;
      }

      throw Exception('Usuario no encontrado');
    } catch (e) {
      dlog('❌ Error obteniendo usuario: $e');
      rethrow;
    }
  }

  // ✅ CORREGIDO: Agregados parámetros tipo y estado
  Future<Usuario> updateUser(
    String userId, {
    String? nombre,
    String? apellidos,
    String? email,
    String? telefono,
    UserRole? tipo, // ✅ AGREGAR ESTA LÍNEA
    UserStatus? estado, // ✅ AGREGAR ESTA LÍNEA
  }) async {
    try {
      dlog('✏️ UsuarioService: Actualizando usuario $userId...');

      final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (apellidos != null) data['apellidos'] = apellidos;
      if (email != null) data['email'] = email;
      if (telefono != null) {
        data['perfil'] = {'telefono': telefono};
      }

      // ✅ AGREGAR tipo y estado
      // ✅ AGREGAR ESTAS 2 LÍNEAS
      if (tipo != null) data['tipo'] = tipo.value;
      if (estado != null) data['estado'] = estado.value;

      final response = await _apiService.put(
        AppConfig.usuarioUpdate(userId),
        data: data,
      );

      if (response['success'] == true) {
        final updatedUser = Usuario.fromJson(response['data']);
        dlog('✅ Usuario actualizado: ${updatedUser.nombreCompleto}');
        return updatedUser;
      }

      throw Exception('Error actualizando usuario');
    } catch (e) {
      dlog('❌ Error actualizando usuario: $e');
      rethrow;
    }
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      dlog('🔒 UsuarioService: Cambiando contraseña para usuario $userId...');

      final data = {
        'passwordActual': currentPassword,
        'nuevaPassword': newPassword,
      };

      final response = await _apiService.post(
        AppConfig.usuarioChangePassword(userId),
        data: data,
      );

      if (response['success'] == true) {
        dlog('✅ Contraseña cambiada exitosamente');
        return;
      }

      throw Exception(response['message'] ?? 'Error cambiando contraseña');
    } catch (e) {
      dlog('❌ Error cambiando contraseña: $e');
      rethrow;
    }
  }

  // ✅ CORREGIDO: Validación de campos NULL
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
      dlog('➕ UsuarioService: Creando usuario $email...');
      dlog('🏫 EscuelaId: $escuelaId');

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

      dlog('📤 Enviando datos: ${data.keys.toList()}');

      final response = await _apiService.post(
        AppConfig.authRegister,
        data: data,
      );

      dlog('📦 Respuesta recibida: ${response.keys.toList()}');

      if (response['success'] == true) {
        final userData = response['data'];
        if (userData == null) {
          dlog('⚠️ Backend no devolvió datos del usuario');
          throw Exception('Backend no devolvió los datos del usuario creado');
        }

        // ✅ FIX: Validar y completar campos NULL del backend
        if (userData['nombre'] == null) userData['nombre'] = nombre;
        if (userData['apellidos'] == null) userData['apellidos'] = apellidos;
        if (userData['email'] == null) userData['email'] = email;
        if (userData['escuelaId'] == null) userData['escuelaId'] = escuelaId;
        if (userData['tipo'] == null) userData['tipo'] = tipo.value;
        if (userData['estado'] == null) userData['estado'] = estado.value;

        dlog('✅ Parseando usuario...');
        final newUser = Usuario.fromJson(userData);
        dlog('✅ Usuario creado: ${newUser.nombreCompleto} (${newUser.id})');
        return newUser;
      }

      throw Exception(response['message'] ?? 'Error creando usuario');
    } catch (e) {
      dlog('❌ Error creando usuario: $e');
      rethrow;
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      dlog('🗑️ UsuarioService: Desactivando usuario $userId...');

      final response = await _apiService.delete(
        AppConfig.usuarioDelete(userId),
      );

      if (response['success'] == true) {
        dlog('✅ Usuario desactivado');
        return;
      }

      throw Exception('Error desactivando usuario');
    } catch (e) {
      dlog('❌ Error desactivando usuario: $e');
      rethrow;
    }
  }

  Future<List<Usuario>> getAssociatedStudents(String acudienteId) async {
    try {
      dlog('👨‍👩‍👧‍👦 UsuarioService: Obteniendo estudiantes asociados...');

      final response = await _apiService.get(
        AppConfig.usuarioAssociatedStudents(acudienteId),
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final students = data.map((json) => Usuario.fromJson(json)).toList();
        dlog('✅ ${students.length} estudiantes asociados');
        return students;
      }

      return [];
    } catch (e) {
      dlog('❌ Error obteniendo estudiantes asociados: $e');
      return [];
    }
  }

  Future<List<Usuario>> buscarEstudiantesParaAsociar({
    required String escuelaId,
    String? query,
  }) async {
    try {
      dlog('🔍 UsuarioService: Buscando estudiantes para asociar...');
      dlog('   Escuela: $escuelaId');
      dlog('   Query: $query');

      final queryParams = <String, dynamic>{
        'tipo': UserRole.estudiante.value,
        'escuelaId': escuelaId,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      final response = await _apiService.get(
        AppConfig.usuarios,
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final estudiantes = data.map((json) => Usuario.fromJson(json)).toList();
        dlog('✅ ${estudiantes.length} estudiantes encontrados');
        return estudiantes;
      }

      return [];
    } catch (e) {
      dlog('❌ Error buscando estudiantes: $e');
      rethrow;
    }
  }

  // ➕ Asociar estudiante a acudiente
  Future<void> asociarEstudiante({
    required String acudienteId,
    required String estudianteId,
  }) async {
    try {
      dlog('➕ UsuarioService: Asociando estudiante...');
      dlog('   Acudiente: $acudienteId');
      dlog('   Estudiante: $estudianteId');

      final response = await _apiService.post(
        AppConfig.usuarioAssociateStudent(acudienteId),
        data: {'estudianteId': estudianteId},
      );

      if (response['success'] == true) {
        dlog('✅ Estudiante asociado correctamente');
        return;
      }

      throw Exception('Error asociando estudiante');
    } catch (e) {
      dlog('❌ Error asociando estudiante: $e');
      rethrow;
    }
  }

  // ➖ Desasociar estudiante de acudiente
  Future<void> desasociarEstudiante({
    required String acudienteId,
    required String estudianteId,
  }) async {
    try {
      dlog('➖ UsuarioService: Desasociando estudiante...');
      dlog('   Acudiente: $acudienteId');
      dlog('   Estudiante: $estudianteId');

      final response = await _apiService.delete(
        AppConfig.usuarioDisassociateStudent(acudienteId, estudianteId),
      );

      if (response['success'] == true) {
        dlog('✅ Estudiante desasociado correctamente');
        return;
      }

      throw Exception('Error desasociando estudiante');
    } catch (e) {
      dlog('❌ Error desasociando estudiante: $e');
      rethrow;
    }
  }
}
