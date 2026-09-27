// test/legacy_downloads_test.dart
// Limpieza única de adjuntos sueltos de versiones anteriores (auditoría A5)
import 'dart:io';

import 'package:educanexo360_app/utils/file_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('externo_app');
  });

  tearDown(() => dir.delete(recursive: true));

  test('borra solo archivos sueltos de nivel superior y una sola vez',
      () async {
    File('${dir.path}/circular_usuario_A.pdf').writeAsStringSync('A');
    final otraCarpeta = Directory('${dir.path}/plugin_cache')..createSync();
    final archivoPlugin = File('${otraCarpeta.path}/dato.bin')
      ..writeAsStringSync('x');

    await FileHelper.clearLegacyDownloadsOnce(dir,
        flagKey: FileHelper.legacyExternalCleanupKey);

    expect(File('${dir.path}/circular_usuario_A.pdf').existsSync(), isFalse);
    expect(archivoPlugin.existsSync(), isTrue); // subcarpetas intactas

    // Segunda vez: la bandera impide volver a borrar
    final nuevo = File('${dir.path}/otro.pdf')..writeAsStringSync('B');
    await FileHelper.clearLegacyDownloadsOnce(dir,
        flagKey: FileHelper.legacyExternalCleanupKey);
    expect(nuevo.existsSync(), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(FileHelper.legacyExternalCleanupKey), isTrue);
  });
}
