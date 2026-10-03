// lib/utils/html_texto.dart
//
// Contenido de mensajes y anuncios entre la app y la web (G8).
// La web guarda HTML (<p>, <br>, <blockquote>, listas, negritas, enlaces) y
// lo muestra con DOMPurify. La app:
// - Al mostrar: interpreta ese HTML en segmentos de texto con estilo
//   (nunca ejecuta nada: solo texto). Antes quitaba las etiquetas sin
//   respetar párrafos y la cita al responder salía pegada.
// - Al enviar: convierte el texto escrito a HTML seguro (escapado, con
//   <p>/<br>), porque la web ignora los saltos de línea de texto plano.

/// Fragmento de texto con su estilo
class SegmentoHtml {
  const SegmentoHtml(
    this.texto, {
    this.negrita = false,
    this.cursiva = false,
    this.cita = false,
    this.enlace,
  });

  final String texto;
  final bool negrita;
  final bool cursiva;
  final bool cita;
  final String? enlace;
}

final _etiqueta = RegExp(r'<\s*(/)?\s*([a-zA-Z0-9]+)([^>]*)>');
final _tieneEtiquetas = RegExp(r'<\s*/?\s*[a-zA-Z][a-zA-Z0-9]*[^>]*>');
final _href = RegExp(r'''href\s*=\s*["']([^"']*)["']''', caseSensitive: false);

const _bloques = {'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'tr'};

String _decodificar(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#x27;', "'")
    .replaceAll('&amp;', '&');

/// Interpreta [html] en segmentos con estilo. Un texto sin etiquetas (lo que
/// enviaban versiones anteriores de la app) se devuelve tal cual, con sus
/// saltos de línea.
List<SegmentoHtml> segmentosHtml(String html) {
  if (!_tieneEtiquetas.hasMatch(html)) {
    final texto = _decodificar(html).trim();
    return texto.isEmpty ? const [] : [SegmentoHtml(texto)];
  }

  // En HTML los saltos y espacios repetidos valen como un solo espacio
  final fuente = html.replaceAll(RegExp(r'\s+'), ' ');
  final segmentos = <SegmentoHtml>[];
  var negrita = 0, cursiva = 0, cita = 0;
  String? enlace;

  void agregar(String texto) {
    if (texto.isEmpty) return;
    segmentos.add(SegmentoHtml(
      texto,
      negrita: negrita > 0,
      cursiva: cursiva > 0,
      cita: cita > 0,
      enlace: enlace,
    ));
  }

  var pos = 0;
  for (final m in _etiqueta.allMatches(fuente)) {
    agregar(_decodificar(fuente.substring(pos, m.start)));
    pos = m.end;
    final cierre = m.group(1) != null;
    final nombre = m.group(2)!.toLowerCase();
    switch (nombre) {
      case 'br':
        agregar('\n');
      case 'li':
        if (!cierre) agregar('\n• ');
      case 'ul':
      case 'ol':
        agregar('\n');
      case 'blockquote':
        agregar('\n');
        cita += cierre ? -1 : 1;
      case 'strong':
      case 'b':
        negrita += cierre ? -1 : 1;
      case 'em':
      case 'i':
        cursiva += cierre ? -1 : 1;
      case 'a':
        // El href viene escapado como cualquier atributo: '&amp;' separa los
        // parámetros de enlaces de Forms/Drive/YouTube (J4)
        final href = _href.firstMatch(m.group(3) ?? '')?.group(1);
        enlace = cierre || href == null ? null : _decodificar(href.trim());
      default:
        if (_bloques.contains(nombre)) {
          agregar('\n');
          if (nombre.startsWith('h')) negrita += cierre ? -1 : 1;
        }
      // Otras etiquetas (span, font, img, script…) se ignoran: solo texto
    }
    if (negrita < 0) negrita = 0;
    if (cursiva < 0) cursiva = 0;
    if (cita < 0) cita = 0;
  }
  agregar(_decodificar(fuente.substring(pos)));
  return _normalizar(segmentos);
}

/// Quita espacios al inicio de cada línea, deja como máximo una línea en
/// blanco seguida y recorta los saltos del principio y del final.
List<SegmentoHtml> _normalizar(List<SegmentoHtml> segmentos) {
  final resultado = <SegmentoHtml>[];
  var saltosSeguidos = 2; // al inicio no se aceptan saltos
  var inicioDeLinea = true;
  // Espacios pendientes: solo se escriben si sigue texto en la misma línea
  // (sin espacios al inicio ni al final de las líneas)
  var espaciosPendientes = 0;
  for (final s in segmentos) {
    final buffer = StringBuffer();
    for (final c in s.texto.split('')) {
      if (c == '\n') {
        espaciosPendientes = 0;
        if (saltosSeguidos < 2) buffer.write('\n');
        saltosSeguidos++;
        inicioDeLinea = true;
      } else if (c == ' ') {
        if (!inicioDeLinea) espaciosPendientes++;
      } else {
        if (espaciosPendientes > 0) {
          if (buffer.isEmpty) {
            // Espacio entre segmentos: sin el estilo del siguiente (p. ej.
            // que no quede subrayado como parte de un enlace)
            resultado.add(SegmentoHtml(' ' * espaciosPendientes));
          } else {
            buffer.write(' ' * espaciosPendientes);
          }
          espaciosPendientes = 0;
        }
        buffer.write(c);
        saltosSeguidos = 0;
        inicioDeLinea = false;
      }
    }
    if (buffer.isNotEmpty) {
      resultado.add(SegmentoHtml(buffer.toString(),
          negrita: s.negrita,
          cursiva: s.cursiva,
          cita: s.cita,
          enlace: s.enlace));
    }
  }
  // Saltos finales
  while (resultado.isNotEmpty && resultado.last.texto.trim().isEmpty) {
    resultado.removeLast();
  }
  if (resultado.isNotEmpty) {
    final ultimo = resultado.removeLast();
    resultado.add(SegmentoHtml(ultimo.texto.trimRight(),
        negrita: ultimo.negrita,
        cursiva: ultimo.cursiva,
        cita: ultimo.cita,
        enlace: ultimo.enlace));
  }
  return resultado;
}

/// Texto plano con saltos de línea (vistas previas, edición de borradores).
String htmlATexto(String html) =>
    segmentosHtml(html).map((s) => s.texto).join();

/// Texto escrito en la app → HTML seguro para guardar (se ve igual en la web):
/// escapa los caracteres especiales; un salto de línea es <br> y una línea en
/// blanco separa párrafos.
String textoAHtml(String texto) {
  final limpio = texto.replaceAll('\r\n', '\n').trim();
  if (limpio.isEmpty) return '';
  String escapar(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
  return limpio
      .split(RegExp(r'\n\s*\n'))
      .map((parrafo) =>
          '<p>${parrafo.split('\n').map(escapar).join('<br>')}</p>')
      .join();
}
