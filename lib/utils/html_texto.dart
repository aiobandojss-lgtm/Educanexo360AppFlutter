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

// Solo estas etiquetas cuentan como HTML (J5). Cualquier otro '<…>' es texto
// literal: un texto plano con "<coordinacion@colegio.edu>" no debe perder sus
// saltos de línea ni el correo.
const _conocidas = 'p|br|div|strong|b|em|i|u|ul|ol|li|blockquote|a|span|h[1-6]';

// Etiquetas que la web puede traer pegadas desde Word u otras páginas: se
// quitan sin mostrarse (no activan el modo HTML por sí solas)
const _ignoradas =
    'font|img|hr|table|thead|tbody|tfoot|tr|td|th|sup|sub|s|del|small|mark|code|pre';

final _etiqueta = RegExp(
    '<\\s*(/)?\\s*($_conocidas|$_ignoradas)(?=[\\s/>])([^>]*)>',
    caseSensitive: false);
final _tieneEtiquetas =
    RegExp('<\\s*/?\\s*($_conocidas)(?=[\\s/>])[^>]*>', caseSensitive: false);
final _inicioLista =
    RegExp(r'''start\s*=\s*["']?(\d+)''', caseSensitive: false);
final _href = RegExp(r'''href\s*=\s*["']([^"']*)["']''', caseSensitive: false);

const _bloques = {'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'tr'};

// Entidades con nombre que traen los editores de texto (Word, Gmail…)
const _entidades = {
  'nbsp': ' ', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'amp': '&',
  'rsquo': '’', 'lsquo': '‘', 'rdquo': '”', 'ldquo': '“', 'ndash': '–',
  'mdash': '—', 'hellip': '…', 'bull': '•', 'middot': '·', 'deg': '°',
  'iquest': '¿', 'iexcl': '¡', 'laquo': '«', 'raquo': '»', 'euro': '€',
  'aacute': 'á', 'eacute': 'é', 'iacute': 'í', 'oacute': 'ó', 'uacute': 'ú',
  'Aacute': 'Á', 'Eacute': 'É', 'Iacute': 'Í', 'Oacute': 'Ó', 'Uacute': 'Ú',
  'ntilde': 'ñ', 'Ntilde': 'Ñ', 'uuml': 'ü', 'Uuml': 'Ü', 'copy': '©',
};
final _entidad = RegExp(r'&(#[0-9]{1,7}|#[xX][0-9a-fA-F]{1,6}|[a-zA-Z]{2,8});');

/// Decodifica entidades numéricas (&#160;, &#x27;) y con nombre (&rsquo;)
/// en una sola pasada (así '&amp;lt;' queda '&lt;', como en el navegador).
/// Las desconocidas se dejan tal cual.
String _decodificar(String s) => s.replaceAllMapped(_entidad, (m) {
      final e = m.group(1)!;
      if (e.startsWith('#')) {
        final hex = e.length > 1 && (e[1] == 'x' || e[1] == 'X');
        final codigo = int.tryParse(e.substring(hex ? 2 : 1), radix: hex ? 16 : 10);
        if (codigo == null || codigo == 0 || codigo > 0x10FFFF) return m[0]!;
        // &#160; (espacio duro) cuenta como espacio normal
        return codigo == 160 ? ' ' : String.fromCharCode(codigo);
      }
      return _entidades[e] ?? m[0]!;
    });

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
  // Listas abiertas: null = con viñetas (ul), número = numerada (ol)
  final listas = <int?>[];

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
        if (!cierre) {
          final numerada = listas.isNotEmpty && listas.last != null;
          if (numerada) listas[listas.length - 1] = listas.last! + 1;
          agregar(numerada ? '\n${listas.last}. ' : '\n• ');
        }
      case 'ul':
      case 'ol':
        // Una lista anidada no separa con línea propia: cada <li> ya abre línea
        final anidada = cierre ? listas.length > 1 : listas.isNotEmpty;
        if (!anidada) agregar('\n');
        if (cierre) {
          if (listas.isNotEmpty) listas.removeLast();
        } else if (nombre == 'ol') {
          final inicio = _inicioLista.firstMatch(m.group(3) ?? '')?.group(1);
          listas.add((int.tryParse(inicio ?? '') ?? 1) - 1);
        } else {
          listas.add(null);
        }
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
      // Otras etiquetas conocidas (span, u, font, img…) se ignoran: solo texto
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
