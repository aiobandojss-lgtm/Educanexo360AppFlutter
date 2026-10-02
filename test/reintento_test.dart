// test/reintento_test.dart
// G6: reintento automático único ante timeout o error de red
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/providers/asistencia_provider.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/utils/reintento.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _red = ApiException(message: ApiService.mensajeTiempoAgotado, statusCode: 0);

/// La primera petición expira; la segunda responde con estadísticas
class _PrimeraExpira implements HttpClientAdapter {
  int peticiones = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    peticiones++;
    if (peticiones == 1) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.receiveTimeout);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'estudiante': {'nombre': 'Hijo', 'apellidos': 'Uno'},
          'estadisticas': {'totalClases': 10, 'presentes': 9, 'ausentes': 1},
          'registros': [],
        },
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sinEspera = Duration.zero;

  test('error de red: reintenta una vez y devuelve el resultado', () async {
    var intentos = 0;
    final r = await conReintentoUnico(() async {
      intentos++;
      if (intentos == 1) throw _red;
      return 'ok';
    }, espera: sinEspera);
    expect(r, 'ok');
    expect(intentos, 2);
  });

  test('error del servidor (500): no reintenta', () async {
    var intentos = 0;
    await expectLater(
      conReintentoUnico(() async {
        intentos++;
        throw ApiException(message: 'Error del servidor', statusCode: 500);
      }, espera: sinEspera),
      throwsA(isA<ApiException>()),
    );
    expect(intentos, 1);
  });

  test('dos errores de red seguidos: un solo reintento y luego el error',
      () async {
    var intentos = 0;
    await expectLater(
      conReintentoUnico(() async {
        intentos++;
        throw _red;
      }, espera: sinEspera),
      throwsA(isA<ApiException>()),
    );
    expect(intentos, 2);
  });

  test('asistencia del acudiente: la primera expira y aun así carga (G6)',
      () async {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
    final backend = _PrimeraExpira();
    ApiService().httpClientAdapter = backend;

    final provider = AsistenciaProvider();
    await provider.cargarMiAsistencia(
      estudianteId: 'h1',
      desde: '2026-01-01',
      hasta: '2026-10-01',
      refresh: true,
    );

    expect(backend.peticiones, 2);
    expect(provider.error, isNull);
    expect(provider.estadisticasEstudiante.totalClases, 10);
  });
}
