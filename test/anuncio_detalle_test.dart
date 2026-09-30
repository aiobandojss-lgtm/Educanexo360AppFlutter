// test/anuncio_detalle_test.dart
// Abrir un anuncio con la lista vacía (desde notificación) (Fase 5, D3)
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/providers/anuncio_provider.dart';
import 'package:educanexo360_app/screens/anuncios/anuncio_detail_screen.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status);
  final int status;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final body = status == 200
        ? {
            'success': true,
            'data': {
              '_id': options.path.split('/').last,
              'titulo': 'Salida pedagógica',
              'contenido': 'Detalles',
              'creador': 'u1',
              'escuelaId': 'e1',
            },
          }
        : {'success': false, 'message': 'Anuncio no encontrado'};
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
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

  test('con la lista vacía lo pide al servidor (antes: StateError)', () async {
    ApiService().httpClientAdapter = _Adapter(200);
    final provider = AnuncioProvider();

    final anuncio = await provider.getAnuncioById('a9');

    expect(anuncio?.id, 'a9');
  });

  test('con la lista vacía y el anuncio inexistente lanza el error del API',
      () async {
    ApiService().httpClientAdapter = _Adapter(404);

    await expectLater(
        AnuncioProvider().getAnuncioById('zz'), throwsA(isA<ApiException>()));
  });

  Future<void> abrirDetalle(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Inicio'))),
        GoRoute(
          path: '/anuncio',
          builder: (_, __) => const AnuncioDetailScreen(anuncioId: 'zz'),
        ),
      ],
    );
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AnuncioProvider(),
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/anuncio');
    await tester.pumpAndSettle();
  }

  testWidgets('anuncio borrado (404): "ya no está disponible" (E5)',
      (tester) async {
    ApiService().httpClientAdapter = _Adapter(404);
    await abrirDetalle(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Este anuncio ya no está disponible'), findsOneWidget);
  });

  testWidgets('sin permiso (403): también "ya no está disponible"',
      (tester) async {
    ApiService().httpClientAdapter = _Adapter(403);
    await abrirDetalle(tester);

    expect(find.text('Este anuncio ya no está disponible'), findsOneWidget);
  });

  testWidgets('si falla la carga no queda el spinner colgado',
      (tester) async {
    ApiService().httpClientAdapter = _Adapter(500);
    final router = GoRouter(
      routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Inicio'))),
        GoRoute(
          path: '/anuncio',
          builder: (_, __) => const AnuncioDetailScreen(anuncioId: 'zz'),
        ),
      ],
    );
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AnuncioProvider(),
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/anuncio');
    await tester.pumpAndSettle();

    // Volvió atrás con el aviso y sin spinner
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Error al cargar el anuncio'), findsOneWidget);
  });
}
