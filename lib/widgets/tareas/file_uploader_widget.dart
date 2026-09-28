// lib/widgets/tareas/file_uploader_widget.dart

import '../../utils/logger.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_config.dart';

/// 📎 FILE UPLOADER
/// Widget para seleccionar y mostrar archivos antes de subirlos
class FileUploader extends StatefulWidget {
  final List<File> archivosSeleccionados;
  final Function(List<File>) onArchivosChanged;
  final int? maxArchivos;
  final int? maxTamanoMB;
  final List<String>? tiposPermitidos;
  final String? titulo;
  final String? descripcion;

  const FileUploader({
    super.key,
    required this.archivosSeleccionados,
    required this.onArchivosChanged,
    this.maxArchivos = 5,
    this.maxTamanoMB = 10,
    this.tiposPermitidos,
    this.titulo,
    this.descripcion,
  });

  @override
  State<FileUploader> createState() => _FileUploaderState();
}

class _FileUploaderState extends State<FileUploader> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título y descripción
        if (widget.titulo != null) ...[
          Text(
            widget.titulo!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
        ],

        if (widget.descripcion != null) ...[
          Text(
            widget.descripcion!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Botón para seleccionar archivos
        if (widget.archivosSeleccionados.length < (widget.maxArchivos ?? 5))
          _buildSelectorButton(),

        const SizedBox(height: 16),

        // Lista de archivos seleccionados
        if (widget.archivosSeleccionados.isNotEmpty)
          _buildArchivosList()
        else
          _buildEmptyState(),

        // Info de límites
        const SizedBox(height: 12),
        _buildLimitesInfo(),
      ],
    );
  }

  // ========================================
  // 🔘 BOTÓN SELECTOR
  // ========================================

  Widget _buildSelectorButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _seleccionarArchivos,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.attach_file),
      label: Text(
        widget.archivosSeleccionados.isEmpty
            ? 'Seleccionar archivos'
            : 'Agregar más archivos',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ========================================
  // 📋 LISTA DE ARCHIVOS
  // ========================================

  Widget _buildArchivosList() {
    return Column(
      children: widget.archivosSeleccionados.map((archivo) {
        final index = widget.archivosSeleccionados.indexOf(archivo);
        return _buildArchivoItem(archivo, index);
      }).toList(),
    );
  }

  Widget _buildArchivoItem(File archivo, int index) {
    final nombre = archivo.path.split('/').last;
    final tamanoMB = (archivo.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    final extension = nombre.split('.').last.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Icono según tipo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorByExtension(extension).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconByExtension(extension),
              color: _getColorByExtension(extension),
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Info del archivo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$tamanoMB MB • ${extension.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Botón eliminar
          IconButton(
            onPressed: () => _eliminarArchivo(index),
            icon: const Icon(Icons.close, size: 20),
            color: Colors.red,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🚫 ESTADO VACÍO
  // ========================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No hay archivos seleccionados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // ℹ️ INFO DE LÍMITES
  // ========================================

  Widget _buildLimitesInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF047857)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Máximo ${widget.maxArchivos} archivos de ${widget.maxTamanoMB} MB c/u',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF065F46),
              ),
            ),
          ),
          Text(
            '${widget.archivosSeleccionados.length}/${widget.maxArchivos}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🎬 ACCIONES
  // ========================================

  Future<void> _seleccionarArchivos() async {
    try {
      setState(() => _isLoading = true);

      // Calcular cuántos archivos más se pueden agregar
      final maxRestantes =
          (widget.maxArchivos ?? 5) - widget.archivosSeleccionados.length;

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        // Solo los tipos que acepta el backend (antes FileType.any)
        type: FileType.custom,
        allowedExtensions:
            widget.tiposPermitidos ?? AppConfig.extensionesPermitidas,
      );

      if (result != null && result.files.isNotEmpty) {
        final nuevosArchivos = <File>[];

        for (var file in result.files.take(maxRestantes)) {
          if (file.path != null) {
            // Algunos administradores de archivos ignoran el filtro
            if (widget.tiposPermitidos == null &&
                !AppConfig.extensionPermitida(file.name)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppConfig.mensajeTipoNoPermitido(file.name)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              continue;
            }

            final archivo = File(file.path!);
            final tamanoMB = archivo.lengthSync() / (1024 * 1024);

            // Validar tamaño
            if (tamanoMB > (widget.maxTamanoMB ?? 10)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'El archivo "${file.name}" excede el tamaño máximo de ${widget.maxTamanoMB} MB',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              continue;
            }

            nuevosArchivos.add(archivo);
          }
        }

        if (nuevosArchivos.isNotEmpty) {
          final archivosActualizados = [
            ...widget.archivosSeleccionados,
            ...nuevosArchivos,
          ];
          widget.onArchivosChanged(archivosActualizados);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${nuevosArchivos.length} archivo(s) agregado(s)',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      dlog('Error seleccionando archivos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar archivos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _eliminarArchivo(int index) {
    final archivosActualizados = List<File>.from(widget.archivosSeleccionados);
    archivosActualizados.removeAt(index);
    widget.onArchivosChanged(archivosActualizados);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archivo eliminado'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ========================================
  // 🎨 HELPERS
  // ========================================

  IconData _getIconByExtension(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorByExtension(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return const Color(0xFF0D9488);
      case 'zip':
      case 'rar':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
