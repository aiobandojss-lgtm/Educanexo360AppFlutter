// lib/models/asistencia.dart

/// 📋 MODELO DE ASISTENCIA COMPLETO
/// Basado en la estructura de React Native y backend
library;

// ==========================================
// CONSTANTES - Estados de Asistencia
// ==========================================

class EstadosAsistencia {
  static const String presente = 'PRESENTE';
  static const String ausente = 'AUSENTE';
  static const String tardanza = 'TARDANZA';
  static const String justificado = 'JUSTIFICADO';
  static const String permiso = 'PERMISO';

  static List<String> get todos => [
        presente,
        ausente,
        tardanza,
        justificado,
        permiso,
      ];

  static String getLabel(String estado) {
    switch (estado) {
      case presente:
        return 'Presente';
      case ausente:
        return 'Ausente';
      case tardanza:
        return 'Tardanza';
      case justificado:
        return 'Justificado';
      case permiso:
        return 'Permiso';
      default:
        return estado;
    }
  }
}

class TiposSesion {
  static const String clase = 'CLASE';
  static const String actividad = 'ACTIVIDAD';
  static const String evento = 'EVENTO';
  static const String otro = 'OTRO';

  static List<String> get todos => [clase, actividad, evento, otro];

  static String getLabel(String tipo) {
    switch (tipo) {
      case clase:
        return 'Clase';
      case actividad:
        return 'Actividad';
      case evento:
        return 'Evento';
      case otro:
        return 'Otro';
      default:
        return tipo;
    }
  }
}

// ==========================================
// MODELO PRINCIPAL - Registro de Asistencia
// ==========================================

class RegistroAsistencia {
  final String id;
  final DateTime fecha;
  final CursoAsistencia curso;
  final AsignaturaAsistencia? asignatura;
  final DocenteAsistencia? docente;
  final String? periodoId;
  final String tipoSesion;
  final String horaInicio;
  final String horaFin;
  final List<EstudianteAsistencia> estudiantes;
  final String? observacionesGenerales;
  final bool finalizado;
  final DateTime createdAt;
  final DateTime updatedAt;

  RegistroAsistencia({
    required this.id,
    required this.fecha,
    required this.curso,
    this.asignatura,
    this.docente,
    this.periodoId,
    required this.tipoSesion,
    required this.horaInicio,
    required this.horaFin,
    required this.estudiantes,
    this.observacionesGenerales,
    required this.finalizado,
    required this.createdAt,
    required this.updatedAt,
  });

  // 📄 DESERIALIZACIÓN desde JSON - ✅ MANEJA STRING O MAP
  factory RegistroAsistencia.fromJson(Map<String, dynamic> json) {
    return RegistroAsistencia(
      id: json['_id'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      curso: _parseCurso(json['cursoId']),
      asignatura: _parseAsignatura(json['asignaturaId']),
      docente: _parseDocente(json['docenteId']),
      periodoId: json['periodoId'] is String ? json['periodoId'] : null,
      tipoSesion: json['tipoSesion'] ?? TiposSesion.clase,
      horaInicio: json['horaInicio'] ?? '',
      horaFin: json['horaFin'] ?? '',
      estudiantes: (json['estudiantes'] as List<dynamic>?)
              ?.map((e) => EstudianteAsistencia.fromJson(e))
              .toList() ??
          [],
      observacionesGenerales: json['observacionesGenerales'],
      finalizado: json['finalizado'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 🔧 Helper: Parsear curso (puede ser String o Map)
  static CursoAsistencia _parseCurso(dynamic cursoData) {
    if (cursoData == null) {
      return CursoAsistencia(
        id: '',
        nombre: 'Sin curso',
        grado: '',
        grupo: '',
      );
    }

    if (cursoData is String) {
      return CursoAsistencia(
        id: cursoData,
        nombre: 'Curso ID: $cursoData',
        grado: '',
        grupo: '',
      );
    }

    return CursoAsistencia.fromJson(cursoData as Map<String, dynamic>);
  }

  // 🔧 Helper: Parsear asignatura (puede ser String o Map)
  static AsignaturaAsistencia? _parseAsignatura(dynamic asignaturaData) {
    if (asignaturaData == null) return null;

    if (asignaturaData is String) {
      return AsignaturaAsistencia(
        id: asignaturaData,
        nombre: 'Asignatura ID: $asignaturaData',
      );
    }

    return AsignaturaAsistencia.fromJson(
        asignaturaData as Map<String, dynamic>);
  }

  // 🔧 Helper: Parsear docente (puede ser String o Map)
  static DocenteAsistencia? _parseDocente(dynamic docenteData) {
    if (docenteData == null) return null;

    if (docenteData is String) {
      return DocenteAsistencia(
        id: docenteData,
        nombre: 'Docente',
        apellidos: 'ID: $docenteData',
      );
    }

    return DocenteAsistencia.fromJson(docenteData as Map<String, dynamic>);
  }

  // 📤 SERIALIZACIÓN a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fecha': fecha.toIso8601String().split('T')[0],
      'cursoId': curso.id,
      'asignaturaId': asignatura?.id,
      'docenteId': docente?.id,
      'periodoId': periodoId,
      'tipoSesion': tipoSesion,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'estudiantes': estudiantes.map((e) => e.toJson()).toList(),
      'observacionesGenerales': observacionesGenerales,
      'finalizado': finalizado,
    };
  }

  // 🔧 ESTADÍSTICAS del registro
  EstadisticasAsistencia get estadisticas {
    final total = estudiantes.length;
    final presentes =
        estudiantes.where((e) => e.estado == EstadosAsistencia.presente).length;
    final ausentes =
        estudiantes.where((e) => e.estado == EstadosAsistencia.ausente).length;
    final tardanzas =
        estudiantes.where((e) => e.estado == EstadosAsistencia.tardanza).length;
    final justificados = estudiantes
        .where((e) => e.estado == EstadosAsistencia.justificado)
        .length;
    final permisos =
        estudiantes.where((e) => e.estado == EstadosAsistencia.permiso).length;

    return EstadisticasAsistencia(
      totalEstudiantes: total,
      presentes: presentes,
      ausentes: ausentes,
      tardanzas: tardanzas,
      justificados: justificados,
      permisos: permisos,
    );
  }
}

// ==========================================
// ESTUDIANTE EN ASISTENCIA
// ==========================================

class EstudianteAsistencia {
  final String estudianteId;
  final String? nombre;
  final String? apellidos;
  final String estado;
  final String? justificacion;
  final String? observaciones;

  EstudianteAsistencia({
    required this.estudianteId,
    this.nombre,
    this.apellidos,
    required this.estado,
    this.justificacion,
    this.observaciones,
  });

  factory EstudianteAsistencia.fromJson(Map<String, dynamic> json) {
    final raw = json['estudianteId'];
    final esObjeto = raw is Map<String, dynamic>;
    return EstudianteAsistencia(
      estudianteId: esObjeto ? (raw['_id'] ?? '').toString() : (raw ?? '').toString(),
      nombre: json['nombre'] ?? (esObjeto ? raw['nombre'] : null),
      apellidos: json['apellidos'] ?? (esObjeto ? raw['apellidos'] : null),
      estado: json['estado'] ?? EstadosAsistencia.presente,
      justificacion: json['justificacion'],
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estudianteId': estudianteId,
      'nombre': nombre,
      'apellidos': apellidos,
      'estado': estado,
      'justificacion': justificacion,
      'observaciones': observaciones,
    };
  }

  String get nombreCompleto {
    if (nombre == null && apellidos == null) return 'Sin nombre';
    return '${nombre ?? ''} ${apellidos ?? ''}'.trim();
  }

  EstudianteAsistencia copyWith({
    String? estudianteId,
    String? nombre,
    String? apellidos,
    String? estado,
    String? justificacion,
    String? observaciones,
  }) {
    return EstudianteAsistencia(
      estudianteId: estudianteId ?? this.estudianteId,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      estado: estado ?? this.estado,
      justificacion: justificacion ?? this.justificacion,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}

// ==========================================
// CURSO EN ASISTENCIA
// ==========================================

class CursoAsistencia {
  final String id;
  final String nombre;
  final String grado;
  final String grupo;

  CursoAsistencia({
    required this.id,
    required this.nombre,
    required this.grado,
    required this.grupo,
  });

  factory CursoAsistencia.fromJson(Map<String, dynamic> json) {
    return CursoAsistencia(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      grado: json['grado'] ?? '',
      grupo: json['grupo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'grado': grado,
      'grupo': grupo,
    };
  }

  String get nombreCompleto => '$nombre - $grado$grupo';
}

// ==========================================
// ASIGNATURA EN ASISTENCIA
// ==========================================

class AsignaturaAsistencia {
  final String id;
  final String nombre;

  AsignaturaAsistencia({
    required this.id,
    required this.nombre,
  });

  factory AsignaturaAsistencia.fromJson(Map<String, dynamic> json) {
    return AsignaturaAsistencia(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
    };
  }
}

// ==========================================
// DOCENTE EN ASISTENCIA
// ==========================================

class DocenteAsistencia {
  final String id;
  final String nombre;
  final String apellidos;

  DocenteAsistencia({
    required this.id,
    required this.nombre,
    required this.apellidos,
  });

  factory DocenteAsistencia.fromJson(Map<String, dynamic> json) {
    return DocenteAsistencia(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellidos': apellidos,
    };
  }

  String get nombreCompleto => '$nombre $apellidos';
}

// ==========================================
// RESUMEN DE ASISTENCIA (para la lista)
// ==========================================

class ResumenAsistencia {
  final String id;
  final DateTime fecha;
  final CursoAsistencia curso;
  final AsignaturaAsistencia? asignatura; // ✅ NUEVO CAMPO
  final int totalEstudiantes;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final int justificados;
  final int permisos;
  final double porcentajeAsistencia;
  final DocenteAsistencia? registradoPor;
  final bool finalizado;
  final DateTime createdAt;

  ResumenAsistencia({
    required this.id,
    required this.fecha,
    required this.curso,
    this.asignatura, // ✅ NUEVO CAMPO
    required this.totalEstudiantes,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.justificados,
    required this.permisos,
    required this.porcentajeAsistencia,
    this.registradoPor,
    required this.finalizado,
    required this.createdAt,
  });

  factory ResumenAsistencia.fromJson(Map<String, dynamic> json) {
    return ResumenAsistencia(
      id: json['_id'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      curso: _parseCursoResumen(json['curso'] ?? json['cursoId']),
      asignatura: _parseAsignaturaResumen(
          json['asignatura'] ?? json['asignaturaId']), // ✅ NUEVO
      totalEstudiantes: json['totalEstudiantes'] ?? 0,
      presentes: json['presentes'] ?? 0,
      ausentes: json['ausentes'] ?? 0,
      tardanzas: json['tardes'] ?? json['tardanzas'] ?? 0,
      justificados: json['justificados'] ?? 0,
      permisos: json['permisos'] ?? 0,
      porcentajeAsistencia: (json['porcentajeAsistencia'] ?? 0.0).toDouble(),
      registradoPor: _parseDocenteResumen(json['registradoPor']),
      finalizado: json['finalizado'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 🔧 Helper: Parsear curso para resumen
  static CursoAsistencia _parseCursoResumen(dynamic cursoData) {
    if (cursoData == null) {
      return CursoAsistencia(
        id: '',
        nombre: 'Sin curso',
        grado: '',
        grupo: '',
      );
    }

    if (cursoData is String) {
      return CursoAsistencia(
        id: cursoData,
        nombre: 'Curso ID: $cursoData',
        grado: '',
        grupo: '',
      );
    }

    return CursoAsistencia.fromJson(cursoData as Map<String, dynamic>);
  }

  // 🔧 Helper: Parsear docente para resumen
  static DocenteAsistencia? _parseDocenteResumen(dynamic docenteData) {
    if (docenteData == null) return null;

    if (docenteData is String) {
      return DocenteAsistencia(
        id: docenteData,
        nombre: 'Docente',
        apellidos: '',
      );
    }

    return DocenteAsistencia.fromJson(docenteData as Map<String, dynamic>);
  }

  // 🔧 Helper: Parsear asignatura para resumen - ✅ NUEVO
  static AsignaturaAsistencia? _parseAsignaturaResumen(dynamic asignaturaData) {
    if (asignaturaData == null) return null;

    if (asignaturaData is String) {
      return AsignaturaAsistencia(
        id: asignaturaData,
        nombre: 'Asignatura',
      );
    }

    return AsignaturaAsistencia.fromJson(
        asignaturaData as Map<String, dynamic>);
  }
}

// ==========================================
// ESTADÍSTICAS DE ASISTENCIA
// ==========================================

class EstadisticasAsistencia {
  final int totalEstudiantes;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final int justificados;
  final int permisos;

  EstadisticasAsistencia({
    required this.totalEstudiantes,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.justificados,
    required this.permisos,
  });

  double get porcentajePresentes {
    if (totalEstudiantes == 0) return 0.0;
    return (presentes / totalEstudiantes) * 100;
  }

  double get porcentajeAsistencia {
    if (totalEstudiantes == 0) return 0.0;
    final asistieron = presentes + tardanzas;
    return (asistieron / totalEstudiantes) * 100;
  }

  int get noAsistieron => ausentes;
}

// ==========================================
// CURSO DISPONIBLE (para selección)
// ==========================================

class CursoDisponible {
  final String id;
  final String nombre;
  final String grado;
  final String grupo;

  CursoDisponible({
    required this.id,
    required this.nombre,
    required this.grado,
    required this.grupo,
  });

  factory CursoDisponible.fromJson(Map<String, dynamic> json) {
    return CursoDisponible(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      grado: json['grado'] ?? '',
      grupo: json['grupo'] ?? '',
    );
  }

  String get nombreCompleto => '$nombre - $grado$grupo';
}

// ==========================================
// ASIGNATURA DISPONIBLE (para selección)
// ==========================================

class AsignaturaDisponible {
  final String id;
  final String nombre;
  final String? docenteNombre;

  AsignaturaDisponible({
    required this.id,
    required this.nombre,
    this.docenteNombre,
  });

  factory AsignaturaDisponible.fromJson(Map<String, dynamic> json) {
    return AsignaturaDisponible(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      docenteNombre: json['docenteNombre'],
    );
  }

  String get nombreCompleto {
    if (docenteNombre != null && docenteNombre!.isNotEmpty) {
      return '$nombre - $docenteNombre';
    }
    return nombre;
  }
}

// ==========================================
// ALERTA DE ASISTENCIA
// ==========================================

class AlertaAsistencia {
  final String id;
  final String estudianteNombre;
  final String estudianteApellidos;
  final String estudianteId;
  final String cursoNombre;
  final String cursoId;
  final String nivel; // ALERTA | CRITICO | INMINENTE
  final double porcentajeAusencias;
  final String periodoId;
  final DateTime fechaEnvio;

  AlertaAsistencia({
    required this.id,
    required this.estudianteNombre,
    required this.estudianteApellidos,
    required this.estudianteId,
    required this.cursoNombre,
    required this.cursoId,
    required this.nivel,
    required this.porcentajeAusencias,
    required this.periodoId,
    required this.fechaEnvio,
  });

  factory AlertaAsistencia.fromJson(Map<String, dynamic> json) {
    final estudiante = json['estudianteId'];
    final curso = json['cursoId'];

    return AlertaAsistencia(
      id: json['_id'] ?? '',
      estudianteNombre: estudiante is Map ? estudiante['nombre'] ?? '' : '',
      estudianteApellidos: estudiante is Map ? estudiante['apellidos'] ?? '' : '',
      estudianteId: estudiante is Map ? estudiante['_id'] ?? '' : (estudiante ?? ''),
      cursoNombre: curso is Map ? curso['nombre'] ?? '' : '',
      cursoId: curso is Map ? curso['_id'] ?? '' : (curso ?? ''),
      nivel: json['nivel'] ?? 'ALERTA',
      porcentajeAusencias: (json['porcentajeAusencias'] ?? 0.0).toDouble(),
      periodoId: json['periodoId'] ?? '',
      fechaEnvio: json['fechaEnvio'] != null
          ? DateTime.parse(json['fechaEnvio'])
          : DateTime.now(),
    );
  }

  String get estudianteNombreCompleto => '$estudianteNombre $estudianteApellidos'.trim();
}

class NivelesAlerta {
  static const String alerta = 'ALERTA';
  static const String critico = 'CRITICO';
  static const String inminente = 'INMINENTE';
}

// ==========================================
// ESTADÍSTICAS DE UN ESTUDIANTE (endpoint /estadisticas/estudiante/:id)
// ==========================================

class EstadisticasEstudiante {
  final int totalClases;
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final int justificados;
  final int permisos;
  final double porcentajeAsistencia;

  EstadisticasEstudiante({
    required this.totalClases,
    required this.presentes,
    required this.ausentes,
    required this.tardanzas,
    required this.justificados,
    required this.permisos,
    required this.porcentajeAsistencia,
  });

  factory EstadisticasEstudiante.fromJson(Map<String, dynamic> json) {
    return EstadisticasEstudiante(
      // Backend devuelve 'clasesTotales'; se acepta 'totalClases' como fallback
      totalClases: json['clasesTotales'] ?? json['totalClases'] ?? 0,
      presentes: json['presentes'] ?? 0,
      ausentes: json['ausentes'] ?? 0,
      tardanzas: json['tardanzas'] ?? 0,
      justificados: json['justificados'] ?? 0,
      permisos: json['permisos'] ?? 0,
      porcentajeAsistencia: (json['porcentajeAsistencia'] ?? 0.0).toDouble(),
    );
  }

  factory EstadisticasEstudiante.vacia() {
    return EstadisticasEstudiante(
      totalClases: 0,
      presentes: 0,
      ausentes: 0,
      tardanzas: 0,
      justificados: 0,
      permisos: 0,
      porcentajeAsistencia: 0,
    );
  }
}

// ==========================================
// HISTORIAL DE ASISTENCIA (endpoint /informes/historial/:id)
// ==========================================

class HistorialRegistro {
  final DateTime fecha;
  final String diaSemana;
  final String cursoNombre;
  final String? asignaturaNombre;
  final String estado;
  final String? justificacion;
  final String? observaciones;

  HistorialRegistro({
    required this.fecha,
    required this.diaSemana,
    required this.cursoNombre,
    this.asignaturaNombre,
    required this.estado,
    this.justificacion,
    this.observaciones,
  });

  factory HistorialRegistro.fromJson(Map<String, dynamic> json) {
    final curso = json['curso'];
    final asignatura = json['asignatura'];

    return HistorialRegistro(
      fecha: DateTime.parse(json['fecha']),
      diaSemana: json['diaSemana'] ?? '',
      cursoNombre: curso is Map ? curso['nombre'] ?? '' : '',
      asignaturaNombre: asignatura is Map ? asignatura['nombre'] : null,
      estado: json['estado'] ?? EstadosAsistencia.presente,
      justificacion: json['justificacion'],
      observaciones: json['observaciones'],
    );
  }
}

class HistorialEstudiante {
  final String nombre;
  final String apellidos;
  final EstadisticasEstudiante resumen;
  final List<HistorialRegistro> registros;

  HistorialEstudiante({
    required this.nombre,
    required this.apellidos,
    required this.resumen,
    required this.registros,
  });

  factory HistorialEstudiante.fromJson(Map<String, dynamic> json) {
    final estudiante = json['estudiante'] as Map<String, dynamic>? ?? {};
    final resumenJson = json['resumen'] as Map<String, dynamic>? ?? {};
    final registrosJson = json['registros'] as List<dynamic>? ?? [];

    return HistorialEstudiante(
      nombre: estudiante['nombre'] ?? '',
      apellidos: estudiante['apellidos'] ?? '',
      resumen: EstadisticasEstudiante.fromJson(resumenJson),
      registros: registrosJson
          .map((r) => HistorialRegistro.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();
}
