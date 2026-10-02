// test/fechas_test.dart
// Zona horaria (G1): instantes en UTC ↔ hora local; fechas sin hora tal cual.
// Las pruebas "Bogotá" corren cuando el sistema está en UTC-5 (America/Bogota)
// y se saltan en otra zona; las invariantes valen en cualquier zona.
import 'package:educanexo360_app/models/asistencia.dart';
import 'package:educanexo360_app/models/message.dart';
import 'package:educanexo360_app/utils/fechas.dart';
import 'package:flutter_test/flutter_test.dart';

final _esBogota =
    DateTime(2026, 10, 1).timeZoneOffset == const Duration(hours: -5);
final _skipNoBogota = _esBogota ? false : 'El sistema no está en UTC-5';

void main() {
  group('invariantes (cualquier zona)', () {
    test('fechaLocal devuelve hora local del mismo instante', () {
      final f = fechaLocal('2026-10-02T03:35:00.000Z');
      expect(f.isUtc, isFalse);
      expect(f.toUtc(), DateTime.utc(2026, 10, 2, 3, 35));
    });

    test('fechaParaEnviar siempre en UTC con Z y conserva el instante', () {
      final local = DateTime(2026, 10, 10, 14, 30);
      final enviado = fechaParaEnviar(local);
      expect(enviado.endsWith('Z'), isTrue);
      expect(DateTime.parse(enviado), local.toUtc());
    });

    test('ida y vuelta: lo que se envía se lee como la misma hora local', () {
      final local = DateTime(2026, 10, 10, 7, 0);
      expect(fechaLocal(fechaParaEnviar(local)), local);
    });

    test('fecha sin hora: medianoche UTC NO se corre al día anterior', () {
      final f = soloFecha('2026-10-01T00:00:00.000Z');
      expect([f.year, f.month, f.day], [2026, 10, 1]);
      expect(soloFecha('2026-10-01'), DateTime(2026, 10, 1));
      expect(soloFechaOpcional('x'), isNull);
      expect(soloFechaOpcional(null), isNull);
    });

    test('soloFechaParaEnviar usa el día local', () {
      expect(soloFechaParaEnviar(DateTime(2026, 10, 1, 23, 59)), '2026-10-01');
      expect(soloFechaParaEnviar(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('asistencia: la fecha del registro es el día que envió el servidor',
        () {
      final registro = RegistroAsistencia.fromJson({
        '_id': 'r1',
        'fecha': '2026-10-01T00:00:00.000Z',
        'cursoId': 'c1',
        'estudiantes': [],
      });
      expect([registro.fecha.year, registro.fecha.month, registro.fecha.day],
          [2026, 10, 1]);
    });
  });

  group('Bogotá (UTC-5)', () {
    test('mensaje enviado el 1/10 22:35 en Colombia se muestra 1/10 22:35',
        () {
      // El servidor lo guarda como 2026-10-02T03:35Z (antes se mostraba el 2/10)
      final m = Message.fromJson({
        '_id': 'm1',
        'remitente': 'u1',
        'createdAt': '2026-10-02T03:35:00.000Z',
        'updatedAt': '2026-10-02T03:35:00.000Z',
      });
      expect([m.createdAt.day, m.createdAt.hour, m.createdAt.minute],
          [1, 22, 35]);
    }, skip: _skipNoBogota);

    test('evento "todo el día" del 10 se envía 05:00Z y 23:59 local', () {
      // Convención de la web: medianoche local → 05:00Z; fin 23:59 local
      expect(fechaParaEnviar(DateTime(2026, 10, 10)), '2026-10-10T05:00:00.000Z');
      expect(fechaParaEnviar(DateTime(2026, 10, 10, 23, 59)),
          '2026-10-11T04:59:00.000Z');
      // Y al leerlo vuelve a ser el día 10 (antes la web mostraba el 9)
      expect(fechaLocal('2026-10-10T05:00:00.000Z').day, 10);
    }, skip: _skipNoBogota);
  });
}
