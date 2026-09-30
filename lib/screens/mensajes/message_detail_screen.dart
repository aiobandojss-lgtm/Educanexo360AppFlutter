// lib/screens/messages/message_detail_screen.dart

import '../../utils/logger.dart';
import '../../utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../widgets/common/gradient_header.dart';
import '../mensajes/create_message_screen.dart';
import '../../services/api_service.dart' show mensajeDeError;

/// ðŸ“– PANTALLA DE DETALLE DE MENSAJE
/// Muestra el mensaje completo con todas sus caracterÃ­sticas
class MessageDetailScreen extends StatefulWidget {
  final String messageId;

  const MessageDetailScreen({
    super.key,
    required this.messageId,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final MessageService _messageService = MessageService();
  Message? _message;
  bool _loading = true;
  String? _error;
  bool _verTodosDestinatarios = false;

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  bool _canReply() {
    if (_message == null) return false;

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';

    // âŒ NO permitir responder si:
    // 1. Es un borrador
    if (_message!.isDraft) return false;

    // 2. El mensaje fue enviado por el usuario actual
    if (_message!.remitente.id == currentUserId) return false;

    // âœ… Permitir responder solo si es destinatario
    return _message!.destinatarios.any((d) => d.id == currentUserId);
  }

  /// Se puede reportar cualquier mensaje recibido de otra persona.
  /// No tiene sentido reportarse a uno mismo ni reportar un borrador.
  bool _canReport() {
    if (_message == null) return false;
    if (_message!.isDraft) return false;

    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
    return _message!.remitente.id != currentUserId;
  }

  // ========================================
  // ðŸ”„ CARGAR MENSAJE
  // ========================================

  Future<void> _loadMessage() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      dlog('📥 Cargando mensaje: ${widget.messageId}');

      final message = await _messageService.getMessageById(widget.messageId);

      if (message == null) {
        throw Exception('Mensaje no encontrado');
      }

      // Marcar como leÃ­do automÃ¡ticamente si es el destinatario
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUser?.id ?? '';

      if (!message.isReadByUser(currentUserId)) {
        final isRecipient =
            message.destinatarios.any((d) => d.id == currentUserId);

        if (isRecipient) {
          dlog('👁 Marcando mensaje como leído...');
          await _messageService.markAsRead(widget.messageId);
        }
      }

      setState(() {
        _message = message;
        _loading = false;
      });
    } catch (e) {
      dlog('❌ Error cargando mensaje: $e');
      setState(() {
        _error = mensajeDeError(e, 'No se pudo cargar el mensaje.');
        _loading = false;
      });
    }
  }

  // ========================================
  // ðŸŽ¨ UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Mensaje',
              showBack: true,
              leadingIcon: Icons.mail_outline,
            ),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    if (_error != null || _message == null) {
      return Scaffold(
        body: Column(
          children: [
            const GradientHeader(
              title: 'Error',
              showBack: true,
              leadingIcon: Icons.mail_outline,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Mensaje no encontrado',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
            ),
          ],
        ),
      );
    }

    final message = _message!;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Mensaje',
            showBack: true,
            leadingIcon: Icons.mail_outline,
            actions: [
              // Reportar contenido inapropiado
              if (_canReport())
                IconButton(
                  icon: const Icon(Icons.flag_outlined, color: Colors.white),
                  onPressed: _handleReport,
                  tooltip: 'Reportar mensaje',
                ),

              // Archivar
              if (message.archivado != true)
                IconButton(
                  icon: const Icon(Icons.archive_outlined, color: Colors.white),
                  onPressed: _handleArchive,
                  tooltip: 'Archivar',
                ),

              // Eliminar
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _handleDelete,
                tooltip: 'Eliminar',
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con remitente
                  _buildSenderHeader(message, primaryColor),

                  const Divider(height: 1),

            // Destinatarios
            if (message.cantidadDestinatarios > 0)
              _buildRecipientsSection(message),

            const Divider(height: 1),

            // Asunto y prioridad
            _buildSubjectSection(message),

            const Divider(
                height: 1,
                thickness: 4,
                color: Color.fromARGB(255, 133, 132, 132)),

            // Contenido
            _buildContentSection(message),

            // Adjuntos
            if (message.hasAttachments) _buildAttachmentsSection(message),

            const SizedBox(height: 80), // Espacio para el FAB
          ],
        ),
      ),
            ),
          ],
        ),
      floatingActionButton: _canReply() // â† CAMBIAR ESTA CONDICIÃ“N
          ? FloatingActionButton.extended(
              onPressed: _handleReply,
              icon: const Icon(Icons.reply),
              label: const Text('Responder'),
            )
          : null,
    );
  }

  // ========================================
  // ðŸŽ¨ WIDGETS
  // ========================================

  Widget _buildSenderHeader(Message message, Color primaryColor) {
    final sender = message.remitente;
    final avatarColor = Color(sender.avatarColor);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: avatarColor,
            radius: 28,
            child: Text(
              sender.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sender.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      sender.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sender.tipo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (sender.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sender.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsSection(Message message) {
    const limite = 4;
    // Total real (masivos: el backend solo envía algunos destinatarios)
    final total = message.cantidadDestinatarios;
    final visibles = message.destinatarios.length;
    final mostrar = _verTodosDestinatarios
        ? message.destinatarios
        : message.destinatarios.take(limite).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Para: $total destinatario${total != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...mostrar.map((dest) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(dest.avatarColor),
                      radius: 16,
                      child: Text(
                        dest.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${dest.tipo} ${dest.emoji}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (visibles > limite)
            GestureDetector(
              onTap: () => setState(
                  () => _verTodosDestinatarios = !_verTodosDestinatarios),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _verTodosDestinatarios
                      ? 'Ver menos ▲'
                      : '+${visibles - limite} más ▼',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
          // Destinatarios que el backend no envía (masivos, por privacidad)
          if (total > visibles)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                visibles == 0
                    ? '$total destinatario${total != 1 ? 's' : ''}'
                    : 'y ${total - visibles} más',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectSection(Message message) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (message.prioridad == Prioridad.alta) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔴', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'PRIORIDAD ALTA',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  _formatDate(message.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message.asunto,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(Message message) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Text(
        _stripHtml(message.contenido),
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(Message message) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file, size: 18),
              const SizedBox(width: 8),
              Text(
                'Archivos adjuntos (${message.attachmentCount})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...message.adjuntos!
              .map((attachment) => _buildAttachmentItem(attachment)),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(Adjunto attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              attachment.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          attachment.nombre,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          attachment.formattedSize,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _handleDownloadAttachment(attachment),
          tooltip: 'Descargar',
        ),
      ),
    );
  }

  // ========================================
  // ðŸ”§ HELPERS
  // ========================================

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy - HH:mm', 'es').format(date);
  }

  // ========================================
  // ðŸŽ¯ ACCIONES
  // ========================================

  void _handleReply() {
    if (_message == null) return;

    dlog('📧 Respondiendo mensaje: ${_message!.id}');
    dlog('   Remitente: ${_message!.remitente.fullName}');
    dlog('   Asunto: ${_message!.asunto}');

    // Navegar a crear mensaje en modo REPLY
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMessageScreen(
          originalMessage: _message,
          isReply: true,
        ),
      ),
    );
  }

  Future<void> _handleArchive() async {
    try {
      await context.read<MessageProvider>().archiveMessage(widget.messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje archivado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeDeError(e, 'Error al archivar'))),
        );
      }
    }
  }

  Future<void> _handleReport() async {
    if (_message == null) return;

    final enviado = await showDialog<int>(
      context: context,
      builder: (context) => _ReportarMensajeDialog(
        message: _message!,
        messageService: _messageService,
      ),
    );

    if (enviado != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enviado == 1
                ? 'Reporte enviado. El colegio lo revisara.'
                : 'Reporte enviado a $enviado personas del colegio.',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar mensaje?'),
        content: const Text('El mensaje se moverá a la papelera.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<MessageProvider>().deleteMessage(widget.messageId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mensaje movido a papelera')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensajeDeError(e, 'Error al eliminar'))),
          );
        }
      }
    }
  }

  Future<void> _handleDownloadAttachment(Adjunto attachment) async {
    await FileHelper.downloadAndOpen(
      context,
      '/mensajes/${widget.messageId}/adjuntos/${attachment.fileId}',
      attachment.nombre,
    );
  }
}

/// 🚩 DIÁLOGO PARA REPORTAR UN MENSAJE
/// El reporte llega al personal administrativo del colegio, que es quien
/// modera y puede desactivar al usuario desde la web.
class _ReportarMensajeDialog extends StatefulWidget {
  final Message message;
  final MessageService messageService;

  const _ReportarMensajeDialog({
    required this.message,
    required this.messageService,
  });

  @override
  State<_ReportarMensajeDialog> createState() => _ReportarMensajeDialogState();
}

class _ReportarMensajeDialogState extends State<_ReportarMensajeDialog> {
  final TextEditingController _comentarioController = TextEditingController();
  String? _motivo;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_motivo == null) {
      setState(() => _error = 'Selecciona un motivo');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final enviados = await widget.messageService.reportMessage(
        message: widget.message,
        motivo: _motivo!,
        comentario: _comentarioController.text,
      );
      if (mounted) Navigator.of(context).pop(enviados);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = mensajeDeError(e, 'No se pudo enviar el reporte.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const warnColor = Color(0xFFF59E0B);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.flag_outlined, color: warnColor),
          SizedBox(width: 8),
          Expanded(child: Text('Reportar mensaje')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El reporte se enviara al personal administrativo del colegio '
              'junto con una copia del mensaje de '
              '${widget.message.remitente.fullName}.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Motivo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            RadioGroup<String>(
              groupValue: _motivo,
              onChanged: (value) {
                if (_loading) return;
                setState(() {
                  _motivo = value;
                  _error = null;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: MessageService.motivosReporte
                    .map(
                      (motivo) => RadioListTile<String>(
                        value: motivo,
                        title:
                            Text(motivo, style: const TextStyle(fontSize: 14)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              enabled: !_loading,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: warnColor),
          onPressed: _loading ? null : _enviar,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar reporte'),
        ),
      ],
    );
  }
}
