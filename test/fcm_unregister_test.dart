// test/fcm_unregister_test.dart
// Desvinculación del token FCM al cerrar sesión (addendum Fase 2B)
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/auth_service.dart';
import 'package:educanexo360_app/services/fcm_service.dart';
import 'package:educanexo360_app/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ResponseBody _json(Object body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Backend lento: la desvinculación tarda 300 ms en responder
class _SlowUnregisterAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final completed = Completer<void>();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!completed.isCompleted) completed.complete();
    return _json({
      'success': true,
      'message': 'Dispositivo desvinculado',
      'data': {'tokenRemoved': true},
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Backend principal: responde al instante y cuenta los registros de token
class _OkAdapter implements HttpClientAdapter {
  final registeredTokens = <Object?>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path.contains('/notificaciones/register-token')) {
      registeredTokens.add((options.data as Map)['fcmToken']);
    }
    return _json({'success': true});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Valores originales del singleton: cada prueba los restablece al terminar
  final timeoutOriginal = FcmService.instance.pendingUnregisterTimeout;
  tearDown(() {
    FcmService.instance
      ..pendingUnregisterTimeout = timeoutOriginal
      ..debugTokenOverride = null;
  });

  test(
      'logout limpia lo local de inmediato y desvincula el token en segundo '
      'plano con el token de la sesión que se cierra', () async {
    FlutterSecureStorage.setMockInitialValues({
      '@educanexo360_token': 'old-access',
      '@educanexo360_refreshToken': 'old-refresh',
    });
    SharedPreferences.setMockInitialValues({});
    ApiService().httpClientAdapter = _OkAdapter();

    final adapter = _SlowUnregisterAdapter();
    FcmService.instance
      ..unregisterHttpClientAdapter = adapter
      ..debugTokenOverride = () async => 'fcm-token-123';

    await AuthService().logout(silent: true);

    // El logout ya volvió: lo local está limpio y la desvinculación sigue en
    // curso (no bloqueó la navegación al login)
    expect(await StorageService.getToken(), isNull);
    expect(await StorageService.getRefreshToken(), isNull);
    expect(adapter.completed.isCompleted, isFalse);

    // La desvinculación termina después, en segundo plano
    await FcmService.instance.pendingUnregister!
        .timeout(const Duration(seconds: 2));
    expect(adapter.completed.isCompleted, isTrue);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/notificaciones/unregister-token');
    expect(request.headers['Authorization'], 'Bearer old-access');
    expect(request.data, {'fcmToken': 'fcm-token-123'});
  });

  test(
      'sesión expirada: con el storage ya borrado se desvincula con el token '
      'capturado', () async {
    FlutterSecureStorage.setMockInitialValues({}); // ApiService ya lo borró
    SharedPreferences.setMockInitialValues({});
    ApiService().httpClientAdapter = _OkAdapter();

    final adapter = _SlowUnregisterAdapter();
    final fcm = FcmService.instance;
    fcm.unregisterHttpClientAdapter = adapter;
    fcm.debugTokenOverride = () async => 'fcm-token-123';

    await AuthService()
        .logout(silent: true, accessTokenOverride: 'expired-access');
    await fcm.pendingUnregister!.timeout(const Duration(seconds: 2));

    expect(adapter.requests.single.headers['Authorization'],
        'Bearer expired-access');
  });

  test(
      'login de otro usuario durante una desvinculación lenta: no registra el '
      'token viejo; registra al terminar la desvinculación', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final backend = _OkAdapter();
    ApiService().httpClientAdapter = backend;

    final unregister = _SlowUnregisterAdapter(); // tarda 300 ms
    final fcm = FcmService.instance;
    fcm.unregisterHttpClientAdapter = unregister;
    fcm.debugTokenOverride = () async => 'fcm-token-123';
    fcm.pendingUnregisterTimeout = const Duration(milliseconds: 50);

    // Logout de A (la desvinculación queda en curso)
    unawaited(FcmService.instance.unregisterDevice(accessToken: 'a-access'));

    // B inicia sesión mientras tanto
    await StorageService.saveToken('b-access');
    await FcmService.instance.registerTokenToBackend();

    // La espera expiró: no se registró el token viejo
    expect(unregister.completed.isCompleted, isFalse);
    expect(backend.registeredTokens, isEmpty);

    // Al terminar la desvinculación se registra (una sola vez)
    await FcmService.instance.pendingUnregister!
        .timeout(const Duration(seconds: 2));
    for (var i = 0; i < 50 && backend.registeredTokens.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(backend.registeredTokens, ['fcm-token-123']);

    // Margen después del primer registro: no debe haber un segundo
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(backend.registeredTokens, hasLength(1));
  });
}
