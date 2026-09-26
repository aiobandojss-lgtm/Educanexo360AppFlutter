// lib/screens/calendario/create_evento_screen.dart

import '../../utils/logger.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_config.dart';
import '../../models/evento.dart';
import '../../providers/calendario_provider.dart';
import '../../widgets/common/gradient_header.dart';

class CreateEventoScreen extends StatefulWidget {
  final Evento? evento;
  final DateTime? fechaInicial;

  const CreateEventoScreen({
    super.key,
    this.evento,
    this.fechaInicial,
  });

  @override
  State<CreateEventoScreen> createState() => _CreateEventoScreenState();
}

class _CreateEventoScreenState extends State<CreateEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditMode;
  bool _isSaving = false;

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _lugarController = TextEditingController();

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _horaInicio = TimeOfDay.now();
  TimeOfDay _horaFin = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);
  bool _todoElDia = false;
  EventType _tipoSeleccionado = EventType.academico;
  EventStatus _estadoSeleccionado = EventStatus.activo;
  File? _archivoAdjunto;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.evento != null;

    if (_isEditMode) {
      _loadEventoData();
    } else if (widget.fechaInicial != null) {
      _fechaInicio = widget.fechaInicial!;
      _fechaFin = widget.fechaInicial!.add(const Duration(hours: 1));
    }
  }

  void _loadEventoData() {
    final evento = widget.evento!;

    dlog('✏️ Cargando datos del evento para edición:');
    dlog('   Título: ${evento.titulo}');
    dlog('   Estado actual: ${evento.estado.value}');

    _tituloController.text = evento.titulo;
    _descripcionController.text = evento.descripcion;
    _lugarController.text = evento.lugar ?? '';
    _fechaInicio = evento.fechaInicio;
    _fechaFin = evento.fechaFin;
    _horaInicio = TimeOfDay.fromDateTime(evento.fechaInicio);
    _horaFin = TimeOfDay.fromDateTime(evento.fechaFin);
    _todoElDia = evento.todoElDia;
    _tipoSeleccionado = evento.tipo;
    _estadoSeleccionado = evento.estado;

    dlog('   Estado cargado en UI: ${_estadoSeleccionado.value}');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _lugarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header unificado
            GradientHeader(
              title: _isEditMode ? 'Editar Evento' : 'Crear Evento',
              showBack: true,
              leadingIcon: _isEditMode ? Icons.edit : Icons.event,
              onBack: () => Navigator.pop(context),
            ),
            // Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      title: 'Información básica',
                      children: [
                        _buildTextField(
                          controller: _tituloController,
                          label: 'Título del evento',
                          hint: 'Ej: Reunión de padres',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El título es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descripcionController,
                          label: 'Descripción',
                          hint: 'Describe el evento...',
                          icon: Icons.description,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La descripción es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _lugarController,
                          label: 'Lugar (opcional)',
                          hint: 'Ej: Auditorio principal',
                          icon: Icons.location_on,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Fecha y hora',
                      children: [
                        _buildSwitchTile(
                          title: 'Evento de todo el día',
                          value: _todoElDia,
                          onChanged: (value) {
                            setState(() => _todoElDia = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTimePicker(
                                label: 'Fecha inicio',
                                date: _fechaInicio,
                                time: _horaInicio,
                                showTime: !_todoElDia,
                                onDateChanged: (date) {
                                  setState(() => _fechaInicio = date);
                                },
                                onTimeChanged: (time) {
                                  setState(() => _horaInicio = time);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTimePicker(
                                label: 'Fecha fin',
                                date: _fechaFin,
                                time: _horaFin,
                                showTime: !_todoElDia,
                                onDateChanged: (date) {
                                  setState(() => _fechaFin = date);
                                },
                                onTimeChanged: (time) {
                                  setState(() => _horaFin = time);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Tipo de evento',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: EventType.values.map((tipo) {
                            final isSelected = _tipoSeleccionado == tipo;
                            return ChoiceChip(
                              label: Text('${tipo.icon} ${tipo.displayName}'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _tipoSeleccionado = tipo);
                                }
                              },
                              selectedColor:
                                  _getEventTypeColor(tipo).withOpacity(0.2),
                              labelStyle: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _getEventTypeColor(tipo)
                                    : Colors.grey[700],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Estado del evento',
                      children: [
                        if (_isEditMode)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_estadoSeleccionado)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(_estadoSeleccionado)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: _getStatusColor(_estadoSeleccionado),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Estado actual: ${_estadoSeleccionado.displayName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(_estadoSeleccionado),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: EventStatus.values.map((estado) {
                            final isSelected = _estadoSeleccionado == estado;
                            return ChoiceChip(
                              label: Text(estado.displayName),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    dlog(
                                        '🔄 Cambiando estado UI: ${_estadoSeleccionado.value} → ${estado.value}');
                                    _estadoSeleccionado = estado;
                                  });
                                }
                              },
                              selectedColor:
                                  _getStatusColor(estado).withOpacity(0.2),
                              labelStyle: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _getStatusColor(estado)
                                    : Colors.grey[700],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'El estado controla la visibilidad del evento para los usuarios.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Archivo adjunto (opcional)',
                      children: [
                        if (_archivoAdjunto != null)
                          _buildFileCard()
                        else if (_isEditMode &&
                            widget.evento!.archivoAdjunto != null)
                          _buildExistingFileCard()
                        else
                          _buildFilePickerButton(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required bool showTime,
    required ValueChanged<DateTime> onDateChanged,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, date, onDateChanged),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('d MMM yyyy', 'es_ES').format(date),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showTime) ...[
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, time, onTimeChanged),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Text(
                          time.format(context),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime currentDate,
    ValueChanged<DateTime> onChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay currentTime,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  Widget _buildFilePickerButton() {
    return OutlinedButton.icon(
      onPressed: _pickFile,
      icon: const Icon(Icons.attach_file),
      label: const Text('Seleccionar archivo'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    final file = _archivoAdjunto!;
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file,
              size: 32, color: Color(0xFF059669)),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  '${(fileSize / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _archivoAdjunto = null);
            },
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingFileCard() {
    final adjunto = widget.evento!.archivoAdjunto!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
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
                  'Archivo actual - ${adjunto.formattedSize}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickFile,
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        // Lista blanca (misma que mensajes): sin video ni audio, para que la
        // declaracion de Seguridad de los datos de Play siga siendo exacta
        type: FileType.custom,
        allowedExtensions: const [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt',
          'jpg', 'jpeg', 'png', 'gif', 'webp',
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final archivo = File(result.files.first.path!);

        // Límite del servidor: avisar antes de intentar subirlo
        const maxBytes = AppConfig.calendarioMaxArchivoMB * 1024 * 1024;
        final tamano = archivo.lengthSync();
        if (tamano > maxBytes) {
          _showError(
            'El archivo es muy grande '
            '(${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB). '
            'Máximo ${AppConfig.calendarioMaxArchivoMB} MB.',
          );
          return;
        }

        setState(() {
          _archivoAdjunto = archivo;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar archivo');
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveEvento,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_isEditMode ? 'Actualizar' : 'Crear evento'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEvento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final fechaInicio = DateTime(
        _fechaInicio.year,
        _fechaInicio.month,
        _fechaInicio.day,
        _todoElDia ? 0 : _horaInicio.hour,
        _todoElDia ? 0 : _horaInicio.minute,
      );

      final fechaFin = DateTime(
        _fechaFin.year,
        _fechaFin.month,
        _fechaFin.day,
        _todoElDia ? 23 : _horaFin.hour,
        _todoElDia ? 59 : _horaFin.minute,
      );

      if (fechaFin.isBefore(fechaInicio)) {
        _showError('La fecha de fin debe ser posterior a la fecha de inicio');
        setState(() => _isSaving = false);
        return;
      }

      dlog('\n📤 ===== GUARDANDO EVENTO =====');
      dlog('Título: ${_tituloController.text}');
      dlog('Tipo: ${_tipoSeleccionado.value}');
      dlog('Estado a enviar: ${_estadoSeleccionado.value}');
      dlog('Modo: ${_isEditMode ? "EDICIÓN" : "CREACIÓN"}');

      final provider = context.read<CalendarioProvider>();

      if (_isEditMode) {
        dlog('ID del evento: ${widget.evento!.id}');

        await provider.actualizarEvento(
          eventoId: widget.evento!.id,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          todoElDia: _todoElDia,
          lugar: _lugarController.text.isEmpty ? null : _lugarController.text,
          tipo: _tipoSeleccionado,
          estado: _estadoSeleccionado,
          archivoAdjunto: _archivoAdjunto,
        );

        dlog('✅ Evento actualizado con estado: ${_estadoSeleccionado.value}');
        _showSuccess('Evento actualizado exitosamente');
      } else {
        await provider.crearEvento(
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          todoElDia: _todoElDia,
          lugar: _lugarController.text.isEmpty ? null : _lugarController.text,
          tipo: _tipoSeleccionado,
          estado: _estadoSeleccionado,
          archivoAdjunto: _archivoAdjunto,
        );

        dlog('✅ Evento creado con estado: ${_estadoSeleccionado.value}');
        _showSuccess('Evento creado exitosamente');
      }

      dlog('===============================\n');

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      dlog('❌ Error al guardar evento: $e');
      _showError('Error al guardar evento: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
