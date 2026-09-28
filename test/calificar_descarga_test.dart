// test/calificar_descarga_test.dart
// El docente abre un archivo entregado con ?tipo=entrega (auditoría E4)
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/providers/tarea_provider.dart';
import 'package:educanexo360_app/screens/tareas/calificar_entrega_screen.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Backend implements HttpClientAdapter {
  ResponseBody _json(Object body) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.uri.path.endsWith('/entregas')) {
      return _json({
        'success': true,
        'data': [
          {
            '_id': 'e1',
            'estudianteId': {'_id': 's1', 'nombre': 'Ana', 'apellidos': 'Ruiz'},
            'estado': 'ENTREGADA',
            'archivos': [
              {'fileId': 'f1', 'nombre': 'taller.pdf', 'tipo': 'application/pdf', 'tamaño': 3},
            ],
          },
        ],
      });
    }
    return _json({
      'success': true,
      'data': {
        '_id': 't1',
        'titulo': 'Taller',
        'descripcion': '',
        'fechaAsignacion': '2026-09-01T00:00:00.000Z',
        'fechaLimite': '2026-09-30T00:00:00.000Z',
      },
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => FileHelper.debugInterceptarDescarga = null);

  testWidgets('abrir un archivo entregado pide ?tipo=entrega', (tester) async {
    ApiService().httpClientAdapter = _Backend();
    final pedidos = <String>[];
    FileHelper.debugInterceptarDescarga =
        (endpoint, nombre) => pedidos.add(endpoint);

    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => TareaProvider(),
      child: const MaterialApp(
        home: CalificarEntregaScreen(tareaId: 't1', entregaId: 'e1'),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('taller.pdf'));
    await tester.pump();

    expect(pedidos, ['/tareas/t1/archivos/f1?tipo=entrega']);
  });
}
