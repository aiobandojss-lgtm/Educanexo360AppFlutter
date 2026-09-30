// lib/screens/anuncios/anuncio_detail_screen.dart
// ✅ ÚNICO CAMBIO: Gradient → Color sólido en header (línea 200)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/anuncio.dart';
import '../../providers/anuncio_provider.dart';
import '../../services/api_service.dart' show ApiException, mensajeDeError;
import '../../services/permission_service.dart';
import '../../utils/file_helper.dart';
import '../../widgets/common/gradient_header.dart';

class AnuncioDetailScreen extends StatefulWidget {
  final String anuncioId;

  const AnuncioDetailScreen({
    super.key,
    required this.anuncioId,
  });

  @override
  State<AnuncioDetailScreen> createState() => _AnuncioDetailScreenState();
}

class _AnuncioDetailScreenState extends State<AnuncioDetailScreen> {
  Anuncio? _anuncio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnuncio();
  }

  static const String _mensajeNoDisponible =
      'Este anuncio ya no está disponible';

  Future<void> _loadAnuncio() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<AnuncioProvider>();
      final anuncio = await provider.getAnuncioById(widget.anuncioId);

      if (!mounted) return;
      if (anuncio != null) {
        setState(() {
          _anuncio = anuncio;
          _isLoading = false;
        });

        // ✅ SIN marcar como leído - Solo mostrar contador
      } else {
        // Sin anuncio: quitar el spinner (no debe quedar colgado)
        setState(() => _isLoading = false);
        _showError(_mensajeNoDisponible);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // 404: el anuncio se borró (p. ej. abierto desde una notificación vieja)
      _showError(e is ApiException && e.statusCode == 404
          ? _mensajeNoDisponible
          : 'Error al cargar el anuncio');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    context.pop();
  }

  bool _canEdit() {
    if (_anuncio == null) return false;

    // Siempre puede editar su propio anuncio
    final currentUser = PermissionService.getCurrentUser();
    if (currentUser != null && _anuncio!.creador.id == currentUser.id) {
      return true;
    }

    // O si tiene permiso de editar
    return PermissionService.canAccess('anuncios.editar');
  }

  bool _canDelete() {
    return PermissionService.canAccess('anuncios.eliminar');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Cargando...',
              showBack: true,
              leadingIcon: Icons.campaign,
            ),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            ),
          ],
        ),
      );
    }

    if (_anuncio == null) {
      return const Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Error',
              showBack: true,
              leadingIcon: Icons.campaign,
            ),
            Expanded(child: Center(child: Text('Anuncio no encontrado'))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 8),
                    _buildContentSection(),
                    if (_anuncio!.hasAttachments) ...[
                      const SizedBox(height: 8),
                      _buildAttachmentsSection(),
                    ],
                    const SizedBox(height: 8),
                    _buildStatsSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      title: 'Anuncio',
      showBack: true,
      leadingIcon: Icons.campaign,
      onBack: () => context.pop(),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareAnuncio,
        ),
        if (_canEdit())
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              context.push('/anuncios/create', extra: _anuncio);
            },
          ),
        if (_canDelete())
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _confirmDelete,
          ),
      ],
      bottom: _anuncio!.destacado
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 6),
                  Text(
                    'ANUNCIO DESTACADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildTitleSection() {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy HH:mm', 'es');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            _anuncio!.titulo,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Metadata
          _buildMetaItem(
            icon: '👤',
            label: 'Por',
            value: _anuncio!.creador.fullName,
          ),
          const SizedBox(height: 8),
          _buildMetaItem(
            icon: '📅',
            label: 'Fecha',
            value: dateFormat.format(
              _anuncio!.fechaPublicacion ?? _anuncio!.createdAt,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetaItem(
            icon: '👥',
            label: 'Para',
            value: _anuncio!.audienceText,
          ),

          // Badge borrador
          if (!_anuncio!.estaPublicado)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anuncio en Borrador',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Este anuncio aún no ha sido publicado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_canEdit())
                    ElevatedButton(
                      onPressed: _publishAnuncio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                      ),
                      child: const Text('Publicar'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Text(
        _anuncio!.contenido,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📎 Archivos Adjuntos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...(_anuncio!.archivosAdjuntos.map((adjunto) {
            return GestureDetector(
              onTap: () => _downloadAttachment(adjunto),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFBBF7D0)),
                      ),
                      child: Center(
                        child: Text(adjunto.icon,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adjunto.nombre,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            adjunto.formattedSize,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.download_rounded,
                        color: Color(0xFF059669), size: 22),
                  ],
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: '👁️',
            value: '${_anuncio!.lecturas.length}',
            label: 'Lecturas',
          ),
          _buildStatItem(
            icon: '📎',
            value: '${_anuncio!.attachmentCount}',
            label: 'Adjuntos',
          ),
          _buildStatItem(
            icon: _anuncio!.estaPublicado ? '✅' : '📝',
            value: _anuncio!.estaPublicado ? 'Publicado' : 'Borrador',
            label: 'Estado',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _shareAnuncio() {
    // TODO: Implementar share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de compartir próximamente')),
    );
  }

  Future<void> _publishAnuncio() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Publicar Anuncio'),
          content:
              const Text('¿Estás seguro de que deseas publicar este anuncio?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Publicar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final provider = context.read<AnuncioProvider>();
        final updated = await provider.publicarAnuncio(widget.anuncioId);

        setState(() => _anuncio = updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Anuncio publicado correctamente'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeDeError(e, 'Error al publicar'))),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Anuncio'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este anuncio? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final provider = context.read<AnuncioProvider>();
        await provider.deleteAnuncio(widget.anuncioId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Anuncio eliminado correctamente'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          context.pop();
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

  Future<void> _downloadAttachment(ArchivoAdjunto adjunto) async {
    await FileHelper.downloadAndOpen(
      context,
      '/anuncios/${widget.anuncioId}/adjunto/${adjunto.fileId}',
      adjunto.nombre,
    );
  }
}
