// lib/screens/messages/create_message_screen.dart
// ✅ VERSIÓN FINAL - ESTRUCTURA ANTI-OVERFLOW + FUNCIONALIDAD COMPLETA

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';
import '../../services/permission_service.dart';

class CreateMessageScreen extends StatefulWidget {
  final Message? originalMessage;
  final bool isReply;
  final bool isDraftEdit;

  const CreateMessageScreen({
    super.key,
    this.originalMessage,
    this.isReply = false,
    this.isDraftEdit = false,
  });

  @override
  State<CreateMessageScreen> createState() => _CreateMessageScreenState();
}

class _CreateMessageScreenState extends State<CreateMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _contenidoController = TextEditingController();

  List<User> _selectedRecipients = [];
  Course? _selectedCourse;
  Prioridad _prioridad = Prioridad.normal;
  List<File> _attachments = [];
  bool _loading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadRecipientsAndCourses();

    _asuntoController.addListener(() => _hasUnsavedChanges = true);
    _contenidoController.addListener(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    _asuntoController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final original = widget.originalMessage;
    if (original == null) return;

    if (widget.isReply) {
      _asuntoController.text = original.asunto.startsWith('Re: ')
          ? original.asunto
          : 'Re: ${original.asunto}';
      _selectedRecipients = [original.remitente];
      _prioridad = original.prioridad;
    } else if (widget.isDraftEdit) {
      _asuntoController.text = original.asunto;
      _contenidoController.text = original.contenido;
      _selectedRecipients = original.destinatarios;
      _prioridad = original.prioridad;
    }
  }

  Future<void> _loadRecipientsAndCourses() async {
    final messageProvider = context.read<MessageProvider>();
    await messageProvider.loadRecipientsAndCourses();
  }

  // 🔧 VALIDACIÓN DE TAMAÑO DE ARCHIVOS
  bool _validateFileSize(List<File> files) {
    const maxFileSize = 4 * 1024 * 1024; // 4MB por archivo
    const maxTotalSize = 10 * 1024 * 1024; // 10MB total

    for (final file in files) {
      final size = file.lengthSync();
      if (size > maxFileSize) {
        final fileName = file.path.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El archivo "$fileName" es muy grande (${(size / (1024 * 1024)).toStringAsFixed(1)}MB). Máximo permitido es 4MB por archivo.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return false;
      }
    }

    final totalSize =
        files.fold<int>(0, (sum, file) => sum + file.lengthSync());
    if (totalSize > maxTotalSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El tamaño total de los archivos es muy grande (${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB). El máximo permitido es 10MB total.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  // 📎 ADJUNTAR DOCUMENTO
  Future<void> _handleAttachDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: true,
      );

      if (result != null) {
        final newFiles = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        final allAttachments = [..._attachments, ...newFiles];
        if (_validateFileSize(allAttachments)) {
          setState(() {
            _attachments.addAll(newFiles);
            _hasUnsavedChanges = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📎 ${newFiles.length} documento(s) agregado(s)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error seleccionando documento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al seleccionar el documento'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🖼️ ADJUNTAR IMAGEN
  // 🖼️ ADJUNTAR IMAGEN
  Future<void> _handleAttachImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70,
      );

      if (images.isNotEmpty) {
        final newFiles = images.map((xfile) => File(xfile.path)).toList();

        final allAttachments = [..._attachments, ...newFiles];
        if (_validateFileSize(allAttachments)) {
          setState(() {
            _attachments.addAll(newFiles);
            _hasUnsavedChanges = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🖼️ ${newFiles.length} imagen(es) agregada(s)'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error seleccionando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🗑️ ELIMINAR ADJUNTO
  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
      _hasUnsavedChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Archivo eliminado'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 📤 ENVIAR MENSAJE
  Future<void> _handleSendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRecipients.isEmpty && _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debes seleccionar al menos un destinatario o un curso'),
        ),
      );
      return;
    }

    if (_attachments.isNotEmpty && !_validateFileSize(_attachments)) {
      return;
    }

    try {
      setState(() => _loading = true);

      final messageProvider = context.read<MessageProvider>();

      debugPrint('📤 Enviando mensaje...');
      debugPrint('📋 Destinatarios: ${_selectedRecipients.length}');
      debugPrint('🏫 Curso: ${_selectedCourse?.nombre ?? "Ninguno"}');
      debugPrint('📎 Adjuntos: ${_attachments.length}');

      if (widget.isDraftEdit && widget.originalMessage != null) {
        await messageProvider.sendDraft(widget.originalMessage!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Borrador enviado correctamente')),
          );
          Navigator.pop(context);
        }
        return;
      }

      await messageProvider.createMessage(
        destinatarios: _selectedRecipients.map((u) => u.id).toList(),
        cursoIds: _selectedCourse != null ? [_selectedCourse!.id] : null,
        asunto: _asuntoController.text.trim(),
        contenido: _contenidoController.text.trim(),
        prioridad: _prioridad,
        adjuntos: _attachments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Mensaje enviado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error enviando mensaje: $e');

      if (mounted) {
        String errorMessage = 'No se pudo enviar el mensaje';
        if (e.toString().contains('message')) {
          errorMessage = e.toString().split('message:').last.trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 💾 GUARDAR BORRADOR
  Future<void> _handleSaveDraft() async {
    if (_asuntoController.text.trim().isEmpty &&
        _contenidoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe escribir al menos el asunto o el contenido'),
        ),
      );
      return;
    }

    if (_attachments.isNotEmpty && !_validateFileSize(_attachments)) {
      return;
    }

    try {
      setState(() => _loading = true);

      final messageProvider = context.read<MessageProvider>();

      debugPrint('💾 Guardando borrador...');

      await messageProvider.saveDraft(
        destinatarios: _selectedRecipients.map((u) => u.id).toList(),
        cursoIds: _selectedCourse != null ? [_selectedCourse!.id] : null,
        asunto: _asuntoController.text.trim().isEmpty
            ? '(Sin asunto)'
            : _asuntoController.text.trim(),
        contenido: _contenidoController.text.trim(),
        prioridad: _prioridad,
        adjuntos: _attachments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Borrador guardado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error guardando borrador: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🚪 CONFIRMACIÓN AL SALIR
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content:
            const Text('Tienes cambios sin guardar. ¿Deseas descartarlos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  // 👥 MOSTRAR SELECTOR DE DESTINATARIOS
  void _showRecipientSelector() async {
    final messageProvider = context.read<MessageProvider>();
    final recipients = messageProvider.availableRecipients;

    final selected = await showDialog<List<User>>(
      context: context,
      builder: (context) => _RecipientSelectorDialog(
        recipients: recipients,
        selectedRecipients: _selectedRecipients,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedRecipients = selected;
        _hasUnsavedChanges = true;
      });
    }
  }

  // 🏫 MOSTRAR SELECTOR DE CURSOS
  void _showCourseSelector() async {
    final messageProvider = context.read<MessageProvider>();
    final courses = messageProvider.availableCourses;

    final selected = await showDialog<Course>(
      context: context,
      builder: (context) => _CourseSelectorDialog(courses: courses),
    );

    if (selected != null) {
      setState(() {
        _selectedCourse = selected;
        _hasUnsavedChanges = true;
      });
    }
  }

  // 📊 FORMATEAR TAMAÑO DE ARCHIVO
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final canSendMasive = PermissionService.canAccess('mensajes.enviar_masivo');

    String title = 'Nuevo Mensaje';
    if (widget.isReply) title = 'Responder';
    if (widget.isDraftEdit) title = 'Editar Borrador';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (!widget.isReply)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _loading ? null : _handleSaveDraft,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Borrador'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                // ✅ ESTRUCTURA ANTI-OVERFLOW (igual al login)
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 📨 HEADER DE RESPUESTA (si aplica)
                        if (widget.isReply && widget.originalMessage != null)
                          _buildReplyHeader(),

                        // 📝 FORMULARIO PRINCIPAL
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 👥 DESTINATARIOS INDIVIDUALES
                              _buildRecipientsSection(),
                              const SizedBox(height: 16),

                              // 🏫 ENVÍO MASIVO A CURSO (solo si tiene permiso)
                              if (canSendMasive && !widget.isReply) ...[
                                _buildCourseSection(),
                                const SizedBox(height: 16),
                              ],

                              // ✉️ ASUNTO
                              _buildAsuntoField(),
                              const SizedBox(height: 16),

                              // 📄 CONTENIDO
                              _buildContenidoField(),
                              const SizedBox(height: 16),

                              // 🚩 PRIORIDAD
                              _buildPrioridadSelector(),
                              const SizedBox(height: 16),

                              // 📎 ADJUNTOS
                              _buildAttachmentsSection(),

                              // 🔽 ESPACIO PARA FAB
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        floatingActionButton: _loading
            ? null
            : FloatingActionButton.extended(
                onPressed: _handleSendMessage,
                icon: const Icon(Icons.send),
                label: Text(widget.isDraftEdit ? 'Enviar Borrador' : 'Enviar'),
              ),
      ),
    );
  }

  // 📨 WIDGET: HEADER DE RESPUESTA
  Widget _buildReplyHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Respondiendo a:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.originalMessage!.asunto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 👥 WIDGET: DESTINATARIOS
  Widget _buildRecipientsSection() {
    final isReadOnly = widget.isReply;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 22, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  isReadOnly ? 'Para:' : 'Destinatarios individuales',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedRecipients.isEmpty)
              Text(
                isReadOnly ? 'Sin destinatarios' : 'Ninguno seleccionado',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedRecipients.map((user) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(user.avatarColor),
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(user.fullName),
                    deleteIcon:
                        isReadOnly ? null : const Icon(Icons.close, size: 18),
                    onDeleted: isReadOnly
                        ? null
                        : () {
                            setState(() {
                              _selectedRecipients.remove(user);
                              _hasUnsavedChanges = true;
                            });
                          },
                  );
                }).toList(),
              ),
            if (!isReadOnly) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showRecipientSelector,
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar destinatarios'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  backgroundColor: Colors.indigo,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🏫 WIDGET: CURSO
  Widget _buildCourseSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined,
                    size: 22, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Envío masivo a curso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Opcional: Enviar a todos los estudiantes de un curso',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_selectedCourse == null)
              const Text(
                'Ningún curso seleccionado',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            else
              Chip(
                avatar: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.school, size: 18, color: Colors.white),
                ),
                label: Text(_selectedCourse!.fullDescription),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedCourse = null;
                    _hasUnsavedChanges = true;
                  });
                },
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showCourseSelector,
              icon: const Icon(Icons.class_outlined),
              label: const Text('Seleccionar curso'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✉️ WIDGET: ASUNTO
  Widget _buildAsuntoField() {
    return TextFormField(
      controller: _asuntoController,
      decoration: InputDecoration(
        labelText: 'Asunto *',
        hintText: 'Escribe el asunto del mensaje',
        prefixIcon: const Icon(Icons.subject),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El asunto es obligatorio';
        }
        if (value.trim().length < 3) {
          return 'El asunto debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  // 📄 WIDGET: CONTENIDO
  Widget _buildContenidoField() {
    return TextFormField(
      controller: _contenidoController,
      decoration: InputDecoration(
        labelText: 'Mensaje *',
        hintText: 'Escribe tu mensaje aquí...',
        prefixIcon: const Icon(Icons.message),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: true,
      ),
      maxLines: 8,
      maxLength: 5000,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El mensaje es obligatorio';
        }
        if (value.trim().length < 10) {
          return 'El mensaje debe tener al menos 10 caracteres';
        }
        return null;
      },
    );
  }

  // 🚩 WIDGET: PRIORIDAD
  Widget _buildPrioridadSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 22, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Prioridad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPrioridadButton(Prioridad.alta)),
                const SizedBox(width: 8),
                Expanded(child: _buildPrioridadButton(Prioridad.normal)),
                const SizedBox(width: 8),
                Expanded(child: _buildPrioridadButton(Prioridad.baja)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioridadButton(Prioridad prioridad) {
    final isSelected = _prioridad == prioridad;
    final color = Color(prioridad.color);

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _prioridad = prioridad;
          _hasUnsavedChanges = true;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.15) : null,
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Text(
            prioridad.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            prioridad.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // 📎 WIDGET: ADJUNTOS
  Widget _buildAttachmentsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, size: 22, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Archivos adjuntos${_attachments.isNotEmpty ? " (${_attachments.length})" : ""}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BOTONES DE ADJUNTAR
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleAttachDocument,
                    icon: const Text('📎', style: TextStyle(fontSize: 18)),
                    label: const Text('Documento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleAttachImage,
                    icon: const Text('🖼️', style: TextStyle(fontSize: 18)),
                    label: const Text('Imagen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // LISTA DE ARCHIVOS ADJUNTOS
            if (_attachments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Ningún archivo adjunto',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  final fileName = file.path.split('/').last;
                  final fileSize = file.lengthSync();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(fileName),
                          size: 28,
                          color: Colors.purple[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatFileSize(fileSize),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: Colors.red[700],
                          onPressed: () => _removeAttachment(index),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            // INFORMACIÓN DE LÍMITES
            if (_attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Límites: 4MB por archivo, 10MB total',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 📄 HELPER: ICONO DE ARCHIVO
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// ============================================
// 🔹 DIALOG: SELECTOR DE DESTINATARIOS
// ============================================

class _RecipientSelectorDialog extends StatefulWidget {
  final List<User> recipients;
  final List<User> selectedRecipients;

  const _RecipientSelectorDialog({
    required this.recipients,
    required this.selectedRecipients,
  });

  @override
  State<_RecipientSelectorDialog> createState() =>
      _RecipientSelectorDialogState();
}

class _RecipientSelectorDialogState extends State<_RecipientSelectorDialog> {
  late List<User> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedRecipients);
  }

  List<User> get _filteredRecipients {
    if (_searchQuery.isEmpty) return widget.recipients;
    final query = _searchQuery.toLowerCase();
    return widget.recipients.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.tipo.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Seleccionar Destinatarios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // BÚSQUEDA
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '🔍 Buscar por nombre, email o rol...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // CONTADOR DE SELECCIONADOS
            if (_selected.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.indigo[50],
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.indigo[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_selected.length} destinatario(s) seleccionado(s)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ],
                ),
              ),

            // LISTA DE USUARIOS
            Expanded(
              child: _filteredRecipients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron usuarios',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredRecipients.length,
                      itemBuilder: (context, index) {
                        final user = _filteredRecipients[index];
                        final isSelected =
                            _selected.any((u) => u.id == user.id);

                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${user.tipo} • ${user.email}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: Color(user.avatarColor),
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          activeColor: Colors.indigo,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selected.add(user);
                              } else {
                                _selected.removeWhere((u) => u.id == user.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            // BOTONES DE ACCIÓN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _selected),
                      icon: const Icon(Icons.check),
                      label: Text('Seleccionar (${_selected.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 🔹 DIALOG: SELECTOR DE CURSOS
// ============================================

class _CourseSelectorDialog extends StatelessWidget {
  final List<Course> courses;

  const _CourseSelectorDialog({required this.courses});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Seleccionar Curso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // LISTA DE CURSOS
            Expanded(
              child: courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.class_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay cursos disponibles',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[700],
                              child:
                                  const Icon(Icons.class_, color: Colors.white),
                            ),
                            title: Text(
                              course.fullDescription,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '👥 ${course.cantidadEstudiantes} estudiantes',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pop(context, course),
                          ),
                        );
                      },
                    ),
            ),

            // BOTÓN CANCELAR
            Container(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
