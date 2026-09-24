// test/session_generation_test.dart
// Respuestas que llegan después del logout (Fase 2B, ítem 2B.4)
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/session_generation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SlowAdapter implements HttpClientAdapter {
  _SlowAdapter(this.status);

  final int status;
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path.contains('/auth/refresh-token')) refreshCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return ResponseBody.fromString(
      jsonEncode({'success': status == 200, 'data': 'datos del usuario A'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// /mensajes responde 401 al instante; el refresh tarda 100 ms y falla
class _RefreshDuringLogoutAdapter implements HttpClientAdapter {
  bool refreshStarted = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path.contains('/auth/refresh-token')) {
      refreshStarted = true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'success': false}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// true si el Future se completó (con valor o con error) dentro del plazo
Future<bool> _completesWithin(Future<Object?> future, Duration limit) async {
  var completed = false;
  future.then((_) => completed = true, onError: (_) => completed = true);
  await Future<void>.delayed(limit);
  return completed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      '@educanexo360_token': 'a-access',
      '@educanexo360_refreshToken': 'a-refresh',
    });
    SharedPreferences.setMockInitialValues({});
  });

  test('respuesta que llega tras el logout se descarta (ni datos ni error)',
      () async {
    final api = ApiService()..httpClientAdapter = _SlowAdapter(200);

    final pending = api.get('/mensajes');
    // Logout mientras la petición ya está en vuelo
    await Future<void>.delayed(const Duration(milliseconds: 30));
    SessionGeneration.next();

    expect(await _completesWithin(pending, const Duration(milliseconds: 400)),
        isFalse);
  });

  test('un 401 de la sesión anterior no dispara refresh', () async {
    final adapter = _SlowAdapter(401);
    final api = ApiService()..httpClientAdapter = adapter;

    final pending = api.get('/mensajes');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    SessionGeneration.next();

    expect(await _completesWithin(pending, const Duration(milliseconds: 400)),
        isFalse);
    expect(adapter.refreshCalls, 0);
  });

  test('logout durante el refresh → la petición original se descarta',
      () async {
    final adapter = _RefreshDuringLogoutAdapter();
    final api = ApiService()..httpClientAdapter = adapter;

    final pending = api.get('/mensajes');
    // Esperar a que el refresh esté en vuelo y cerrar sesión
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(adapter.refreshStarted, isTrue);
    SessionGeneration.next();

    expect(await _completesWithin(pending, const Duration(milliseconds: 400)),
        isFalse);
  });

  test('las peticiones de la sesión nueva funcionan normal', () async {
    final api = ApiService()..httpClientAdapter = _SlowAdapter(200);
    SessionGeneration.next();

    final result = await api
        .get('/mensajes')
        .timeout(const Duration(seconds: 2));
    expect(result['success'], isTrue);
  });
}
