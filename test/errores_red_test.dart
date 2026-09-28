// test/errores_red_test.dart
// Errores de red en español, sin host ni texto técnico (auditoría E2)
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.responder);
  final Future<ResponseBody> Function(RequestOptions) responder;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      responder(options);

  @override
  void close({bool force = false}) {}
}

_Adapter _fallaDeRed(DioExceptionType tipo) => _Adapter((o) async =>
    throw DioException(
      requestOptions: o,
      type: tipo,
      message: 'The connection errored: Failed host lookup: '
          "'educanexo360.creativebycode.com'",
    ));

Matcher _sinTextoTecnico() => allOf(
      isNot(contains('creativebycode')),
      isNot(contains('Failed host')),
      isNot(contains('connection errored')),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
  });

  Future<ApiException> errorDe(Future<Object?> Function() llamada) async {
    try {
      await llamada();
    } on ApiException catch (e) {
      return e;
    }
    fail('Se esperaba ApiException');
  }

  test('sin internet: mensaje en español, sin host', () async {
    ApiService().httpClientAdapter =
        _fallaDeRed(DioExceptionType.connectionError);

    final e = await errorDe(() => ApiService().get('/mensajes'));

    expect(e.statusCode, 0);
    expect(e.message, ApiService.mensajeSinConexion);
    expect(mensajeDeError(e, 'x'), ApiService.mensajeSinConexion);
    expect(mensajeDeError(e, 'x'), _sinTextoTecnico());
  });

  test('subida lenta (sendTimeout): mensaje propio', () async {
    ApiService().httpClientAdapter = _fallaDeRed(DioExceptionType.sendTimeout);

    final e = await errorDe(
        () => ApiService().postFormData('/tareas/t1/entregar', FormData()));

    expect(e.message, ApiService.mensajeSubidaLenta);
  });

  test('ningún tipo de error de red muestra el texto de Dio', () async {
    for (final tipo in DioExceptionType.values) {
      if (tipo == DioExceptionType.badResponse) continue; // requiere respuesta
      ApiService().httpClientAdapter = _fallaDeRed(tipo);
      final e = await errorDe(() => ApiService().get('/anuncios'));
      expect(e.message, _sinTextoTecnico(), reason: '$tipo');
      expect(ApiService.mensajesDeRed, contains(e.message), reason: '$tipo');
    }
  });

  test('mensajeDeError: texto del backend solo con statusCode > 0', () {
    final backend =
        ApiException(message: 'Tipo de archivo no permitido', statusCode: 400);
    expect(mensajeDeError(backend, 'x'), 'Tipo de archivo no permitido');

    final tecnico = ApiException(
        message: 'SocketException: Failed host lookup', statusCode: 0);
    expect(mensajeDeError(tecnico, 'Intenta de nuevo'), 'Intenta de nuevo');
  });

  test('message del backend que no es texto → mensaje genérico', () async {
    ApiService().httpClientAdapter = _Adapter((o) async => ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'message': ['campo inválido'],
          }),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ));

    final e = await errorDe(() => ApiService().get('/anuncios'));
    expect(e.statusCode, 400);
    expect(e.message, 'Error del servidor');
  });
}
