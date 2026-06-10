// lib/utils/logger.dart
//
// Logging centralizado. Solo imprime en modo debug.
// En release (Play Store / App Store) no produce output.
//
// Uso: dlog('mensaje') en lugar de print('mensaje')

import 'package:flutter/foundation.dart';

/// Imprime solo en modo debug. No-op en release.
void dlog(Object? message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(message);
  }
}
