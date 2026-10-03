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

EntregaTarea _entrega(String estado, {bool entregada = false}) =>
    EntregaTarea.fromJson({
      '_id': 'e1',
      'estudianteId': 's1',
      'estado': estado,
      if (entregada) 'fechaEntrega': '2026-09-11T15:00:00.000Z',
      if (estado == 'CALIFICADA') 'calificacion': 4.5,
    });

void main() {
  test('etiqueta según la entrega', () {
    expect(_tareaVencida.etiquetaFechaLimite(_entrega('CALIFICADA')),
        'Calificada');
    expect(
        _tareaVencida
            .etiquetaFechaLimite(_entrega('ENTREGADA', entregada: true)),
        'Entregada');
    // J1: ATRASADA con fechaEntrega = entrega tardía
    expect(
        _tareaVencida
            .etiquetaFechaLimite(_entrega('ATRASADA', entregada: true)),
        'Entregada');
    // J1: ATRASADA sin fechaEntrega = nunca se entregó
    expect(_tareaVencida.etiquetaFechaLimite(_entrega('ATRASADA')), 'Vencida');
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

  // J1: el backend marca ATRASADA la entrega que venció sin entregarse
  test('ATRASADA sin fechaEntrega no cuenta como entregada', () {
    final nunca = _entrega('ATRASADA');
    final tarde = _entrega('ATRASADA', entregada: true);
    expect(nunca.yaEntregada, isFalse);
    expect(nunca.vencioSinEntregar, isTrue);
    expect(tarde.yaEntregada, isTrue);
    expect(tarde.vencioSinEntregar, isFalse);
    expect(_entrega('CALIFICADA').yaEntregada, isTrue);
    expect(_entrega('PENDIENTE').yaEntregada, isFalse);
  });

  testWidgets('la tarjeta de una tarea vencida sin entregar dice "Vencida" en rojo',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TareaCard(
          tarea: _tareaVencida,
          miEntrega: _entrega('ATRASADA'),
          onTap: () {},
        ),
      ),
    ));

    expect(find.text('Vencida'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });
}
