// lib/models/evento.dart

/// 📅 TIPOS DE EVENTO
enum EventType {
  academico('ACADEMICO'),
  institucional('INSTITUCIONAL'),
  cultural('CULTURAL'),
  deportivo('DEPORTIVO'),
  otro('OTRO');

  final String value;
  const EventType(this.value);

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => EventType.otro,
    );
  }
}

/// 📊 ESTADOS DE EVENTO
enum EventStatus {
  pendiente('PENDIENTE'),
  activo('ACTIVO'),
  finalizado('FINALIZADO'),
  cancelado('CANCELADO');

  final String value;
  const EventStatus(this.value);

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => EventStatus.activo,
    );
  }
}

// 📎 MODELO DE ARCHIVO ADJUNTO
class ArchivoAdjuntoEvento {
  final String fileId;
  final String nombre;
  final String tipo;
  final int tamano;

  ArchivoAdjuntoEvento({
    required this.fileId,
    required this.nombre,
    required this.tipo,
    required this.tamano,
  });

  factory ArchivoAdjuntoEvento.fromJson(Map<String, dynamic> json) {
    return ArchivoAdjuntoEvento(
      fileId: json['fileId'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      tamano: json['tamano'] ?? json['tamaño'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'nombre': nombre,
      'tipo': tipo,
      'tamano': tamano,
    };
  }

  // 🔧 HELPERS
  String get extension => nombre.split('.').last.toLowerCase();

  bool get isImage =>
      tipo.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);

  bool get isPdf => tipo == 'application/pdf' || extension == 'pdf';

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
    if (tipo.contains('word')) return '📝';
    if (tipo.contains('excel') || tipo.contains('spreadsheet')) return '📊';
    if (tipo.contains('powerpoint') || tipo.contains('presentation')) {
      return '📊';
    }
    return '📎';
  }
}

// 👥 MODELO DE INVITADO
class InvitadoEvento {
  final String usuarioId;
  final bool confirmado;
  final DateTime? fechaConfirmacion;

  InvitadoEvento({
    required this.usuarioId,
    required this.confirmado,
    this.fechaConfirmacion,
  });

  factory InvitadoEvento.fromJson(Map<String, dynamic> json) {
    return InvitadoEvento(
      usuarioId: json['usuarioId'] ?? '',
      confirmado: json['confirmado'] ?? false,
      fechaConfirmacion: json['fechaConfirmacion'] != null
          ? DateTime.parse(json['fechaConfirmacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'confirmado': confirmado,
      if (fechaConfirmacion != null)
        'fechaConfirmacion': fechaConfirmacion!.toIso8601String(),
    };
  }
}

// 👤 MODELO DE USUARIO (simplificado para eventos)
class User {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;
  final String tipo;

  User({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.tipo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? '',
      tipo: json['tipo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'tipo': tipo,
    };
  }

  String get fullName => '$nombre $apellidos';

  String get initials {
    final firstInitial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final lastInitial = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }
}

// 📅 MODELO PRINCIPAL DE EVENTO
class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool todoElDia;
  final String? lugar;
  final EventType tipo;
  final EventStatus estado;
  final String? color;
  final User creador;
  final String? cursoId;
  final String escuelaId;
  final ArchivoAdjuntoEvento? archivoAdjunto;
  final List<InvitadoEvento> invitados;
  final DateTime createdAt;
  final DateTime updatedAt;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.todoElDia,
    this.lugar,
    required this.tipo,
    required this.estado,
    this.color,
    required this.creador,
    this.cursoId,
    required this.escuelaId,
    this.archivoAdjunto,
    required this.invitados,
    required this.createdAt,
    required this.updatedAt,
  });

  // 📄 DESERIALIZACIÓN desde JSON
  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio: DateTime.parse(
          json['fechaInicio'] ?? DateTime.now().toIso8601String()),
      fechaFin:
          DateTime.parse(json['fechaFin'] ?? DateTime.now().toIso8601String()),
      todoElDia: json['todoElDia'] ?? false,
      lugar: json['lugar'],
      tipo: EventType.fromString(json['tipo'] ?? 'OTRO'),
      estado: EventStatus.fromString(json['estado'] ?? 'ACTIVO'),
      color: json['color'],
      creador: _parseCreador(json['creador']),
      cursoId: json['cursoId'],
      escuelaId: json['escuelaId'] ?? '',
      archivoAdjunto: json['archivoAdjunto'] != null
          ? ArchivoAdjuntoEvento.fromJson(
              json['archivoAdjunto'] as Map<String, dynamic>)
          : null,
      invitados: (json['invitados'] as List<dynamic>?)
              ?.map(
                  (inv) => InvitadoEvento.fromJson(inv as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 🔧 HELPER: Parsear creador (puede venir como ID o como objeto)
  static User _parseCreador(dynamic creadorData) {
    if (creadorData == null) {
      return User(
        id: '',
        nombre: 'Desconocido',
        apellidos: '',
        email: '',
        tipo: '',
      );
    }

    if (creadorData is String) {
      return User(
        id: creadorData,
        nombre: 'Usuario',
        apellidos: '',
        email: '',
        tipo: '',
      );
    }

    return User.fromJson(creadorData as Map<String, dynamic>);
  }

  // 📄 SERIALIZACIÓN a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'todoElDia': todoElDia,
      if (lugar != null) 'lugar': lugar,
      'tipo': tipo.value,
      'estado': estado.value,
      if (color != null) 'color': color,
      'creador': creador.toJson(),
      if (cursoId != null) 'cursoId': cursoId,
      'escuelaId': escuelaId,
      if (archivoAdjunto != null) 'archivoAdjunto': archivoAdjunto!.toJson(),
      'invitados': invitados.map((inv) => inv.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 🔧 HELPER: Duración del evento
  Duration get duracion => fechaFin.difference(fechaInicio);

  // 🔧 HELPER: Está activo
  bool get estaActivo => estado == EventStatus.activo;

  // 🔧 HELPER: Está cancelado
  bool get estaCancelado => estado == EventStatus.cancelado;

  // 🔧 HELPER: Ya finalizó
  bool get yaFinalizo => DateTime.now().isAfter(fechaFin);

  // 🔧 HELPER: Cantidad de invitados confirmados
  int get confirmadosCount => invitados.where((inv) => inv.confirmado).length;

  // 🔧 COPYWITH para crear copias inmutables
  Evento copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? todoElDia,
    String? lugar,
    EventType? tipo,
    EventStatus? estado,
    String? color,
    User? creador,
    String? cursoId,
    String? escuelaId,
    ArchivoAdjuntoEvento? archivoAdjunto,
    List<InvitadoEvento>? invitados,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      todoElDia: todoElDia ?? this.todoElDia,
      lugar: lugar ?? this.lugar,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      color: color ?? this.color,
      creador: creador ?? this.creador,
      cursoId: cursoId ?? this.cursoId,
      escuelaId: escuelaId ?? this.escuelaId,
      archivoAdjunto: archivoAdjunto ?? this.archivoAdjunto,
      invitados: invitados ?? this.invitados,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 🔧 EXTENSION PARA EVENT TYPE
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.academico:
        return 'Académico';
      case EventType.institucional:
        return 'Institucional';
      case EventType.cultural:
        return 'Cultural';
      case EventType.deportivo:
        return 'Deportivo';
      case EventType.otro:
        return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case EventType.academico:
        return '📚';
      case EventType.institucional:
        return '🏛️';
      case EventType.cultural:
        return '🎭';
      case EventType.deportivo:
        return '⚽';
      case EventType.otro:
        return '📅';
    }
  }

  String get colorHex {
    switch (this) {
      case EventType.academico:
        return '#8b5cf6'; // Morado
      case EventType.institucional:
        return '#f59e0b'; // Naranja
      case EventType.cultural:
        return '#ec4899'; // Rosa
      case EventType.deportivo:
        return '#10b981'; // Verde
      case EventType.otro:
        return '#6b7280'; // Gris
    }
  }
}

// 🔧 EXTENSION PARA EVENT STATUS
extension EventStatusExtension on EventStatus {
  String get displayName {
    switch (this) {
      case EventStatus.pendiente:
        return 'Pendiente';
      case EventStatus.activo:
        return 'Activo';
      case EventStatus.finalizado:
        return 'Finalizado';
      case EventStatus.cancelado:
        return 'Cancelado';
    }
  }

  String get colorHex {
    switch (this) {
      case EventStatus.pendiente:
        return '#f59e0b'; // Naranja
      case EventStatus.activo:
        return '#10b981'; // Verde
      case EventStatus.finalizado:
        return '#6b7280'; // Gris
      case EventStatus.cancelado:
        return '#ef4444'; // Rojo
    }
  }
}
