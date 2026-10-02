// test/etiqueta_tarea_test.dart
// G7: una tarea calificada o entregada no aparece como "Vencida"
import 'package:educanexo360_app/models/tarea.dart';
import 'package:educanexo360_app/widgets/tareas/tarea_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _tareaVencida = Tarea.fromJson({
  '_id': 't1',
  'titulo': 'Taller de fracciones',
  'descripcion': '',
  'fechaAsignacion': '2026-09-01T12:00:00.000Z',
  'fechaLimite': '2026-09-10T12:00:00.000Z', // ya pasó
});

EntregaTarea _entrega(String estado) => EntregaTarea.fromJson({
      '_id': 'e1',
      'estudianteId': 's1',
      'estado': estado,
      if (estado == 'CALIFICADA') 'calificacion': 4.5,
    });

void main() {
  test('etiqueta según la entrega', () {
    expect(_tareaVencida.etiquetaFechaLimite(_entrega('CALIFICADA')),
        'Calificada');
    expect(_tareaVencida.etiquetaFechaLimite(_entrega('ENTREGADA')),
        'Entregada');
    expect(
        _tareaVencida.etiquetaFechaLimite(_entrega('ATRASADA')), 'Entregada');
    expect(_tareaVencida.etiquetaFechaLimite(_entrega('PENDIENTE')), 'Vencida');
    expect(_tareaVencida.etiquetaFechaLimite(null), 'Vencida'); // docente
  });

  testWidgets('la tarjeta de una tarea calificada no dice "Vencida"',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TareaCard(
          tarea: _tareaVencida,
          miEntrega: _entrega('CALIFICADA'),
          onTap: () {},
        ),
      ),
    ));

    expect(find.text('Calificada'), findsWidgets);
    expect(find.text('Vencida'), findsNothing);
  });
}
