// lib/screens/tareas/detalle_tarea_screen.dart
// ✅ CORREGIDO: Roles y visualización de calificación

import '../../utils/logger.dart';
import '../../utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tarea_service.dart';
import '../../widgets/tareas/estado_badge.dart';
import '../../widgets/tareas/prioridad_badge.dart';
import '../../widgets/tareas/archivo_tile.dart';

class DetalleTareaScreen extends StatefulWidget {
  final String tareaId;

  const DetalleTareaScreen({
    super.key,
    required this.tareaId,
  });

  @override
  State<DetalleTareaScreen> createState() => _DetalleTareaScreenState();
}

class _DetalleTareaScreenState extends State<DetalleTareaScreen> {
  Tarea? _tarea;
  EntregaTarea? _miEntrega;
  List<EntregaTarea>? _entregas;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTarea();
  }

  Future<void> _loadTarea() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final tareaProvider = context.read<TareaProvider>();
      final authProvider = context.read<AuthProvider>();

      // ✅ CORRECCIÓN 2: Verificar todos los roles explícitamente
      final usuario = authProvider.currentUser;
      final tipoUsuario =
          usuario?.tipo.toString().split('.').last.toUpperCase();

      final esEstudiante = tipoUsuario == 'ESTUDIANTE';
      final esDocente = tipoUsuario == 'ADMIN' ||
          tipoUsuario == 'DOCENTE' ||
          tipoUsuario == 'RECTOR' ||
          tipoUsuario == 'COORDINADOR';
      final esAcudiente = tipoUsuario == 'ACUDIENTE';

      // Obtener la tarea
      final tarea = await tareaProvider.obtenerTarea(widget.tareaId);

      setState(() {
        _tarea = tarea;
      });

      // Si es estudiante, marcar como vista y obtener mi entrega
      if (esEstudiante) {
        try {
          await tareaProvider.marcarVista(widget.tareaId);
        } catch (e) {
          dlog('Ya estaba marcada como vista');
        }

        try {
          // Obtener mi entrega del servicio
          final tareaService = TareaService();
          final entrega = await tareaService.verMiEntrega(widget.tareaId);
          setState(() {
            _miEntrega = entrega;
          });
        } catch (e) {
          dlog('No hay entrega aún');
        }
      }

      // Si es acudiente, también obtener la entrega del hijo
      if (esAcudiente) {
        try {
          final tareaService = TareaService();
          final entrega = await tareaService.verMiEntrega(widget.tareaId);
          setState(() {
            _miEntrega = entrega;
          });
        } catch (e) {
          dlog('No hay entrega del estudiante');
        }
      }

      // Si es docente, cargar todas las entregas
      if (esDocente) {
        try {
          final entregas = await tareaProvider.verEntregas(widget.tareaId);
          setState(() {
            _entregas = entregas;
          });
        } catch (e) {
          dlog('No se pudieron cargar entregas');
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleDescargarArchivo(ArchivoTarea archivo) async {
    await FileHelper.downloadAndOpen(
      context,
      '/tareas/${widget.tareaId}/archivos/${archivo.fileId}',
      archivo.nombre,
    );
  }

  Future<void> _handleEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: const Text('¿Estás seguro de eliminar esta tarea?'),
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

    if (confirmar != true) return;

    try {
      final tareaProvider = context.read<TareaProvider>();
      await tareaProvider.eliminarTarea(widget.tareaId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCerrar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Tarea'),
        content: const Text(
          '¿Cerrar esta tarea? No se permitirán más entregas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final tareaProvider = context.read<TareaProvider>();
      await tareaProvider.cerrarTarea(widget.tareaId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea cerrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      _loadTarea();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Tarea'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _tarea == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Tarea no encontrada',
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
      );
    }

    final authProvider = context.watch<AuthProvider>();

    // ✅ CORRECCIÓN 2: Verificar todos los roles explícitamente
// ✅ CORRECCIÓN: Convertir enum a String para comparar
    final usuario = authProvider.currentUser;
    final tipoUsuario = usuario?.tipo.toString().split('.').last.toUpperCase();

    final esEstudiante = tipoUsuario == 'ESTUDIANTE';
    final esDocente = tipoUsuario == 'ADMIN' ||
        tipoUsuario == 'DOCENTE' ||
        tipoUsuario == 'RECTOR' ||
        tipoUsuario == 'COORDINADOR';
    final esAcudiente = tipoUsuario == 'ACUDIENTE';

    // Verificar si puede editar (solo el docente creador o admin)
    final puedeEditar = esDocente &&
        (tipoUsuario == 'ADMIN' || _tarea!.docente.id == usuario?.id);

    // Verificar si puede entregar
    final puedeEntregar = esEstudiante &&
        _tarea!.estado == EstadoTarea.activa &&
        (_miEntrega == null ||
            _miEntrega!.estado == EstadoEntrega.pendiente ||
            _miEntrega!.estado == EstadoEntrega.vista ||
            (_miEntrega!.archivos.isEmpty));

    return Scaffold(
      appBar: AppBar(
        title: Text(_tarea!.titulo),
        actions: [
          // Acciones para docente
          if (puedeEditar) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/tareas/editar/${widget.tareaId}'),
            ),
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: _handleCerrar,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleEliminar,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: (puedeEntregar ? 80 : 0) + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información principal
            _buildMainInfo(),

            // Material de referencia
            if (_tarea!.archivosReferencia.isNotEmpty)
              _buildMaterialReferencia(),

            // Mi entrega (estudiante o acudiente)
            if ((esEstudiante || esAcudiente) && _miEntrega != null)
              _buildMiEntrega(),

            // Lista de entregas (docente)
            if (esDocente && _entregas != null && _entregas!.isNotEmpty)
              _buildEntregasDocente(),

            // Detalles laterales
            _buildDetalles(),
          ],
        ),
      ),

      // Botón de entregar (solo estudiante)
      floatingActionButton: puedeEntregar
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/tareas/${widget.tareaId}/entregar'),
              backgroundColor: const Color(0xFF059669),
              icon: const Icon(Icons.assignment),
              label: const Text('Entregar Tarea'),
            )
          : null,
    );
  }

  Widget _buildMainInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PrioridadBadge(prioridad: _tarea!.prioridad),
              if (_miEntrega != null) EstadoBadge(estado: _miEntrega!.estado),
              if (_tarea!.estado == EstadoTarea.cerrada)
                const Chip(
                  label: Text('Cerrada'),
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle(color: Colors.white),
                ),
              Chip(
                label: Text(_tarea!.tipo == TipoTarea.individual
                    ? 'Individual'
                    : 'Grupal'),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Descripción
          Text(
            'Descripción',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _tarea!.descripcion,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialReferencia() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Material de referencia (${_tarea!.archivosReferencia.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._tarea!.archivosReferencia.map((archivo) => ArchivoTile(
                archivo: archivo,
                onDownload: () => _handleDescargarArchivo(archivo),
              )),
        ],
      ),
    );
  }

  Widget _buildMiEntrega() {
    final authProvider = context.watch<AuthProvider>();
    final esAcudiente = authProvider.currentUser?.tipo == 'ACUDIENTE';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            esAcudiente ? 'Entrega del Estudiante' : 'Mi Entrega',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha de entrega
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Entregada el:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        _miEntrega!.fechaEntrega != null
                            ? DateFormat('dd/MM/yyyy HH:mm')
                                .format(_miEntrega!.fechaEntrega!)
                            : _miEntrega!.estado == EstadoEntrega.pendiente
                                ? 'Pendiente'
                                : 'No entregada',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // ✅ CORRECCIÓN 3: Mejorar visualización de calificación
                  // Mostrar si está calificada O si tiene calificación
                  if (_miEntrega!.estaCalificada ||
                      _miEntrega!.calificacion != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Sección de calificación destacada con fondo verde
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF059669),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Calificación grande y destacada
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, size: 18, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Calificación:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                              Text(
                                '${_miEntrega!.calificacion?.toStringAsFixed(1) ?? '0.0'} / ${_tarea!.calificacionMaxima.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),

                          // Retroalimentación del docente (si existe)
                          if (_miEntrega!.comentarioDocente != null &&
                              _miEntrega!.comentarioDocente!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF059669)),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Retroalimentación del docente:',
                                          style: TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _miEntrega!.comentarioDocente!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Botón para entregar si está pendiente
                  if (!esAcudiente &&
                      _miEntrega!.estado == EstadoEntrega.pendiente &&
                      _tarea!.estado == EstadoTarea.activa) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/tareas/${widget.tareaId}/entregar'),
                        icon: const Icon(Icons.assignment),
                        label: const Text('Entregar Ahora'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntregasDocente() {
    final sinCalificar = _entregas!
        .where((e) =>
            e.fueEntregada &&
            e.estado != EstadoEntrega.calificada)
        .length;
    final todasCalificadas = sinCalificar == 0 && _entregas!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Entregas (${_entregas!.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 12),
              // Badge de estado de calificación
              if (sinCalificar > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending_actions,
                          size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(
                        '$sinCalificar sin calificar',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                )
              else if (todasCalificadas)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF6EE7B7)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'Todo calificado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.push('/tareas/${widget.tareaId}/entregas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: const Text('Ver y Calificar Entregas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalles() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Docente
              _buildDetalleRow('Docente', _tarea!.docente.nombreCompleto),

              // Asignatura
              _buildDetalleRow('Asignatura', _tarea!.asignatura.nombre),

              // Curso
              _buildDetalleRow(
                  'Curso', '${_tarea!.curso.nivel} - ${_tarea!.curso.nombre}'),

              const Divider(height: 24),

              // Fecha límite
              _buildDetalleRow(
                'Fecha límite',
                DateFormat('dd/MM/yyyy HH:mm').format(_tarea!.fechaLimite),
                valueColor: DateTime.now().isAfter(_tarea!.fechaLimite)
                    ? Colors.red
                    : null,
                valueBold: DateTime.now().isAfter(_tarea!.fechaLimite),
              ),

              // Calificación máxima
              _buildDetalleRow('Calificación máxima',
                  '${_tarea!.calificacionMaxima} puntos'),

              // Peso en evaluación
              _buildDetalleRow(
                'Peso en evaluación',
                _tarea!.pesoEvaluacion != null
                    ? '${_tarea!.pesoEvaluacion}%'
                    : 'No definido',
              ),

              // Entregas tardías
              _buildDetalleRow(
                'Entregas tardías',
                _tarea!.permiteTardias ? 'Permitidas' : 'No permitidas',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
