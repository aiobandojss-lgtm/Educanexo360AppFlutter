// test/selector_destinatarios_test.dart
// G3: el selector de destinatarios abierto antes de que termine la carga
// muestra un indicador y luego la lista, sin tener que reabrirlo.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/models/usuario.dart';
import 'package:educanexo360_app/providers/auth_provider.dart';
import 'package:educanexo360_app/providers/message_provider.dart';
import 'package:educanexo360_app/screens/mensajes/create_message_screen.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend lento: los destinatarios llegan cuando la prueba lo indica
class _BackendLento implements HttpClientAdapter {
  final liberar = Completer<void>();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    var data = <Object>[];
    if (options.path.contains('destinatarios-disponibles')) {
      await liberar.future;
      data = [
        {
          '_id': 'd1',
          'nombre': 'Laura',
          'apellidos': 'Gómez',
          'email': 'laura@colegio.co',
          'tipo': 'ACUDIENTE',
        },
      ];
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('el selector recibe los destinatarios al llegar, sin reabrir',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      '@educanexo360_token': 't',
      '@educanexo360_refreshToken': 'r',
    });
    SharedPreferences.setMockInitialValues({});
    await StorageService.saveUser(Usuario.fromJson({
      '_id': 'u1',
      'nombre': 'Docente',
      'apellidos': 'Prueba',
      'email': 'docente@colegio.co',
      'tipo': 'DOCENTE',
      'escuelaId': 'e1',
    }));
    final backend = _BackendLento();
    ApiService().httpClientAdapter = backend;

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: const MaterialApp(home: CreateMessageScreen()),
    ));
    await _esperar(tester);

    // Abrir el selector mientras los destinatarios siguen cargando
    await tester.tap(find.text('Agregar destinatarios'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Seleccionar Destinatarios'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(CircularProgressIndicator)),
        findsOneWidget);
    expect(find.text('No se encontraron usuarios'), findsNothing);

    // Llegan los destinatarios: aparecen en el mismo diálogo
    backend.liberar.complete();
    await _esperar(tester);

    expect(find.text('Seleccionar Destinatarios'), findsOneWidget);
    expect(find.text('Laura Gómez'), findsOneWidget);
  });
}
