// test/models_parse_test.dart
// Referencias que pueden llegar con populate (Map), como id (String) o null
// (Fase 2A, ítem 2.9)
import 'package:educanexo360_app/models/asistencia_informes.dart';
import 'package:educanexo360_app/models/curso.dart';
import 'package:educanexo360_app/models/message.dart';
import 'package:educanexo360_app/models/ultimo_mensaje.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message.remitente', () {
    test('Map (populate)', () {
      final m = Message.fromJson({
        '_id': 'm1',
        'remitente': {'_id': 'u1', 'nombre': 'Ana', 'apellidos': 'Ruiz'},
      });
      expect(m.remitente.id, 'u1');
      expect(m.remitente.nombre, 'Ana');
    });

    test('String (sin populate)', () {
      final m = Message.fromJson({'_id': 'm1', 'remitente': 'u1'});
      expect(m.remitente.id, 'u1');
    });

    test('null', () {
      final m = Message.fromJson({'_id': 'm1', 'remitente': null});
      expect(m.remitente.id, '');
    });
  });

  test('UltimoMensaje.remitente como String no lanza', () {
    final u = UltimoMensaje.fromJson({'_id': 'm1', 'remitente': 'u1'});
    expect(u.remitente.iniciales, '??');
  });

  test('Curso.director_grupo como String o Map', () {
    expect(Curso.fromJson({'_id': 'c1', 'director_grupo': 'd1'})
        .directorGrupo
        ?.id, 'd1');
    expect(
        Curso.fromJson({
          '_id': 'c1',
          'director_grupo': {'_id': 'd1', 'nombre': 'Luis'}
        }).directorGrupo?.nombre,
        'Luis');
    expect(Curso.fromJson({'_id': 'c1'}).directorGrupo, isNull);
  });

  test('RegistroHistorial con referencias como String', () {
    final r = RegistroHistorial.fromJson({
      'curso': 'c1',
      'asignatura': 'a1',
      'registradoPor': 'd1',
    });
    expect(r.curso.id, 'c1');
    expect(r.asignatura?.id, 'a1');
    expect(r.registradoPor?.id, 'd1');
  });

  test('EstudianteRiesgo con curso null o String', () {
    expect(EstudianteRiesgo.fromJson({'curso': null}).curso.id, '');
    expect(EstudianteRiesgo.fromJson({'curso': 'c1'}).curso.id, 'c1');
  });
}
