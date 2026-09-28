// lib/screens/tareas/entregar_tarea_screen.dart
// ✅ Pantalla para que el estudiante entregue una tarea con archivos

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart' show mensajeDeError;
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../widgets/tareas/file_uploader_widget.dart';
import '../../widgets/common/gradient_header.dart';

class EntregarTareaScreen extends StatefulWidget {
  final String tareaId;

  const EntregarTareaScreen({
    super.key,
    required this.tareaId,
  });

  @override
  State<EntregarTareaScreen> createState() => _EntregarTareaScreenState();
}

class _EntregarTareaScreenState extends State<EntregarTareaScreen> {
  final TextEditingController _comentarioController = TextEditingController();
  final List<File> _archivos = [];

  Tarea? _tarea;
  bool _loading = true;
  bool _enviando = false;
  double? _progreso; // 0..1 mientras se suben los archivos
  bool _success = false;
  String? _error;
  bool _descripcionExpandida = false;

  @override
  void initState() {
    super.initState();
    _loadTarea();
  }

  // Progreso de subida (se actualiza por cada 1 %)
  void _onSendProgress(int sent, int total) {
    if (total <= 0 || !mounted) return;
    final progreso = sent / total;
    final anterior = _progreso;
    // progreso < anterior: la subida se reinició (reintento tras 401)
    if (anterior == null ||
        progreso < anterior ||
        progreso - anterior >= 0.01 ||
        progreso >= 1) {
      setState(() => _progreso = progreso);
    }
  }

  String get _textoEnviando {
    final progreso = _progreso;
    if (progreso == null) return 'Entregando...';
    if (progreso < 1) return 'Subiendo ${(progreso * 100).round()}%';
    return 'Procesando...';
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _loadTarea() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final tareaProvider = context.read<TareaProvider>();
      final tarea = await tareaProvider.obtenerTarea(widget.tareaId);

      setState(() {
        _tarea = tarea;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onFilesChanged(List<File> files) {
    setState(() {
      _archivos.clear();
      _archivos.addAll(files);
    });
  }

  Future<void> _handleEntregar() async {
    // Validación: debe tener al menos un archivo o comentario
    if (_archivos.isEmpty && _comentarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Debes adjuntar al menos un archivo o escribir un comentario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _enviando = true;
        _progreso = null;
        _error = null;
      });

      final tareaProvider = context.read<TareaProvider>();

      await tareaProvider.entregarTarea(
        tareaId: widget.tareaId,
        archivos: _archivos,
        comentarioEstudiante: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
        onSendProgress: _archivos.isEmpty ? null : _onSendProgress,
      );

      setState(() {
        _enviando = false;
        _success = true;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tarea entregada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      // Redirigir después de 2 segundos
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      context.pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _enviando = false;
        _success = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Mensaje del backend (p. ej. tipo de archivo no permitido)
          content: Text(mensajeDeError(e, 'No se pudo entregar la tarea')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Entregar Tarea',
              showBack: true,
              leadingIcon: Icons.upload_file,
            ),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    if (_error != null && _tarea == null) {
      return Scaffold(
        body: Column(
          children: [
            const GradientHeader(
              title: 'Error',
              showBack: true,
              leadingIcon: Icons.upload_file,
            ),
            Expanded(
              child: Center(
                child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
            ),
          ],
        ),
      );
    }

    if (_tarea == null) {
      return const Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Entregar Tarea',
              showBack: true,
              leadingIcon: Icons.upload_file,
            ),
            Expanded(child: Center(child: Text('Tarea no encontrada'))),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            title: 'Entregar Tarea',
            showBack: true,
            leadingIcon: Icons.upload_file,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la tarea
              Text(
                _tarea!.titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Información de la tarea
              _buildTareaInfo(),

              const SizedBox(height: 24),

              // Campo de comentario
              _buildComentarioField(),

              const SizedBox(height: 24),

              // File Uploader
              AbsorbPointer(
                absorbing: _enviando || _success,
                child: Opacity(
                  opacity: _enviando || _success ? 0.5 : 1.0,
                  child: FileUploader(
                    archivosSeleccionados: _archivos,
                    onArchivosChanged: _onFilesChanged,
                    maxArchivos: AppConfig.tareaMaxArchivos,
                    maxTamanoMB: AppConfig.tareaMaxArchivoMB,
                    titulo: 'Archivos de la entrega',
                    descripcion: 'Sube los archivos de tu tarea',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Advertencia si no hay archivos ni comentario
              if (_archivos.isEmpty &&
                  _comentarioController.text.trim().isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Debes adjuntar al menos un archivo o escribir un comentario para poder entregar',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Mensajes de error o éxito
              if (_error != null && !_success)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_success)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¡Tarea entregada exitosamente! Redirigiendo...',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _enviando || _success ? null : () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _enviando ||
                              _success ||
                              (_archivos.isEmpty &&
                                  _comentarioController.text.trim().isEmpty)
                          ? null
                          : _handleEntregar,
                      icon: _enviando
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                                value: _progreso != null && _progreso! < 1
                                    ? _progreso
                                    : null,
                              ),
                            )
                          : const Icon(Icons.send),
                      label:
                          Text(_enviando ? _textoEnviando : 'Entregar Tarea'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaInfo() {
    final descripcion = _tarea!.descripcion;
    final esLarga = descripcion.length > 120;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción de la tarea:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: const TextStyle(fontSize: 15, height: 1.5),
            maxLines: _descripcionExpandida ? null : 3,
            overflow: _descripcionExpandida
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (esLarga) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(
                  () => _descripcionExpandida = !_descripcionExpandida),
              child: Text(
                _descripcionExpandida ? 'Ver menos ▲' : 'Ver más ▼',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComentarioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentario (opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comentarioController,
          maxLines: 4,
          enabled: !_enviando && !_success,
          decoration: InputDecoration(
            hintText: 'Escribe aquí cualquier comentario sobre tu entrega...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }
}
