// lib/services/asistencia_service.dart

import '../config/app_config.dart';
import '../models/asistencia.dart';
import 'api_service.dart';

/// 📋 SERVICIO DE ASISTENCIA
/// Maneja TODOS los endpoints de asistencia
class AsistenciaService {
  final ApiService _apiService = ApiService();

  // ========================================
  // 📋 OBTENER RESUMEN DE ASISTENCIA
  // ========================================

  Future<List<ResumenAsistencia>> obtenerResumenAsistencia({
    String? fechaInicio,
    String? fechaFin,
    String? cursoId,
  }) async {
    try {
      print('📥 Obteniendo resumen de asistencia...');
      print('   Fecha inicio: $fechaInicio');
      print('   Fecha fin: $fechaFin');
      print('   Curso: $cursoId');

      final queryParams = <String, dynamic>{};

      if (fechaInicio != null) queryParams['fechaInicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fechaFin'] = fechaFin;
      if (cursoId != null && cursoId.isNotEmpty)
        queryParams['cursoId'] = cursoId;

      final response = await _apiService.get(
        '/asistencia/resumen',
        queryParameters: queryParams,
      );

      final data = response['data'] as List<dynamic>? ?? [];
      final resumen =
          data.map((json) => ResumenAsistencia.fromJson(json)).toList();

      print('✅ Resumen obtenido: ${resumen.length} registros');
      return resumen;
    } catch (e) {
      print('❌ Error obteniendo resumen: $e');
      rethrow;
    }
  }

  // ========================================
  // 📄 OBTENER REGISTRO ESPECÍFICO
  // ========================================

  Future<RegistroAsistencia> obtenerRegistroAsistencia(String id) async {
    try {
      print('📥 Obteniendo registro de asistencia: $id');

      final response = await _apiService.get(AppConfig.asistenciaDetail(id));

      final registro = RegistroAsistencia.fromJson(response['data']);

      print('✅ Registro obtenido');
      return registro;
    } catch (e) {
      print('❌ Error obteniendo registro: $e');
      rethrow;
    }
  }

  // ========================================
  // ➕ CREAR REGISTRO DE ASISTENCIA
  // ========================================

  Future<RegistroAsistencia> crearRegistroAsistencia({
    required DateTime fecha,
    required String cursoId,
    String? asignaturaId,
    String? periodoId,
    required String tipoSesion,
    required String horaInicio,
    required String horaFin,
    required List<EstudianteAsistencia> estudiantes,
    String? observacionesGenerales,
  }) async {
    try {
      print('📝 Creando registro de asistencia...');
      print('   Fecha: $fecha');
      print('   Curso: $cursoId');
      print('   Asignatura: $asignaturaId');
      print('   Estudiantes: ${estudiantes.length}');

      // Construir data sin campos null innecesarios
      final data = <String, dynamic>{
        'fecha': fecha.toIso8601String().split('T')[0],
        'cursoId': cursoId,
        'tipoSesion': tipoSesion,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'estudiantes': estudiantes.map((e) => e.toJson()).toList(),
      };

      // Solo agregar asignaturaId si no es null
      if (asignaturaId != null && asignaturaId.isNotEmpty) {
        data['asignaturaId'] = asignaturaId;
      }

      // Solo agregar periodoId si no es null
      if (periodoId != null && periodoId.isNotEmpty) {
        data['periodoId'] = periodoId;
      }

      // Solo agregar observaciones si no es null
      if (observacionesGenerales != null && observacionesGenerales.isNotEmpty) {
        data['observacionesGenerales'] = observacionesGenerales;
      }

      final response = await _apiService.post(
        AppConfig.asistencia,
        data: data,
      );

      final registro = RegistroAsistencia.fromJson(response['data']);

      print('✅ Registro creado con ID: ${registro.id}');
      return registro;
    } catch (e) {
      print('❌ Error creando registro: $e');
      rethrow;
    }
  }

  // ========================================
  // ✏️ ACTUALIZAR REGISTRO DE ASISTENCIA
  // ========================================

  Future<RegistroAsistencia> actualizarRegistroAsistencia({
    required String id,
    DateTime? fecha,
    String? cursoId,
    String? asignaturaId,
    String? periodoId,
    String? tipoSesion,
    String? horaInicio,
    String? horaFin,
    List<EstudianteAsistencia>? estudiantes,
    String? observacionesGenerales,
  }) async {
    try {
      print('✏️ Actualizando registro: $id');

      final data = <String, dynamic>{};

      if (fecha != null) data['fecha'] = fecha.toIso8601String().split('T')[0];
      if (cursoId != null) data['cursoId'] = cursoId;
      if (asignaturaId != null) data['asignaturaId'] = asignaturaId;
      if (periodoId != null) data['periodoId'] = periodoId;
      if (tipoSesion != null) data['tipoSesion'] = tipoSesion;
      if (horaInicio != null) data['horaInicio'] = horaInicio;
      if (horaFin != null) data['horaFin'] = horaFin;
      if (estudiantes != null) {
        data['estudiantes'] = estudiantes.map((e) => e.toJson()).toList();
      }
      if (observacionesGenerales != null) {
        data['observacionesGenerales'] = observacionesGenerales;
      }

      final response = await _apiService.put(
        AppConfig.asistenciaUpdate(id),
        data: data,
      );

      final registro = RegistroAsistencia.fromJson(response['data']);

      print('✅ Registro actualizado');
      return registro;
    } catch (e) {
      print('❌ Error actualizando registro: $e');
      rethrow;
    }
  }

  // ========================================
  // ✅ FINALIZAR REGISTRO
  // ========================================

  Future<RegistroAsistencia> finalizarRegistroAsistencia(String id) async {
    try {
      print('✅ Finalizando registro: $id');

      final response = await _apiService.patch(
        AppConfig.asistenciaFinalizar(id),
      );

      // ✅ FIX: Verificar si data existe
      // Algunos backends devuelven null en data cuando finalizan algo
      if (response['data'] != null && response['data'] is Map) {
        // Caso 1: Backend devuelve el registro actualizado
        final registro = RegistroAsistencia.fromJson(response['data']);
        print('✅ Registro finalizado (con data)');
        return registro;
      } else {
        // Caso 2: Backend solo confirma éxito, sin devolver el registro
        // Recargamos el registro actualizado
        print('⚠️ Backend no devolvió data, recargando registro...');
        final registroActualizado = await obtenerRegistroAsistencia(id);
        print('✅ Registro recargado y finalizado');
        return registroActualizado;
      }
    } catch (e) {
      print('❌ Error finalizando registro: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR REGISTRO
  // ========================================

  Future<void> eliminarRegistroAsistencia(String id) async {
    try {
      print('🗑️ Eliminando registro: $id');

      await _apiService.delete(AppConfig.asistenciaDelete(id));

      print('✅ Registro eliminado');
    } catch (e) {
      print('❌ Error eliminando registro: $e');
      rethrow;
    }
  }

  // ========================================
  // 📚 OBTENER CURSOS DISPONIBLES
  // ========================================

  Future<List<CursoDisponible>> obtenerCursosDisponibles() async {
    try {
      print('📚 Obteniendo cursos disponibles...');

      final response = await _apiService.get(AppConfig.cursos);

      final data = response['data'] as List<dynamic>? ?? [];
      final cursos =
          data.map((json) => CursoDisponible.fromJson(json)).toList();

      print('✅ Cursos obtenidos: ${cursos.length}');
      return cursos;
    } catch (e) {
      print('❌ Error obteniendo cursos: $e');
      rethrow;
    }
  }

  // ========================================
  // 👥 OBTENER ESTUDIANTES POR CURSO
  // ========================================

  Future<List<EstudianteAsistencia>> obtenerEstudiantesPorCurso(
    String cursoId,
  ) async {
    try {
      print('👥 Obteniendo estudiantes del curso: $cursoId');

      final response = await _apiService.get(
        AppConfig.cursoEstudiantes(cursoId),
      );

      final data = response['data'] as List<dynamic>? ?? [];
      final estudiantes = data.map((json) {
        return EstudianteAsistencia(
          estudianteId: json['_id'] ?? '',
          nombre: json['nombre'] ?? '',
          apellidos: json['apellidos'] ?? '',
          estado: EstadosAsistencia.presente, // Por defecto presente
        );
      }).toList();

      print('✅ Estudiantes obtenidos: ${estudiantes.length}');
      return estudiantes;
    } catch (e) {
      print('❌ Error obteniendo estudiantes: $e');
      rethrow;
    }
  }

  // ========================================
  // 📚 OBTENER ASIGNATURAS DE UN CURSO
  // ========================================

  Future<List<AsignaturaDisponible>> obtenerAsignaturasPorCurso(
    String cursoId,
  ) async {
    try {
      print('📚 Obteniendo asignaturas del curso: $cursoId');

      final response = await _apiService.get(
        '/asignaturas',
        queryParameters: {'cursoId': cursoId},
      );

      final data = response['data'] as List<dynamic>? ?? [];
      final asignaturas = data.map((json) {
        return AsignaturaDisponible(
          id: json['_id'] ?? '',
          nombre: json['nombre'] ?? '',
          docenteNombre: json['docenteId'] != null
              ? '${json['docenteId']['nombre'] ?? ''} ${json['docenteId']['apellidos'] ?? ''}'
              : null,
        );
      }).toList();

      print('✅ Asignaturas obtenidas: ${asignaturas.length}');
      return asignaturas;
    } catch (e) {
      print('❌ Error obteniendo asignaturas: $e');
      rethrow;
    }
  }

  // ========================================
  // 📊 OBTENER ESTADÍSTICAS POR CURSO
  // ========================================

  Future<Map<String, dynamic>> obtenerEstadisticasPorCurso({
    required String cursoId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      print('📊 Obteniendo estadísticas del curso: $cursoId');

      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) queryParams['fechaInicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fechaFin'] = fechaFin;

      final response = await _apiService.get(
        AppConfig.asistenciaEstadisticasCurso(cursoId),
        queryParameters: queryParams,
      );

      print('✅ Estadísticas obtenidas');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  // ========================================
  // 📊 OBTENER ESTADÍSTICAS POR ESTUDIANTE
  // ========================================

  Future<Map<String, dynamic>> obtenerEstadisticasPorEstudiante({
    required String estudianteId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      print('📊 Obteniendo estadísticas del estudiante: $estudianteId');

      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) queryParams['fechaInicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fechaFin'] = fechaFin;

      final response = await _apiService.get(
        AppConfig.asistenciaEstadisticasEstudiante(estudianteId),
        queryParameters: queryParams,
      );

      print('✅ Estadísticas obtenidas');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  // ========================================
  // 📥 OBTENER ASISTENCIA POR DÍA
  // ========================================

  Future<List<RegistroAsistencia>> obtenerAsistenciaPorDia({
    required DateTime fecha,
    String? cursoId,
  }) async {
    try {
      print('📥 Obteniendo asistencia del día: $fecha');

      final queryParams = <String, dynamic>{
        'fecha': fecha.toIso8601String().split('T')[0],
      };

      if (cursoId != null && cursoId.isNotEmpty) {
        queryParams['cursoId'] = cursoId;
      }

      final response = await _apiService.get(
        AppConfig.asistenciaDia,
        queryParameters: queryParams,
      );

      final data = response['data'] as List<dynamic>? ?? [];
      final registros =
          data.map((json) => RegistroAsistencia.fromJson(json)).toList();

      print('✅ Registros obtenidos: ${registros.length}');
      return registros;
    } catch (e) {
      print('❌ Error obteniendo asistencia del día: $e');
      rethrow;
    }
  }
}

// Singleton instance
final asistenciaService = AsistenciaService();
