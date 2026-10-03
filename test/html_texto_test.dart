// test/html_texto_test.dart
// G8: el contenido HTML de la web se ve con sus párrafos en la app, y lo que
// la app envía se ve con sus saltos de línea en la web.
import 'package:educanexo360_app/utils/html_texto.dart';
import 'package:educanexo360_app/widgets/common/contenido_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Plantilla exacta con la que la web cita al responder (NuevoMensaje.tsx)
const _respuestaDesdeLaWeb = '''Gracias, nos vemos el lunes.
              <br><br>
              <p>--------- Mensaje Original ---------</p>
              <p><strong>De:</strong> Rectoría Colegio</p>
              <p><strong>Fecha:</strong> 1/10/2026, 10:35:00 p.m.</p>
              <p><strong>Asunto:</strong> Reunión de padres</p>
              <blockquote style="border-left: 2px solid #ccc; padding-left: 10px; color: #555;">
                <p>Los esperamos el lunes a las 7 a.m.</p>
              </blockquote>
            ''';

void main() {
  test('la cita de la web sale en líneas separadas, no pegada', () {
    final texto = htmlATexto(_respuestaDesdeLaWeb);
    final lineas = texto.split('\n').where((l) => l.trim().isNotEmpty).toList();

    expect(lineas, [
      'Gracias, nos vemos el lunes.',
      '--------- Mensaje Original ---------',
      'De: Rectoría Colegio',
      'Fecha: 1/10/2026, 10:35:00 p.m.',
      'Asunto: Reunión de padres',
      'Los esperamos el lunes a las 7 a.m.',
    ]);
  });

  test('negritas, citas y enlaces se marcan en los segmentos', () {
    final segmentos = segmentosHtml(
        '<p><strong>De:</strong> Ana</p><blockquote>Hola</blockquote>'
        '<p>Ver <a href="https://colegio.edu.co">aquí</a></p>');
    expect(segmentos.firstWhere((s) => s.texto == 'De:').negrita, isTrue);
    expect(segmentos.firstWhere((s) => s.texto.contains('Hola')).cita, isTrue);
    expect(segmentos.firstWhere((s) => s.texto == 'aquí').enlace,
        'https://colegio.edu.co');
    // El espacio antes del enlace no queda como parte del enlace
    expect(segmentos.where((s) => s.enlace != null).map((s) => s.texto),
        ['aquí']);
  });

  test('el enlace decodifica &amp; (parámetros de Google Forms/YouTube)', () {
    final segmentos = segmentosHtml(
        '<p><a href="https://docs.google.com/forms/d/x/viewform?usp=sf_link&amp;entry.1=Ana">'
        'Formulario</a></p>');
    expect(segmentos.single.enlace,
        'https://docs.google.com/forms/d/x/viewform?usp=sf_link&entry.1=Ana');
    expect(Uri.parse(segmentos.single.enlace!).queryParameters['entry.1'],
        'Ana');
  });

  test('listas con viñetas y entidades decodificadas', () {
    expect(htmlATexto('<ul><li>Uno</li><li>Dos &amp; tres</li></ul>'),
        '• Uno\n• Dos & tres');
  });

  test('texto plano de versiones anteriores de la app conserva sus saltos',
      () {
    expect(htmlATexto('Hola\nsegunda línea'), 'Hola\nsegunda línea');
  });

  test('lo que la app envía: HTML seguro que la web muestra con saltos', () {
    const escrito = 'Buenos días,\nmañana no hay clase.\n\nAtentamente,\nRectoría';
    final html = textoAHtml(escrito);
    expect(html,
        '<p>Buenos días,<br>mañana no hay clase.</p><p>Atentamente,<br>Rectoría</p>');
    // Ida y vuelta: la app lo vuelve a mostrar igual
    expect(htmlATexto(html), escrito);
  });

  test('el texto escrito no puede inyectar HTML', () {
    final html = textoAHtml('<script>alert(1)</script> & <b>hola</b>');
    expect(html, contains('&lt;script&gt;'));
    expect(html, isNot(contains('<script>')));
    expect(html, isNot(contains('<b>')));
    expect(htmlATexto(html), '<script>alert(1)</script> & <b>hola</b>');
  });

  test('vacío → vacío', () {
    expect(textoAHtml('   '), '');
    expect(htmlATexto(''), '');
  });

  testWidgets('ContenidoHtml muestra la cita de la web con sus líneas',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ContenidoHtml(_respuestaDesdeLaWeb)),
    ));
    final texto = tester.widget<Text>(find.byType(Text)).textSpan!.toPlainText();
    // Entre párrafos una línea en blanco (como el margen de <p> en la web)
    expect(texto, contains('Mensaje Original ---------\n\nDe: Rectoría'));
    expect(texto, contains('Asunto: Reunión de padres\n\nLos esperamos'));
  });
}
