// test/tipos_archivo_test.dart
// Tipos de archivo permitidos, alineados con el backend (Fase 5, D4)
import 'package:educanexo360_app/config/app_config.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // OJO: esto compara contra una COPIA FIJA de la lista del backend, no contra
  // el backend en vivo. Copiada de educanexo360-backend/src/utils/tipoArchivo.ts
  // (lista definida en el commit b44fc03, sin cambios hasta 3c9334d, dist de
  // la Fase 5). Si el backend cambia la lista, este test NO lo detecta:
  // actualizar AppConfig.extensionesPermitidas y esta copia a mano.
  test('la lista coincide con la copia de la del backend (b44fc03)', () {
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
    // Excepciones propias de la app (texto en español para el usuario)
    expect(mensajeDeError(Exception('Debe seleccionar un curso'), 'genérico'),
        'Debe seleccionar un curso');
    // Cualquier otra cosa → el genérico
    expect(mensajeDeError(StateError('Bad state'), 'genérico'), 'genérico');
  });
}
