// lib/services/preferencias_service.dart
//
// Preferencia de correo de mensajes del usuario (backend Fase 4):
//   GET/PUT /usuarios/me/preferencias  →  { email, porDefecto, opciones }
// Los mensajes urgentes (prioridad ALTA), las alertas y los correos de la
// cuenta salen siempre, sin importar la preferencia.

import '../config/app_config.dart';
import '../utils/logger.dart';
import '../utils/reintento.dart';
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
  PreferenciasService({
    ApiService? api,
    this.esperaReintento = const Duration(milliseconds: 800),
  }) : _api = api ?? apiService;

  final ApiService _api;

  /// Espera antes del reintento automático por red (G9); inyectable en pruebas
  final Duration esperaReintento;

  /// Solo en debug: status y mensaje del error para diagnosticar (G9)
  void _registrar(String accion, Object error) {
    if (error is ApiException) {
      dlog('⚠️ Preferencias ($accion): status ${error.statusCode} - '
          '${error.message}');
    } else {
      dlog('⚠️ Preferencias ($accion): ${error.runtimeType} - $error');
    }
  }

  /// Preferencia actual. null si el backend no tiene el endpoint (404:
  /// backend anterior a la Fase 4): la app oculta la sección.
  Future<PreferenciasCorreo?> obtener() async {
    try {
      // Timeout o red: un reintento automático (criterio de G6)
      final response = await conReintentoUnico(
        () => _api.get(AppConfig.usuariosMisPreferencias),
        espera: esperaReintento,
      );
      return PreferenciasCorreo.fromJson(
          response['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        dlog('ℹ️ Preferencias de correo no disponibles en este backend');
        return null;
      }
      _registrar('cargar', e);
      rethrow;
    }
  }

  /// Guarda la preferencia y devuelve la que quedó en el servidor
  /// (el PUT es idempotente: reintentarlo no duplica nada)
  Future<PreferenciasCorreo> actualizar(PreferenciaCorreo preferencia) async {
    try {
      final response = await conReintentoUnico(
        () => _api.put(
          AppConfig.usuariosMisPreferencias,
          data: {'email': preferencia.value},
        ),
        espera: esperaReintento,
      );
      return PreferenciasCorreo.fromJson(
          response['data'] as Map<String, dynamic>);
    } catch (e) {
      _registrar('guardar', e);
      rethrow;
    }
  }
}
