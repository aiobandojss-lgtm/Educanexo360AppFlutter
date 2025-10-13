// lib/models/usuario.dart

/// Tipos de usuario en el sistema
/// Traducido desde src/types/entities/user.ts
enum UserRole {
  superAdmin('SUPER_ADMIN'),
  admin('ADMIN'),
  rector('RECTOR'),
  coordinador('COORDINADOR'),
  administrativo('ADMINISTRATIVO'),
  docente('DOCENTE'),
  estudiante('ESTUDIANTE'),
  acudiente('ACUDIENTE');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.estudiante,
    );
  }
}

/// Estados del usuario
enum UserStatus {
  activo('ACTIVO'),
  inactivo('INACTIVO'),
  pendiente('PENDIENTE');

  final String value;
  const UserStatus(this.value);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserStatus.pendiente,
    );
  }
}

/// Información académica específica por rol
class AcademicInfo {
  final String? grado;
  final String? docentePrincipal;
  final List<String>? cursos;
  final List<String>? estudiantesAsociados;
  final List<String>? asignaturas;

  AcademicInfo({
    this.grado,
    this.docentePrincipal,
    this.cursos,
    this.estudiantesAsociados,
    this.asignaturas,
  });

  factory AcademicInfo.fromJson(Map<String, dynamic> json) {
    return AcademicInfo(
      grado: json['grado'],
      docentePrincipal: json['docente_principal'],
      cursos: json['cursos'] != null ? List<String>.from(json['cursos']) : null,
      estudiantesAsociados: json['estudiantes_asociados'] != null
          ? List<String>.from(json['estudiantes_asociados'])
          : null,
      asignaturas: json['asignaturas'] != null
          ? List<String>.from(json['asignaturas'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (grado != null) 'grado': grado,
      if (docentePrincipal != null) 'docente_principal': docentePrincipal,
      if (cursos != null) 'cursos': cursos,
      if (estudiantesAsociados != null)
        'estudiantes_asociados': estudiantesAsociados,
      if (asignaturas != null) 'asignaturas': asignaturas,
    };
  }
}

/// Información de contacto
class ContactInfo {
  final String? telefono;
  final String? direccion;
  final String? ciudad;
  final String? pais;

  ContactInfo({
    this.telefono,
    this.direccion,
    this.ciudad,
    this.pais,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      telefono: json['telefono'],
      direccion: json['direccion'],
      ciudad: json['ciudad'],
      pais: json['pais'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (telefono != null) 'telefono': telefono,
      if (direccion != null) 'direccion': direccion,
      if (ciudad != null) 'ciudad': ciudad,
      if (pais != null) 'pais': pais,
    };
  }
}

/// Modelo de Usuario completo
class Usuario {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;
  final UserRole tipo;
  final UserStatus estado;
  final String? escuelaId;
  final AcademicInfo? infoAcademica;
  final ContactInfo? infoContacto;
  final String? avatar;
  final DateTime? fechaNacimiento;
  final String? genero;
  final DateTime? ultimoAcceso;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos para sistema futuro de permisos
  final String? rolBase;
  final String? perfilRolId;
  final List<String>? permisos;

  // ✅ AGREGAR ESTOS 3 CAMPOS NUEVOS
  final String? fcmToken;
  final String? platform;
  final DateTime? fcmTokenUpdatedAt;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.tipo,
    required this.estado,
    this.escuelaId,
    this.infoAcademica,
    this.infoContacto,
    this.avatar,
    this.fechaNacimiento,
    this.genero,
    this.ultimoAcceso,
    this.createdAt,
    this.updatedAt,
    this.rolBase,
    this.perfilRolId,
    this.permisos,
    // ✅ AGREGAR EN EL CONSTRUCTOR
    this.fcmToken,
    this.platform,
    this.fcmTokenUpdatedAt,
  });

  /// Nombre completo del usuario
  String get nombreCompleto => '$nombre $apellidos';

  /// Iniciales del usuario (para avatares)
  String get iniciales {
    final primerNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final primerApellido =
        apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$primerNombre$primerApellido';
  }

  /// Factory para crear desde JSON
  factory Usuario.fromJson(Map<String, dynamic> json) {
    // ✅ FIX CRÍTICO: Manejar TODOS los casos de null

    // 1️⃣ ID con fallback seguro
    final userId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    if (userId.isEmpty) {
      print('⚠️ WARNING: Usuario sin ID válido');
    }

    return Usuario(
      // ✅ ID con triple protección
      id: userId,

      // ✅ Campos requeridos con fallback seguro
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      email: json['email']?.toString() ?? '',

      // ✅ Enums con fallback
      tipo: UserRole.fromString(json['tipo']?.toString() ??
          json['rolBase']?.toString() ??
          'ESTUDIANTE'),
      estado: UserStatus.fromString(json['estado']?.toString() ?? 'ACTIVO'),

      // ✅ Campos opcionales (ya estaban bien)
      escuelaId: json['escuelaId']?.toString(),

      // ✅ Info académica protegida
      infoAcademica: json['info_academica'] != null
          ? AcademicInfo.fromJson(
              json['info_academica'] as Map<String, dynamic>)
          : null,

      // ✅ Info contacto con doble fuente
      infoContacto: json['info_contacto'] != null || json['perfil'] != null
          ? ContactInfo.fromJson((json['info_contacto'] ?? json['perfil'] ?? {})
              as Map<String, dynamic>)
          : null,

      // ✅ Avatar con doble fuente
      avatar: json['avatar']?.toString() ?? json['perfil']?['foto']?.toString(),

      // ✅ Fechas con tryParse (ya estaban bien)
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.tryParse(json['fechaNacimiento'].toString())
          : null,

      genero: json['genero']?.toString(),

      ultimoAcceso: json['ultimoAcceso'] != null
          ? DateTime.tryParse(json['ultimoAcceso'].toString())
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,

      // ✅ Campos sistema futuro
      rolBase: json['rolBase']?.toString(),
      perfilRolId: json['perfilRolId']?.toString(),
      permisos: json['permisos'] != null
          ? List<String>.from(json['permisos'] as List)
          : null,

      // ✅ CAMPOS FCM (para notificaciones push)
      fcmToken: json['fcmToken']?.toString(),
      platform: json['platform']?.toString(),
      fcmTokenUpdatedAt: json['fcmTokenUpdatedAt'] != null
          ? DateTime.tryParse(json['fcmTokenUpdatedAt'].toString())
          : null,
    );
  }

  static UserRole _parseUserRole(String? role) {
    if (role == null) return UserRole.estudiante;
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'ADMIN':
        return UserRole.admin;
      case 'RECTOR':
        return UserRole.rector;
      case 'COORDINADOR':
        return UserRole.coordinador;
      case 'ADMINISTRATIVO':
        return UserRole.administrativo;
      case 'DOCENTE':
        return UserRole.docente;
      case 'ESTUDIANTE':
        return UserRole.estudiante;
      case 'ACUDIENTE':
        return UserRole.acudiente;
      default:
        return UserRole.estudiante;
    }
  }

  static UserStatus _parseUserStatus(String? status) {
    if (status == null) return UserStatus.activo;
    switch (status.toUpperCase()) {
      case 'ACTIVO':
        return UserStatus.activo;
      case 'INACTIVO':
        return UserStatus.inactivo;
      case 'PENDIENTE':
        return UserStatus.pendiente;
      default:
        return UserStatus.activo;
    }
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'tipo': tipo.value,
      'estado': estado.value,
      if (escuelaId != null) 'escuelaId': escuelaId,
      if (infoAcademica != null) 'info_academica': infoAcademica!.toJson(),
      if (infoContacto != null) 'info_contacto': infoContacto!.toJson(),
      if (avatar != null) 'avatar': avatar,
      if (fechaNacimiento != null)
        'fechaNacimiento': fechaNacimiento!.toIso8601String(),
      if (genero != null) 'genero': genero,
      if (ultimoAcceso != null) 'ultimoAcceso': ultimoAcceso!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (rolBase != null) 'rolBase': rolBase,
      if (perfilRolId != null) 'perfilRolId': perfilRolId,
      if (permisos != null) 'permisos': permisos,
    };
  }

  /// Copiar con campos modificados
  Usuario copyWith({
    String? id,
    String? nombre,
    String? apellidos,
    String? email,
    UserRole? tipo,
    UserStatus? estado,
    String? escuelaId,
    AcademicInfo? infoAcademica,
    ContactInfo? infoContacto,
    String? avatar,
    DateTime? fechaNacimiento,
    String? genero,
    DateTime? ultimoAcceso,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rolBase,
    String? perfilRolId,
    List<String>? permisos,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      escuelaId: escuelaId ?? this.escuelaId,
      infoAcademica: infoAcademica ?? this.infoAcademica,
      infoContacto: infoContacto ?? this.infoContacto,
      avatar: avatar ?? this.avatar,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      genero: genero ?? this.genero,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rolBase: rolBase ?? this.rolBase,
      perfilRolId: perfilRolId ?? this.perfilRolId,
      permisos: permisos ?? this.permisos,
    );
  }
}

/// Respuesta de autenticación
/// Traducida desde src/types/entities/user.ts - AuthResponse
/// Respuesta de autenticación (modificada para auth_service)
class AuthResponse {
  final bool success;
  final String message;
  final Usuario? user;
  final String? token;
  final String? refreshToken;

  AuthResponse({
    required this.success,
    this.message = '',
    this.user,
    this.token,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? Usuario.fromJson(json['user']) : null,
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }
}

/// Datos de autenticación
class AuthData {
  final String accessToken;
  final String refreshToken;
  final Usuario user;

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    // El backend puede enviar los tokens en diferentes formatos
    String accessToken;
    String refreshToken;

    if (json['tokens'] != null) {
      // Formato: { tokens: { access: { token: "..." }, refresh: { token: "..." } } }
      accessToken = json['tokens']['access']['token'];
      refreshToken = json['tokens']['refresh']['token'];
    } else {
      // Formato directo: { token: "...", refreshToken: "..." }
      accessToken = json['token'];
      refreshToken = json['refreshToken'];
    }

    return AuthData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: Usuario.fromJson(json['user']),
    );
  }
}

/// Extensión para obtener nombres amigables de los roles
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.rector:
        return 'Rector';
      case UserRole.coordinador:
        return 'Coordinador';
      case UserRole.administrativo:
        return 'Administrativo';
      case UserRole.docente:
        return 'Docente';
      case UserRole.estudiante:
        return 'Estudiante';
      case UserRole.acudiente:
        return 'Acudiente';
    }
  }
}
