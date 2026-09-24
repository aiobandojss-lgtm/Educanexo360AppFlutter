// test/multipart_upload_test.dart
// Subidas multipart: reintento tras 401, timeouts y progreso (Fase 2B, 2B.3)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _UploadAdapter implements HttpClientAdapter {
  final uploadBytes = <int>[];
  final uploadSendTimeouts = <Duration?>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (options.path.contains('/auth/refresh-token')) {
      return _json(200, {
        'success': true,
        'data': {
          'access': {'token': 'new-access'},
          'refresh': {'token': 'new-refresh'},
        },
      });
    }

    // Consumir el cuerpo como lo haría la red
    var bytes = 0;
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes += chunk.length;
      }
    }
    uploadBytes.add(bytes);
    uploadSendTimeouts.add(options.sendTimeout);

    // Primer intento: token vencido
    if (uploadBytes.length == 1) {
      return _json(401, {'success': false, 'message': 'Token expirado'});
    }
    return _json(200, {'success': true, 'data': 'ok'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('subida multipart con 401 → refresh y reintento con el archivo completo',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      '@educanexo360_token': 'old-access',
      '@educanexo360_refreshToken': 'old-refresh',
    });
    SharedPreferences.setMockInitialValues({});
    final adapter = _UploadAdapter();
    final api = ApiService()..httpClientAdapter = adapter;

    final tempDir = await Directory.systemTemp.createTemp('upload_test');
    final file = File('${tempDir.path}/entrega.pdf')
      ..writeAsBytesSync(List.filled(50 * 1024, 7));

    final formData = FormData();
    formData.files.add(MapEntry(
      'archivos',
      await MultipartFile.fromFile(file.path, filename: 'entrega.pdf'),
    ));

    var lastSent = 0;
    var lastTotal = 0;
    final result = await api.postFormData(
      '/tareas/t1/entregar',
      formData,
      onSendProgress: (sent, total) {
        lastSent = sent;
        lastTotal = total;
      },
    ).timeout(const Duration(seconds: 5));

    expect(result['success'], isTrue);
    expect(adapter.uploadBytes.length, 2); // original + un reintento
    expect(adapter.uploadBytes[1], adapter.uploadBytes[0]);
    expect(adapter.uploadBytes[1], greaterThan(50 * 1024));
    expect(adapter.uploadSendTimeouts,
        everyElement(const Duration(seconds: 120)));
    expect(lastTotal, greaterThan(0));
    expect(lastSent, lastTotal);

    await tempDir.delete(recursive: true);
  });
}
