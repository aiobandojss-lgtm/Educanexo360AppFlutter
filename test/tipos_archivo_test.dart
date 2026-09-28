// test/tipos_archivo_test.dart
// Tipos de archivo permitidos, alineados con el backend (Fase 5, D4)
import 'package:educanexo360_app/config/app_config.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la lista coincide con la del backend (utils/tipoArchivo.ts)', () {
    expect(AppConfig.extensionesPermitidas.toSet(), {
      'pdf', 'doc', 'xls', 'ppt', 'docx', 'xlsx', 'pptx', 'zip', 'txt',
      'csv', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif',
    });
  });

  test('acepta los tipos permitidos sin importar mayúsculas', () {
    for (final nombre in [
      'guia.pdf',
      'Taller.DOCX',
      'notas.xlsx',
      'expo.pptx',
      'datos.csv',
      'foto_iphone.HEIC',
      'trabajo.zip',
    ]) {
      expect(AppConfig.extensionPermitida(nombre), isTrue, reason: nombre);
    }
  });

  test('rechaza video, audio, ejecutables y archivos sin extensión', () {
    for (final nombre in ['video.mp4', 'nota.mp3', 'app.apk', 'script.exe', 'LEEME']) {
      expect(AppConfig.extensionPermitida(nombre), isFalse, reason: nombre);
    }
    expect(AppConfig.mensajeTipoNoPermitido('video.mp4'),
        contains('No se permite "video.mp4"'));
  });

  test('mensajeDeError muestra el mensaje del backend (400) sin prefijos', () {
    final error400 = ApiException(
        message: 'Tipo de archivo no permitido: video.mp4', statusCode: 400);
    expect(mensajeDeError(error400, 'genérico'),
        'Tipo de archivo no permitido: video.mp4');
    expect(mensajeDeError(Exception('x'), 'genérico'), 'genérico');
  });
}
