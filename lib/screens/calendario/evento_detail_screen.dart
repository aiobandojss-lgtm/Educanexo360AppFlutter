// lib/screens/calendario/evento_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evento.dart';
import '../../providers/calendario_provider.dart';
import '../../services/permission_service.dart';
import '../../services/calendario_service.dart';
import 'create_evento_screen.dart';

class EventoDetailScreen extends StatefulWidget {
  final String eventoId;

  const EventoDetailScreen({
    Key? key,
    required this.eventoId,
  }) : super(key: key);

  @override
  State<EventoDetailScreen> createState() => _EventoDetailScreenState();
}

class _EventoDetailScreenState extends State<EventoDetailScreen> {
  bool _isLoading = true;
  Evento? _evento;
  final CalendarioService _calendarioService = CalendarioService();

  @override
  void initState() {
    super.initState();
    _loadEvento();
  }

  Future<void> _loadEvento() async {
    try {
      final provider = context.read<CalendarioProvider>();
      final evento = await provider.getEventoById(widget.eventoId);

      if (mounted) {
        setState(() {
          _evento = evento;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error al cargar el evento');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF8b5cf6),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_evento == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF8b5cf6),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '❌',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              const Text(
                'Evento no encontrado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final evento = _evento!;
    final canEdit = PermissionService.canAccess('calendario.editar');
    final canDelete = PermissionService.canAccess('calendario.eliminar');
    final canChangeState = PermissionService.canAccess('calendario.editar');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // HEADER
          _buildHeader(evento),

          // CONTENIDO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INFO PRINCIPAL
                  _buildMainInfo(evento),
                  const SizedBox(height: 20),

                  // DESCRIPCIÓN
                  _buildSection(
                    icon: Icons.description,
                    title: 'Descripción',
                    child: Text(
                      evento.descripcion,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DETALLES
                  _buildDetailsSection(evento),
                  const SizedBox(height: 20),

                  // ARCHIVO ADJUNTO
                  if (evento.archivoAdjunto != null) ...[
                    _buildAttachmentSection(evento),
                    const SizedBox(height: 20),
                  ],

                  // INVITADOS (si hay)
                  if (evento.invitados.isNotEmpty) ...[
                    _buildInvitadosSection(evento),
                    const SizedBox(height: 20),
                  ],

                  // ACCIONES ADMIN/DOCENTE
                  if (canChangeState) ...[
                    _buildAdminActions(evento),
                    const SizedBox(height: 20),
                  ],

                  // BOTONES DE ACCIÓN
                  _buildActionButtons(evento, canEdit, canDelete),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader(Evento evento) {
    final color = _getEventTypeColor(evento.tipo);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: color,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // CHIP DE TIPO
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${evento.tipo.icon} ${evento.tipo.displayName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TÍTULO
                  Text(
                    evento.titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // INFO PRINCIPAL
  // ==========================================

  Widget _buildMainInfo(Evento evento) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // FECHA Y HORA
          _buildInfoRow(
            icon: Icons.event,
            iconColor: const Color(0xFF8b5cf6),
            title: 'Fecha y hora',
            subtitle: evento.todoElDia
                ? DateFormat('d \'de\' MMMM yyyy', 'es_ES')
                    .format(evento.fechaInicio)
                : '${DateFormat('d \'de\' MMMM yyyy, HH:mm', 'es_ES').format(evento.fechaInicio)}\n'
                    '${DateFormat('d \'de\' MMMM yyyy, HH:mm', 'es_ES').format(evento.fechaFin)}',
          ),

          if (evento.lugar != null) ...[
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.location_on,
              iconColor: const Color(0xFFef4444),
              title: 'Lugar',
              subtitle: evento.lugar!,
            ),
          ],

          const Divider(height: 32),
          _buildInfoRow(
            icon: Icons.person,
            iconColor: const Color(0xFF10b981),
            title: 'Creado por',
            subtitle: evento.creador.fullName,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1f2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECCIÓN GENÉRICA
  // ==========================================

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8b5cf6), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ==========================================
  // DETALLES
  // ==========================================

  Widget _buildDetailsSection(Evento evento) {
    return _buildSection(
      icon: Icons.info_outline,
      title: 'Detalles',
      child: Column(
        children: [
          _buildDetailRow('Estado', evento.estado.displayName,
              color: _getStatusColor(evento.estado)),
          const Divider(height: 24),
          _buildDetailRow('Todo el día', evento.todoElDia ? 'Sí' : 'No'),
          if (evento.color != null) ...[
            const Divider(height: 24),
            _buildDetailRow('Color', '',
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(
                        int.parse(evento.color!.substring(1), radix: 16) +
                            0xFF000000),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? color, Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing ??
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF1f2937),
              ),
            ),
      ],
    );
  }

  // ==========================================
  // ARCHIVO ADJUNTO
  // ==========================================

  Widget _buildAttachmentSection(Evento evento) {
    final adjunto = evento.archivoAdjunto!;

    return _buildSection(
      icon: Icons.attach_file,
      title: 'Archivo adjunto',
      child: InkWell(
        onTap: () => _downloadAttachment(evento.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Text(adjunto.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adjunto.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adjunto.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.download, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // INVITADOS
  // ==========================================

  Widget _buildInvitadosSection(Evento evento) {
    final confirmados = evento.confirmadosCount;
    final total = evento.invitados.length;

    return _buildSection(
      icon: Icons.people,
      title: 'Invitados ($confirmados/$total confirmados)',
      child: Column(
        children: evento.invitados.take(5).map((invitado) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  invitado.confirmado
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 20,
                  color: invitado.confirmado
                      ? const Color(0xFF10b981)
                      : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Text(
                  invitado.usuarioId,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // ACCIONES ADMIN
  // ==========================================

  Widget _buildAdminActions(Evento evento) {
    return _buildSection(
      icon: Icons.admin_panel_settings,
      title: 'Acciones de administrador',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: EventStatus.values.map((estado) {
          final isCurrentState = evento.estado == estado;
          return ChoiceChip(
            label: Text(estado.displayName),
            selected: isCurrentState,
            onSelected: isCurrentState
                ? null
                : (selected) {
                    if (selected) _changeEventStatus(evento, estado);
                  },
            selectedColor: _getStatusColor(estado).withOpacity(0.2),
            labelStyle: TextStyle(
              fontWeight: isCurrentState ? FontWeight.bold : FontWeight.normal,
              color:
                  isCurrentState ? _getStatusColor(estado) : Colors.grey[700],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // BOTONES DE ACCIÓN
  // ==========================================

  Widget _buildActionButtons(Evento evento, bool canEdit, bool canDelete) {
    return Row(
      children: [
        if (canEdit)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _editEvent(evento),
              icon: const Icon(Icons.edit),
              label: const Text('Editar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b5cf6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (canEdit && canDelete) const SizedBox(width: 12),
        if (canDelete)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _deleteEvent(evento),
              icon: const Icon(Icons.delete),
              label: const Text('Eliminar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // ACCIONES
  // ==========================================

  Future<void> _changeEventStatus(
      Evento evento, EventStatus nuevoEstado) async {
    try {
      final provider = context.read<CalendarioProvider>();

      // ✅ USAR actualizarEvento() que SÍ existe
      await provider.actualizarEvento(
        eventoId: evento.id,
        estado: nuevoEstado,
      );

      if (mounted) {
        _showSuccess('Estado actualizado a ${nuevoEstado.displayName}');
        _loadEvento(); // Recargar evento
      }
    } catch (e) {
      _showError('Error al cambiar estado: $e');
    }
  }

  Future<void> _editEvent(Evento evento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventoScreen(evento: evento),
      ),
    );

    if (result == true) {
      _loadEvento(); // Recargar evento
    }
  }

  Future<void> _deleteEvent(Evento evento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content:
            Text('¿Estás seguro de que deseas eliminar "${evento.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = context.read<CalendarioProvider>();
        await provider.eliminarEvento(evento.id);

        if (mounted) {
          Navigator.pop(context); // Volver a la lista
          _showSuccess('Evento eliminado');
        }
      } catch (e) {
        _showError('Error al eliminar evento');
      }
    }
  }

  Future<void> _downloadAttachment(String eventoId) async {
    try {
      final url = _calendarioService.getAdjuntoUrl(eventoId);
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('No se puede abrir el archivo');
      }
    } catch (e) {
      _showError('Error al descargar archivo');
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  Color _getEventTypeColor(EventType type) {
    return Color(
      int.parse(type.colorHex.substring(1), radix: 16) + 0xFF000000,
    );
  }

  Color _getStatusColor(EventStatus status) {
    return Color(
      int.parse(status.colorHex.substring(1), radix: 16) + 0xFF000000,
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10b981),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFef4444),
      ),
    );
  }
}
