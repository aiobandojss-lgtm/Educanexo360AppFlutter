// test/sin_errores_crudos_test.dart
// Guardián (auditoría F2): ninguna pantalla muestra e.toString() ni '$e'.
// Recorre el código de lib/ y falla si aparece un error crudo fuera de los
// usos permitidos (logs y clasificación interna). Para mostrar un error al
// usuario se usa mensajeDeError(e, 'contexto en español').
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _patron = RegExp(
  r'\$(e|err|error|ex|exception)(?![A-Za-z0-9_])'
  r'|\$\{(e|err|error|ex)(\.toString\(\))?\}'
  r'|(?<![A-Za-z_])(e|err|error|ex)\.toString\(\)',
);

// Usos que NO se muestran al usuario (archivo → fragmento de la línea)
const _permitidos = {
  'lib/models/tarea.dart': ['.map((e) => e.toString())'],
  'lib/providers/auth_provider.dart': ['final errorStr = error.toString();'],
  'lib/screens/perfil/cambiar_password_screen.dart': [
    "e.toString().contains('passwordActual')",
    "e.toString().contains('incorrecta')",
  ],
  'lib/services/api_service.dart': [
    "'Respuesta de refresh inesperada: \$e'", // mensaje interno de Dio
    'final texto = error.toString();', // dentro de mensajeDeError
  ],
};

void main() {
  test('ninguna pantalla muestra errores crudos (e.toString() / \$e)', () {
    final hallazgos = <String>[];
    final archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final archivo in archivos) {
      final ruta = archivo.path.replaceAll('\\', '/');
      final lineas = archivo.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.startsWith('//') ||
            linea.contains('dlog(') ||
            linea.contains('print(')) {
          continue;
        }
        if (!_patron.hasMatch(linea)) continue;
        final permitido =
            (_permitidos[ruta] ?? const []).any((f) => linea.contains(f));
        if (!permitido) hallazgos.add('$ruta:${i + 1}: $linea');
      }
    }

    expect(hallazgos, isEmpty,
        reason: 'Usa mensajeDeError(e, ...) para mostrar errores:\n'
            '${hallazgos.join('\n')}');
  });
}
