// lib/widgets/common/contenido_html.dart
//
// Muestra el contenido de mensajes (HTML) y anuncios (Markdown, J6), escrito
// en la web o en la app, respetando párrafos, saltos de línea, listas, citas,
// títulos, negritas y enlaces. Solo texto con estilo: no ejecuta nada.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/html_texto.dart';
import '../../utils/markdown_texto.dart';

/// Esquemas de enlace que se pueden abrir (http, https y correo)
bool enlacePermitido(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && const {'http', 'https', 'mailto'}.contains(uri.scheme);
}

class ContenidoHtml extends StatefulWidget {
  /// Contenido HTML (mensajes)
  const ContenidoHtml(this.html, {super.key, this.estilo}) : markdown = false;

  /// Contenido Markdown (anuncios, como los muestra la web)
  const ContenidoHtml.markdown(String texto, {super.key, this.estilo})
      : html = texto,
        markdown = true;

  final String html;
  final bool markdown;
  final TextStyle? estilo;

  @override
  State<ContenidoHtml> createState() => _ContenidoHtmlState();
}

class _ContenidoHtmlState extends State<ContenidoHtml> {
  final _toques = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final t in _toques) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _abrir(String url) async {
    // Solo enlaces web y de correo
    if (!enlacePermitido(url)) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    for (final t in _toques) {
      t.dispose();
    }
    _toques.clear();

    final base = widget.estilo ??
        const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87);

    final segmentos = widget.markdown
        ? segmentosMarkdown(widget.html)
        : segmentosHtml(widget.html);
    final tamano = base.fontSize ?? 16;

    final spans = segmentos.map((s) {
      // Un enlace con otro esquema (javascript:, file:…) queda como texto
      final esEnlace = s.enlace != null && enlacePermitido(s.enlace!);
      TapGestureRecognizer? toque;
      if (esEnlace) {
        toque = TapGestureRecognizer()..onTap = () => _abrir(s.enlace!);
        _toques.add(toque);
      }
      return TextSpan(
        text: s.texto,
        recognizer: toque,
        style: TextStyle(
          fontWeight: s.negrita ? FontWeight.bold : null,
          fontSize: s.titulo ? tamano * 1.2 : null,
          fontStyle: s.cursiva || s.cita ? FontStyle.italic : null,
          color: esEnlace
              ? const Color(0xFF0D9488)
              : (s.cita ? Colors.grey.shade600 : null),
          decoration: esEnlace ? TextDecoration.underline : null,
        ),
      );
    }).toList();

    return Text.rich(TextSpan(style: base, children: spans));
  }
}
