// lib/screens/messages/create_message_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';
import '../../services/permission_service.dart';

/// ✏️ PANTALLA DE CREAR/RESPONDER/EDITAR MENSAJE
/// ✅ Soporte para: crear nuevo, responder, editar borrador
class CreateMessageScreen extends StatefulWidget {
  // 🆕 Parámetros opcionales para diferentes modos
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
      // 📧 MODO RESPUESTA
      _asuntoController.text = original.asunto.startsWith('Re: ')
          ? original.asunto
          : 'Re: ${original.asunto}';
      _selectedRecipients = [original.remitente];
      _prioridad = original.prioridad;
    } else if (widget.isDraftEdit) {
      // ✏️ MODO EDITAR BORRADOR
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

  @override
  Widget build(BuildContext context) {
    final canSendMasive = PermissionService.canAccess('mensajes.enviar_masivo');

    String title = 'Nuevo Mensaje';
    if (widget.isReply) title = 'Responder Mensaje';
    if (widget.isDraftEdit) title = 'Editar Borrador';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (!widget.isReply)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _handleSaveDraft,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Borrador'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.isReply && widget.originalMessage != null)
                      _buildOriginalMessageInfo(),
                    _buildRecipientsSection(),
                    const SizedBox(height: 16),
                    if (canSendMasive && !widget.isReply) ...[
                      _buildCourseSection(),
                      const SizedBox(height: 16),
                    ],
                    _buildAsuntoField(),
                    const SizedBox(height: 16),
                    _buildContenidoField(),
                    const SizedBox(height: 16),
                    _buildPrioridadSelector(),
                    const SizedBox(height: 16),
                    _buildAttachmentsSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : _handleSendMessage,
          icon: const Icon(Icons.send),
          label: Text(widget.isDraftEdit ? 'Enviar Borrador' : 'Enviar'),
        ),
      ),
    );
  }

  Widget _buildOriginalMessageInfo() {
    final original = widget.originalMessage!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reply, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Respondiendo a:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          Text('De: ${original.remitente.fullName}'),
          Text('Asunto: ${original.asunto}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRecipientsSection() {
    final isReadOnly = widget.isReply;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline, size: 20),
                const SizedBox(width: 8),
                Text(isReadOnly ? 'Para:' : 'Destinatarios individuales',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedRecipients.isEmpty)
              Text(isReadOnly ? 'Sin destinatarios' : 'Toca para seleccionar',
                  style: TextStyle(color: Colors.grey[600]))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedRecipients.map((user) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(user.avatarColor),
                      child: Text(user.initials,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
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
                    minimumSize: const Size(double.infinity, 40)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('Envío masivo a curso',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedCourse == null)
              Text('Opcional: Enviar a todos los estudiantes de un curso',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14))
            else
              Chip(
                avatar: const CircleAvatar(child: Icon(Icons.school, size: 18)),
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
                  minimumSize: const Size(double.infinity, 40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsuntoField() {
    return TextFormField(
      controller: _asuntoController,
      decoration: const InputDecoration(
        labelText: 'Asunto *',
        hintText: 'Escribe el asunto del mensaje',
        prefixIcon: Icon(Icons.subject),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return 'El asunto es obligatorio';
        if (value.trim().length < 3)
          return 'El asunto debe tener al menos 3 caracteres';
        return null;
      },
    );
  }

  Widget _buildContenidoField() {
    return TextFormField(
      controller: _contenidoController,
      decoration: const InputDecoration(
        labelText: 'Mensaje *',
        hintText: 'Escribe tu mensaje aquí...',
        prefixIcon: Icon(Icons.message),
        border: OutlineInputBorder(),
      ),
      maxLines: 8,
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return 'El mensaje es obligatorio';
        if (value.trim().length < 10)
          return 'El mensaje debe tener al menos 10 caracteres';
        return null;
      },
    );
  }

  Widget _buildPrioridadSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('Prioridad',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        backgroundColor: isSelected ? color.withOpacity(0.1) : null,
        side: BorderSide(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(prioridad.icon),
          const SizedBox(width: 4),
          Text(prioridad.displayName),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, size: 20),
                const SizedBox(width: 8),
                Text(
                    'Archivos adjuntos${_attachments.isNotEmpty ? " (${_attachments.length})" : ""}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (_attachments.isNotEmpty) ...[
              ..._attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                final fileName = file.path.split('/').last;
                final fileSize = file.lengthSync();
                final sizeKB = (fileSize / 1024).toStringAsFixed(1);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fileName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('$sizeKB KB',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _attachments.removeAt(index);
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _handleAttachFile,
              icon: const Icon(Icons.add),
              label: const Text('Adjuntar archivo'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40)),
            ),
          ],
        ),
      ),
    );
  }

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
              child: const Text('Cancelar')),
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

  void _showRecipientSelector() async {
    final messageProvider = context.read<MessageProvider>();
    final recipients = messageProvider.availableRecipients;

    final selected = await showDialog<List<User>>(
      context: context,
      builder: (context) => _RecipientSelectorDialog(
          recipients: recipients, selectedRecipients: _selectedRecipients),
    );

    if (selected != null) {
      setState(() {
        _selectedRecipients = selected;
        _hasUnsavedChanges = true;
      });
    }
  }

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

  Future<void> _handleAttachFile() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(allowMultiple: true, type: FileType.any);

      if (result != null) {
        final newFiles = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        setState(() {
          _attachments.addAll(newFiles);
          _hasUnsavedChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newFiles.length} archivo(s) adjuntado(s)')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al adjuntar: $e')),
      );
    }
  }

  Future<void> _handleSendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRecipients.isEmpty && _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Debes seleccionar al menos un destinatario o un curso')),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final messageProvider = context.read<MessageProvider>();

      if (widget.isDraftEdit && widget.originalMessage != null) {
        await messageProvider.sendDraft(widget.originalMessage!.id);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Borrador enviado')));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Mensaje enviado')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSaveDraft() async {
    if (_asuntoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El asunto es obligatorio para guardar')),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final messageProvider = context.read<MessageProvider>();

      await messageProvider.saveDraft(
        destinatarios: _selectedRecipients.map((u) => u.id).toList(),
        cursoIds: _selectedCourse != null ? [_selectedCourse!.id] : null,
        asunto: _asuntoController.text.trim(),
        contenido: _contenidoController.text.trim(),
        prioridad: _prioridad,
        adjuntos: _attachments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ Borrador guardado')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// DIALOGS
class _RecipientSelectorDialog extends StatefulWidget {
  final List<User> recipients;
  final List<User> selectedRecipients;

  const _RecipientSelectorDialog(
      {required this.recipients, required this.selectedRecipients});

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
    return AlertDialog(
      title: const Text('Seleccionar destinatarios'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRecipients.length,
                itemBuilder: (context, index) {
                  final user = _filteredRecipients[index];
                  final isSelected = _selected.any((u) => u.id == user.id);

                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(user.fullName),
                    subtitle: Text('${user.tipo} • ${user.email}'),
                    secondary: CircleAvatar(
                      backgroundColor: Color(user.avatarColor),
                      child: Text(user.initials,
                          style: const TextStyle(color: Colors.white)),
                    ),
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
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('Seleccionar (${_selected.length})'),
        ),
      ],
    );
  }
}

class _CourseSelectorDialog extends StatelessWidget {
  final List<Course> courses;

  const _CourseSelectorDialog({required this.courses});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar curso'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.school)),
              title: Text(course.nombre),
              subtitle: Text(course.fullDescription),
              onTap: () => Navigator.pop(context, course),
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
      ],
    );
  }
}
