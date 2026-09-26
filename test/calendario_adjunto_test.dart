// test/calendario_adjunto_test.dart
// Crear/editar evento con archivo: contrato con el backend (addendum Fase 2B)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/models/evento.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/calendario_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Respuesta con la forma real del backend (calendario.controller.ts)
Map<String, dynamic> _eventoBackend(String id) => {
      '_id': id,
      'titulo': 'Reunión de padres',
      'descripcion': 'Entrega de boletines',
      'fechaInicio': '2026-10-01T13:00:00.000Z',
      'fechaFin': '2026-10-01T15:00:00.000Z',
      'todoElDia': false,
      'tipo': 'INSTITUCIONAL',
      'estado': 'PENDIENTE',
      'escuelaId': 'esc1',
      'archivoAdjunto': {
        'fileId': 'f1',
        'nombre': 'circular.pdf',
        'tipo': 'application/pdf',
        'tamaño': 2048,
      },
    };

class _CalendarioAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <String>[];

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
    bodies.add(latin1.decode(bytes));
    final id = options.path == '/calendario' ? 'nuevo' : 'ev1';
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': _eventoBackend(id)}),
      options.path == '/calendario' ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CalendarioAdapter adapter;
  late File archivo;
  late Directory tempDir;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
    adapter = _CalendarioAdapter();
    ApiService().httpClientAdapter = adapter;
    tempDir = await Directory.systemTemp.createTemp('calendario_test');
    archivo = File('${tempDir.path}/circular.pdf')
      ..writeAsBytesSync(List.filled(2048, 1));
  });

  tearDown(() => tempDir.delete(recursive: true));

  void expectMultipartConArchivo(String body) {
    expect(body, contains('name="archivo"; filename="circular.pdf"'));
    expect(body, contains('name="titulo"'));
    expect(body, contains('name="fechaInicio"'));
    expect(body, contains('name="todoElDia"\r\n\r\nfalse'));
  }

  test('crear evento con archivo → POST /calendario multipart', () async {
    final evento = await CalendarioService().crearEvento(
      titulo: 'Reunión de padres',
      descripcion: 'Entrega de boletines',
      fechaInicio: DateTime.utc(2026, 10, 1, 13),
      fechaFin: DateTime.utc(2026, 10, 1, 15),
      todoElDia: false,
      tipo: EventType.institucional,
      archivoAdjunto: archivo,
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/calendario');
    expect(request.data, isA<FormData>());
    expectMultipartConArchivo(adapter.bodies.single);

    expect(evento.id, 'nuevo');
    expect(evento.archivoAdjunto?.nombre, 'circular.pdf');
    expect(evento.archivoAdjunto?.tamano, 2048);
  });

  test('editar evento con archivo → POST /calendario/:id multipart', () async {
    final evento = await CalendarioService().actualizarEvento(
      id: 'ev1',
      titulo: 'Reunión de padres',
      fechaInicio: DateTime.utc(2026, 10, 1, 13),
      fechaFin: DateTime.utc(2026, 10, 1, 15),
      todoElDia: false,
      archivoAdjunto: archivo,
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/calendario/ev1');
    expect(request.sendTimeout, const Duration(seconds: 120));
    expectMultipartConArchivo(adapter.bodies.single);

    expect(evento.id, 'ev1');
    expect(evento.archivoAdjunto?.fileId, 'f1');
  });
}
