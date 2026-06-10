// lib/services/asistencia_informes_service.dart
//
// Servicio para los 5 endpoints de informes analíticos de asistencia.
// Todos requieren JWT Bearer token.
// Roles con acceso: ADMIN, RECTOR, COORDINADOR, DOCENTE, ADMINISTRATIVO.
// Ranking solo: ADMIN, RECTOR, COORDINADOR.

import '../utils/logger.dart';
import '../models/asistencia_informes.dart';
import 'api_service.dart';

class AsistenciaInformesService {
  final ApiService _api = ApiService();

  // ==========================================
  // INFORME 1 — ESTUDIANTES EN RIESGO
  // GET /api/asistencia/informes/riesgo
  // ==========================================

  Future<InformeRiesgoResponse> obtenerRiesgo({
    int umbral = 80,
    String? cursoId,
    String? desde,
    String? hasta,
  }) async {
    try {
      dlog('📊 Informe riesgo — umbral: $umbral, curso: $cursoId');

      final params = <String, dynamic>{'umbral': umbral};
      if (cursoId != null && cursoId.isNotEmpty) params['cursoId'] = cursoId;
      if (desde != null) params['desde'] = desde;
      if (hasta != null) params['hasta'] = hasta;

      final response = await _api.get(
        '/asistencia/informes/riesgo',
        queryParameters: params,
      );

      return InformeRiesgoResponse.fromJson(response);
    } catch (e) {
      dlog('❌ Error informe riesgo: $e');
      rethrow;
    }
  }

  // ==========================================
  // INFORME 2 — TENDENCIA DE ASISTENCIA
  // GET /api/asistencia/informes/tendencia
  // ==========================================

  Future<InformeTendenciaResponse> obtenerTendencia({
    required String desde,
    required String hasta,
    String agrupacion = 'semana',
    String? cursoId,
  }) async {
    try {
      dlog('📊 Informe tendencia — $desde → $hasta ($agrupacion)');

      final params = <String, dynamic>{
        'desde': desde,
        'hasta': hasta,
        'agrupacion': agrupacion,
      };
      if (cursoId != null && cursoId.isNotEmpty) params['cursoId'] = cursoId;

      final response = await _api.get(
        '/asistencia/informes/tendencia',
        queryParameters: params,
      );

      return InformeTendenciaResponse.fromJson(response);
    } catch (e) {
      dlog('❌ Error informe tendencia: $e');
      rethrow;
    }
  }

  // ==========================================
  // INFORME 3 — RANKING DE CURSOS
  // GET /api/asistencia/informes/ranking-cursos
  // Solo ADMIN, RECTOR, COORDINADOR
  // ==========================================

  Future<InformeRankingResponse> obtenerRankingCursos({
    required String desde,
    required String hasta,
  }) async {
    try {
      dlog('📊 Informe ranking — $desde → $hasta');

      final response = await _api.get(
        '/asistencia/informes/ranking-cursos',
        queryParameters: {'desde': desde, 'hasta': hasta},
      );

      return InformeRankingResponse.fromJson(response);
    } catch (e) {
      dlog('❌ Error informe ranking: $e');
      rethrow;
    }
  }

  // ==========================================
  // INFORME 4 — PATRÓN POR DÍA DE LA SEMANA
  // GET /api/asistencia/informes/patron-dias
  // ==========================================

  Future<InformePatronDiasResponse> obtenerPatronDias({
    required String desde,
    required String hasta,
    String? cursoId,
  }) async {
    try {
      dlog('📊 Informe patrón días — $desde → $hasta');

      final params = <String, dynamic>{'desde': desde, 'hasta': hasta};
      if (cursoId != null && cursoId.isNotEmpty) params['cursoId'] = cursoId;

      final response = await _api.get(
        '/asistencia/informes/patron-dias',
        queryParameters: params,
      );

      return InformePatronDiasResponse.fromJson(response);
    } catch (e) {
      dlog('❌ Error informe patrón días: $e');
      rethrow;
    }
  }

  // ==========================================
  // INFORME 5 — HISTORIAL DE ESTUDIANTE
  // GET /api/asistencia/informes/historial/:estudianteId
  // ==========================================

  Future<InformeHistorialResponse> obtenerHistorialEstudiante({
    required String estudianteId,
    required String desde,
    required String hasta,
  }) async {
    try {
      dlog('📊 Informe historial — estudiante: $estudianteId');

      final response = await _api.get(
        '/asistencia/informes/historial/$estudianteId',
        queryParameters: {'desde': desde, 'hasta': hasta},
      );

      return InformeHistorialResponse.fromJson(response);
    } catch (e) {
      dlog('❌ Error informe historial: $e');
      rethrow;
    }
  }
}

// Singleton global
final asistenciaInformesService = AsistenciaInformesService();
