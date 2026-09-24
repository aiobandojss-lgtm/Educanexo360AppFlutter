// test/cursos_conteos_test.dart
// Conteo de asignaturas sin N+1 (Fase 2B, ítem 2B.2)
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/models/curso.dart';
import 'package:educanexo360_app/providers/curso_provider.dart';
import 'package:educanexo360_app/services/api_service.dart';
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

class _CursosAdapter implements HttpClientAdapter {
  int enVuelo = 0;
  int maxEnVuelo = 0;
  int peticionesConteo = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path == '/cursos') {
      return _json({
        'success': true,
        'data': List.generate(
            12, (i) => {'_id': 'c$i', 'nombre': 'Curso $i', 'escuelaId': 'e'}),
      });
    }
    // /cursos/:id/asignaturas
    peticionesConteo++;
    enVuelo++;
    if (enVuelo > maxEnVuelo) maxEnVuelo = enVuelo;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    enVuelo--;
    return _json({
      'success': true,
      'data': [
        {'_id': 'a1'},
        {'_id': 'a2'},
      ],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('los conteos se cargan después de la lista y con máximo 4 a la vez',
      () async {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
    final adapter = _CursosAdapter();
    ApiService().httpClientAdapter = adapter;

    final provider = CursoProvider();
    await provider.loadCursos();

    // La lista está disponible de inmediato, antes de los conteos
    expect(provider.cursos.length, 12);

    // Esperar a que lleguen todos los conteos
    for (var i = 0; i < 100; i++) {
      if (provider.cursos.every((c) => c.asignaturasCount != null)) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(provider.cursos.every((c) => c.asignaturasCount == 2), isTrue);
    expect(adapter.peticionesConteo, 12);
    expect(adapter.maxEnVuelo, lessThanOrEqualTo(4));
  });

  test('Curso.fromJson usa asignaturasCount/estudiantesCount si vienen', () {
    final curso = Curso.fromJson({
      '_id': 'c1',
      'asignaturasCount': 7,
      'estudiantesCount': 30,
    });
    expect(curso.totalAsignaturas, 7);
    expect(curso.totalEstudiantes, 30);
  });

  test('Curso.fromJson tolera estudiantes sin populate (ids)', () {
    final curso = Curso.fromJson({
      '_id': 'c1',
      'estudiantes': ['e1', 'e2', 'e3'],
    });
    expect(curso.totalEstudiantes, 3);
  });
}
