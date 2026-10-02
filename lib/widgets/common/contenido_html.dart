// lib/widgets/common/contenido_html.dart
//
// Muestra el contenido HTML de mensajes y anuncios (escrito en la web o en la
// app) respetando párrafos, saltos de línea, listas, citas, negritas y
// enlaces. Solo texto con estilo: no ejecuta nada del HTML.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/html_texto.dart';

class ContenidoHtml extends StatefulWidget {
  const ContenidoHtml(this.html, {super.key, this.estilo});

  final String html;
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
    final uri = Uri.tryParse(url);
    // Solo enlaces web y de correo
    if (uri == null || !{'http', 'https', 'mailto'}.contains(uri.scheme)) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    for (final t in _toques) {
      t.dispose();
    }
    _toques.clear();

    final base = widget.estilo ??
        const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87);

    final spans = segmentosHtml(widget.html).map((s) {
      TapGestureRecognizer? toque;
      if (s.enlace != null) {
        toque = TapGestureRecognizer()..onTap = () => _abrir(s.enlace!);
        _toques.add(toque);
      }
      return TextSpan(
        text: s.texto,
        recognizer: toque,
        style: TextStyle(
          fontWeight: s.negrita ? FontWeight.bold : null,
          fontStyle: s.cursiva || s.cita ? FontStyle.italic : null,
          color: s.enlace != null
              ? const Color(0xFF0D9488)
              : (s.cita ? Colors.grey.shade600 : null),
          decoration: s.enlace != null ? TextDecoration.underline : null,
        ),
      );
    }).toList();

    return Text.rich(TextSpan(style: base, children: spans));
  }
}
