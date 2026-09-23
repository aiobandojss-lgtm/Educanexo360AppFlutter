// lib/models/message.dart

/// 📨 MODELO DE MENSAJE COMPLETO
/// Soporta: Individual, Grupal, Borradores, Adjuntos, Prioridades
class Message {
  final String id;
  final User remitente;
  final List<User> destinatarios;
  final String asunto;
  final String contenido;
  final List<Adjunto>? adjuntos;
  final List<Lectura>? lecturas;
  final TipoMensaje tipo;
  final String estado;
  final Prioridad prioridad;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? fechaEnvio;
  final bool? archivado;
  final bool? eliminado;

  Message({
    required this.id,
    required this.remitente,
    required this.destinatarios,
    required this.asunto,
    required this.contenido,
    this.adjuntos,
    this.lecturas,
    required this.tipo,
    required this.estado,
    required this.prioridad,
    required this.createdAt,
    required this.updatedAt,
    this.fechaEnvio,
    this.archivado,
    this.eliminado,
  });

  // 🔄 DESERIALIZACIÓN desde JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      remitente: _parseRemitente(json['remitente']),
      destinatarios: (json['destinatarios'] as List?)?.map((d) {
            // Si es String (solo ID), crear User parcial
            if (d is String) {
              return User(
                id: d,
                nombre: 'Usuario',
                apellidos: '',
                email: '',
                tipo: 'ESTUDIANTE', // ✅ String, no enum
              );
            }
            // Si es Map (objeto completo), parsear normalmente
            return User.fromJson(d as Map<String, dynamic>);
          }).toList() ??
          [],
      asunto: json['asunto'] ?? '',
      contenido: json['contenido'] ?? '',
      adjuntos: (json['adjuntos'] as List<dynamic>?)
          ?.map((adj) => Adjunto.fromJson(adj as Map<String, dynamic>))
          .toList(),
      lecturas: (json['lecturas'] as List<dynamic>?)
          ?.map((lec) => Lectura.fromJson(lec as Map<String, dynamic>))
          .toList(),
      tipo: _tipoFromString(json['tipo'] as String?),
      estado: json['estado'] ?? 'ENVIADO',
      prioridad: _prioridadFromString(json['prioridad'] as String?),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      fechaEnvio: json['fechaEnvio'] != null
          ? DateTime.parse(json['fechaEnvio'])
          : null,
      archivado: json['archivado'] as bool?,
      eliminado: json['eliminado'] as bool?,
    );
  }

  // remitente puede llegar como objeto (populate), como String (solo id) o null
  static User _parseRemitente(dynamic data) {
    if (data is Map<String, dynamic>) return User.fromJson(data);
    return User(
      id: data is String ? data : '',
      nombre: 'Usuario',
      apellidos: '',
      email: '',
      tipo: '',
    );
  }

  // 🔄 SERIALIZACIÓN a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'remitente': remitente.toJson(),
      'destinatarios': destinatarios.map((d) => d.toJson()).toList(),
      'asunto': asunto,
      'contenido': contenido,
      'adjuntos': adjuntos?.map((a) => a.toJson()).toList(),
      'lecturas': lecturas?.map((l) => l.toJson()).toList(),
      'tipo': tipo.name.toUpperCase(),
      'estado': estado,
      'prioridad': prioridad.name.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fechaEnvio': fechaEnvio?.toIso8601String(),
      'archivado': archivado,
      'eliminado': eliminado,
    };
  }

  // 🔧 HELPER: ¿Está leído por el usuario?
  bool isReadByUser(String userId) {
    if (lecturas == null) return false;
    return lecturas!.any((lectura) => lectura.usuarioId == userId);
  }

  // 🔧 HELPER: ¿Tiene adjuntos?
  bool get hasAttachments => adjuntos != null && adjuntos!.isNotEmpty;

  // 🔧 HELPER: Cantidad de adjuntos
  int get attachmentCount => adjuntos?.length ?? 0;

  // 🔧 HELPER: ¿Es borrador?
  bool get isDraft => tipo == TipoMensaje.borrador;

  // 🔧 HELPER: Copiar con cambios
  Message copyWith({
    String? id,
    User? remitente,
    List<User>? destinatarios,
    String? asunto,
    String? contenido,
    List<Adjunto>? adjuntos,
    List<Lectura>? lecturas,
    TipoMensaje? tipo,
    String? estado,
    Prioridad? prioridad,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? fechaEnvio,
    bool? archivado,
    bool? eliminado,
  }) {
    return Message(
      id: id ?? this.id,
      remitente: remitente ?? this.remitente,
      destinatarios: destinatarios ?? this.destinatarios,
      asunto: asunto ?? this.asunto,
      contenido: contenido ?? this.contenido,
      adjuntos: adjuntos ?? this.adjuntos,
      lecturas: lecturas ?? this.lecturas,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      archivado: archivado ?? this.archivado,
      eliminado: eliminado ?? this.eliminado,
    );
  }

  // 🔧 CONVERTIR STRING A TIPO
  static TipoMensaje _tipoFromString(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'INDIVIDUAL':
        return TipoMensaje.individual;
      case 'GRUPAL':
        return TipoMensaje.grupal;
      case 'BORRADOR':
        return TipoMensaje.borrador;
      default:
        return TipoMensaje.individual;
    }
  }

  // 🔧 CONVERTIR STRING A PRIORIDAD
  static Prioridad _prioridadFromString(String? prioridad) {
    switch (prioridad?.toUpperCase()) {
      case 'ALTA':
        return Prioridad.alta;
      case 'BAJA':
        return Prioridad.baja;
      case 'NORMAL':
      default:
        return Prioridad.normal;
    }
  }
}

// 📎 MODELO DE ADJUNTO
class Adjunto {
  final String fileId;
  final String nombre;
  final String tipo;
  final int tamano;
  final DateTime fechaSubida;

  Adjunto({
    required this.fileId,
    required this.nombre,
    required this.tipo,
    required this.tamano,
    required this.fechaSubida,
  });

  factory Adjunto.fromJson(Map<String, dynamic> json) {
    return Adjunto(
      fileId: json['fileId'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      tamano: json['tamano'] ?? json['tamaño'] ?? 0,
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

  // 🔧 HELPER: Obtener extensión
  String get extension {
    return nombre.split('.').last.toLowerCase();
  }

  // 🔧 HELPER: ¿Es imagen?
  bool get isImage {
    return tipo.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  // 🔧 HELPER: ¿Es PDF?
  bool get isPdf {
    return tipo == 'application/pdf' || extension == 'pdf';
  }

  // 🔧 HELPER: Formatear tamano
  String get formattedSize {
    if (tamano < 1024) return '$tamano B';
    if (tamano < 1024 * 1024) return '${(tamano / 1024).toStringAsFixed(1)} KB';
    return '${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // 🔧 HELPER: Icono segun tipo
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

// 👁️ MODELO DE LECTURA
class Lectura {
  final String usuarioId;
  final DateTime fechaLectura;

  Lectura({
    required this.usuarioId,
    required this.fechaLectura,
  });

  factory Lectura.fromJson(Map<String, dynamic> json) {
    return Lectura(
      usuarioId: json['usuarioId'] ?? '',
      fechaLectura: DateTime.parse(
          json['fechaLectura'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'fechaLectura': fechaLectura.toIso8601String(),
    };
  }
}

// 👤 MODELO DE USUARIO (simplificado para mensajes)
class User {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;
  final String tipo;
  final String? asignatura;
  final String? curso;
  final String? infoContextual;

  User({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.tipo,
    this.asignatura,
    this.curso,
    this.infoContextual,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? '',
      tipo: json['tipo'] ?? '',
      asignatura: json['asignatura'] as String?,
      curso: json['curso'] as String?,
      infoContextual: json['infoContextual'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'tipo': tipo,
      'asignatura': asignatura,
      'curso': curso,
      'infoContextual': infoContextual,
    };
  }

  // 🔧 HELPER: Nombre completo
  String get fullName => '$nombre $apellidos';

  // 🔧 HELPER: Iniciales
  String get initials {
    final firstInitial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final lastInitial = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  // 🔧 HELPER: Color según tipo
  int get avatarColor {
    switch (tipo.toUpperCase()) {
      case 'ADMIN':
        return 0xFF0F766E; // Teal-700
      case 'DOCENTE':
        return 0xFF2563EB; // Azul
      case 'ESTUDIANTE':
        return 0xFF059669; // Verde
      case 'ACUDIENTE':
        return 0xFFDC2626; // Rojo
      case 'RECTOR':
        return 0xFFD97706; // Naranja
      case 'COORDINADOR':
        return 0xFF0891B2; // Cyan
      default:
        return 0xFF64748B; // Gris
    }
  }

  // 🔧 HELPER: Emoji según tipo
  String get emoji {
    switch (tipo.toUpperCase()) {
      case 'DOCENTE':
        return '👩‍🏫';
      case 'ESTUDIANTE':
        return '🎓';
      case 'ACUDIENTE':
        return '👨‍👩‍👧‍👦';
      case 'ADMIN':
        return '⚙️';
      case 'RECTOR':
        return '👑';
      case 'COORDINADOR':
        return '📋';
      default:
        return '👤';
    }
  }
}

// 📋 MODELO DE CURSO (para envío masivo)
class Course {
  final String id;
  final String nombre;
  final int cantidadEstudiantes;
  final String grado;
  final String seccion;

  Course({
    required this.id,
    required this.nombre,
    required this.cantidadEstudiantes,
    required this.grado,
    required this.seccion,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      cantidadEstudiantes: json['cantidadEstudiantes'] ?? 0,
      grado: json['grado'] ?? '',
      seccion: json['seccion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'cantidadEstudiantes': cantidadEstudiantes,
      'grado': grado,
      'seccion': seccion,
    };
  }

  // 🔧 HELPER: Descripción completa
  String get fullDescription => '$nombre ($cantidadEstudiantes estudiantes)';
}

// 🏷️ ENUMS
enum TipoMensaje {
  individual,
  grupal,
  borrador,
}

enum Prioridad {
  alta,
  normal,
  baja,
}

enum Bandeja {
  recibidos,
  enviados,
  borradores,
  archivados,
  eliminados,
}

// 🔧 EXTENSION PARA BANDEJA
extension BandejaExtension on Bandeja {
  String get displayName {
    switch (this) {
      case Bandeja.recibidos:
        return 'Recibidos';
      case Bandeja.enviados:
        return 'Enviados';
      case Bandeja.borradores:
        return 'Borradores';
      case Bandeja.archivados:
        return 'Archivados';
      case Bandeja.eliminados:
        return 'Eliminados';
    }
  }

  String get icon {
    switch (this) {
      case Bandeja.recibidos:
        return '📬';
      case Bandeja.enviados:
        return '📤';
      case Bandeja.borradores:
        return '📝';
      case Bandeja.archivados:
        return '🗂️';
      case Bandeja.eliminados:
        return '🗑️';
    }
  }

  String get emptyMessage {
    switch (this) {
      case Bandeja.recibidos:
        return 'No tienes mensajes';
      case Bandeja.enviados:
        return 'No has enviado mensajes';
      case Bandeja.borradores:
        return 'No tienes borradores';
      case Bandeja.archivados:
        return 'No hay mensajes archivados';
      case Bandeja.eliminados:
        return 'No hay mensajes eliminados';
    }
  }

  String get emptySubtitle {
    switch (this) {
      case Bandeja.recibidos:
        return 'Los nuevos mensajes aparecerán aquí';
      case Bandeja.enviados:
        return 'Toca ✏️ para enviar tu primer mensaje';
      case Bandeja.borradores:
        return 'Los borradores guardados aparecerán aquí';
      case Bandeja.archivados:
      case Bandeja.eliminados:
        return 'Cuando tengas elementos aquí aparecerán en esta lista';
    }
  }
}

// 🔧 EXTENSION PARA PRIORIDAD
extension PrioridadExtension on Prioridad {
  String get displayName {
    switch (this) {
      case Prioridad.alta:
        return 'Alta';
      case Prioridad.normal:
        return 'Normal';
      case Prioridad.baja:
        return 'Baja';
    }
  }

  String get icon {
    switch (this) {
      case Prioridad.alta:
        return '🔴';
      case Prioridad.normal:
        return '🟡';
      case Prioridad.baja:
        return '🟢';
    }
  }

  int get color {
    switch (this) {
      case Prioridad.alta:
        return 0xFFEF4444; // Rojo
      case Prioridad.normal:
        return 0xFFF59E0B; // Amarillo
      case Prioridad.baja:
        return 0xFF10B981; // Verde
    }
  }
}
