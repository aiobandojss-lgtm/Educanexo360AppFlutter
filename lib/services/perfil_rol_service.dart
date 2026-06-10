// lib/services/perfil_rol_service.dart
library;

/// Servicio de solo LECTURA para perfiles de rol (RBAC).
///
/// La creación, edición y eliminación de perfiles se hace desde la
/// aplicación web (no desde la app móvil). Este servicio solo consulta.
///
/// Incluye caché en memoria para evitar llamadas repetidas a la API.

import '../config/app_config.dart';
import '../models/perfil_rol.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class PerfilRolService {
  // Caché en memoria: se llena al listar y se consulta por ID sin nueva llamada.
  static List<PerfilRol>? _cache;

  // ==========================================
  // CONSULTAS PRINCIPALES
  // ==========================================

  /// Lista todos los perfiles de rol de la escuela del usuario autenticado.
  ///
  /// Usa caché en memoria. Pasa [force: true] para forzar recarga.
  /// Roles permitidos: ADMIN, RECTOR, COORDINADOR.
  static Future<List<PerfilRol>> listar({bool force = false}) async {
    if (_cache != null && !force) return _cache!;

    try {
      dlog('📋 PerfilRolService: cargando perfiles de rol...');
      final response = await apiService.get(AppConfig.perfilesRol);

      final data = response['data'];
      final List<dynamic> lista =
          (data is Map ? data['perfiles'] : null) as List<dynamic>? ?? [];
      _cache = lista.map((json) => PerfilRol.fromJson(json)).toList();

      dlog('✅ PerfilRolService: ${_cache!.length} perfiles cargados');
      return _cache!;
    } catch (e) {
      dlog('❌ PerfilRolService.listar: $e');
      rethrow;
    }
  }

  /// Obtiene un perfil de rol por ID.
  ///
  /// Busca primero en el caché local antes de ir a la API.
  static Future<PerfilRol> obtener(String id) async {
    // Buscar en caché primero
    if (_cache != null) {
      final cached = _cache!.where((p) => p.id == id).firstOrNull;
      if (cached != null) return cached;
    }

    try {
      dlog('📋 PerfilRolService: obteniendo perfil $id...');
      final response = await apiService.get(AppConfig.perfilRolDetail(id));
      return PerfilRol.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      dlog('❌ PerfilRolService.obtener($id): $e');
      rethrow;
    }
  }

  /// Busca el nombre de un perfil por su ID.
  ///
  /// Devuelve null si el ID es nulo/vacío o si no se encuentra el perfil.
  /// No lanza excepción: es seguro llamarlo en la UI sin try/catch.
  static Future<String?> getNombrePorId(String? id) async {
    if (id == null || id.isEmpty) return null;

    try {
      final perfil = await obtener(id);
      return perfil.nombre;
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Limpia el caché (llamar en logout o cuando el admin modifica perfiles).
  static void limpiarCache() {
    _cache = null;
    dlog('🧹 PerfilRolService: caché limpiado');
  }
}
