// lib/screens/tareas/calificar_entrega_screen.dart
// ⭐ CALIFICAR ENTREGA - DOCENTES

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../widgets/tareas/estado_badge.dart';
import '../../widgets/tareas/archivo_tile.dart';

class CalificarEntregaScreen extends StatefulWidget {
  final String tareaId;
  final String entregaId;

  const CalificarEntregaScreen({
    super.key,
    required this.tareaId,
    required this.entregaId,
  });

  @override
  State<CalificarEntregaScreen> createState() => _CalificarEntregaScreenState();
}

class _CalificarEntregaScreenState extends State<CalificarEntregaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _calificacionController = TextEditingController();
  final TextEditingController _retroalimentacionController =
      TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  Tarea? _tarea;
  EntregaTarea? _entrega;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _calificacionController.dispose();
    _retroalimentacionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final tareaProvider = context.read<TareaProvider>();

      // Obtener tarea
      final tarea = await tareaProvider.obtenerTarea(widget.tareaId);
      if (tarea != null) {
        setState(() {
          _tarea = tarea;
        });
      }

      // Obtener entregas y buscar la específica
      final entregas = await tareaProvider.verEntregas(widget.tareaId);
      final entrega = entregas.firstWhere((e) => e.id == widget.entregaId);

      setState(() {
        _entrega = entrega;

        // Si ya está calificada, pre-llenar los campos
        if (entrega.estaCalificada) {
          _calificacionController.text = entrega.calificacion?.toString() ?? '';
          _retroalimentacionController.text = entrega.comentarioDocente ?? '';
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar entrega: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarCalificacion() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final tareaProvider = context.read<TareaProvider>();
      final calificacion = double.parse(_calificacionController.text.trim());
      final retroalimentacion = _retroalimentacionController.text.trim();

      await tareaProvider.calificarEntrega(
        tareaId: widget.tareaId,
        entregaId: widget.entregaId,
        calificacion: calificacion,
        comentarioDocente:
            retroalimentacion.isNotEmpty ? retroalimentacion : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entrega calificada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver a la lista de entregas
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al calificar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Calificar Entrega'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _isSaving,
              child: Opacity(
                opacity: _isSaving ? 0.6 : 1.0,
                child: Column(
                  children: [
                    // Header con info del estudiante
                    if (_entrega != null && _tarea != null) _buildHeader(),

                    // Contenido scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Información de la tarea
                            if (_tarea != null) _buildTareaInfo(),
                            const SizedBox(height: 20),

                            // Estado de la entrega
                            if (_entrega != null) _buildEstadoEntrega(),
                            const SizedBox(height: 20),

                            // Archivos entregados
                            if (_entrega != null &&
                                _entrega!.archivos.isNotEmpty)
                              _buildArchivosEntregados(),
                            const SizedBox(height: 20),

                            // Comentario del estudiante
                            if (_entrega != null &&
                                _entrega!.comentarioEstudiante != null &&
                                _entrega!.comentarioEstudiante!.isNotEmpty)
                              _buildComentarioEstudiante(),
                            const SizedBox(height: 30),

                            // Formulario de calificación
                            _buildFormularioCalificacion(),
                            const SizedBox(height: 30),

                            // Botones de acción
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ========================================
  // 🎨 HEADER
  // ========================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF8B5CF6),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Estudiante',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_entrega!.estudiante?.nombre ?? ''} ${_entrega!.estudiante?.apellidos ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _entrega!.estudiante?.email ?? '',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📋 INFORMACIÓN DE LA TAREA
  // ========================================

  Widget _buildTareaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Información de la Tarea',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _tarea!.titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.book,
            label: 'Asignatura',
            value: _tarea!.asignatura.nombre,
          ),
          _buildInfoItem(
            icon: Icons.group,
            label: 'Curso',
            value: _tarea!.curso.nombre,
          ),
          _buildInfoItem(
            icon: Icons.star,
            label: 'Calificación máxima',
            value: '${_tarea!.calificacionMaxima.toStringAsFixed(1)} puntos',
          ),
          _buildInfoItem(
            icon: Icons.schedule,
            label: 'Fecha límite',
            value: _tarea!.fechaLimiteFormateada,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📊 ESTADO DE LA ENTREGA
  // ========================================

  Widget _buildEstadoEntrega() {
    final estadoColor = Color(_entrega!.estado.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: estadoColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _entrega!.estado.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Estado: ${_entrega!.estado.displayName}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: estadoColor,
                ),
              ),
              const Spacer(),
              EstadoBadge(
                estado: _entrega!.estado,
                compacto: true,
              ),
            ],
          ),
          if (_entrega!.fechaEntrega != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Entregada: ${_formatearFecha(_entrega!.fechaEntrega!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // 📎 ARCHIVOS ENTREGADOS
  // ========================================

  Widget _buildArchivosEntregados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Archivos Entregados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_entrega!.archivos.length} archivo(s)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        ..._entrega!.archivos.map((archivo) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ArchivoTile(
              archivo: archivo,
              onDelete: null, // No permitir eliminar archivos del estudiante
            ),
          );
        }).toList(),
      ],
    );
  }

  // ========================================
  // 💬 COMENTARIO DEL ESTUDIANTE
  // ========================================

  Widget _buildComentarioEstudiante() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentario del Estudiante',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            _entrega!.comentarioEstudiante!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // ⭐ FORMULARIO DE CALIFICACIÓN
  // ========================================

  Widget _buildFormularioCalificacion() {
    if (_tarea == null) return const SizedBox.shrink();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.rate_review, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Calificación y Retroalimentación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Campo de calificación
          Text(
            'Calificación *',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _calificacionController,
            decoration: InputDecoration(
              hintText: 'Ej: 8.5',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.star, color: Colors.amber),
              suffixText: '/ ${_tarea!.calificacionMaxima.toStringAsFixed(1)}',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La calificación es requerida';
              }
              final calificacion = double.tryParse(value.trim());
              if (calificacion == null) {
                return 'Ingresa un número válido';
              }
              if (calificacion < 0) {
                return 'La calificación no puede ser negativa';
              }
              if (calificacion > _tarea!.calificacionMaxima) {
                return 'La calificación no puede ser mayor a ${_tarea!.calificacionMaxima}';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Indicador visual de calificación
          if (_calificacionController.text.isNotEmpty)
            _buildCalificacionIndicator(),

          const SizedBox(height: 20),

          // Campo de retroalimentación
          Text(
            'Retroalimentación (opcional)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Brinda comentarios constructivos al estudiante',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _retroalimentacionController,
            decoration: InputDecoration(
              hintText: 'Ej: Buen trabajo, pero debes mejorar en...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.comment, color: Color(0xFF8B5CF6)),
            ),
            maxLines: 5,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionIndicator() {
    final calificacion =
        double.tryParse(_calificacionController.text.trim()) ?? 0;
    final porcentaje =
        _tarea != null ? (calificacion / _tarea!.calificacionMaxima) : 0;
    final Color colorIndicador;

    if (porcentaje >= 0.9) {
      colorIndicador = Colors.green;
    } else if (porcentaje >= 0.7) {
      colorIndicador = Colors.blue;
    } else if (porcentaje >= 0.5) {
      colorIndicador = Colors.orange;
    } else {
      colorIndicador = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorIndicador.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorIndicador.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rendimiento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorIndicador,
                ),
              ),
              Text(
                '${(porcentaje * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colorIndicador,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje.clamp(0.0, 1.0).toDouble(),
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(colorIndicador),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🔘 BOTONES DE ACCIÓN
  // ========================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _guardarCalificacion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar Calificación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // 🎨 HELPERS
  // ========================================

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inDays == 0) {
      return 'Hoy ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
