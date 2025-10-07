// lib/models/anuncio.dart

/// 📢 MODELO DE ANUNCIO COMPLETO
/// Basado en la estructura de React Native y backend
class Anuncio {
  final String id;
  final String titulo;
  final String contenido;
  final User creador;
  final String escuelaId;
  final bool paraEstudiantes;
  final bool paraDocentes;
  final bool paraPadres;
  final bool destacado;
  final bool estaPublicado;
  final DateTime? fechaPublicacion;
  final List<ArchivoAdjunto> archivosAdjuntos;
  final ImagenPortada? imagenPortada;
  final List<Lectura> lecturas;
  final DateTime createdAt;
  final DateTime updatedAt;

  Anuncio({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.creador,
    required this.escuelaId,
    required this.paraEstudiantes,
    required this.paraDocentes,
    required this.paraPadres,
    required this.destacado,
    required this.estaPublicado,
    this.fechaPublicacion,
    required this.archivosAdjuntos,
    this.imagenPortada,
    required this.lecturas,
    required this.createdAt,
    required this.updatedAt,
  });

  // 📄 DESERIALIZACIÓN desde JSON
  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      creador: _parseCreador(json['creador']),
      escuelaId: json['escuelaId'] ?? '',
      paraEstudiantes: json['paraEstudiantes'] ?? false,
      paraDocentes: json['paraDocentes'] ?? false,
      paraPadres: json['paraPadres'] ?? false,
      destacado: json['destacado'] ?? false,
      estaPublicado: json['estaPublicado'] ?? false,
      fechaPublicacion: json['fechaPublicacion'] != null
          ? DateTime.parse(json['fechaPublicacion'])
          : null,
      archivosAdjuntos: (json['archivosAdjuntos'] as List<dynamic>?)
              ?.map(
                  (adj) => ArchivoAdjunto.fromJson(adj as Map<String, dynamic>))
              .toList() ??
          [],
      imagenPortada: json['imagenPortada'] != null
          ? ImagenPortada.fromJson(
              json['imagenPortada'] as Map<String, dynamic>)
          : null,
      lecturas: (json['lecturas'] as List<dynamic>?)
              ?.map((lec) => Lectura.fromJson(lec as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 🔧 HELPER: Parsear creador (puede venir como String o Object)
  static User _parseCreador(dynamic creadorData) {
    if (creadorData is String) {
      return User(
        id: creadorData,
        nombre: 'Usuario',
        apellidos: '',
        email: '',
        tipo: 'ADMIN',
      );
    } else if (creadorData is Map<String, dynamic>) {
      return User.fromJson(creadorData);
    } else {
      return User(
        id: '',
        nombre: 'Desconocido',
        apellidos: '',
        email: '',
        tipo: 'ADMIN',
      );
    }
  }

  // 📄 SERIALIZACIÓN a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'contenido': contenido,
      'creador': creador.toJson(),
      'escuelaId': escuelaId,
      'paraEstudiantes': paraEstudiantes,
      'paraDocentes': paraDocentes,
      'paraPadres': paraPadres,
      'destacado': destacado,
      'estaPublicado': estaPublicado,
      'fechaPublicacion': fechaPublicacion?.toIso8601String(),
      'archivosAdjuntos': archivosAdjuntos.map((a) => a.toJson()).toList(),
      'imagenPortada': imagenPortada?.toJson(),
      'lecturas': lecturas.map((l) => l.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 🔧 HELPER: ¿Tiene adjuntos?
  bool get hasAttachments => archivosAdjuntos.isNotEmpty;

  // 🔧 HELPER: ¿Tiene imagen de portada?
  bool get hasImage => imagenPortada != null;

  // 🔧 HELPER: Cantidad de adjuntos
  int get attachmentCount => archivosAdjuntos.length;

  // 🔧 HELPER: ¿Es borrador?
  bool get isDraft => !estaPublicado;

  // 🔧 HELPER: Texto de audiencia
  String get audienceText {
    final audiences = <String>[];
    if (paraEstudiantes) audiences.add('Estudiantes');
    if (paraDocentes) audiences.add('Docentes');
    if (paraPadres) audiences.add('Padres');
    return audiences.isEmpty ? 'General' : audiences.join(', ');
  }

  // 🔧 HELPER: Icono según audiencia
  String get audienceIcon {
    if (paraEstudiantes && paraDocentes && paraPadres) return '📢';
    if (paraPadres) return '👨‍👩‍👧‍👦';
    if (paraEstudiantes) return '🎓';
    if (paraDocentes) return '👩‍🏫';
    return '📋';
  }

  // 🔧 HELPER: Color según audiencia
  int get audienceColor {
    if (paraEstudiantes && paraDocentes && paraPadres) return 0xFF2563EB;
    if (paraPadres) return 0xFFF59E0B;
    if (paraEstudiantes) return 0xFF10B981;
    if (paraDocentes) return 0xFF7C3AED;
    return 0xFF64748B;
  }

  // 🔧 HELPER: ¿Está leído por el usuario?
  bool isReadByUser(String userId) {
    return lecturas.any((lectura) => lectura.usuarioId == userId);
  }

  // 🔧 HELPER: Copiar con cambios
  Anuncio copyWith({
    String? id,
    String? titulo,
    String? contenido,
    User? creador,
    String? escuelaId,
    bool? paraEstudiantes,
    bool? paraDocentes,
    bool? paraPadres,
    bool? destacado,
    bool? estaPublicado,
    DateTime? fechaPublicacion,
    List<ArchivoAdjunto>? archivosAdjuntos,
    ImagenPortada? imagenPortada,
    List<Lectura>? lecturas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Anuncio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      creador: creador ?? this.creador,
      escuelaId: escuelaId ?? this.escuelaId,
      paraEstudiantes: paraEstudiantes ?? this.paraEstudiantes,
      paraDocentes: paraDocentes ?? this.paraDocentes,
      paraPadres: paraPadres ?? this.paraPadres,
      destacado: destacado ?? this.destacado,
      estaPublicado: estaPublicado ?? this.estaPublicado,
      fechaPublicacion: fechaPublicacion ?? this.fechaPublicacion,
      archivosAdjuntos: archivosAdjuntos ?? this.archivosAdjuntos,
      imagenPortada: imagenPortada ?? this.imagenPortada,
      lecturas: lecturas ?? this.lecturas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 📎 MODELO DE ARCHIVO ADJUNTO
class ArchivoAdjunto {
  final String fileId;
  final String nombre;
  final String tipo;
  final int tamano;

  ArchivoAdjunto({
    required this.fileId,
    required this.nombre,
    required this.tipo,
    required this.tamano,
  });

  factory ArchivoAdjunto.fromJson(Map<String, dynamic> json) {
    return ArchivoAdjunto(
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

  // 🔧 HELPER: Obtener extensión
  String get extension => nombre.split('.').last.toLowerCase();

  // 🔧 HELPER: ¿Es imagen?
  bool get isImage =>
      tipo.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);

  // 🔧 HELPER: ¿Es PDF?
  bool get isPdf => tipo == 'application/pdf' || extension == 'pdf';

  // 🔧 HELPER: Formatear tamaño
  String get formattedSize {
    if (tamano < 1024) return '$tamano B';
    if (tamano < 1024 * 1024) {
      return '${(tamano / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // 🔧 HELPER: Icono según tipo
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

// 🖼️ MODELO DE IMAGEN PORTADA
class ImagenPortada {
  final String fileId;
  final String url;

  ImagenPortada({
    required this.fileId,
    required this.url,
  });

  factory ImagenPortada.fromJson(Map<String, dynamic> json) {
    return ImagenPortada(
      fileId: json['fileId'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'url': url,
    };
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

// 👤 MODELO DE USUARIO (reutilizado de message.dart)
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
      id: json['_id'] ?? '',
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

// 🏷️ ENUMS Y FILTROS
enum FiltroAnuncio {
  todos,
  destacados,
  estudiantes,
  docentes,
  padres,
  borradores,
}

// 🔧 EXTENSION PARA FILTROS
extension FiltroAnuncioExtension on FiltroAnuncio {
  String get displayName {
    switch (this) {
      case FiltroAnuncio.todos:
        return 'Todos';
      case FiltroAnuncio.destacados:
        return 'Destacados';
      case FiltroAnuncio.estudiantes:
        return 'Estudiantes';
      case FiltroAnuncio.docentes:
        return 'Docentes';
      case FiltroAnuncio.padres:
        return 'Padres';
      case FiltroAnuncio.borradores:
        return 'Borradores';
    }
  }

  String get icon {
    switch (this) {
      case FiltroAnuncio.todos:
        return '📋';
      case FiltroAnuncio.destacados:
        return '⭐';
      case FiltroAnuncio.estudiantes:
        return '🎓';
      case FiltroAnuncio.docentes:
        return '👩‍🏫';
      case FiltroAnuncio.padres:
        return '👨‍👩‍👧‍👦';
      case FiltroAnuncio.borradores:
        return '📝';
    }
  }
}
