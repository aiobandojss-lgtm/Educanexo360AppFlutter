// lib/widgets/messages/message_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';

/// 📨 CARD DE MENSAJE
/// Muestra un mensaje en la lista con avatar, nombre, asunto, preview y metadata
class MessageCard extends StatelessWidget {
  final Message message;
  final Bandeja bandeja;
  final String? currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onUnarchive;
  final VoidCallback? onDeletePermanently;

  const MessageCard({
    super.key,
    required this.message,
    required this.bandeja,
    this.currentUserId,
    required this.onTap,
    this.onArchive,
    this.onDelete,
    this.onRestore,
    this.onUnarchive,
    this.onDeletePermanently,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = _isRead();
    final displayUser = _getDisplayUser();
    final displayName = displayUser.fullName;
    final avatarColor = Color(displayUser.avatarColor);
    final initials = displayUser.initials;

    return Dismissible(
      key: Key(message.id),
      background: _buildSwipeBackground(Colors.blue, Icons.archive, 'Archivar'),
      secondaryBackground:
          _buildSwipeBackground(Colors.red, Icons.delete, 'Eliminar'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe derecha -> Archivar
          if (bandeja == Bandeja.archivados && onUnarchive != null) {
            onUnarchive!();
          } else if (onArchive != null) {
            onArchive!();
          }
        } else {
          // Swipe izquierda -> Eliminar
          if (bandeja == Bandeja.eliminados) {
            // Mostrar opciones: restaurar o eliminar permanentemente
            _showDeleteOptions(context);
          } else if (onDelete != null) {
            onDelete!();
          }
        }
        return false; // No eliminar el item automáticamente
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border(
              left: BorderSide(
                color: message.prioridad == Prioridad.alta
                    ? Colors.red
                    : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Punto de no leído
                if (!isRead && bandeja == Bandeja.recibidos)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),

                // Avatar
                CircleAvatar(
                  backgroundColor: avatarColor,
                  radius: 24,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre y fecha
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getDisplayEmoji(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Asunto
                      Row(
                        children: [
                          if (message.prioridad == Prioridad.alta)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text('🔴', style: TextStyle(fontSize: 12)),
                            ),
                          Expanded(
                            child: Text(
                              message.asunto,
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Preview del contenido
                      Text(
                        _stripHtml(message.contenido),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Metadata (fecha, adjuntos)
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(message.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),

                          if (message.hasAttachments) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.attach_file,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${message.attachmentCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],

                          const Spacer(),

                          // Badge de tipo de mensaje
                          if (message.isDraft)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Borrador',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // 🔧 HELPERS
  // ========================================

  bool _isRead() {
    if (bandeja == Bandeja.enviados || bandeja == Bandeja.borradores) {
      return true; // Los enviados y borradores siempre se muestran como "leídos"
    }
    return message.isReadByUser(currentUserId ?? '');
  }

  User _getDisplayUser() {
    if (bandeja == Bandeja.enviados) {
      // En enviados, mostrar el primer destinatario
      return message.destinatarios.isNotEmpty
          ? message.destinatarios.first
          : message.remitente;
    } else {
      // En recibidos, mostrar el remitente
      return message.remitente;
    }
  }

  String _getDisplayEmoji() {
    final user = _getDisplayUser();
    return user.emoji;
  }

  Color _getBackgroundColor() {
    if (message.isDraft) {
      return Colors.yellow[50]!;
    }
    if (!_isRead() && bandeja == Bandeja.recibidos) {
      return Colors.blue[50]!;
    }
    return Colors.white;
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Hoy - mostrar hora
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      // Esta semana - mostrar día
      return DateFormat('EEEE', 'es').format(date);
    } else if (difference.inDays < 365) {
      // Este año - mostrar día y mes
      return DateFormat('d MMM', 'es').format(date);
    } else {
      // Años anteriores - mostrar fecha completa
      return DateFormat('d/M/yy').format(date);
    }
  }

  Widget _buildSwipeBackground(Color color, IconData icon, String label) {
    return Container(
      color: color,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.blue),
              title: const Text('Restaurar mensaje'),
              onTap: () {
                Navigator.pop(context);
                if (onRestore != null) onRestore!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Eliminar permanentemente'),
              onTap: () {
                Navigator.pop(context);
                if (onDeletePermanently != null) {
                  _confirmPermanentDelete(context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar permanentemente?'),
        content: const Text(
          'Esta acción no se puede deshacer. El mensaje será eliminado definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDeletePermanently != null) onDeletePermanently!();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
