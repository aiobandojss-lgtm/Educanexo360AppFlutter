// test/entrega_acudiente_test.dart
// Entrega que ve el acudiente sin llamar a /mi-entrega (addendum Fase 2B)
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
          {'_id': 'e-$id', 'estudianteId': id, 'estado': 'ENTREGADA'},
      ],
    });

void main() {
  test('hermanos en el mismo curso: se muestra la entrega del hijo indicado',
      () {
    final tarea = _tareaConEntregas(['hijo1', 'hijo2']);
    expect(tarea.entregaParaAcudiente('hijo2')?.id, 'e-hijo2');
    expect(tarea.entregaParaAcudiente('hijo1')?.id, 'e-hijo1');
  });

  test('el hijo indicado no ha entregado: no se muestra la del hermano', () {
    final tarea = _tareaConEntregas(['hijo1']);
    expect(tarea.entregaParaAcudiente('hijo2'), isNull);
  });

  test('sin hijo indicado: la primera entrega', () {
    final tarea = _tareaConEntregas(['hijo1', 'hijo2']);
    expect(tarea.entregaParaAcudiente(null)?.id, 'e-hijo1');
  });

  test('sin entregas: null', () {
    expect(_tareaConEntregas([]).entregaParaAcudiente(null), isNull);
  });
}
