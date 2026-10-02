// test/refresco_listas_test.dart
// G5: las listas se refrescan al volver de un formulario y el estado vacío
// se puede refrescar arrastrando hacia abajo.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/models/usuario.dart';
import 'package:educanexo360_app/providers/auth_provider.dart';
import 'package:educanexo360_app/providers/tarea_provider.dart';
import 'package:educanexo360_app/screens/tareas/lista_tareas_screen.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/storage_service.dart';
import 'package:educanexo360_app/widgets/common/vacio_refrescable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Backend implements HttpClientAdapter {
  int listados = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.method == 'GET' && options.uri.path.endsWith('/tareas')) {
      listados++;
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': [],
        'meta': {'total': 0, 'pagina': 1, 'limite': 20, 'paginas': 1},
      }),
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

  testWidgets('estado vacío: arrastrar hacia abajo refresca', (tester) async {
    var refrescos = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VacioRefrescable(
          onRefresh: () async => refrescos++,
          child: const Center(child: Text('Sin tareas')),
        ),
      ),
    ));

    await tester.fling(find.text('Sin tareas'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refrescos, 1);
  });

  testWidgets('tareas (docente): al volver de crear, la lista se recarga',
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
    final backend = _Backend();
    ApiService().httpClientAdapter = backend;

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const ListaTareasScreen()),
      GoRoute(
        path: '/tareas/crear',
        builder: (_, __) => const Scaffold(body: Text('Formulario')),
      ),
    ]);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TareaProvider()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await _esperar(tester);
    final antes = backend.listados;
    expect(antes, greaterThan(0));

    // Ir a crear y volver
    await tester.tap(find.byType(FloatingActionButton));
    await _esperar(tester);
    expect(find.text('Formulario'), findsOneWidget);
    router.pop();
    await _esperar(tester);

    expect(backend.listados, greaterThan(antes));
  });
}
