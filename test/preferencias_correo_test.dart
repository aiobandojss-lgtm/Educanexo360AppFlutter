// test/preferencias_correo_test.dart
// Preferencias de correo (Fase 4): servicio y sección del perfil
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/preferencias_service.dart';
import 'package:educanexo360_app/widgets/perfil/preferencias_correo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.onFetch);
  final Future<ResponseBody> Function(RequestOptions) onFetch;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    requests.add(options);
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _respuesta(String email, {bool porDefecto = false}) => {
      'success': true,
      'data': {
        'email': email,
        'porDefecto': porDefecto,
        'opciones': ['inmediato', 'resumen', 'ninguno'],
      },
    };

/// Servicio falso para las pruebas del widget
class _FakeService extends PreferenciasService {
  _FakeService({this.inicial, this.falla = false, this.fallaAlGuardar = false});

  final PreferenciasCorreo? inicial;
  final bool falla;
  final bool fallaAlGuardar;
  final guardadas = <PreferenciaCorreo>[];

  @override
  Future<PreferenciasCorreo?> obtener() async {
    if (falla) throw ApiException(message: 'Error', statusCode: 500);
    return inicial;
  }

  @override
  Future<PreferenciasCorreo> actualizar(PreferenciaCorreo preferencia) async {
    guardadas.add(preferencia);
    if (fallaAlGuardar) throw ApiException(message: 'Error', statusCode: 500);
    return PreferenciasCorreo(email: preferencia, porDefecto: false);
  }
}

Widget _app(PreferenciasService service) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PreferenciasCorreoCard(service: service),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferenciasService', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
      SharedPreferences.setMockInitialValues({});
    });

    test('GET: lee la preferencia y si es por defecto', () async {
      final adapter =
          _Adapter((o) async => _json(200, _respuesta('resumen', porDefecto: true)));
      ApiService().httpClientAdapter = adapter;

      final pref = await PreferenciasService().obtener();

      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/usuarios/me/preferencias');
      expect(pref!.email, PreferenciaCorreo.resumen);
      expect(pref.porDefecto, isTrue);
    });

    test('GET 404 (backend viejo) → null, sin error', () async {
      ApiService().httpClientAdapter = _Adapter((o) async =>
          _json(404, {'success': false, 'message': 'Ruta no encontrada'}));

      expect(await PreferenciasService().obtener(), isNull);
    });

    test('GET 500 → lanza (la tarjeta muestra Reintentar)', () async {
      ApiService().httpClientAdapter = _Adapter((o) async =>
          _json(500, {'success': false, 'message': 'Error'}));

      await expectLater(
          PreferenciasService().obtener(), throwsA(isA<ApiException>()));
    });

    test('PUT: envía { email } y devuelve la guardada', () async {
      final adapter = _Adapter((o) async => _json(200, _respuesta('ninguno')));
      ApiService().httpClientAdapter = adapter;

      final pref =
          await PreferenciasService().actualizar(PreferenciaCorreo.ninguno);

      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/usuarios/me/preferencias');
      expect(request.data, {'email': 'ninguno'});
      expect(pref.email, PreferenciaCorreo.ninguno);
    });

    // G9: "No se pudo guardar tu preferencia" en redes lentas
    test('PUT con timeout: reintenta una vez y guarda', () async {
      var peticiones = 0;
      final adapter = _Adapter((o) async {
        peticiones++;
        if (peticiones == 1) {
          throw DioException(
              requestOptions: o, type: DioExceptionType.receiveTimeout);
        }
        return _json(200, _respuesta('resumen'));
      });
      ApiService().httpClientAdapter = adapter;

      final pref = await PreferenciasService(esperaReintento: Duration.zero)
          .actualizar(PreferenciaCorreo.resumen);

      expect(adapter.requests.length, 2);
      expect(pref.email, PreferenciaCorreo.resumen);
    });

    test('GET con error de red: reintenta una vez', () async {
      var peticiones = 0;
      final adapter = _Adapter((o) async {
        peticiones++;
        if (peticiones == 1) {
          throw DioException(
              requestOptions: o, type: DioExceptionType.connectionError);
        }
        return _json(200, _respuesta('inmediato'));
      });
      ApiService().httpClientAdapter = adapter;

      final pref =
          await PreferenciasService(esperaReintento: Duration.zero).obtener();

      expect(adapter.requests.length, 2);
      expect(pref!.email, PreferenciaCorreo.inmediato);
    });

    test('PUT con error del servidor (400): no reintenta', () async {
      final adapter = _Adapter((o) async =>
          _json(400, {'success': false, 'message': 'Preferencia inválida'}));
      ApiService().httpClientAdapter = adapter;

      await expectLater(
          PreferenciasService(esperaReintento: Duration.zero)
              .actualizar(PreferenciaCorreo.ninguno),
          throwsA(isA<ApiException>()));
      expect(adapter.requests.length, 1);
    });
  });

  group('PreferenciasCorreoCard', () {
    const inicialResumen =
        PreferenciasCorreo(email: PreferenciaCorreo.resumen, porDefecto: true);

    testWidgets('muestra las 3 opciones, la aclaración y la seleccionada',
        (tester) async {
      await tester.pumpWidget(_app(_FakeService(inicial: inicialResumen)));
      await tester.pumpAndSettle();

      expect(find.text('✉️ Correos de EducaNexo'), findsOneWidget);
      expect(find.text('Al instante'), findsOneWidget);
      expect(find.text('Resumen diario'), findsOneWidget);
      expect(find.text('Recomendado para acudientes'), findsOneWidget);
      expect(find.text('Ninguno'), findsOneWidget);
      expect(find.textContaining('siempre te llegan'), findsOneWidget);

      // Accesibilidad: la opción elegida se anuncia como seleccionada
      final semantica = tester.getSemantics(
          find.byKey(const ValueKey('preferencia-resumen')));
      expect(
          semantica,
          isSemantics(
              hasCheckedState: true, isChecked: true, hasTapAction: true));
      final otra = tester.getSemantics(
          find.byKey(const ValueKey('preferencia-inmediato')));
      expect(otra, isSemantics(hasCheckedState: true, isChecked: false));
    });

    testWidgets('backend viejo (null) → la sección no se muestra',
        (tester) async {
      await tester.pumpWidget(_app(_FakeService()));
      await tester.pumpAndSettle();

      expect(find.text('✉️ Correos de EducaNexo'), findsNothing);
    });

    testWidgets('error al cargar → Reintentar', (tester) async {
      await tester.pumpWidget(_app(_FakeService(falla: true)));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('elegir una opción la guarda en el servidor', (tester) async {
      final service = _FakeService(inicial: inicialResumen);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('preferencia-ninguno')));
      await tester.pumpAndSettle();

      expect(service.guardadas, [PreferenciaCorreo.ninguno]);
      final semantica = tester.getSemantics(
          find.byKey(const ValueKey('preferencia-ninguno')));
      expect(semantica, isSemantics(hasCheckedState: true, isChecked: true));
    });

    testWidgets('con lector de pantalla (acción semántica tap) se selecciona',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final service = _FakeService(inicial: inicialResumen);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      tester.semantics.tap(find.semantics.byLabel(RegExp('^Ninguno')));
      await tester.pumpAndSettle();

      expect(service.guardadas, [PreferenciaCorreo.ninguno]);
      semantics.dispose();
    });

    testWidgets('si falla al guardar vuelve a la opción anterior y avisa',
        (tester) async {
      final service =
          _FakeService(inicial: inicialResumen, fallaAlGuardar: true);
      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('preferencia-inmediato')));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo guardar'), findsOneWidget);
      final resumen = tester.getSemantics(
          find.byKey(const ValueKey('preferencia-resumen')));
      expect(resumen, isSemantics(hasCheckedState: true, isChecked: true));
    });
  });
}
