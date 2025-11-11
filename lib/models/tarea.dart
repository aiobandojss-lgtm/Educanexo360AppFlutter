// lib/models/tarea.dart

/// 📚 MODELO DE TAREA COMPLETO
/// Basado en la estructura del backend y React Native

// ========================================
// 🏷️ ENUMS
// ========================================

enum TipoTarea {
  individual,
  grupal,
}

extension TipoTareaExtension on TipoTarea {
  String get value {
    switch (this) {
      case TipoTarea.individual:
        return 'INDIVIDUAL';
      case TipoTarea.grupal:
        return 'GRUPAL';
    }
  }

  String get displayName {
    switch (this) {
      case TipoTarea.individual:
        return 'Individual';
      case TipoTarea.grupal:
        return 'Grupal';
    }
  }

  static TipoTarea fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INDIVIDUAL':
        return TipoTarea.individual;
      case 'GRUPAL':
        return TipoTarea.grupal;
      default:
        return TipoTarea.individual;
    }
  }
}

enum PrioridadTarea {
  alta,
  media,
  baja,
}

extension PrioridadTareaExtension on PrioridadTarea {
  String get value {
    switch (this) {
      case PrioridadTarea.alta:
        return 'ALTA';
      case PrioridadTarea.media:
        return 'MEDIA';
      case PrioridadTarea.baja:
        return 'BAJA';
    }
  }

  String get displayName {
    switch (this) {
      case PrioridadTarea.alta:
        return 'Alta';
      case PrioridadTarea.media:
        return 'Media';
      case PrioridadTarea.baja:
        return 'Baja';
    }
  }

  int get color {
    switch (this) {
      case PrioridadTarea.alta:
        return 0xFFF44336; // Rojo
      case PrioridadTarea.media:
        return 0xFFFF9800; // Naranja
      case PrioridadTarea.baja:
        return 0xFF4CAF50; // Verde
    }
  }

  String get icon {
    switch (this) {
      case PrioridadTarea.alta:
        return '🔴';
      case PrioridadTarea.media:
        return '🟡';
      case PrioridadTarea.baja:
        return '🟢';
    }
  }

  static PrioridadTarea fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ALTA':
        return PrioridadTarea.alta;
      case 'MEDIA':
        return PrioridadTarea.media;
      case 'BAJA':
        return PrioridadTarea.baja;
      default:
        return PrioridadTarea.media;
    }
  }
}

enum EstadoTarea {
  activa,
  cerrada,
  cancelada,
}

extension EstadoTareaExtension on EstadoTarea {
  String get value {
    switch (this) {
      case EstadoTarea.activa:
        return 'ACTIVA';
      case EstadoTarea.cerrada:
        return 'CERRADA';
      case EstadoTarea.cancelada:
        return 'CANCELADA';
    }
  }

  String get displayName {
    switch (this) {
      case EstadoTarea.activa:
        return 'Activa';
      case EstadoTarea.cerrada:
        return 'Cerrada';
      case EstadoTarea.cancelada:
        return 'Cancelada';
    }
  }

  static EstadoTarea fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVA':
        return EstadoTarea.activa;
      case 'CERRADA':
        return EstadoTarea.cerrada;
      case 'CANCELADA':
        return EstadoTarea.cancelada;
      default:
        return EstadoTarea.activa;
    }
  }
}

enum EstadoEntrega {
  pendiente,
  vista,
  entregada,
  atrasada,
  calificada,
}

extension EstadoEntregaExtension on EstadoEntrega {
  String get value {
    switch (this) {
      case EstadoEntrega.pendiente:
        return 'PENDIENTE';
      case EstadoEntrega.vista:
        return 'VISTA';
      case EstadoEntrega.entregada:
        return 'ENTREGADA';
      case EstadoEntrega.atrasada:
        return 'ATRASADA';
      case EstadoEntrega.calificada:
        return 'CALIFICADA';
    }
  }

  String get displayName {
    switch (this) {
      case EstadoEntrega.pendiente:
        return 'Pendiente';
      case EstadoEntrega.vista:
        return 'Vista';
      case EstadoEntrega.entregada:
        return 'Entregada';
      case EstadoEntrega.atrasada:
        return 'Atrasada';
      case EstadoEntrega.calificada:
        return 'Calificada';
    }
  }

  int get color {
    switch (this) {
      case EstadoEntrega.pendiente:
        return 0xFF9E9E9E; // Gris
      case EstadoEntrega.vista:
        return 0xFF2196F3; // Azul
      case EstadoEntrega.entregada:
        return 0xFF4CAF50; // Verde
      case EstadoEntrega.atrasada:
        return 0xFFF44336; // Rojo
      case EstadoEntrega.calificada:
        return 0xFF1B5E20; // Verde oscuro
    }
  }

  String get icon {
    switch (this) {
      case EstadoEntrega.pendiente:
        return '⏳';
      case EstadoEntrega.vista:
        return '👁️';
      case EstadoEntrega.entregada:
        return '✅';
      case EstadoEntrega.atrasada:
        return '⚠️';
      case EstadoEntrega.calificada:
        return '⭐';
    }
  }

  static EstadoEntrega fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE':
        return EstadoEntrega.pendiente;
      case 'VISTA':
        return EstadoEntrega.vista;
      case 'ENTREGADA':
        return EstadoEntrega.entregada;
      case 'ATRASADA':
        return EstadoEntrega.atrasada;
      case 'CALIFICADA':
        return EstadoEntrega.calificada;
      default:
        return EstadoEntrega.pendiente;
    }
  }
}

// ========================================
// 📄 MODELO PRINCIPAL: TAREA
// ========================================

class Tarea {
  final String id;
  final String titulo;
  final String descripcion;
  final DocenteInfo docente;
  final AsignaturaInfo asignatura;
  final CursoInfo curso;
  final String escuelaId;
  final List<String> estudiantesIds;
  final DateTime fechaAsignacion;
  final DateTime fechaLimite;
  final TipoTarea tipo;
  final PrioridadTarea prioridad;
  final bool permiteTardias;
  final double calificacionMaxima;
  final double? pesoEvaluacion;
  final List<ArchivoTarea> archivosReferencia;
  final List<VistaTarea> vistas;
  final List<EntregaTarea> entregas;
  final EstadoTarea estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.docente,
    required this.asignatura,
    required this.curso,
    required this.escuelaId,
    required this.estudiantesIds,
    required this.fechaAsignacion,
    required this.fechaLimite,
    required this.tipo,
    required this.prioridad,
    required this.permiteTardias,
    required this.calificacionMaxima,
    this.pesoEvaluacion,
    required this.archivosReferencia,
    required this.vistas,
    required this.entregas,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  // 📄 DESERIALIZACIÓN desde JSON
  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      docente: _parseDocente(json['docenteId']),
      asignatura: _parseAsignatura(json['asignaturaId']),
      curso: _parseCurso(json['cursoId']),
      escuelaId: json['escuelaId'] ?? '',
      estudiantesIds: (json['estudiantesIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fechaAsignacion: DateTime.parse(
          json['fechaAsignacion'] ?? DateTime.now().toIso8601String()),
      fechaLimite: DateTime.parse(
          json['fechaLimite'] ?? DateTime.now().toIso8601String()),
      tipo: TipoTareaExtension.fromString(json['tipo'] ?? 'INDIVIDUAL'),
      prioridad:
          PrioridadTareaExtension.fromString(json['prioridad'] ?? 'MEDIA'),
      permiteTardias: json['permiteTardias'] ?? false,
      calificacionMaxima: (json['calificacionMaxima'] ?? 0).toDouble(),
      pesoEvaluacion: json['pesoEvaluacion']?.toDouble(),
      archivosReferencia: (json['archivosReferencia'] as List<dynamic>?)
              ?.map((a) => ArchivoTarea.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      vistas: (json['vistas'] as List<dynamic>?)
              ?.map((v) => VistaTarea.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      entregas: (json['entregas'] as List<dynamic>?)
              ?.map((e) => EntregaTarea.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estado: EstadoTareaExtension.fromString(json['estado'] ?? 'ACTIVA'),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 🔧 HELPERS: Parsear relaciones (pueden venir como String o Object)
  static DocenteInfo _parseDocente(dynamic docenteData) {
    if (docenteData is String) {
      return DocenteInfo(
        id: docenteData,
        nombre: 'Docente',
        apellidos: '',
        email: '',
      );
    } else if (docenteData is Map<String, dynamic>) {
      return DocenteInfo.fromJson(docenteData);
    } else {
      return DocenteInfo(
        id: '',
        nombre: 'Desconocido',
        apellidos: '',
        email: '',
      );
    }
  }

  static AsignaturaInfo _parseAsignatura(dynamic asignaturaData) {
    if (asignaturaData is String) {
      return AsignaturaInfo(id: asignaturaData, nombre: 'Asignatura');
    } else if (asignaturaData is Map<String, dynamic>) {
      return AsignaturaInfo.fromJson(asignaturaData);
    } else {
      return AsignaturaInfo(id: '', nombre: 'Desconocida');
    }
  }

  static CursoInfo _parseCurso(dynamic cursoData) {
    if (cursoData is String) {
      return CursoInfo(id: cursoData, nombre: 'Curso', nivel: '');
    } else if (cursoData is Map<String, dynamic>) {
      return CursoInfo.fromJson(cursoData);
    } else {
      return CursoInfo(id: '', nombre: 'Desconocido', nivel: '');
    }
  }

  // 📄 SERIALIZACIÓN a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'docenteId': docente.toJson(),
      'asignaturaId': asignatura.toJson(),
      'cursoId': curso.toJson(),
      'escuelaId': escuelaId,
      'estudiantesIds': estudiantesIds,
      'fechaAsignacion': fechaAsignacion.toIso8601String(),
      'fechaLimite': fechaLimite.toIso8601String(),
      'tipo': tipo.value,
      'prioridad': prioridad.value,
      'permiteTardias': permiteTardias,
      'calificacionMaxima': calificacionMaxima,
      'pesoEvaluacion': pesoEvaluacion,
      'archivosReferencia': archivosReferencia.map((a) => a.toJson()).toList(),
      'vistas': vistas.map((v) => v.toJson()).toList(),
      'entregas': entregas.map((e) => e.toJson()).toList(),
      'estado': estado.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 🔧 HELPERS: Getters útiles
  bool get tieneArchivosReferencia => archivosReferencia.isNotEmpty;
  int get cantidadArchivosReferencia => archivosReferencia.length;

  bool get estaVencida => DateTime.now().isAfter(fechaLimite);
  bool get estaActiva => estado == EstadoTarea.activa;
  bool get estaCerrada => estado == EstadoTarea.cerrada;

  Duration get tiempoRestante => fechaLimite.difference(DateTime.now());
  bool get vencePronto =>
      tiempoRestante.inDays <= 2 && tiempoRestante.inDays >= 0;

  String get fechaLimiteFormateada {
    final now = DateTime.now();
    final diff = fechaLimite.difference(now);

    if (diff.isNegative) {
      return 'Vencida';
    } else if (diff.inDays == 0) {
      return 'Hoy a las ${fechaLimite.hour}:${fechaLimite.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Mañana';
    } else if (diff.inDays < 7) {
      return 'En ${diff.inDays} días';
    } else {
      return '${fechaLimite.day}/${fechaLimite.month}/${fechaLimite.year}';
    }
  }

  // 🔧 HELPER: Obtener entrega de un estudiante específico
  EntregaTarea? getEntregaEstudiante(String estudianteId) {
    try {
      return entregas.firstWhere(
        (entrega) => entrega.estudianteId == estudianteId,
      );
    } catch (e) {
      return null;
    }
  }

  // 🔧 HELPER: Estadísticas de entregas
  Map<String, int> get estadisticasEntregas {
    int totalEstudiantes = estudiantesIds.length;
    int pendientes =
        entregas.where((e) => e.estado == EstadoEntrega.pendiente).length;
    int entregadas =
        entregas.where((e) => e.estado == EstadoEntrega.entregada).length;
    int atrasadas =
        entregas.where((e) => e.estado == EstadoEntrega.atrasada).length;
    int calificadas =
        entregas.where((e) => e.estado == EstadoEntrega.calificada).length;

    return {
      'total': totalEstudiantes,
      'pendientes': pendientes,
      'entregadas': entregadas,
      'atrasadas': atrasadas,
      'calificadas': calificadas,
    };
  }

  // 🔧 HELPER: Copiar con cambios
  Tarea copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    DocenteInfo? docente,
    AsignaturaInfo? asignatura,
    CursoInfo? curso,
    String? escuelaId,
    List<String>? estudiantesIds,
    DateTime? fechaAsignacion,
    DateTime? fechaLimite,
    TipoTarea? tipo,
    PrioridadTarea? prioridad,
    bool? permiteTardias,
    double? calificacionMaxima,
    double? pesoEvaluacion,
    List<ArchivoTarea>? archivosReferencia,
    List<VistaTarea>? vistas,
    List<EntregaTarea>? entregas,
    EstadoTarea? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tarea(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      docente: docente ?? this.docente,
      asignatura: asignatura ?? this.asignatura,
      curso: curso ?? this.curso,
      escuelaId: escuelaId ?? this.escuelaId,
      estudiantesIds: estudiantesIds ?? this.estudiantesIds,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      tipo: tipo ?? this.tipo,
      prioridad: prioridad ?? this.prioridad,
      permiteTardias: permiteTardias ?? this.permiteTardias,
      calificacionMaxima: calificacionMaxima ?? this.calificacionMaxima,
      pesoEvaluacion: pesoEvaluacion ?? this.pesoEvaluacion,
      archivosReferencia: archivosReferencia ?? this.archivosReferencia,
      vistas: vistas ?? this.vistas,
      entregas: entregas ?? this.entregas,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ========================================
// 📦 ENTREGA DE TAREA
// ========================================

class EntregaTarea {
  final String? id;
  final String estudianteId;
  final EstudianteInfo? estudiante;
  final DateTime? fechaEntrega;
  final EstadoEntrega estado;
  final List<ArchivoTarea> archivos;
  final String? comentarioEstudiante;
  final double? calificacion;
  final String? comentarioDocente;
  final DateTime? fechaCalificacion;
  final int intentos;

  EntregaTarea({
    this.id,
    required this.estudianteId,
    this.estudiante,
    this.fechaEntrega,
    required this.estado,
    required this.archivos,
    this.comentarioEstudiante,
    this.calificacion,
    this.comentarioDocente,
    this.fechaCalificacion,
    required this.intentos,
  });

  factory EntregaTarea.fromJson(Map<String, dynamic> json) {
    return EntregaTarea(
      id: json['_id'],
      estudianteId: _parseEstudianteId(json['estudianteId']),
      estudiante: _parseEstudiante(json['estudianteId']),
      fechaEntrega: json['fechaEntrega'] != null
          ? DateTime.parse(json['fechaEntrega'])
          : null,
      estado: EstadoEntregaExtension.fromString(json['estado'] ?? 'PENDIENTE'),
      archivos: (json['archivos'] as List<dynamic>?)
              ?.map((a) => ArchivoTarea.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      comentarioEstudiante: json['comentarioEstudiante'],
      calificacion: json['calificacion']?.toDouble(),
      comentarioDocente: json['comentarioDocente'],
      fechaCalificacion: json['fechaCalificacion'] != null
          ? DateTime.parse(json['fechaCalificacion'])
          : null,
      intentos: json['intentos'] ?? 0,
    );
  }

  static String _parseEstudianteId(dynamic data) {
    if (data is String) return data;
    if (data is Map<String, dynamic>) return data['_id'] ?? '';
    return '';
  }

  static EstudianteInfo? _parseEstudiante(dynamic data) {
    if (data is Map<String, dynamic>) {
      return EstudianteInfo.fromJson(data);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'estudianteId': estudianteId,
      'fechaEntrega': fechaEntrega?.toIso8601String(),
      'estado': estado.value,
      'archivos': archivos.map((a) => a.toJson()).toList(),
      'comentarioEstudiante': comentarioEstudiante,
      'calificacion': calificacion,
      'comentarioDocente': comentarioDocente,
      'fechaCalificacion': fechaCalificacion?.toIso8601String(),
      'intentos': intentos,
    };
  }

  bool get fueEntregada => fechaEntrega != null;
  bool get estaCalificada => estado == EstadoEntrega.calificada;
  bool get tieneArchivos => archivos.isNotEmpty;
  bool get estaAtrasada => estado == EstadoEntrega.atrasada;
}

// ========================================
// 📎 ARCHIVO DE TAREA
// ========================================

class ArchivoTarea {
  final String fileId;
  final String nombre;
  final String tipo;
  final int tamano;
  final DateTime fechaSubida;

  ArchivoTarea({
    required this.fileId,
    required this.nombre,
    required this.tipo,
    required this.tamano,
    required this.fechaSubida,
  });

  factory ArchivoTarea.fromJson(Map<String, dynamic> json) {
    return ArchivoTarea(
      fileId: json['fileId'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      tamano: json['tamaño'] ?? json['tamano'] ?? 0,
      fechaSubida: DateTime.parse(
          json['fechaSubida'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'nombre': nombre,
      'tipo': tipo,
      'tamano': tamano,
      'fechaSubida': fechaSubida.toIso8601String(),
    };
  }

  String get extension => nombre.split('.').last.toLowerCase();

  bool get isImage =>
      tipo.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);

  bool get isPdf => tipo == 'application/pdf' || extension == 'pdf';

  bool get isWord =>
      tipo.contains('word') || ['doc', 'docx'].contains(extension);

  bool get isExcel =>
      tipo.contains('excel') ||
      tipo.contains('spreadsheet') ||
      ['xls', 'xlsx'].contains(extension);

  String get formattedSize {
    if (tamano < 1024) return '$tamano B';
    if (tamano < 1024 * 1024) {
      return '${(tamano / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get icon {
    if (isImage) return '🖼️';
    if (isPdf) return '📄';
    if (isWord) return '📝';
    if (isExcel) return '📊';
    return '📎';
  }
}

// ========================================
// 👁️ VISTA DE TAREA
// ========================================

class VistaTarea {
  final String estudianteId;
  final DateTime fechaVista;

  VistaTarea({
    required this.estudianteId,
    required this.fechaVista,
  });

  factory VistaTarea.fromJson(Map<String, dynamic> json) {
    return VistaTarea(
      estudianteId: json['estudianteId'] ?? '',
      fechaVista: DateTime.parse(
          json['fechaVista'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estudianteId': estudianteId,
      'fechaVista': fechaVista.toIso8601String(),
    };
  }
}

// ========================================
// 👤 MODELOS DE INFORMACIÓN (relaciones)
// ========================================

class DocenteInfo {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;

  DocenteInfo({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
  });

  factory DocenteInfo.fromJson(Map<String, dynamic> json) {
    return DocenteInfo(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
    };
  }

  String get nombreCompleto => '$nombre $apellidos';
  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final a = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$n$a';
  }
}

class EstudianteInfo {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;

  EstudianteInfo({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
  });

  factory EstudianteInfo.fromJson(Map<String, dynamic> json) {
    return EstudianteInfo(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
    };
  }

  String get nombreCompleto => '$nombre $apellidos';
  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final a = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$n$a';
  }
}

class AsignaturaInfo {
  final String id;
  final String nombre;

  AsignaturaInfo({
    required this.id,
    required this.nombre,
  });

  factory AsignaturaInfo.fromJson(Map<String, dynamic> json) {
    return AsignaturaInfo(
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

class CursoInfo {
  final String id;
  final String nombre;
  final String nivel;

  CursoInfo({
    required this.id,
    required this.nombre,
    required this.nivel,
  });

  factory CursoInfo.fromJson(Map<String, dynamic> json) {
    return CursoInfo(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      nivel: json['nivel'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'nivel': nivel,
    };
  }

  String get nombreCompleto => '$nivel - $nombre';
}

// ========================================
// 🏷️ FILTROS PARA ESTUDIANTES
// ========================================

enum FiltroTareaEstudiante {
  todas,
  pendientes,
  entregadas,
  calificadas,
}

extension FiltroTareaEstudianteExtension on FiltroTareaEstudiante {
  String get displayName {
    switch (this) {
      case FiltroTareaEstudiante.todas:
        return 'Todas';
      case FiltroTareaEstudiante.pendientes:
        return 'Pendientes';
      case FiltroTareaEstudiante.entregadas:
        return 'Entregadas';
      case FiltroTareaEstudiante.calificadas:
        return 'Calificadas';
    }
  }

  String get value {
    switch (this) {
      case FiltroTareaEstudiante.todas:
        return 'todas';
      case FiltroTareaEstudiante.pendientes:
        return 'pendientes';
      case FiltroTareaEstudiante.entregadas:
        return 'entregadas';
      case FiltroTareaEstudiante.calificadas:
        return 'calificadas';
    }
  }

  String get icon {
    switch (this) {
      case FiltroTareaEstudiante.todas:
        return '📚';
      case FiltroTareaEstudiante.pendientes:
        return '⏳';
      case FiltroTareaEstudiante.entregadas:
        return '✅';
      case FiltroTareaEstudiante.calificadas:
        return '⭐';
    }
  }
}
