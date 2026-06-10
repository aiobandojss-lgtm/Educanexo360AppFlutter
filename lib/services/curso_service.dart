// lib/services/curso_service.dart
import '../utils/logger.dart';
import '../models/curso.dart';
import 'api_service.dart';

class CursoService {
  final ApiService _apiService = apiService;

  /// 📚 Obtener lista de cursos con filtros opcionales
  Future<List<Curso>> getCursos({
    String? busqueda,
    NivelEducativo? nivel,
    EstadoCurso? estado,
    String? anoAcademico,
    Jornada? jornada,
    int? pagina,
    int? limite = 1000, // Obtener todos por defecto para filtrar localmente
  }) async {
    try {
      dlog('📚 CursoService: Obteniendo cursos...');

      final queryParams = <String, dynamic>{};

      if (busqueda != null && busqueda.trim().isNotEmpty) {
        queryParams['busqueda'] = busqueda.trim();
      }
      if (nivel != null) {
        queryParams['nivel'] = nivel.value;
      }
      if (estado != null) {
        queryParams['estado'] = estado.value;
      }
      if (anoAcademico != null) {
        queryParams['año_academico'] = anoAcademico;
      }
      if (jornada != null) {
        queryParams['jornada'] = jornada.value;
      }
      if (pagina != null && pagina > 1) {
        queryParams['pagina'] = pagina.toString();
      }
      if (limite != null) {
        queryParams['limite'] = limite.toString();
      }

      dlog('🔗 Query params: $queryParams');

      final response = await _apiService.get(
        '/cursos',
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];

        // Procesar cursos y obtener conteos reales
        final cursos = await Future.wait(data.map((json) async {
          final curso = Curso.fromJson(json);

          // Obtener conteo real de asignaturas si no viene
          if (curso.asignaturasCount == null) {
            try {
              final count = await _getAsignaturasCount(curso.id);
              return curso.copyWith(asignaturasCount: count);
            } catch (e) {
              dlog('⚠️ Error obteniendo conteo asignaturas: $e');
              return curso;
            }
          }

          return curso;
        }).toList());

        dlog('✅ ${cursos.length} cursos obtenidos');
        return cursos;
      }

      return [];
    } catch (e) {
      dlog('❌ Error obteniendo cursos: $e');
      rethrow;
    }
  }

  /// 📖 Obtener curso específico por ID
  Future<Curso?> getCursoById(String cursoId) async {
    try {
      dlog('🔍 CursoService: Obteniendo curso $cursoId...');

      final response = await _apiService.get('/cursos/$cursoId');

      if (response['success'] == true && response['data'] != null) {
        final curso = Curso.fromJson(response['data']);

        // Obtener conteos reales para el detalle
        try {
          final estudiantes = await getCursoEstudiantes(cursoId);
          final asignaturas = await getCursoAsignaturas(cursoId);

          final cursoConConteos = curso.copyWith(
            estudiantesCount: estudiantes.length,
            asignaturasCount: asignaturas.length,
          );

          dlog('✅ Curso obtenido: ${cursoConConteos.nombre}');
          return cursoConConteos;
        } catch (e) {
          dlog('⚠️ Error obteniendo conteos del curso');
          return curso;
        }
      }

      return null;
    } catch (e) {
      dlog('❌ Error obteniendo curso: $e');
      rethrow;
    }
  }

  /// 👥 Obtener estudiantes de un curso
  Future<List<EstudianteCurso>> getCursoEstudiantes(String cursoId) async {
    try {
      dlog('🔍 CursoService: Obteniendo estudiantes del curso $cursoId...');

      final response = await _apiService.get('/cursos/$cursoId/estudiantes');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final estudiantes =
            data.map((json) => EstudianteCurso.fromJson(json)).toList();

        dlog('✅ ${estudiantes.length} estudiantes obtenidos');
        return estudiantes;
      }

      return [];
    } catch (e) {
      dlog('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }

  /// 📚 Obtener asignaturas de un curso
  Future<List<AsignaturaCurso>> getCursoAsignaturas(String cursoId) async {
    try {
      dlog('🔍 CursoService: Obteniendo asignaturas del curso $cursoId...');

      final response = await _apiService.get(
        '/asignaturas',
        queryParameters: {
          'cursoId': cursoId,
          'expand': 'docente',
        },
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];

        if (data.isEmpty) {
          dlog('⚠️ Lista de asignaturas vacía del backend');
          return [];
        }

        final asignaturas = data.map((json) {
          try {
            return AsignaturaCurso.fromJson(json);
          } catch (e) {
            dlog('❌ Error parseando asignatura: ${json['nombre']}');
            dlog('   Error: $e');
            rethrow;
          }
        }).toList();

        dlog('✅ ${asignaturas.length} asignaturas obtenidas');
        return asignaturas;
      }

      dlog('❌ Backend respondió con success: false');
      return [];
    } catch (e) {
      dlog('❌ Error obteniendo asignaturas: $e');
      return [];
    }
  }

  /// 📊 Obtener solo el conteo de asignaturas (optimizado)
  Future<int> _getAsignaturasCount(String cursoId) async {
    try {
      // ✅ INTENTAR MÉTODO 1: Endpoint específico del curso
      try {
        final response1 = await _apiService.get('/cursos/$cursoId/asignaturas');

        if (response1['success'] == true) {
          if (response1['meta'] != null && response1['meta']['total'] != null) {
            return response1['meta']['total'] as int;
          }
          final List<dynamic> data = response1['data'] ?? [];
          return data.length;
        }
      } catch (e) {
        // Intentar método 2
      }

      // ✅ INTENTAR MÉTODO 2: Endpoint de asignaturas con filtro
      final response2 = await _apiService.get(
        '/asignaturas',
        queryParameters: {
          'cursoId': cursoId,
          'limite': '1',
        },
      );

      if (response2['success'] == true) {
        // Si el backend devuelve meta con total, usarlo
        if (response2['meta'] != null && response2['meta']['total'] != null) {
          return response2['meta']['total'] as int;
        }
        // Si no, contar los datos devueltos
        final List<dynamic> data = response2['data'] ?? [];
        return data.length;
      }

      return 0;
    } catch (e) {
      dlog('⚠️ Error obteniendo conteo de asignaturas: $e');
      return 0;
    }
  }
}
