// test/evento_hora_fin_test.dart
// Crear evento a las 23:xx: la hora final por defecto no puede ser 24
import 'package:educanexo360_app/screens/calendario/create_evento_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a las 23:40 termina a las 00:00 del día siguiente', () {
    final fin = finPorDefectoEvento(DateTime(2026, 10, 2, 23, 40));
    expect(fin, DateTime(2026, 10, 3, 0, 0));
    // Antes: TimeOfDay(hour: 24) (aserción en debug, hora inválida en release)
    expect(TimeOfDay.fromDateTime(fin), const TimeOfDay(hour: 0, minute: 0));
  });

  test('en el último día del mes y del año también', () {
    expect(finPorDefectoEvento(DateTime(2026, 12, 31, 23, 5)),
        DateTime(2027, 1, 1));
  });

  test('a otra hora: la siguiente hora en punto del mismo día', () {
    expect(finPorDefectoEvento(DateTime(2026, 10, 2, 9, 15)),
        DateTime(2026, 10, 2, 10));
  });
}
