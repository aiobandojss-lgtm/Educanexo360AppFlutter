// test/api_service_refresh_test.dart
// Pruebas del flujo de renovación de token (Fase 2A, ítem 2.2)
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptador HTTP falso: cada prueba define cómo responde el "servidor".
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  int refreshCalls = 0;
  int protectedCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (options.path.contains('/auth/refresh-token')) {
      refreshCalls++;
    } else {
      protectedCalls++;
    }
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody unauthorized() =>
    jsonResponse(401, {'success': false, 'message': 'No autorizado'});

ResponseBody refreshOk() => jsonResponse(200, {
      'success': true,
      'data': {
        'access': {'token': 'new-access', 'expires': '1d'},
        'refresh': {'token': 'new-refresh', 'expires': '7d'},
      },
    });

const _timeout = Duration(seconds: 5);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final api = ApiService();
  late int sessionExpiredCalls;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      '@educanexo360_token': 'old-access',
      '@educanexo360_refreshToken': 'old-refresh',
    });
    SharedPreferences.setMockInitialValues({});
    sessionExpiredCalls = 0;
    ApiService.onSessionExpired = () => sessionExpiredCalls++;
  });

  test('(a) refresh rechazado con 401 → sesión expirada, sin colgarse',
      () async {
    final adapter = FakeAdapter((o) async => unauthorized());
    api.httpClientAdapter = adapter;

    await expectLater(
      api.get('/tareas').timeout(_timeout),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)),
    );

    expect(adapter.refreshCalls, 1);
    expect(sessionExpiredCalls, 1);
    expect(await StorageService.getToken(), isNull);
    expect(await StorageService.getRefreshToken(), isNull);
  });

  test('(b) tres 401 simultáneos → un solo refresh y las tres se reintentan',
      () async {
    final adapter = FakeAdapter((o) async {
      if (o.path.contains('/auth/refresh-token')) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return refreshOk();
      }
      if (o.headers['Authorization'] == 'Bearer new-access') {
        return jsonResponse(200, {'success': true, 'data': o.path});
      }
      return unauthorized();
    });
    api.httpClientAdapter = adapter;

    final results = await Future.wait([
      api.get('/tareas'),
      api.get('/mensajes'),
      api.get('/anuncios'),
    ]).timeout(_timeout);

    expect(results.map((r) => r['data']),
        ['/tareas', '/mensajes', '/anuncios']);
    expect(adapter.refreshCalls, 1);
    expect(sessionExpiredCalls, 0);
    expect(await StorageService.getToken(), 'new-access');
    expect(await StorageService.getRefreshToken(), 'new-refresh');
  });

  test('(c) el reintento vuelve a dar 401 → no hay bucle', () async {
    final adapter = FakeAdapter((o) async {
      if (o.path.contains('/auth/refresh-token')) return refreshOk();
      return unauthorized();
    });
    api.httpClientAdapter = adapter;

    await expectLater(
      api.get('/tareas').timeout(_timeout),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)),
    );

    expect(adapter.refreshCalls, 1);
    expect(adapter.protectedCalls, 2); // original + un único reintento
    expect(sessionExpiredCalls, 0);
  });

  test('(d) refresh falla por timeout → se conserva la sesión', () async {
    final adapter = FakeAdapter((o) async {
      if (o.path.contains('/auth/refresh-token')) {
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionTimeout,
        );
      }
      return unauthorized();
    });
    api.httpClientAdapter = adapter;

    await expectLater(
      api.get('/tareas').timeout(_timeout),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 0)
          .having((e) => e.message, 'message', contains('Tiempo de espera'))),
    );

    expect(adapter.refreshCalls, 1);
    expect(sessionExpiredCalls, 0);
    expect(await StorageService.getToken(), 'old-access');
    expect(await StorageService.getRefreshToken(), 'old-refresh');

    // El siguiente intento vuelve a probar el refresh (no quedó bloqueado)
    await expectLater(
        api.get('/tareas').timeout(_timeout), throwsA(isA<ApiException>()));
    expect(adapter.refreshCalls, 2);
  });

  test('(e) refresh responde 500 → se conserva la sesión', () async {
    final adapter = FakeAdapter((o) async {
      if (o.path.contains('/auth/refresh-token')) {
        return jsonResponse(500, {'success': false, 'message': 'Error'});
      }
      return unauthorized();
    });
    api.httpClientAdapter = adapter;

    await expectLater(
      api.get('/tareas').timeout(_timeout),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 500)),
    );

    expect(sessionExpiredCalls, 0);
    expect(await StorageService.getToken(), 'old-access');
    expect(await StorageService.getRefreshToken(), 'old-refresh');
  });

  test('(f) refresh 200 con success:false → sesión expirada', () async {
    final adapter = FakeAdapter((o) async {
      if (o.path.contains('/auth/refresh-token')) {
        return jsonResponse(200, {'success': false});
      }
      return unauthorized();
    });
    api.httpClientAdapter = adapter;

    await expectLater(
        api.get('/tareas').timeout(_timeout), throwsA(isA<ApiException>()));

    expect(sessionExpiredCalls, 1);
    expect(await StorageService.getToken(), isNull);
  });
}
