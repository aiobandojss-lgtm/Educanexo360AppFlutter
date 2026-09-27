// test/entrega_acudiente_test.dart
// Entregas que ve el acudiente sin llamar a /mi-entrega (addendum 2B y A6)
import 'package:educanexo360_app/models/tarea.dart';
import 'package:flutter_test/flutter_test.dart';

Tarea _tareaConEntregas(List<String> estudiantes) => Tarea.fromJson({
      '_id': 't1',
      'titulo': 'Taller',
      'descripcion': '',
      'fechaAsignacion': '2026-09-01T00:00:00.000Z',
      'fechaLimite': '2026-09-30T00:00:00.000Z',
      'entregas': [
        for (final id in estudiantes)
          {
            '_id': 'e-$id',
            'estudianteId': {'_id': id, 'nombre': 'Nombre $id', 'apellidos': ''},
            'estado': 'ENTREGADA',
          },
      ],
    });

List<String?> _ids(List<EntregaTarea> entregas) =>
    entregas.map((e) => e.id).toList();

void main() {
  test('hermanos en el mismo curso: con hijo indicado, solo su entrega', () {
    final tarea = _tareaConEntregas(['hijo1', 'hijo2']);
    expect(_ids(tarea.entregasParaAcudiente('hijo2')), ['e-hijo2']);
    expect(_ids(tarea.entregasParaAcudiente('hijo1')), ['e-hijo1']);
  });

  test('el hijo indicado no ha entregado: no se muestra la del hermano', () {
    final tarea = _tareaConEntregas(['hijo1']);
    expect(tarea.entregasParaAcudiente('hijo2'), isEmpty);
  });

  test(
      'sin hijo indicado (notificación/dashboard) y hermanos: todas las '
      'entregas, cada una con su estudiante (A6)', () {
    final entregas =
        _tareaConEntregas(['hijo1', 'hijo2']).entregasParaAcudiente(null);
    expect(_ids(entregas), ['e-hijo1', 'e-hijo2']);
    expect(entregas.map((e) => e.estudiante?.nombre),
        ['Nombre hijo1', 'Nombre hijo2']);
  });

  test('sin hijo indicado y un solo hijo: esa entrega', () {
    expect(_ids(_tareaConEntregas(['hijo1']).entregasParaAcudiente(null)),
        ['e-hijo1']);
  });

  test('sin entregas: lista vacía', () {
    expect(_tareaConEntregas([]).entregasParaAcudiente(null), isEmpty);
  });
}
