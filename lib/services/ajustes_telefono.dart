// lib/services/ajustes_telefono.dart
//
// Abre los ajustes de notificaciones de la app en el teléfono (Android),
// mediante el canal nativo de MainActivity.kt.

import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../utils/logger.dart';

class AjustesTelefono {
  AjustesTelefono._();

  @visibleForTesting
  static const MethodChannel canal = MethodChannel('educanexo360/ajustes');

  /// Solo para pruebas: fuerza la disponibilidad (en pruebas no es Android)
  @visibleForTesting
  static bool? debugDisponible;

  /// Solo Android por ahora (en iOS no se ha probado)
  static bool get disponible => debugDisponible ?? Platform.isAndroid;

  /// true si se abrió la pantalla de ajustes
  static Future<bool> abrirNotificaciones() async {
    try {
      return await canal.invokeMethod<bool>('abrirNotificaciones') ?? false;
    } catch (e) {
      dlog('⚠️ No se pudieron abrir los ajustes del teléfono: $e');
      return false;
    }
  }
}
