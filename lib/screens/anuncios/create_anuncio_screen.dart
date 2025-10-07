// lib/screens/anuncios/create_anuncio_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/anuncio.dart';
import '../../providers/anuncio_provider.dart';
import '../../services/permission_service.dart';

class CreateAnuncioScreen extends StatefulWidget {
  final Anuncio? anuncio; // Si viene con anuncio, es modo edición

  const CreateAnuncioScreen({
    super.key,
    this.anuncio,
  });

  @override
  State<CreateAnuncioScreen> createState() => _CreateAnuncioScreenState();
}

class _CreateAnuncioScreenState extends State<CreateAnuncioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();

  bool _paraEstudiantes = true;
  bool _paraDocentes = false;
  bool _paraPadres = true;
  bool _destacado = false;

  final List<File> _adjuntos = [];
  bool _isSubmitting = false;

  bool get _isEditing => widget.anuncio != null;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (_isEditing && widget.anuncio != null) {
      _tituloController.text = widget.anuncio!.titulo;
      _contenidoController.text = widget.anuncio!.contenido;
      _paraEstudiantes = widget.anuncio!.paraEstudiantes;
      _paraDocentes = widget.anuncio!.paraDocentes;
      _paraPadres = widget.anuncio!.paraPadres;
      _destacado = widget.anuncio!.destacado;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar permisos
    if (!PermissionService.canAccess('anuncios.crear') && !_isEditing) {
      return _buildNoAccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTituloField(),
                      const SizedBox(height: 16),
                      _buildAudienciaSection(),
                      const SizedBox(height: 16),
                      _buildContenidoField(),
                      const SizedBox(height: 16),
                      _buildOpcionesSection(),
                      const SizedBox(height: 16),
                      _buildAdjuntosSection(),
                      if (_isEditing && widget.anuncio!.hasAttachments)
                        _buildExistingAttachmentsInfo(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEditing ? 'Editar Anuncio' : 'Nuevo Anuncio',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          TextButton.icon(
            onPressed:
                _isSubmitting ? null : () => _handleSave(publicar: false),
            icon: const Icon(Icons.save, color: Colors.white, size: 20),
            label: const Text(
              'Borrador',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Título del Anuncio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                hintText: 'Escribe un título llamativo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título es obligatorio';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienciaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Audiencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona a quién va dirigido el anuncio',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildAudienceSwitch(
              title: '🎓 Estudiantes',
              value: _paraEstudiantes,
              onChanged: (value) => setState(() => _paraEstudiantes = value),
            ),
            _buildAudienceSwitch(
              title: '👩‍🏫 Docentes',
              value: _paraDocentes,
              onChanged: (value) => setState(() => _paraDocentes = value),
            ),
            _buildAudienceSwitch(
              title: '👨‍👩‍👧‍👦 Padres',
              value: _paraPadres,
              onChanged: (value) => setState(() => _paraPadres = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceSwitch({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💬 Contenido del Anuncio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contenidoController,
              decoration: InputDecoration(
                hintText: 'Escribe el contenido de tu anuncio aquí...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              maxLines: 10,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El contenido es obligatorio';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Opciones Adicionales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⭐ Anuncio Destacado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Aparecerá en la parte superior de la lista',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _destacado,
                  onChanged: (value) => setState(() => _destacado = value),
                  activeColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjuntosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📎 Documentos Adjuntos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Adjuntar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_adjuntos.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay documentos adjuntos',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ..._adjuntos.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                final fileName = file.path.split('/').last;
                final fileSize = file.lengthSync();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('📎', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatFileSize(fileSize),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() => _adjuntos.removeAt(index));
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingAttachmentsInfo() {
    return Card(
      color: const Color(0xFFE0F2FE),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF0277BD), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ℹ️ Este anuncio tiene ${widget.anuncio!.attachmentCount} archivo(s) adjunto(s) existente(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0277BD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _handleSave(publicar: true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isEditing ? '📢 Actualizar Anuncio' : '📢 Publicar Anuncio',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildNoAccessScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Restringido'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚫', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Acceso Restringido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No tienes permisos para crear anuncios',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _adjuntos.addAll(
            result.paths.map((path) => File(path!)).toList(),
          );
        });
      }
    } catch (e) {
      _showError('Error al seleccionar archivos');
    }
  }

  Future<void> _handleSave({required bool publicar}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que tenga al menos una audiencia
    if (!_paraEstudiantes && !_paraDocentes && !_paraPadres) {
      _showError('Debes seleccionar al menos una audiencia');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<AnuncioProvider>();

      if (_isEditing) {
        // Actualizar anuncio existente
        await provider.updateAnuncio(
          anuncioId: widget.anuncio!.id,
          titulo: _tituloController.text.trim(),
          contenido: _contenidoController.text.trim(),
          paraEstudiantes: _paraEstudiantes,
          paraDocentes: _paraDocentes,
          paraPadres: _paraPadres,
          destacado: _destacado,
          nuevosAdjuntos: _adjuntos.isEmpty ? null : _adjuntos,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Anuncio actualizado exitosamente'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          context.pop();
        }
      } else {
        // Crear nuevo anuncio
        await provider.createAnuncio(
          titulo: _tituloController.text.trim(),
          contenido: _contenidoController.text.trim(),
          paraEstudiantes: _paraEstudiantes,
          paraDocentes: _paraDocentes,
          paraPadres: _paraPadres,
          destacado: _destacado,
          publicar: publicar,
          adjuntos: _adjuntos.isEmpty ? null : _adjuntos,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                publicar
                    ? '✅ Tu anuncio ha sido publicado exitosamente'
                    : '✅ Tu anuncio se ha guardado como borrador',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('No se pudo guardar el anuncio. Intenta nuevamente.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
