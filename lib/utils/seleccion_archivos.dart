// lib/utils/seleccion_archivos.dart
//
// Filtra los archivos elegidos antes de agregarlos: tipo permitido, tamaño
// máximo por archivo y cantidad máxima. Devuelve los aceptados y un aviso
// claro para el usuario si se descartó alguno.

import 'dart:io';

import '../config/app_config.dart';

class SeleccionArchivos {
  const SeleccionArchivos({required this.aceptados, this.aviso});

  final List<File> aceptados;

  /// Mensaje para el usuario si se descartó algún archivo; null si no
  final String? aviso;
}

SeleccionArchivos filtrarArchivosElegidos({
  required List<String> rutas,
  required int yaSeleccionados,
  required int maxArchivos,
  required int maxMB,
  String unidad = 'archivos',
  int Function(String ruta)? tamanoDe,
}) {
  final medir = tamanoDe ?? (ruta) => File(ruta).lengthSync();
  final avisos = <String>[];
  final validos = <String>[];

  for (final ruta in rutas) {
    final nombre = ruta.split(RegExp(r'[/\\]')).last;
    if (!AppConfig.extensionPermitida(nombre)) {
      avisos.add(AppConfig.mensajeTipoNoPermitido(nombre));
      continue;
    }
    final bytes = medir(ruta);
    if (bytes > maxMB * 1024 * 1024) {
      avisos.add('El archivo "$nombre" pesa '
          '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB. '
          'Máximo $maxMB MB por archivo.');
      continue;
    }
    validos.add(ruta);
  }

  final restantes = maxArchivos - yaSeleccionados;
  final aceptados = validos.take(restantes < 0 ? 0 : restantes).toList();
  if (validos.length > aceptados.length) {
    avisos.add('Puedes adjuntar máximo $maxArchivos $unidad. '
        '${aceptados.isEmpty ? 'No se agregó ninguno.' : 'Se agregaron solo ${aceptados.length}.'}');
  }

  return SeleccionArchivos(
    aceptados: aceptados.map(File.new).toList(),
    aviso: avisos.isEmpty ? null : avisos.join('\n'),
  );
}
