// test/destinatarios_total_test.dart
// Mensajes masivos con destinatarios recortados por el backend (auditoría A9)
import 'package:educanexo360_app/models/message.dart';
import 'package:educanexo360_app/widgets/messages/message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Map<String, dynamic> _mensaje({int? total, int visibles = 3}) => {
      '_id': 'm1',
      'remitente': {'_id': 'yo', 'nombre': 'Rectora', 'apellidos': 'Gómez'},
      'destinatarios': [
        for (var i = 0; i < visibles; i++)
          {'_id': 'd$i', 'nombre': 'Padre$i', 'apellidos': 'Ruiz'},
      ],
      'asunto': 'Circular',
      'contenido': 'Reunión general',
      'tipo': 'GRUPAL',
      'createdAt': '2026-09-26T12:00:00.000Z',
      'updatedAt': '2026-09-26T12:00:00.000Z',
      if (total != null) 'totalDestinatarios': total,
    };

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  test('cantidadDestinatarios usa totalDestinatarios si viene', () {
    expect(Message.fromJson(_mensaje(total: 250)).cantidadDestinatarios, 250);
  });

  test('sin totalDestinatarios (borradores, backend viejo) usa la lista', () {
    expect(Message.fromJson(_mensaje()).cantidadDestinatarios, 3);
  });

  test('totalDestinatarios tolerante: String numérico o valor inválido (B5)',
      () {
    final comoTexto = _mensaje()..['totalDestinatarios'] = '250';
    expect(Message.fromJson(comoTexto).cantidadDestinatarios, 250);

    final invalido = _mensaje()..['totalDestinatarios'] = 'muchos';
    expect(Message.fromJson(invalido).cantidadDestinatarios, 3);
  });

  test('totalDestinatarios NaN / Infinity no tumba el parseo (C2)', () {
    for (final raro in ['NaN', 'Infinity', '-Infinity', double.nan]) {
      final json = _mensaje()..['totalDestinatarios'] = raro;
      expect(Message.fromJson(json).cantidadDestinatarios, 3, reason: '$raro');
    }
  });

  testWidgets('enviados: muestra el primero y el resto con el total real',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MessageCard(
          message: Message.fromJson(_mensaje(total: 250)),
          bandeja: Bandeja.enviados,
          currentUserId: 'yo',
          onTap: () {},
        ),
      ),
    ));

    expect(find.text('Padre0 Ruiz y 249 más'), findsOneWidget);
  });
}
