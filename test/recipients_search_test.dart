// test/recipients_search_test.dart
// Búsqueda de destinatarios en el servidor (Fase 2B, ítem 2B.1)
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/models/message.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/message_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

User _user(String id, String nombre, {String tipo = 'DOCENTE'}) => User(
      id: id,
      nombre: nombre,
      apellidos: '',
      email: '${nombre.toLowerCase()}@colegio.co',
      tipo: tipo,
    );

class _DelayedAdapter implements HttpClientAdapter {
  final requestedQueries = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final q = options.queryParameters['q'] as String;
    requestedQueries.add(q);
    // La búsqueda vieja ('a') es lenta; la nueva ('ana') es rápida
    await Future<void>.delayed(Duration(milliseconds: q == 'a' ? 300 : 10));
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': [
          {
            '_id': 'id-$q',
            'nombre': q,
            'apellidos': '',
            'email': '',
            'tipo': 'DOCENTE'
          }
        ],
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

  group('mergeRecipients', () {
    final initial = [
      _user('1', 'Ana'),
      _user('2', 'Luis', tipo: 'ADMIN'),
    ];

    test('sin texto devuelve la lista inicial', () {
      expect(MessageService.mergeRecipients(initial, [], ''), initial);
    });

    test('incluye resultados del servidor fuera de la lista inicial', () {
      final remote = [_user('99', 'Anabel')];
      final ids = MessageService.mergeRecipients(initial, remote, 'ana')
          .map((u) => u.id);
      expect(ids, containsAll(['99', '1']));
    });

    test('sin duplicados cuando el servidor repite a alguien de la lista', () {
      final remote = [_user('1', 'Ana')];
      expect(MessageService.mergeRecipients(initial, remote, 'ana').length, 1);
    });

    test('la búsqueda por rol sigue funcionando (el servidor no la soporta)',
        () {
      final ids =
          MessageService.mergeRecipients(initial, [], 'admin').map((u) => u.id);
      expect(ids, ['2']);
    });
  });

  test('una búsqueda cancelada no devuelve resultados', () async {
    FlutterSecureStorage.setMockInitialValues({'@educanexo360_token': 't'});
    SharedPreferences.setMockInitialValues({});
    final adapter = _DelayedAdapter();
    ApiService().httpClientAdapter = adapter;
    final service = MessageService();

    final oldToken = CancelToken();
    final oldSearch = expectLater(
      service.searchRecipients('a', cancelToken: oldToken),
      throwsA(isA<ApiException>()),
    );
    oldToken.cancel();
    final newResults =
        await service.searchRecipients('ana', cancelToken: CancelToken());

    await oldSearch;
    expect(oldToken.isCancelled, isTrue);
    expect(newResults.single.id, 'id-ana');
  });
}
