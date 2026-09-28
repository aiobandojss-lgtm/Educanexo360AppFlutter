// test/tarea_descarga_test.dart
// Descarga de archivos de tareas con ?tipo= (Fase 5, D1)
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/config/app_config.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/tarea_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simula el backend: sin ?tipo= válido responde 400 como el real
class _DescargaAdapter implements HttpClientAdapter {
  final uris = <Uri>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    uris.add(options.uri);
    final tipo = options.uri.queryParameters['tipo'];
    if (tipo != 'referencia' && tipo != 'entrega') {
      return ResponseBody.fromString(
          '{"success":false,"message":"Tipo de archivo inválido"}', 400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
    }
    return ResponseBody.fromBytes([1, 2, 3], 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la URL de descarga incluye ?tipo= (referencia por defecto)', () {
    expect(AppConfig.tareaArchivoDownload('t1', 'a1'),
        '/tareas/t1/archivos/a1?tipo=referencia');
    expect(
        AppConfig.tareaArchivoDownload('t1', 'a1',
            tipo: AppConfig.tipoArchivoEntrega),
        '/tareas/t1/archivos/a1?tipo=entrega');
  });

  test('descargar material de referencia envía tipo=referencia y funciona',
      () async {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
    final adapter = _DescargaAdapter();
    ApiService().httpClientAdapter = adapter;

    final dir = await Directory.systemTemp.createTemp('descarga_tarea');
    addTearDown(() => dir.delete(recursive: true));
    final destino = '${dir.path}/guia.pdf';

    await TareaService().descargarArchivoReferencia('t1', 'a1', destino);

    expect(adapter.uris.single.path, endsWith('/tareas/t1/archivos/a1'));
    expect(adapter.uris.single.queryParameters['tipo'], 'referencia');
    expect(File(destino).readAsBytesSync(), [1, 2, 3]);
  });
}
