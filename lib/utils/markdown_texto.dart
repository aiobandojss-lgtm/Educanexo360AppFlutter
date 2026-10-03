// lib/utils/markdown_texto.dart
//
// Anuncios en Markdown (J6). La web los guarda y muestra como Markdown con
// ReactMarkdown sin plugins (DetalleAnuncio.tsx): CommonMark, sin GFM y sin
// HTML crudo. La app los interpreta igual con el paquete oficial `markdown`
// de dart-lang (solo el parser; nada de WebView) y produce los mismos
// segmentos con estilo que el HTML de los mensajes (html_texto.dart):
// párrafos, negritas, cursivas, títulos, listas, citas y enlaces.
// - Imágenes: no se cargan (nada remoto).
// - HTML embebido: no se interpreta; se quitan las etiquetas y queda su texto.
// - Un salto de línea simple vale como espacio (igual que en la web); una
//   línea en blanco separa párrafos.

import 'package:markdown/markdown.dart' as md;

import 'html_texto.dart';

// Un '<' real en un nodo de texto solo puede ser HTML crudo: con encodeHtml
// el texto escrito llega escapado (&lt;)
final _htmlCrudo = RegExp(r'<[^>]*>');

/// Interpreta [texto] (Markdown) en segmentos con estilo.
List<SegmentoHtml> segmentosMarkdown(String texto) {
  final limpio = texto.replaceAll('\r\n', '\n').trim();
  if (limpio.isEmpty) return const [];

  // CommonMark como ReactMarkdown (sin las extensiones de GitHub)
  final nodos = md.Document(encodeHtml: true).parse(limpio);

  final segmentos = <SegmentoHtml>[];
  var negrita = 0, cursiva = 0, cita = 0, titulo = 0, preformateado = 0;
  String? enlace;
  // Listas abiertas: null = con viñetas, número = numerada
  final listas = <int?>[];

  void agregar(String t) {
    if (t.isEmpty) return;
    segmentos.add(SegmentoHtml(
      t,
      negrita: negrita > 0,
      cursiva: cursiva > 0,
      cita: cita > 0,
      titulo: titulo > 0,
      enlace: enlace,
    ));
  }

  void recorrer(md.Node nodo) {
    if (nodo is md.Text) {
      var t = decodificarEntidades(nodo.text.replaceAll(_htmlCrudo, ''));
      if (preformateado == 0) t = t.replaceAll('\n', ' ');
      agregar(t);
      return;
    }
    if (nodo is! md.Element) {
      agregar(nodo.textContent);
      return;
    }
    void hijos() => nodo.children?.forEach(recorrer);

    switch (nodo.tag) {
      case 'p':
        agregar('\n');
        hijos();
        agregar('\n\n');
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final grande = const {'h1', 'h2', 'h3'}.contains(nodo.tag);
        agregar('\n');
        negrita++;
        if (grande) titulo++;
        hijos();
        negrita--;
        if (grande) titulo--;
        agregar('\n\n');
      case 'blockquote':
        agregar('\n');
        cita++;
        hijos();
        cita--;
        agregar('\n');
      case 'ul':
      case 'ol':
        final anidada = listas.isNotEmpty;
        if (!anidada) agregar('\n');
        listas.add(nodo.tag == 'ol'
            ? (int.tryParse(nodo.attributes['start'] ?? '') ?? 1) - 1
            : null);
        hijos();
        listas.removeLast();
        if (!anidada) agregar('\n\n');
      case 'li':
        final numerada = listas.isNotEmpty && listas.last != null;
        if (numerada) listas[listas.length - 1] = listas.last! + 1;
        agregar(numerada ? '\n${listas.last}. ' : '\n• ');
        // En listas "sueltas" cada ítem trae su <p>: sin líneas de más
        for (final hijo in nodo.children ?? const <md.Node>[]) {
          if (hijo is md.Element && hijo.tag == 'p') {
            hijo.children?.forEach(recorrer);
          } else {
            recorrer(hijo);
          }
        }
      case 'strong':
        negrita++;
        hijos();
        negrita--;
      case 'em':
        cursiva++;
        hijos();
        cursiva--;
      case 'a':
        final anterior = enlace;
        final href = nodo.attributes['href'];
        enlace = href == null ? null : decodificarEntidades(href.trim());
        hijos();
        enlace = anterior;
      case 'br':
      case 'hr':
        agregar('\n');
      case 'pre':
        agregar('\n');
        preformateado++;
        hijos();
        preformateado--;
        agregar('\n\n');
      case 'img':
        // Sin imágenes remotas
        break;
      default:
        hijos();
    }
  }

  nodos.forEach(recorrer);
  return normalizarSegmentos(segmentos);
}

/// Texto plano (vista previa en la lista de anuncios)
String markdownATexto(String texto) =>
    segmentosMarkdown(texto).map((s) => s.texto).join();
