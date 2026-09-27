// lib/services/preferencias_service.dart
//
// Preferencia de correo de mensajes del usuario (backend Fase 4):
//   GET/PUT /usuarios/me/preferencias  →  { email, porDefecto, opciones }
// Los mensajes urgentes (prioridad ALTA), las alertas y los correos de la
// cuenta salen siempre, sin importar la preferencia.

import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_service.dart';

/// Opciones de correo que acepta el backend
enum PreferenciaCorreo {
  inmediato('inmediato'),
  resumen('resumen'),
  ninguno('ninguno');

  final String value;
  const PreferenciaCorreo(this.value);

  static PreferenciaCorreo? fromValue(String? value) {
    for (final opcion in PreferenciaCorreo.values) {
      if (opcion.value == value) return opcion;
    }
    return null;
  }
}

class PreferenciasCorreo {
  final PreferenciaCorreo email;

  /// true si el usuario nunca eligió (el backend aplica la de su rol:
  /// ACUDIENTE → resumen, resto → inmediato)
  final bool porDefecto;

  const PreferenciasCorreo({required this.email, required this.porDefecto});

  factory PreferenciasCorreo.fromJson(Map<String, dynamic> json) {
    return PreferenciasCorreo(
      email: PreferenciaCorreo.fromValue(json['email'] as String?) ??
          PreferenciaCorreo.inmediato,
      porDefecto: json['porDefecto'] == true,
    );
  }
}

class PreferenciasService {
  PreferenciasService({ApiService? api}) : _api = api ?? apiService;

  final ApiService _api;

  /// Preferencia actual. null si el backend no tiene el endpoint (404:
  /// backend anterior a la Fase 4): la app oculta la sección.
  Future<PreferenciasCorreo?> obtener() async {
    try {
      final response = await _api.get(AppConfig.usuariosMisPreferencias);
      return PreferenciasCorreo.fromJson(
          response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        dlog('ℹ️ Preferencias de correo no disponibles en este backend');
        return null;
      }
      rethrow;
    }
  }

  /// Guarda la preferencia y devuelve la que quedó en el servidor
  Future<PreferenciasCorreo> actualizar(PreferenciaCorreo preferencia) async {
    final response = await _api.put(
      AppConfig.usuariosMisPreferencias,
      data: {'email': preferencia.value},
    );
    return PreferenciasCorreo.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
