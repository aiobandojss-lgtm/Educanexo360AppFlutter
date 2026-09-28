// test/anuncio_adjuntos_test.dart
// Anuncios con adjuntos: JSON + POST /anuncios/:id/adjuntos (Fase 5, D2)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/services/anuncio_service.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _anuncio(String id) => {
      '_id': id,
      'titulo': 'Salida pedagógica',
      'contenido': 'Detalles',
      'creador': 'u1',
      'escuelaId': 'e1',
      'paraPadres': true,
    };

/// Backend simulado: POST/PUT /anuncios solo aceptan JSON (como el real)
class _AnunciosAdapter implements HttpClientAdapter {
  _AnunciosAdapter({this.adjuntosFallan = false});

  final bool adjuntosFallan;
  final requests = <RequestOptions>[];
  final cuerposAdjuntos = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }

    if (options.path.endsWith('/adjuntos')) {
      cuerposAdjuntos.add(latin1.decode(bytes));
      if (adjuntosFallan) {
        return _json(400, {
          'success': false,
          'message': 'Tipo de archivo no permitido: video.mp4',
        });
      }
      return _json(200, {
        'success': true,
        'data': [
          {'fileId': 'f1', 'nombre': 'circular.pdf', 'tipo': 'application/pdf', 'tamaño': 10},
        ],
      });
    }

    // Crear/actualizar: el cuerpo debe ser JSON, nunca multipart
    if (options.data is FormData) {
      return _json(400, {'success': false, 'message': 'El título es obligatorio'});
    }
    final id = options.method == 'POST' ? 'nuevo' : 'a1';
    return _json(options.method == 'POST' ? 201 : 200,
        {'success': true, 'data': _anuncio(id)});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late File pdf;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('anuncio_test');
    pdf = File('${dir.path}/circular.pdf')..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => dir.delete(recursive: true));

  test('crear con adjuntos: JSON y luego POST /anuncios/:id/adjuntos',
      () async {
    final adapter = _AnunciosAdapter();
    ApiService().httpClientAdapter = adapter;

    final anuncio = await AnuncioService().createAnuncio(
      titulo: 'Salida pedagógica',
      contenido: 'Detalles',
      paraPadres: true,
      adjuntos: [pdf],
    );

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'),
        ['POST /anuncios', 'POST /anuncios/nuevo/adjuntos']);
    expect(adapter.requests.first.data, isA<Map>());
    expect(adapter.cuerposAdjuntos.single,
        contains('name="archivos"; filename="circular.pdf"'));
    expect(anuncio.archivosAdjuntos.single.nombre, 'circular.pdf');
  });

  test('crear sin adjuntos: una sola petición JSON', () async {
    final adapter = _AnunciosAdapter();
    ApiService().httpClientAdapter = adapter;

    await AnuncioService().createAnuncio(
        titulo: 'Aviso', contenido: 'Texto', paraPadres: true);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'),
        ['POST /anuncios']);
  });

  test('actualizar con adjuntos nuevos: PUT JSON y luego adjuntos', () async {
    final adapter = _AnunciosAdapter();
    ApiService().httpClientAdapter = adapter;

    await AnuncioService().updateAnuncio(
      anuncioId: 'a1',
      titulo: 'Salida pedagógica',
      contenido: 'Detalles',
      paraPadres: true,
      nuevosAdjuntos: [pdf],
    );

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'),
        ['PUT /anuncios/a1', 'POST /anuncios/a1/adjuntos']);
    expect(adapter.requests.first.data, isA<Map>());
  });

  test(
      'si los adjuntos fallan, avisa con el anuncio ya creado y el mensaje '
      'del backend (no se debe volver a crear)', () async {
    ApiService().httpClientAdapter = _AnunciosAdapter(adjuntosFallan: true);

    await expectLater(
      AnuncioService().createAnuncio(
          titulo: 'Aviso', contenido: 'Texto', paraPadres: true, adjuntos: [pdf]),
      throwsA(isA<AdjuntosNoSubidosException>()
          .having((e) => e.anuncio.id, 'anuncio.id', 'nuevo')
          .having((e) => e.motivo, 'motivo', contains('no permitido'))),
    );
  });
}
