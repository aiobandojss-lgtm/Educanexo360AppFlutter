// lib/models/curso.dart

/// Niveles educativos
enum NivelEducativo {
  preescolar('PREESCOLAR'),
  primaria('PRIMARIA'),
  secundaria('SECUNDARIA'),
  media('MEDIA');

  final String value;
  const NivelEducativo(this.value);

  static NivelEducativo fromString(String value) {
    return NivelEducativo.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NivelEducativo.primaria,
    );
  }

  String get displayName {
    switch (this) {
      case NivelEducativo.preescolar:
        return 'Preescolar';
      case NivelEducativo.primaria:
        return 'Primaria';
      case NivelEducativo.secundaria:
        return 'Secundaria';
      case NivelEducativo.media:
        return 'Media';
    }
  }
}

/// Jornadas escolares
enum Jornada {
  matutina('MATUTINA'),
  vespertina('VESPERTINA'),
  nocturna('NOCTURNA'),
  completa('COMPLETA');

  final String value;
  const Jornada(this.value);

  static Jornada? fromString(String? value) {
    if (value == null) return null;
    try {
      return Jornada.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }

  String get displayName {
    switch (this) {
      case Jornada.matutina:
        return 'Matutina';
      case Jornada.vespertina:
        return 'Vespertina';
      case Jornada.nocturna:
        return 'Nocturna';
      case Jornada.completa:
        return 'Completa';
    }
  }

  String get icono {
    switch (this) {
      case Jornada.matutina:
        return '🌅';
      case Jornada.vespertina:
        return '🌇';
      case Jornada.nocturna:
        return '🌙';
      case Jornada.completa:
        return '☀️';
    }
  }
}

/// Estados del curso
enum EstadoCurso {
  activo('ACTIVO'),
  inactivo('INACTIVO'),
  finalizado('FINALIZADO');

  final String value;
  const EstadoCurso(this.value);

  static EstadoCurso fromString(String value) {
    return EstadoCurso.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoCurso.activo,
    );
  }
}

/// Director de grupo
class DirectorGrupo {
  final String id;
  final String nombre;
  final String apellidos;
  final String? email;

  DirectorGrupo({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.email,
  });

  String get nombreCompleto => '$nombre $apellidos';

  factory DirectorGrupo.fromJson(Map<String, dynamic> json) {
    return DirectorGrupo(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      if (email != null) 'email': email,
    };
  }
}

/// Estudiante del curso
class EstudianteCurso {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;
  final String? estado;
  final DateTime? fechaNacimiento;
  final String? genero;

  EstudianteCurso({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    this.estado,
    this.fechaNacimiento,
    this.genero,
  });

  String get nombreCompleto => '$nombre $apellidos';

  String get iniciales {
    final primerNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final primerApellido =
        apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$primerNombre$primerApellido';
  }

  factory EstudianteCurso.fromJson(Map<String, dynamic> json) {
    return EstudianteCurso(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? '',
      estado: json['estado'],
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.tryParse(json['fechaNacimiento'])
          : null,
      genero: json['genero'],
    );
  }
}

/// Docente de asignatura
class DocenteAsignatura {
  final String id;
  final String nombre;
  final String apellidos;
  final String? email;

  DocenteAsignatura({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.email,
  });

  String get nombreCompleto => '$nombre $apellidos';

  factory DocenteAsignatura.fromJson(Map<String, dynamic> json) {
    return DocenteAsignatura(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'],
    );
  }
}

/// Asignatura del curso
class AsignaturaCurso {
  final String id;
  final String nombre;
  final String? codigo;
  final int? creditos;
  final int? intensidadHoraria;
  final DocenteAsignatura? docente;
  final String? docenteId;
  final String? estado;

  AsignaturaCurso({
    required this.id,
    required this.nombre,
    this.codigo,
    this.creditos,
    this.intensidadHoraria,
    this.docente,
    this.docenteId,
    this.estado,
  });

  factory AsignaturaCurso.fromJson(Map<String, dynamic> json) {
    // ✅ Parsear docente - puede venir en 2 formatos
    DocenteAsignatura? docenteParsed;
    String? docenteIdParsed;

    // Si viene el campo 'docente' directamente, usarlo
    if (json['docente'] != null && json['docente'] is Map) {
      docenteParsed = DocenteAsignatura.fromJson(json['docente']);
    }
    // Si no, verificar si 'docenteId' es un objeto (populate)
    else if (json['docenteId'] != null && json['docenteId'] is Map) {
      docenteParsed = DocenteAsignatura.fromJson(json['docenteId']);
      docenteIdParsed = json['docenteId']['_id'] ?? json['docenteId']['id'];
    }
    // Si 'docenteId' es un String simple
    else if (json['docenteId'] != null && json['docenteId'] is String) {
      docenteIdParsed = json['docenteId'];
    }

    return AsignaturaCurso(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      codigo: json['codigo'],
      creditos: json['creditos'],
      intensidadHoraria:
          json['intensidad_horaria'] ?? json['intensidadHoraria'],
      docente: docenteParsed,
      docenteId: docenteIdParsed,
      estado: json['estado'],
    );
  }
}

/// Modelo principal de Curso
class Curso {
  final String id;
  final String nombre;
  final NivelEducativo nivel;
  final String? grado;
  final String? grupo;
  final String? seccion;
  final String? anoAcademico;
  final EstadoCurso estado;
  final Jornada? jornada;
  final int? capacidad;
  final DirectorGrupo? directorGrupo;
  final List<EstudianteCurso>? estudiantes;
  final List<AsignaturaCurso>? asignaturas;
  final int? estudiantesCount;
  final int? asignaturasCount;
  final String escuelaId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Curso({
    required this.id,
    required this.nombre,
    required this.nivel,
    this.grado,
    this.grupo,
    this.seccion,
    this.anoAcademico,
    required this.estado,
    this.jornada,
    this.capacidad,
    this.directorGrupo,
    this.estudiantes,
    this.asignaturas,
    this.estudiantesCount,
    this.asignaturasCount,
    required this.escuelaId,
    this.createdAt,
    this.updatedAt,
  });

  /// Obtener display del grado (ej: "9° A")
  String get gradoDisplay {
    if (grado != null && grupo != null) {
      final esNumerico = int.tryParse(grado!) != null;
      final gradoFormateado =
          esNumerico && !grado!.contains('°') ? '$grado°' : grado!;
      return '$gradoFormateado $grupo';
    }

    // Extraer del nombre si no hay grado/grupo separados
    final nombreParts = nombre.split(' ');
    if (nombreParts.length >= 2) {
      return '${nombreParts[0]} ${nombreParts[1]}';
    }

    return nombre;
  }

  /// Obtener nombre del director
  String get nombreDirector {
    if (directorGrupo == null) return 'No asignado';
    return directorGrupo!.nombreCompleto;
  }

  /// Obtener conteo de estudiantes
  int get totalEstudiantes {
    if (estudiantesCount != null) return estudiantesCount!;
    if (estudiantes != null) return estudiantes!.length;
    return 0;
  }

  /// Obtener conteo de asignaturas
  int get totalAsignaturas {
    if (asignaturasCount != null) return asignaturasCount!;
    if (asignaturas != null) return asignaturas!.length;
    return 0;
  }

  factory Curso.fromJson(Map<String, dynamic> json) {
    return Curso(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? 'Curso sin nombre',
      nivel: NivelEducativo.fromString(json['nivel'] ?? 'PRIMARIA'),
      grado: json['grado'],
      grupo: json['grupo'] ?? json['seccion'],
      seccion: json['seccion'] ?? json['grupo'],
      anoAcademico:
          json['año_academico'] ?? json['anoEscolar'] ?? json['aÃ±o_academico'],
      estado: EstadoCurso.fromString(json['estado'] ?? 'ACTIVO'),
      jornada: Jornada.fromString(json['jornada']),
      capacidad: json['capacidad'],
      directorGrupo: json['director_grupo'] != null
          ? DirectorGrupo.fromJson(json['director_grupo'])
          : null,
      estudiantes: json['estudiantes'] != null
          ? (json['estudiantes'] as List)
              .map((e) => EstudianteCurso.fromJson(e))
              .toList()
          : null,
      asignaturas: json['asignaturas'] != null
          ? (json['asignaturas'] as List)
              .map((e) => AsignaturaCurso.fromJson(e))
              .toList()
          : null,
      estudiantesCount: json['estudiantesCount'],
      asignaturasCount: json['asignaturasCount'],
      escuelaId: json['escuelaId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'nivel': nivel.value,
      if (grado != null) 'grado': grado,
      if (grupo != null) 'grupo': grupo,
      if (seccion != null) 'seccion': seccion,
      if (anoAcademico != null) 'año_academico': anoAcademico,
      'estado': estado.value,
      if (jornada != null) 'jornada': jornada!.value,
      if (capacidad != null) 'capacidad': capacidad,
      if (directorGrupo != null) 'director_grupo': directorGrupo!.toJson(),
      if (estudiantesCount != null) 'estudiantesCount': estudiantesCount,
      if (asignaturasCount != null) 'asignaturasCount': asignaturasCount,
      'escuelaId': escuelaId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Curso copyWith({
    String? id,
    String? nombre,
    NivelEducativo? nivel,
    String? grado,
    String? grupo,
    String? seccion,
    String? anoAcademico,
    EstadoCurso? estado,
    Jornada? jornada,
    int? capacidad,
    DirectorGrupo? directorGrupo,
    List<EstudianteCurso>? estudiantes,
    List<AsignaturaCurso>? asignaturas,
    int? estudiantesCount,
    int? asignaturasCount,
    String? escuelaId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Curso(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nivel: nivel ?? this.nivel,
      grado: grado ?? this.grado,
      grupo: grupo ?? this.grupo,
      seccion: seccion ?? this.seccion,
      anoAcademico: anoAcademico ?? this.anoAcademico,
      estado: estado ?? this.estado,
      jornada: jornada ?? this.jornada,
      capacidad: capacidad ?? this.capacidad,
      directorGrupo: directorGrupo ?? this.directorGrupo,
      estudiantes: estudiantes ?? this.estudiantes,
      asignaturas: asignaturas ?? this.asignaturas,
      estudiantesCount: estudiantesCount ?? this.estudiantesCount,
      asignaturasCount: asignaturasCount ?? this.asignaturasCount,
      escuelaId: escuelaId ?? this.escuelaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
