// test/entrega_calificacion_test.dart
// La nota de una entrega nunca asume que CALIFICADA trae calificación (E6)
import 'package:educanexo360_app/models/tarea.dart';
import 'package:flutter_test/flutter_test.dart';

EntregaTarea _entrega({required String estado, num? calificacion}) =>
    EntregaTarea.fromJson({
      '_id': 'e1',
      'estudianteId': 's1',
      'estado': estado,
      if (calificacion != null) 'calificacion': calificacion,
    });

void main() {
  test('calificada con nota: muestra la nota sobre la máxima', () {
    final e = _entrega(estado: 'CALIFICADA', calificacion: 4.5);
    expect(e.textoCalificacion(5), 'Calificación: 4.5 / 5.0');
  });

  test('CALIFICADA sin nota (dato inconsistente): "Sin calificar", no falla',
      () {
    final e = _entrega(estado: 'CALIFICADA');
    expect(e.estaCalificada, isTrue);
    expect(e.calificacion, isNull);
    expect(e.textoCalificacion(5), 'Sin calificar');
  });

  test('re-entrega sobre una calificada (5.C12): ENTREGADA sin nota', () {
    final e = _entrega(estado: 'ENTREGADA');
    expect(e.estaCalificada, isFalse);
    expect(e.textoCalificacion(5), 'Sin calificar');
  });
}
