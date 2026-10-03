// test/markdown_texto_test.dart
// J6: los anuncios se ven como Markdown, igual que en la web (ReactMarkdown)
import 'package:educanexo360_app/utils/markdown_texto.dart';
import 'package:educanexo360_app/widgets/common/contenido_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Anuncio típico escrito en la web
const _anuncio = '''# Salida pedagógica

Los estudiantes de **grado 5** visitarán el *Museo del Oro*.

## Llevar

- Uniforme de diario
- Merienda

1. Firmar la autorización
2. Entregarla al director de grupo

> Salida: 7:00 a. m.

Más información en [la página del colegio](https://colegio.edu.co/salidas?grado=5&dia=lunes).''';

void main() {
  test('párrafos, títulos, listas y cita sin los signos de Markdown', () {
    expect(markdownATexto(_anuncio), '''Salida pedagógica

Los estudiantes de grado 5 visitarán el Museo del Oro.

Llevar

• Uniforme de diario
• Merienda

1. Firmar la autorización
2. Entregarla al director de grupo

Salida: 7:00 a. m.

Más información en la página del colegio.''');
  });

  test('negritas, cursivas, títulos, citas y enlaces se marcan', () {
    final s = segmentosMarkdown(_anuncio);
    final titulo = s.firstWhere((x) => x.texto == 'Salida pedagógica');
    expect(titulo.titulo, isTrue);
    expect(titulo.negrita, isTrue);
    expect(s.firstWhere((x) => x.texto == 'grado 5').negrita, isTrue);
    expect(s.firstWhere((x) => x.texto == 'Museo del Oro').cursiva, isTrue);
    expect(s.firstWhere((x) => x.texto.contains('7:00')).cita, isTrue);
    expect(s.firstWhere((x) => x.texto == 'la página del colegio').enlace,
        'https://colegio.edu.co/salidas?grado=5&dia=lunes');
  });

  test('texto plano escrito en la app (válido como Markdown)', () {
    // Un salto simple es un espacio, como en la web; la línea en blanco
    // separa párrafos
    expect(markdownATexto('Reunión el lunes\na las 7.\n\nGracias'),
        'Reunión el lunes a las 7.\n\nGracias');
    // Un correo entre <> es un enlace de correo, no desaparece
    final s = segmentosMarkdown('Escribir a <coordinacion@colegio.edu>');
    expect(markdownATexto('Escribir a <coordinacion@colegio.edu>'),
        'Escribir a coordinacion@colegio.edu');
    expect(s.last.enlace, 'mailto:coordinacion@colegio.edu');
  });

  test('sin imágenes remotas ni HTML embebido', () {
    expect(markdownATexto('Antes ![logo](https://x.co/a.png) después'),
        'Antes después');
    final s = segmentosMarkdown('Hola <b onclick="x()">mundo</b> '
        '<script>alert(1)</script>');
    expect(s.map((x) => x.texto).join(), 'Hola mundo alert(1)');
    expect(s.any((x) => x.negrita), isFalse); // <b> no se interpreta
    expect(markdownATexto('<div>\nBloque\n</div>'), 'Bloque');
  });

  test('el texto escrito con < y & se muestra literal', () {
    expect(markdownATexto('Notas < 3.0 & faltas'), 'Notas < 3.0 & faltas');
  });

  test('vacío → vacío', () {
    expect(segmentosMarkdown('  \n '), isEmpty);
  });

  testWidgets('ContenidoHtml.markdown: enlace permitido subrayado, '
      'javascript: queda como texto', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ContenidoHtml.markdown(
            '**Hola** [sitio](https://colegio.edu.co) y [malo](javascript:alert(1))'),
      ),
    ));
    final raiz = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
    final spans = raiz.children!.cast<TextSpan>();
    expect(raiz.toPlainText(), 'Hola sitio y malo');
    expect(spans.firstWhere((t) => t.text == 'Hola').style!.fontWeight,
        FontWeight.bold);
    expect(spans.firstWhere((t) => t.text == 'sitio').recognizer, isNotNull);
    final malo = spans.firstWhere((t) => t.text == 'malo');
    expect(malo.recognizer, isNull);
    expect(malo.style!.decoration, isNull);
  });

  test('la web: el anuncio no muestra **, #, - ni > (antes se veían)', () {
    final texto = markdownATexto(_anuncio);
    for (final signo in ['**', '# ', '- ', '> ', '](']) {
      expect(texto, isNot(contains(signo)), reason: signo);
    }
  });
}
