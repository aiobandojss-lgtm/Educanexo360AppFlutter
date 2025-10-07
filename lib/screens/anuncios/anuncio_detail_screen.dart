// lib/screens/anuncios/anuncio_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/anuncio.dart';
import '../../providers/anuncio_provider.dart';
import '../../services/permission_service.dart';

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

  Future<void> _loadAnuncio() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<AnuncioProvider>();
      final anuncio = await provider.getAnuncioById(widget.anuncioId);

      if (anuncio != null) {
        setState(() {
          _anuncio = anuncio;
          _isLoading = false;
        });

        // Marcar como leído
        provider.markAsRead(widget.anuncioId);
      } else {
        _showError('Anuncio no encontrado');
      }
    } catch (e) {
      _showError('Error al cargar el anuncio');
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
          ),
        ),
      );
    }

    if (_anuncio == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Anuncio no encontrado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Spacer(),
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
          ),
          if (_anuncio!.destacado)
            Container(
              margin: const EdgeInsets.only(top: 8),
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
            ),
        ],
      ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anuncio en Borrador',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(adjunto.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adjunto.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adjunto.formattedSize,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF10B981)),
                    onPressed: () => _downloadAttachment(adjunto),
                  ),
                ],
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
          SnackBar(content: Text('Error al publicar: $e')),
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
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  void _downloadAttachment(ArchivoAdjunto adjunto) {
    // TODO: Implementar descarga según plataforma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descargando ${adjunto.nombre}...')),
    );
  }
}
