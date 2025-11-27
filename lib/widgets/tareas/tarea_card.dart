// lib/widgets/tareas/tarea_card.dart
// âœ… CORREGIDO: Overflow y lÃ³gica de "VENCIDA"

import 'package:flutter/material.dart';
import '../../models/tarea.dart';

/// ðŸ“š TARJETA DE TAREA
/// Widget reutilizable para mostrar tareas en listas
class TareaCard extends StatelessWidget {
  final Tarea tarea;
  final EntregaTarea? miEntrega; // null si es docente viendo la tarea
  final VoidCallback? onTap;
  final bool mostrarDocente;
  final bool compacto;
  final bool isReadOnly; // Modo solo lectura (para acudientes)

  const TareaCard({
    super.key,
    required this.tarea,
    this.miEntrega,
    this.onTap,
    this.mostrarDocente = true,
    this.compacto = false,
    this.isReadOnly = false, // Por defecto no es read-only
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Badges y fecha
              _buildHeader(context),

              const SizedBox(height: 12),

              // TÃ­tulo
              Text(
                tarea.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // DescripciÃ³n
              if (!compacto)
                Text(
                  tarea.descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Info: Asignatura, Curso, Docente
              _buildInfoRow(context),

              // Estado de mi entrega (solo para estudiantes)
              if (miEntrega != null) ...[
                const SizedBox(height: 12),
                _buildEstadoEntrega(context),
              ],

              // Archivos de referencia (del docente)
              if (tarea.tieneArchivosReferencia && !compacto) ...[
                const SizedBox(height: 12),
                _buildArchivosReferenciaInfo(),
              ],

              // Archivos de entrega (del estudiante)
              if (miEntrega != null &&
                  miEntrega!.archivos.isNotEmpty &&
                  !compacto) ...[
                const SizedBox(height: 12),
                _buildArchivosEntregaInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ðŸŽ¨ HEADER CON BADGES
  // ========================================

  Widget _buildHeader(BuildContext context) {
    // âœ… CORRECCIÃ“N 4: Solo mostrar "VENCIDA" si NO ha sido entregada
    final bool yafueEntregada = miEntrega?.estado == EstadoEntrega.entregada ||
        miEntrega?.estado == EstadoEntrega.atrasada ||
        miEntrega?.estado == EstadoEntrega.calificada;

    final bool mostrarVencida = tarea.estaVencida &&
        !yafueEntregada &&
        (miEntrega?.estado == EstadoEntrega.pendiente ||
            miEntrega?.estado == EstadoEntrega.vista);

    return Row(
      children: [
        // Badge de prioridad
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Color(tarea.prioridad.color),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tarea.prioridad.icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                tarea.prioridad.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Badge de estado de tarea (si estÃ¡ cerrada)
        if (tarea.estaCerrada)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Cerrada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        const Spacer(),

        // âœ… CORRECCIÃ“N 1: Fecha lÃ­mite con Flexible para evitar overflow
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mostrarVencida
                    ? Icons.warning_amber_rounded
                    : (tarea.vencePronto
                        ? Icons.schedule_outlined
                        : Icons.schedule),
                size: 16,
                color: mostrarVencida
                    ? Colors.red
                    : (tarea.vencePronto ? Colors.orange : Colors.grey[600]),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tarea.fechaLimiteFormateada,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: mostrarVencida
                        ? Colors.red
                        : (tarea.vencePronto
                            ? Colors.orange
                            : Colors.grey[700]),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // â„¹ï¸ INFO ROW (Asignatura, Curso, Docente)
  // ========================================

  Widget _buildInfoRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Asignatura
        _buildInfoChip(
          icon: Icons.book_outlined,
          label: tarea.asignatura.nombre,
          color: Colors.blue,
        ),

        // Curso
        _buildInfoChip(
          icon: Icons.group_outlined,
          label: tarea.curso.nombre,
          color: Colors.green,
        ),

        // Docente (opcional)
        if (mostrarDocente)
          _buildInfoChip(
            icon: Icons.person_outline,
            label: tarea.docente.nombreCompleto,
            color: Colors.purple,
          ),

        // CalificaciÃ³n mÃ¡xima
        _buildInfoChip(
          icon: Icons.star_outline,
          label: '${tarea.calificacionMaxima.toStringAsFixed(1)} pts',
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ðŸ“Š ESTADO DE MI ENTREGA (ESTUDIANTE)
  // ========================================

  Widget _buildEstadoEntrega(BuildContext context) {
    if (miEntrega == null) return const SizedBox.shrink();

    final entrega = miEntrega!;
    final estadoColor = Color(entrega.estado.color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: estadoColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entrega.estado.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Estado: ${entrega.estado.displayName}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: estadoColor,
                ),
              ),
              const Spacer(),
              if (entrega.estaCalificada && entrega.calificacion != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entrega.calificacion!.toStringAsFixed(1)} / ${tarea.calificacionMaxima.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          // Feedback del docente
          if (entrega.estaCalificada && entrega.comentarioDocente != null) ...[
            const SizedBox(height: 8),
            Text(
              'RetroalimentaciÃ³n:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entrega.comentarioDocente!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Fecha de entrega
          if (entrega.fueEntregada && entrega.fechaEntrega != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Entregada: ${_formatearFecha(entrega.fechaEntrega!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // 📎 INFO DE ARCHIVOS DE REFERENCIA
  // ========================================

  Widget _buildArchivosReferenciaInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📎', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '${tarea.cantidadArchivosReferencia} archivo${tarea.cantidadArchivosReferencia > 1 ? 's' : ''} de referencia',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📤 INFO DE ARCHIVOS DE ENTREGA
  // ========================================

  Widget _buildArchivosEntregaInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📤', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '${miEntrega!.archivos.length} archivo${miEntrega!.archivos.length > 1 ? 's' : ''} entregado${miEntrega!.archivos.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ðŸŽ¨ HELPERS
  // ========================================

  Color _getBorderColor() {
    // Si estÃ¡ vencida y pendiente, borde rojo
    if (tarea.estaVencida && miEntrega?.estado == EstadoEntrega.pendiente) {
      return Colors.red;
    }
    // Si vence pronto, borde naranja
    if (tarea.vencePronto && miEntrega?.estado == EstadoEntrega.pendiente) {
      return Colors.orange;
    }
    // Si tiene prioridad alta, usar su color
    if (tarea.prioridad == PrioridadTarea.alta) {
      return Color(tarea.prioridad.color).withOpacity(0.3);
    }
    // Si estÃ¡ calificada, borde verde
    if (miEntrega?.estaCalificada == true) {
      return Colors.green;
    }
    // Default
    return Colors.grey[300]!;
  }

  double _getBorderWidth() {
    // Bordes mÃ¡s gruesos para estados importantes
    if (tarea.estaVencida ||
        tarea.vencePronto ||
        tarea.prioridad == PrioridadTarea.alta) {
      return 2;
    }
    return 1;
  }

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inDays == 0) {
      return 'Hoy a las ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} dÃ­as';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
