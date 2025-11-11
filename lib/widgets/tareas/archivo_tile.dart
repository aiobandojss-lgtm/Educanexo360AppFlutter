// lib/widgets/tareas/archivo_tile.dart

import 'package:flutter/material.dart';
import '../../models/tarea.dart';

/// 📎 ARCHIVO TILE
/// Widget para mostrar un archivo ya subido (de referencia o de entrega)
class ArchivoTile extends StatelessWidget {
  final ArchivoTarea archivo;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool mostrarFecha;
  final bool compacto;

  const ArchivoTile({
    super.key,
    required this.archivo,
    this.onTap,
    this.onDownload,
    this.onDelete,
    this.mostrarFecha = true,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap ?? onDownload,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compacto ? 8 : 12),
          child: Row(
            children: [
              // Icono del archivo
              Container(
                padding: EdgeInsets.all(compacto ? 8 : 10),
                decoration: BoxDecoration(
                  color: _getColorByType().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  archivo.icon,
                  style: TextStyle(fontSize: compacto ? 20 : 24),
                ),
              ),

              SizedBox(width: compacto ? 8 : 12),

              // Info del archivo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      archivo.nombre,
                      style: TextStyle(
                        fontSize: compacto ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: compacto ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: compacto ? 2 : 4),

                    // Metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Tamaño
                        _buildMetadata(
                          icon: Icons.file_present,
                          text: archivo.formattedSize,
                        ),

                        // Extensión
                        _buildMetadata(
                          icon: Icons.label_outline,
                          text: archivo.extension.toUpperCase(),
                        ),

                        // Fecha (opcional)
                        if (mostrarFecha && !compacto)
                          _buildMetadata(
                            icon: Icons.schedule,
                            text: _formatearFecha(archivo.fechaSubida),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Acciones
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón descargar
                  if (onDownload != null)
                    IconButton(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_outlined),
                      color: const Color(0xFF6366F1),
                      tooltip: 'Descargar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),

                  // Botón eliminar
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Eliminar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // 🏷️ METADATA CHIP
  // ========================================

  Widget _buildMetadata({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ========================================
  // 🎨 HELPERS
  // ========================================

  Color _getColorByType() {
    if (archivo.isPdf) return Colors.red;
    if (archivo.isWord) return Colors.blue;
    if (archivo.isExcel) return Colors.green;
    if (archivo.isImage) return Colors.purple;
    return Colors.grey;
  }

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inDays == 0) {
      return 'Hoy ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays}d';
    } else if (diff.inDays < 30) {
      return 'Hace ${(diff.inDays / 7).floor()}sem';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}

/// 📎 LISTA DE ARCHIVOS
/// Widget para mostrar múltiples archivos
class ArchivosList extends StatelessWidget {
  final List<ArchivoTarea> archivos;
  final Function(ArchivoTarea)? onDownload;
  final Function(ArchivoTarea)? onDelete;
  final String? titulo;
  final bool compacto;

  const ArchivosList({
    super.key,
    required this.archivos,
    this.onDownload,
    this.onDelete,
    this.titulo,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    if (archivos.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título (opcional)
        if (titulo != null) ...[
          Row(
            children: [
              const Text('📎', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                titulo!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${archivos.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Lista de archivos
        ...archivos.map((archivo) {
          return ArchivoTile(
            archivo: archivo,
            onDownload: onDownload != null ? () => onDownload!(archivo) : null,
            onDelete: onDelete != null ? () => onDelete!(archivo) : null,
            compacto: compacto,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No hay archivos',
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
}

/// 📎 GRID DE ARCHIVOS
/// Mostrar archivos en formato de grid (útil para imágenes)
class ArchivosGrid extends StatelessWidget {
  final List<ArchivoTarea> archivos;
  final Function(ArchivoTarea)? onTap;
  final int crossAxisCount;

  const ArchivosGrid({
    super.key,
    required this.archivos,
    this.onTap,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (archivos.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: archivos.length,
      itemBuilder: (context, index) {
        final archivo = archivos[index];
        return _buildGridItem(archivo);
      },
    );
  }

  Widget _buildGridItem(ArchivoTarea archivo) {
    final color = _getColorByType(archivo);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap != null ? () => onTap!(archivo) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(archivo.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                archivo.nombre,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                archivo.formattedSize,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorByType(ArchivoTarea archivo) {
    if (archivo.isPdf) return Colors.red;
    if (archivo.isWord) return Colors.blue;
    if (archivo.isExcel) return Colors.green;
    if (archivo.isImage) return Colors.purple;
    return Colors.grey;
  }
}
