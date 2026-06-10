// lib/utils/file_helper.dart
//
// Utilidad para descargar archivos del backend y abrirlos directamente
// con la aplicación nativa del dispositivo (PDF reader, Word, etc.).
//
// Flujo:
//   1. Descarga el archivo al directorio temporal de la app (sin permisos).
//   2. Lo abre con open_filex, que invoca la app correspondiente.
//   3. Si no hay app instalada para ese tipo, muestra un aviso.

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'logger.dart';
import '../services/api_service.dart';

class FileHelper {
  static final ApiService _apiService = ApiService();

  /// Descarga [endpoint] (ruta relativa del API) y lo abre inmediatamente.
  ///
  /// [context]  : BuildContext para mostrar diálogo y SnackBar.
  /// [endpoint] : ruta relativa, ej: '/mensajes/id/adjuntos/fileId'
  /// [fileName] : nombre del archivo, ej: 'circular.pdf'
  static Future<void> downloadAndOpen(
    BuildContext context,
    String endpoint,
    String fileName,
  ) async {
    // Sanitizar el nombre para evitar problemas en el sistema de archivos
    final safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_');

    bool dialogOpen = false;

    if (context.mounted) {
      dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF059669)),
                  SizedBox(height: 16),
                  Text('Abriendo archivo...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // Descargar al directorio temporal (no requiere permisos de almacenamiento)
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$safeFileName';

      dlog('⬇️ FileHelper: descargando $endpoint → $filePath');
      await _apiService.download(endpoint, filePath);
      dlog('✅ FileHelper: descarga completada');

      // Cerrar diálogo de progreso
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      // Abrir con la app nativa correspondiente al tipo de archivo
      final result = await OpenFilex.open(filePath);
      dlog('📂 FileHelper open_filex: ${result.type} - ${result.message}');

      if (context.mounted && result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró una app para abrir este tipo de archivo. '
              'Instala un lector de documentos e intenta de nuevo.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      dlog('❌ FileHelper error: $e');

      // Cerrar diálogo si sigue abierto
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el archivo: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
