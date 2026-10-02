
import '../utils/fechas.dart';// lib/models/asistencia_informes.dart
//
// Modelos para los 5 informes analíticos de asistencia.
// Estos modelos son SOLO para lectura (informes), no modifican el registro base.

// ==========================================
// SUB-OBJETOS COMPARTIDOS
// ==========================================

/// Normaliza una referencia que puede llegar con populate (Map),
/// solo como id (String) o null.
Map<String, dynamic> _refMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is String) return {'_id': value};
  return <String, dynamic>{};
}

class CursoInforme {
  final String id;
  final String nombre;
  final String grado;
  final String grupo;

  CursoInforme({
    required this.id,
    required this.nombre,
    required this.grado,
    required this.grupo,
  });

  factory CursoInforme.fromJson(Map<String, dynamic> json) {
    return CursoInforme(
      id: json['_id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      grado: json['grado']?.toString() ?? '',
      grupo: json['grupo']?.toString() ?? '',
    );
  }

  String get nombreCompleto => '$nombre $grado$grupo'.trim();
}

class AsignaturaInforme {
  final String id;
  final String nombre;

  AsignaturaInforme({required this.id, required this.nombre});

  factory AsignaturaInforme.fromJson(Map<String, dynamic> json) {
    return AsignaturaInforme(
      id: json['_id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
    );
  }
}

class DocenteInforme {
  final String id;
  final String nombre;
  final String apellidos;

  DocenteInforme({
    required this.id,
    required this.nombre,
    required this.apellidos,
  });

  factory DocenteInforme.fromJson(Map<String, dynamic> json) {
    return DocenteInforme(
      id: json['_id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
}

// ==========================================
// INFORME 1 — ESTUDIANTES EN RIESGO
// GET /api/asistencia/informes/riesgo
// ==========================================

class InformeRiesgoResponse {
  final int umbral;
  final int total;
  final int criticos;
  final int alertas;
  final List<EstudianteRiesgo> estudiantes;

  InformeRiesgoResponse({
    required this.umbral,
    required this.total,
    required this.criticos,
    required this.alertas,
    required this.estudiantes,
  });

  factory InformeRiesgoResponse.fromJson(Map<String, dynamic> json) {
    return InformeRiesgoResponse(
      umbral: (json['umbral'] ?? 80) as int,
      total: (json['total'] ?? 0) as int,
      criticos: (json['criticos'] ?? 0) as int,
      alertas: (json['alertas'] ?? 0) as int,
      estudiantes: (json['estudiantes'] as List<dynamic>? ?? [])
          .map((e) => EstudianteRiesgo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EstudianteRiesgo {
  final String estudianteId;
  final String nombre;
  final String apellidos;
  final CursoInforme curso;
  final int clasesTotales;
  final int ausencias;
  final int tardanzas;
  final double porcentajeAsistencia;
  final String nivelRiesgo; // 'CRITICO' | 'ALERTA'

  EstudianteRiesgo({
    required this.estudianteId,
    required this.nombre,
    required this.apellidos,
    required this.curso,
    required this.clasesTotales,
    required this.ausencias,
    required this.tardanzas,
    required this.porcentajeAsistencia,
    required this.nivelRiesgo,
  });

  factory EstudianteRiesgo.fromJson(Map<String, dynamic> json) {
    return EstudianteRiesgo(
      estudianteId: json['estudianteId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      curso: CursoInforme.fromJson(_refMap(json['curso'])),
      clasesTotales: (json['clasesTotales'] ?? 0) as int,
      ausencias: (json['ausencias'] ?? 0) as int,
      tardanzas: (json['tardanzas'] ?? 0) as int,
      porcentajeAsistencia: (json['porcentajeAsistencia'] ?? 0.0).toDouble(),
      nivelRiesgo: json['nivelRiesgo']?.toString() ?? 'ALERTA',
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
}

// ==========================================
// INFORME 2 — TENDENCIA DE ASISTENCIA
// GET /api/asistencia/informes/tendencia
// ==========================================

class InformeTendenciaResponse {
  final String agrupacion;
  final int puntos;
  final List<PuntoTendencia> tendencia;

  InformeTendenciaResponse({
    required this.agrupacion,
    required this.puntos,
    required this.tendencia,
  });

  factory InformeTendenciaResponse.fromJson(Map<String, dynamic> json) {
    return InformeTendenciaResponse(
      agrupacion: json['agrupacion']?.toString() ?? 'semana',
      puntos: (json['puntos'] ?? 0) as int,
      tendencia: (json['tendencia'] as List<dynamic>? ?? [])
          .map((e) => PuntoTendencia.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PuntoTendencia {
  final String periodo;
  final DateTime fechaInicio;
  final int totalClases;
  final int totalEstudiantes;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final double porcentajeAsistencia;

  PuntoTendencia({
    required this.periodo,
    required this.fechaInicio,
    required this.totalClases,
    required this.totalEstudiantes,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.porcentajeAsistencia,
  });

  factory PuntoTendencia.fromJson(Map<String, dynamic> json) {
    return PuntoTendencia(
      periodo: json['periodo']?.toString() ?? '',
      fechaInicio: soloFechaOpcional(json['fechaInicio']?.toString() ?? '') ??
          DateTime.now(),
      totalClases: (json['totalClases'] ?? 0) as int,
      totalEstudiantes: (json['totalEstudiantes'] ?? 0) as int,
      presentes: (json['presentes'] ?? 0) as int,
      ausentes: (json['ausentes'] ?? 0) as int,
      tardanzas: (json['tardanzas'] ?? 0) as int,
      porcentajeAsistencia: (json['porcentajeAsistencia'] ?? 0.0).toDouble(),
    );
  }
}

// ==========================================
// INFORME 3 — RANKING DE CURSOS
// GET /api/asistencia/informes/ranking-cursos
// ==========================================

class InformeRankingResponse {
  final int total;
  final List<CursoRanking> ranking;

  InformeRankingResponse({required this.total, required this.ranking});

  factory InformeRankingResponse.fromJson(Map<String, dynamic> json) {
    return InformeRankingResponse(
      total: (json['total'] ?? 0) as int,
      ranking: (json['ranking'] as List<dynamic>? ?? [])
          .map((e) => CursoRanking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CursoRanking {
  final int posicion;
  final String cursoId;
  final String nombre;
  final String grado;
  final String grupo;
  final int totalClases;
  final int totalEstudiantes;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final double porcentajeAsistencia;

  CursoRanking({
    required this.posicion,
    required this.cursoId,
    required this.nombre,
    required this.grado,
    required this.grupo,
    required this.totalClases,
    required this.totalEstudiantes,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.porcentajeAsistencia,
  });

  factory CursoRanking.fromJson(Map<String, dynamic> json) {
    return CursoRanking(
      posicion: (json['posicion'] ?? 0) as int,
      cursoId: json['cursoId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      grado: json['grado']?.toString() ?? '',
      grupo: json['grupo']?.toString() ?? '',
      totalClases: (json['totalClases'] ?? 0) as int,
      totalEstudiantes: (json['totalEstudiantes'] ?? 0) as int,
      presentes: (json['presentes'] ?? 0) as int,
      ausentes: (json['ausentes'] ?? 0) as int,
      tardanzas: (json['tardanzas'] ?? 0) as int,
      porcentajeAsistencia: (json['porcentajeAsistencia'] ?? 0.0).toDouble(),
    );
  }

  String get nombreCompleto => '$nombre $grado$grupo'.trim();
}

// ==========================================
// INFORME 4 — PATRÓN POR DÍA DE LA SEMANA
// GET /api/asistencia/informes/patron-dias
// ==========================================

class InformePatronDiasResponse {
  final List<PatronDia> dias;

  InformePatronDiasResponse({required this.dias});

  factory InformePatronDiasResponse.fromJson(Map<String, dynamic> json) {
    return InformePatronDiasResponse(
      dias: (json['dias'] as List<dynamic>? ?? [])
          .map((e) => PatronDia.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PatronDia {
  final int diaSemana;
  final String nombreDia;
  final int totalClases;
  final int totalEstudiantes;
  final int ausencias;
  final int tardanzas;
  final double porcentajeAusentismo;

  PatronDia({
    required this.diaSemana,
    required this.nombreDia,
    required this.totalClases,
    required this.totalEstudiantes,
    required this.ausencias,
    required this.tardanzas,
    required this.porcentajeAusentismo,
  });

  factory PatronDia.fromJson(Map<String, dynamic> json) {
    return PatronDia(
      diaSemana: (json['diaSemana'] ?? 0) as int,
      nombreDia: json['nombreDia']?.toString() ?? '',
      totalClases: (json['totalClases'] ?? 0) as int,
      totalEstudiantes: (json['totalEstudiantes'] ?? 0) as int,
      ausencias: (json['ausencias'] ?? 0) as int,
      tardanzas: (json['tardanzas'] ?? 0) as int,
      porcentajeAusentismo: (json['porcentajeAusentismo'] ?? 0.0).toDouble(),
    );
  }
}

// ==========================================
// INFORME 5 — HISTORIAL DE ESTUDIANTE
// GET /api/asistencia/informes/historial/:estudianteId
// ==========================================

class InformeHistorialResponse {
  final EstudianteHistorial estudiante;
  final ResumenHistorial resumen;
  final List<RegistroHistorial> registros;

  InformeHistorialResponse({
    required this.estudiante,
    required this.resumen,
    required this.registros,
  });

  factory InformeHistorialResponse.fromJson(Map<String, dynamic> json) {
    return InformeHistorialResponse(
      estudiante: EstudianteHistorial.fromJson(
          json['estudiante'] as Map<String, dynamic>? ?? {}),
      resumen: ResumenHistorial.fromJson(
          json['resumen'] as Map<String, dynamic>? ?? {}),
      registros: (json['registros'] as List<dynamic>? ?? [])
          .map((e) => RegistroHistorial.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EstudianteHistorial {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;

  EstudianteHistorial({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
  });

  factory EstudianteHistorial.fromJson(Map<String, dynamic> json) {
    return EstudianteHistorial(
      id: json['_id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
}

class ResumenHistorial {
  final int clasesTotales;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final int justificados;
  final int permisos;
  final double porcentajeAsistencia;

  ResumenHistorial({
    required this.clasesTotales,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.justificados,
    required this.permisos,
    required this.porcentajeAsistencia,
  });

  factory ResumenHistorial.fromJson(Map<String, dynamic> json) {
    return ResumenHistorial(
      clasesTotales: (json['clasesTotales'] ?? 0) as int,
      presentes: (json['presentes'] ?? 0) as int,
      ausentes: (json['ausentes'] ?? 0) as int,
      tardanzas: (json['tardanzas'] ?? 0) as int,
      justificados: (json['justificados'] ?? 0) as int,
      permisos: (json['permisos'] ?? 0) as int,
      porcentajeAsistencia: (json['porcentajeAsistencia'] ?? 0.0).toDouble(),
    );
  }
}

class RegistroHistorial {
  final DateTime fecha;
  final String diaSemana;
  final CursoInforme curso;
  final AsignaturaInforme? asignatura;
  final String estado;
  final String? justificacion;
  final String? observaciones;
  final DocenteInforme? registradoPor;

  RegistroHistorial({
    required this.fecha,
    required this.diaSemana,
    required this.curso,
    this.asignatura,
    required this.estado,
    this.justificacion,
    this.observaciones,
    this.registradoPor,
  });

  factory RegistroHistorial.fromJson(Map<String, dynamic> json) {
    return RegistroHistorial(
      fecha:
          soloFechaOpcional(json['fecha']?.toString() ?? '') ?? DateTime.now(),
      diaSemana: json['diaSemana']?.toString() ?? '',
      curso: CursoInforme.fromJson(_refMap(json['curso'])),
      asignatura: json['asignatura'] != null
          ? AsignaturaInforme.fromJson(_refMap(json['asignatura']))
          : null,
      estado: json['estado']?.toString() ?? '',
      justificacion: json['justificacion']?.toString(),
      observaciones: json['observaciones']?.toString(),
      registradoPor: json['registradoPor'] != null
          ? DocenteInforme.fromJson(_refMap(json['registradoPor']))
          : null,
    );
  }
}
