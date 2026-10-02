
import '../utils/fechas.dart';// lib/models/perfil_rol.dart

/// Modelo de perfil de rol personalizado por escuela (sistema RBAC)
///
/// Un perfil de rol es una variante personalizada de un rol base.
/// Ejemplo: "Psicólogo" hereda de DOCENTE pero con permisos reducidos.
/// Solo el ADMIN puede crear y gestionar perfiles; la app los consume para
/// mostrar el nombre correcto y aplicar los permisos dinámicos.
class PerfilRol {
  final String id;
  final String nombre;
  final String? descripcion;

  /// Rol base del que hereda: DOCENTE, COORDINADOR, RECTOR, ADMINISTRATIVO, etc.
  final String rolBase;

  /// Lista de strings de permisos granulares (ej: "calificaciones.ver")
  final List<String> permisos;

  final bool activo;
  final String escuelaId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PerfilRol({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.rolBase,
    required this.permisos,
    required this.activo,
    required this.escuelaId,
    this.createdAt,
    this.updatedAt,
  });

  factory PerfilRol.fromJson(Map<String, dynamic> json) {
    return PerfilRol(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      rolBase: json['rolBase']?.toString() ?? '',
      permisos: json['permisos'] != null
          ? List<String>.from(json['permisos'] as List)
          : [],
      activo: json['activo'] as bool? ?? true,
      escuelaId: json['escuelaId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? fechaLocalOpcional(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? fechaLocalOpcional(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'rolBase': rolBase,
      'permisos': permisos,
      'activo': activo,
      'escuelaId': escuelaId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Cantidad de permisos asignados (útil para mostrar en UI)
  int get cantidadPermisos => permisos.length;
}
