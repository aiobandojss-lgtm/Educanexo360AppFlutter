// lib/utils/file_helper.dart
//
// Utilidad para descargar archivos del backend y abrirlos directamente
// con la aplicación nativa del dispositivo (PDF reader, Word, etc.).
//
// Flujo:
//   1. Descarga el archivo al directorio temporal de la app (sin permisos).
//   2. Lo abre con open_filex, que invoca la app correspondiente.
//   3. Si no hay app instalada para ese tipo, muestra un aviso.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'logger.dart';
import '../services/api_service.dart';

class FileHelper {
  static final ApiService _apiService = ApiService();

  /// Subcarpeta de descargas de la app (se borra al cerrar sesión)
  static const String downloadsFolder = 'descargas';

  // Marca de la limpieza única de descargas de versiones anteriores
  static const String _legacyCleanupKey = '@educanexo360_legacy_downloads_cleaned';
  @visibleForTesting
  static const String legacyExternalCleanupKey =
      '@educanexo360_legacy_external_downloads_cleaned';

  /// Sanea un nombre de archivo que llega del servidor antes de usarlo en
  /// una ruta: solo el nombre base, sin caracteres inválidos, sin puntos
  /// iniciales (evita '..' y ocultos) y con longitud limitada.
  static String sanitizeFileName(String fileName) {
    // Solo el nombre base: descarta cualquier ruta (/ o \)
    var name = fileName.split(RegExp(r'[/\\]')).last;
    name = name.replaceAll(RegExp(r'[<>:"|?*\x00-\x1f]'), '_').trim();
    name = name.replaceFirst(RegExp(r'^[.\s]+'), '');

    const maxLength = 120;
    if (name.length > maxLength) {
      final dot = name.lastIndexOf('.');
      final ext = dot > 0 && name.length - dot <= 10 ? name.substring(dot) : '';
      name = name.substring(0, maxLength - ext.length) + ext;
    }
    return name.isEmpty ? 'archivo' : name;
  }

  /// Las versiones anteriores descargaban sueltas en la raíz del directorio
  /// temporal (FileHelper) y del externo de la app (adjuntos de mensajes). Se
  /// borran esos archivos de nivel superior (no subcarpetas de otros plugins)
  /// una sola vez por carpeta: no se limpian en cada sesión.
  @visibleForTesting
  static Future<void> clearLegacyDownloadsOnce(
    Directory dir, {
    String flagKey = _legacyCleanupKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(flagKey) == true) return;
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
    }
    await prefs.setBool(flagKey, true);
  }

  /// Carpeta de descargas dentro de [base] (se crea si no existe)
  static Future<Directory> downloadsDir(Directory base) async {
    final dir = Directory('${base.path}/$downloadsFolder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Borra los archivos descargados por la sesión (llamado al cerrar sesión).
  /// Errores ignorados: no debe impedir el logout.
  static Future<void> clearDownloads() async {
    final bases = <Directory?>[];
    try {
      final tempDir = await getTemporaryDirectory();
      bases.add(tempDir);
      await clearLegacyDownloadsOnce(tempDir);
    } catch (e) {
      dlog('⚠️ FileHelper: no se pudo limpiar el temporal: $e');
    }
    try {
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        bases.add(externalDir);
        // Almacenamiento propio de la app: adjuntos sueltos de versiones
        // anteriores (solo archivos de nivel superior, una sola vez)
        if (externalDir != null) {
          await clearLegacyDownloadsOnce(externalDir,
              flagKey: legacyExternalCleanupKey);
        }
      }
      bases.add(await getApplicationDocumentsDirectory());
    } catch (e) {
      dlog('⚠️ FileHelper: no se pudieron obtener directorios: $e');
    }
    for (final base in bases) {
      if (base == null) continue;
      try {
        final dir = Directory('${base.path}/$downloadsFolder');
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (e) {
        dlog('⚠️ FileHelper: no se pudo borrar ${base.path}/$downloadsFolder: $e');
      }
    }
  }

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
    final safeFileName = sanitizeFileName(fileName);

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
      final tempDir = await downloadsDir(await getTemporaryDirectory());
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
