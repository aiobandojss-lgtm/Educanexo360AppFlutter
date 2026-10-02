// lib/utils/reintento.dart
//
// Reintento automático único ante fallos de red o tiempo de espera (G6/G9):
// en redes móviles la primera petición a veces expira y la segunda responde.
// Solo se reintenta cuando NO hubo respuesta del servidor; los errores del
// servidor (4xx/5xx) se muestran tal cual.

import '../services/api_service.dart';
import 'logger.dart';

/// true si el error es de red o tiempo de espera (sin respuesta del servidor)
bool esErrorDeRed(Object error) =>
    error is ApiException &&
    error.statusCode == 0 &&
    error.message != ApiService.mensajeCancelado &&
    ApiService.mensajesDeRed.contains(error.message);

/// Ejecuta [accion]; si falla por red o tiempo de espera, la reintenta una
/// vez tras [espera] antes de propagar el error.
Future<T> conReintentoUnico<T>(
  Future<T> Function() accion, {
  Duration espera = const Duration(milliseconds: 800),
}) async {
  try {
    return await accion();
  } catch (e) {
    if (!esErrorDeRed(e)) rethrow;
    dlog('🔁 Error de red, reintento automático: $e');
    await Future<void>.delayed(espera);
    return accion();
  }
}
