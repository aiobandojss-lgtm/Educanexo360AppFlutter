// lib/services/tarea_service.dart
import '../utils/logger.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/tarea.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class TareaService {
  final ApiService _apiService;

  TareaService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ==========================================
  // CRUD BÁSICO DE TAREAS
  // ==========================================

  /// Listar tareas con paginación y filtros (docentes/admin)
  Future<Map<String, dynamic>> listarTareas({
    int page = 1,
    int limite = 20,
    EstadoTarea? estado,
    PrioridadTarea? prioridad,
    String? cursoId,
    String? asignaturaId,
    String? busqueda,
  }) async {
    try {
      dlog('📋 Listando tareas... (página $page)');

      final queryParams = <String, dynamic>{
        'page': page,
        'limite': limite,
      };

      if (estado != null) queryParams['estado'] = estado.value;
      if (prioridad != null) queryParams['prioridad'] = prioridad.value;
      if (cursoId != null) queryParams['cursoId'] = cursoId;
      if (asignaturaId != null) queryParams['asignaturaId'] = asignaturaId;
      if (busqueda != null && busqueda.isNotEmpty) {
        queryParams['busqueda'] = busqueda;
      }

      final response = await _apiService.get(
        AppConfig.tareas,
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> tareasData = response['data'] as List<dynamic>;
        final tareas = tareasData.map((json) => Tarea.fromJson(json)).toList();

        return {
          'tareas': tareas,
          'meta': response['meta'] ??
              {
                'total': tareas.length,
                'pagina': page,
                'limite': limite,
                'paginas': 1,
              },
        };
      }

      throw Exception(response['message'] ?? 'Error al listar tareas');
    } catch (e) {
      dlog('❌ Error en listarTareas: $e');
      rethrow;
    }
  }

  /// Obtener mis tareas (para estudiantes)
  Future<List<Tarea>> misTareas({FiltroTareaEstudiante? filtro}) async {
    try {
      dlog('📚 Obteniendo mis tareas...');

      final queryParams = <String, dynamic>{};
      if (filtro != null) {
        queryParams['filtro'] = filtro.value;
      }

      final response = await _apiService.get(
        AppConfig.misTareas,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => Tarea.fromJson(json)).toList();
      }

      throw Exception(response['message'] ?? 'Error al obtener mis tareas');
    } catch (e) {
      dlog('❌ Error en misTareas: $e');
      rethrow;
    }
  }

  /// Obtener detalle de una tarea
  Future<Tarea?> obtenerTarea(String id) async {
    try {
      dlog('📄 Obteniendo tarea $id...');

      final response = await _apiService.get(AppConfig.tareaDetail(id));

      if (response['success'] == true) {
        return Tarea.fromJson(response['data']);
      }

      throw Exception(response['message'] ?? 'Error al obtener tarea');
    } catch (e) {
      dlog('❌ Error en obtenerTarea: $e');
      rethrow;
    }
  }

  /// Crear nueva tarea
  Future<Tarea> crearTarea({
    required String titulo,
    required String descripcion,
    required String asignaturaId,
    required String cursoId,
    required DateTime fechaLimite,
    required double calificacionMaxima,
    TipoTarea tipo = TipoTarea.individual,
    PrioridadTarea prioridad = PrioridadTarea.media,
    bool permiteTardias = false,
    double? pesoEvaluacion,
    List<String>? estudiantesIds,
    List<File>? archivosReferencia,
  }) async {
    try {
      dlog('\n📦 ========== CREAR TAREA ==========');
      dlog('📝 Título: $titulo');
      dlog('📚 Asignatura: $asignaturaId');
      dlog('👥 Curso: $cursoId');
      dlog('====================================\n');

      // ✅ PASO 1: Crear la tarea con JSON puro (sin archivos)
      dlog('📦 PASO 1: Creando tarea...');

      final requestBody = {
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'asignaturaId': asignaturaId.trim(),
        'cursoId': cursoId.trim(),
        'fechaLimite': fechaLimite.toIso8601String(),
        'calificacionMaxima': calificacionMaxima.toInt(),
        'tipo': tipo.value,
        'prioridad': prioridad.value,
        'permiteTardias': permiteTardias,
      };

      if (pesoEvaluacion != null) {
        requestBody['pesoEvaluacion'] = pesoEvaluacion.toInt();
      }

      if (estudiantesIds != null && estudiantesIds.isNotEmpty) {
        requestBody['estudiantesIds'] = estudiantesIds;
      }

      // Logs de debug
      dlog('🌐 ========== POST DEBUG ==========');
      dlog('📍 BaseURL: ${AppConfig.baseUrl}');
      dlog('📍 Endpoint: ${AppConfig.tareas}');
      dlog('📍 URL Final: ${AppConfig.baseUrl}${AppConfig.tareas}');
      dlog('📦 Data type: ${requestBody.runtimeType}');
      dlog('📦 Data keys: ${requestBody.keys.join(', ')}');
      dlog('==================================\n');

      final response = await _apiService.post(
        AppConfig.tareas,
        data: requestBody,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Error al crear tarea');
      }

      final tareaCreada = Tarea.fromJson(response['data']);
      dlog('✅ Tarea creada con ID: ${tareaCreada.id}');

      // ✅ PASO 2: Si hay archivos, subirlos usando el endpoint correcto
      if (archivosReferencia != null && archivosReferencia.isNotEmpty) {
        dlog('\n📦 PASO 2: Subiendo archivos a la tarea...');
        await _subirArchivos(tareaCreada.id, archivosReferencia);
        dlog('✅ Archivos subidos exitosamente\n');
      }

      dlog('✅ ========== TAREA CREADA EXITOSAMENTE ==========\n');

      // Obtener la tarea completa con los archivos
      return await obtenerTarea(tareaCreada.id) ?? tareaCreada;
    } catch (e) {
      dlog('❌ =============================================');
      dlog('❌ ERROR CREANDO TAREA');
      dlog('=============================================');
      dlog('Error: $e');
      dlog('=============================================');
      rethrow;
    }
  }

  /// Método privado para subir archivos
  Future<void> _subirArchivos(String tareaId, List<File> archivos) async {
    if (archivos.isEmpty) return;

    try {
      final formData = FormData();

      for (var i = 0; i < archivos.length; i++) {
        final archivo = archivos[i];
        dlog('📎 Archivo ${i + 1}: ${archivo.path.split('/').last}');

        formData.files.add(MapEntry(
          'archivos',
          await MultipartFile.fromFile(
            archivo.path,
            filename: archivo.path.split('/').last,
          ),
        ));
      }

      dlog('🌐 ========== POST DEBUG ==========');
      dlog('📍 BaseURL: ${AppConfig.baseUrl}');
      dlog('📍 Endpoint: ${AppConfig.tareaArchivos(tareaId)}');
      dlog(
          '📍 URL Final: ${AppConfig.baseUrl}${AppConfig.tareaArchivos(tareaId)}');
      dlog('📦 Data type: FormData');
      dlog('==================================\n');

      final response = await _apiService.postFormData(
        AppConfig.tareaArchivos(tareaId),
        formData,
      );

      if (response['success'] != true) {
        throw Exception(
            response['message'] ?? 'Error al subir archivos de referencia');
      }

      dlog('✅ Archivos de referencia subidos exitosamente');
    } catch (e) {
      dlog('❌ Error subiendo archivos de referencia: $e');
      rethrow;
    }
  }

  /// Subir archivos de referencia a una tarea existente
  Future<Tarea> subirArchivosReferencia({
    required String tareaId,
    required List<File> archivos,
  }) async {
    try {
      dlog('📎 Subiendo archivos de referencia a tarea: $tareaId');
      await _subirArchivos(tareaId, archivos);

      // Retornar la tarea actualizada
      final tarea = await obtenerTarea(tareaId);
      if (tarea == null) {
        throw Exception('No se pudo obtener la tarea actualizada');
      }
      return tarea;
    } catch (e) {
      dlog('❌ Error en subirArchivosReferencia: $e');
      rethrow;
    }
  }

  /// Editar una tarea existente
  Future<Tarea> actualizarTarea({
    required String tareaId,
    required String titulo,
    required String descripcion,
    required DateTime fechaLimite,
    required double calificacionMaxima,
    TipoTarea? tipo,
    PrioridadTarea? prioridad,
    bool? permiteTardias,
    double? pesoEvaluacion,
  }) async {
    try {
      dlog('✏️ Actualizando tarea $tareaId...');

      final requestBody = {
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'fechaLimite': fechaLimite.toIso8601String(),
        'calificacionMaxima': calificacionMaxima.toInt(),
      };

      if (tipo != null) requestBody['tipo'] = tipo.value;
      if (prioridad != null) requestBody['prioridad'] = prioridad.value;
      if (permiteTardias != null) {
        requestBody['permiteTardias'] = permiteTardias;
      }
      if (pesoEvaluacion != null) {
        requestBody['pesoEvaluacion'] = pesoEvaluacion.toInt();
      }

      final response = await _apiService.put(
        AppConfig.tareaUpdate(tareaId),
        data: requestBody,
      );

      if (response['success'] == true) {
        dlog('✅ Tarea actualizada exitosamente');
        return Tarea.fromJson(response['data']);
      }

      throw Exception(response['message'] ?? 'Error al actualizar tarea');
    } catch (e) {
      dlog('❌ Error en actualizarTarea: $e');
      rethrow;
    }
  }

  /// Eliminar una tarea
  Future<void> eliminarTarea(String tareaId) async {
    try {
      dlog('🗑️ Eliminando tarea $tareaId...');

      final response = await _apiService.delete(
        AppConfig.tareaDelete(tareaId),
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Error al eliminar tarea');
      }

      dlog('✅ Tarea eliminada exitosamente');
    } catch (e) {
      dlog('❌ Error en eliminarTarea: $e');
      rethrow;
    }
  }

  /// Cerrar una tarea (no permite más entregas)
  Future<Tarea> cerrarTarea(String tareaId) async {
    try {
      dlog('🔒 Cerrando tarea $tareaId...');

      final response = await _apiService.put(AppConfig.tareaCerrar(tareaId));

      if (response['success'] == true) {
        dlog('✅ Tarea cerrada exitosamente');
        return Tarea.fromJson(response['data']);
      }

      throw Exception(response['message'] ?? 'Error al cerrar tarea');
    } catch (e) {
      dlog('❌ Error en cerrarTarea: $e');
      rethrow;
    }
  }

  // ==========================================
  // GESTIÓN DE ARCHIVOS DE REFERENCIA
  // ==========================================

  /// Eliminar un archivo de referencia
  Future<Tarea> eliminarArchivoReferencia({
    required String tareaId,
    required String archivoId,
  }) async {
    try {
      dlog('🗑️ Eliminando archivo de referencia...');

      final response = await _apiService.delete(
        AppConfig.tareaArchivoDelete(tareaId, archivoId),
      );

      if (response['success'] == true) {
        dlog('✅ Archivo de referencia eliminado');

        // 🔧 FIX: Si el backend no retorna data, obtener la tarea actualizada
        if (response['data'] != null) {
          return Tarea.fromJson(response['data']);
        } else {
          // Obtener la tarea actualizada del servidor
          final tarea = await obtenerTarea(tareaId);
          if (tarea == null) {
            throw Exception('No se pudo obtener la tarea actualizada');
          }
          return tarea;
        }
      }

      throw Exception(
          response['message'] ?? 'Error al eliminar archivo de referencia');
    } catch (e) {
      dlog('❌ Error eliminando archivo de referencia: $e');
      rethrow;
    }
  }

  /// Descargar archivo de referencia
  Future<String> descargarArchivoReferencia(
    String tareaId,
    String archivoId,
    String savePath,
  ) async {
    try {
      dlog('⬇️ Descargando archivo de referencia...');

      await _apiService.download(
        AppConfig.tareaArchivoDownload(tareaId, archivoId),
        savePath,
      );

      dlog('✅ Archivo descargado en: $savePath');
      return savePath;
    } catch (e) {
      dlog('❌ Error descargando archivo: $e');
      rethrow;
    }
  }

  // ==========================================
  // ENTREGAS DE ESTUDIANTES
  // ==========================================

  /// Marcar tarea como vista (estudiante)
  Future<void> marcarVista(String tareaId) async {
    try {
      dlog('👁️ Marcando tarea como vista...');

      final response = await _apiService.post(
        AppConfig.tareaMarcarVista(tareaId),
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Error al marcar como vista');
      }

      dlog('✅ Tarea marcada como vista');
    } catch (e) {
      dlog('❌ Error marcando como vista: $e');
      rethrow;
    }
  }

  /// Entregar tarea (estudiante)
  Future<EntregaTarea> entregarTarea({
    required String tareaId,
    required List<File> archivos,
    String? comentarioEstudiante,
  }) async {
    try {
      dlog('\n📤 ========== ENTREGAR TAREA ==========');
      dlog('📋 Tarea ID: $tareaId');
      dlog('📎 Archivos: ${archivos.length}');
      dlog('=======================================\n');

      final formData = FormData();

      if (comentarioEstudiante != null && comentarioEstudiante.isNotEmpty) {
        formData.fields.add(
          MapEntry('comentarioEstudiante', comentarioEstudiante),
        );
      }

      for (var i = 0; i < archivos.length; i++) {
        final archivo = archivos[i];
        dlog('📎 Archivo ${i + 1}: ${archivo.path.split('/').last}');

        formData.files.add(MapEntry(
          'archivos',
          await MultipartFile.fromFile(
            archivo.path,
            filename: archivo.path.split('/').last,
          ),
        ));
      }

      final response = await _apiService.postFormData(
        AppConfig.tareaEntregar(tareaId),
        formData,
      );

      if (response['success'] == true) {
        dlog('✅ Tarea entregada exitosamente\n');
        return EntregaTarea.fromJson(response['data']);
      }

      throw Exception(response['message'] ?? 'Error al entregar tarea');
    } catch (e) {
      dlog('❌ Error entregando tarea: $e');
      rethrow;
    }
  }

  /// Ver mi entrega (estudiante/acudiente)
  Future<EntregaTarea?> verMiEntrega(String tareaId) async {
    try {
      dlog('📝 Obteniendo mi entrega...');

      final response = await _apiService.get(
        AppConfig.tareaMiEntrega(tareaId),
      );

      if (response['success'] == true && response['data'] != null) {
        return EntregaTarea.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      dlog('❌ Error obteniendo mi entrega: $e');
      rethrow;
    }
  }

  /// Ver todas las entregas de una tarea (docente)
  Future<List<EntregaTarea>> verEntregas(String tareaId) async {
    try {
      dlog('📋 Obteniendo entregas de la tarea...');

      final response = await _apiService.get(
        AppConfig.tareaEntregas(tareaId),
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => EntregaTarea.fromJson(json)).toList();
      }

      throw Exception(response['message'] ?? 'Error al obtener entregas');
    } catch (e) {
      dlog('❌ Error obteniendo entregas: $e');
      rethrow;
    }
  }

  /// Calificar una entrega (docente)
  Future<EntregaTarea> calificarEntrega({
    required String tareaId,
    required String entregaId,
    required double calificacion,
    String? comentarioDocente,
  }) async {
    try {
      dlog('✍️ Calificando entrega...');

      final requestBody = {
        'calificacion': calificacion,
        if (comentarioDocente != null && comentarioDocente.isNotEmpty)
          'comentarioDocente': comentarioDocente,
      };

      final response = await _apiService.post(
        AppConfig.tareaCalificar(tareaId, entregaId),
        data: requestBody,
      );

      if (response['success'] == true) {
        dlog('✅ Entrega calificada exitosamente');
        return EntregaTarea.fromJson(response['data']);
      }

      throw Exception(response['message'] ?? 'Error al calificar entrega');
    } catch (e) {
      dlog('❌ Error calificando entrega: $e');
      rethrow;
    }
  }

  /// Obtener tareas de un estudiante específico (para acudientes)
  Future<List<Tarea>> tareasEstudiante({
    required String estudianteId,
  }) async {
    try {
      dlog('📥 Obteniendo tareas del estudiante: $estudianteId');

      final response = await _apiService.get(
        '/tareas/especial/estudiante/$estudianteId',
      );

      if (response['success'] == true) {
        final List<dynamic> tareasJson = response['data'] ?? [];

        // El backend retorna tareas con campo 'entregaEstudiante'
        // Necesitamos mapearlo al formato que espera el modelo Tarea
        final tareas = tareasJson.map((json) {
          // Si viene entregaEstudiante, moverlo a entregas
          if (json['entregaEstudiante'] != null) {
            json['entregas'] = [json['entregaEstudiante']];
          }
          return Tarea.fromJson(json);
        }).toList();

        dlog('✅ Tareas del estudiante obtenidas: ${tareas.length}');
        return tareas;
      }

      throw Exception(
          response['message'] ?? 'Error al obtener tareas del estudiante');
    } catch (e) {
      dlog('❌ Error en tareasEstudiante: $e');
      rethrow;
    }
  }

  /// Obtener información básica de un estudiante (para selector)
  Future<Map<String, dynamic>> obtenerInfoEstudiante(
      String estudianteId) async {
    try {
      dlog('📥 Obteniendo info del estudiante: $estudianteId');

      final response = await _apiService.get(
        '/usuarios/$estudianteId',
      );

      if (response['success'] == true) {
        return response['data'];
      }

      throw Exception('Error al obtener información del estudiante');
    } catch (e) {
      dlog('❌ Error en obtenerInfoEstudiante: $e');
      rethrow;
    }
  }
}
