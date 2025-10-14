// lib/screens/asistencia/detalle_asistencia_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/asistencia.dart';
import '../../providers/asistencia_provider.dart';
import '../../services/permission_service.dart';

class DetalleAsistenciaScreen extends StatefulWidget {
  final String asistenciaId;

  const DetalleAsistenciaScreen({
    super.key,
    required this.asistenciaId,
  });

  @override
  State<DetalleAsistenciaScreen> createState() =>
      _DetalleAsistenciaScreenState();
}

class _DetalleAsistenciaScreenState extends State<DetalleAsistenciaScreen> {
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarRegistro();
  }

  Future<void> _cargarRegistro() async {
    final provider = context.read<AsistenciaProvider>();
    await provider.cargarRegistro(widget.asistenciaId);
  }

  Future<void> _finalizarRegistro() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Registro'),
        content: const Text(
          'Al finalizar el registro, se confirmará que la información es correcta y ya no se podrán realizar cambios. ¿Deseas finalizar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);

    try {
      final provider = context.read<AsistenciaProvider>();
      final exito = await provider.finalizarRegistro(widget.asistenciaId);

      if (exito && mounted) {
        _mostrarMensaje('Registro finalizado exitosamente', tipo: 'exito');
      } else if (mounted) {
        _mostrarMensaje('Error al finalizar el registro', tipo: 'error');
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _eliminarRegistro() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text(
          '¿Estás seguro de eliminar este registro de asistencia? Esta acción no se puede deshacer.',
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);

    try {
      final provider = context.read<AsistenciaProvider>();
      final exito = await provider.eliminarRegistro(widget.asistenciaId);

      if (exito && mounted) {
        _mostrarMensaje('Registro eliminado exitosamente', tipo: 'exito');
        context.go('/asistencia');
      } else if (mounted) {
        _mostrarMensaje('Error al eliminar el registro', tipo: 'error');
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {String tipo = 'info'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: tipo == 'exito'
            ? Colors.green
            : tipo == 'error'
                ? Colors.red
                : Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detalle de Asistencia'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ BOTÓN EDITAR - Solo si NO está finalizado
          Consumer<AsistenciaProvider>(
            builder: (context, provider, _) {
              final registro = provider.registroActual;

              if (registro == null) return const SizedBox.shrink();

              // Mostrar botón editar si NO está finalizado y tiene permiso
              if (!registro.finalizado &&
                  PermissionService.canAccess('asistencia.editar')) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    context.push('/asistencia/editar/${widget.asistenciaId}');
                  },
                  tooltip: 'Editar asistencia',
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // Menú de opciones
          Consumer<AsistenciaProvider>(
            builder: (context, provider, _) {
              final registro = provider.registroActual;
              if (registro == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'finalizar':
                      _finalizarRegistro();
                      break;
                    case 'eliminar':
                      _eliminarRegistro();
                      break;
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];

                  // Finalizar solo si no está finalizado y tiene permiso
                  if (!registro.finalizado &&
                      PermissionService.canAccess('asistencia.editar')) {
                    items.add(
                      const PopupMenuItem(
                        value: 'finalizar',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Finalizar'),
                          ],
                        ),
                      ),
                    );
                  }

                  // Eliminar (solo ADMIN o creador)
                  if (PermissionService.canAccess('asistencia.editar')) {
                    items.add(
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    );
                  }

                  return items;
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<AsistenciaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildError(provider.error!);
          }

          final registro = provider.registroActual;
          if (registro == null) {
            return const Center(child: Text('Registro no encontrado'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // 📊 RESUMEN Y ESTADÍSTICAS
                _buildResumenCard(registro),

                // 👥 LISTA DE ESTUDIANTES
                _buildListaEstudiantes(registro),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================================
  // 📊 CARD DE RESUMEN
  // ========================================

  Widget _buildResumenCard(RegistroAsistencia registro) {
    final estadisticas = registro.estadisticas;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.indigo[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                          .format(registro.fecha),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${registro.horaInicio} - ${registro.horaFin}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (registro.finalizado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Finalizado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Info del curso
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        registro.curso.nombreCompleto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // ✅ ASIGNATURA - Mostrar si existe
                if (registro.asignatura != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          registro.asignatura!.nombre,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Estadísticas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Porcentaje de asistencia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Porcentaje de Asistencia',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${estadisticas.porcentajeAsistencia.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getColorPorcentaje(
                          estadisticas.porcentajeAsistencia,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: estadisticas.porcentajeAsistencia / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      _getColorPorcentaje(estadisticas.porcentajeAsistencia),
                    ),
                  ),
                ),

                const Divider(height: 24),

                // Contadores - PRIMERA FILA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildContador(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      label: 'Presentes',
                      valor: estadisticas.presentes,
                    ),
                    _buildContador(
                      icon: Icons.cancel,
                      color: Colors.red,
                      label: 'Ausentes',
                      valor: estadisticas.ausentes,
                    ),
                    _buildContador(
                      icon: Icons.access_time,
                      color: Colors.orange,
                      label: 'Tardanzas',
                      valor: estadisticas.tardanzas,
                    ),
                  ],
                ),

                // ✅ SEGUNDA FILA - Justificados y Permisos
                if (estadisticas.justificados > 0 ||
                    estadisticas.permisos > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (estadisticas.justificados > 0)
                        _buildContador(
                          icon: Icons.assignment_late,
                          color: Colors.blue,
                          label: 'Justificados',
                          valor: estadisticas.justificados,
                        ),
                      if (estadisticas.permisos > 0)
                        _buildContador(
                          icon: Icons.shield,
                          color: Colors.purple,
                          label: 'Permisos',
                          valor: estadisticas.permisos,
                        ),
                      // Spacer para mantener simetría si solo hay uno
                      if (estadisticas.justificados == 0 ||
                          estadisticas.permisos == 0)
                        const SizedBox(width: 80),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Observaciones generales
          if (registro.observacionesGenerales != null &&
              registro.observacionesGenerales!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Observaciones Generales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    registro.observacionesGenerales!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContador({
    required IconData icon,
    required Color color,
    required String label,
    required int valor,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ========================================
  // 👥 LISTA DE ESTUDIANTES
  // ========================================

  Widget _buildListaEstudiantes(RegistroAsistencia registro) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.indigo, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Estudiantes (${registro.estudiantes.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: registro.estudiantes.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final estudiante = registro.estudiantes[index];
              return _buildEstudianteItem(estudiante);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEstudianteItem(EstudianteAsistencia estudiante) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: _getColorEstado(estudiante.estado),
                radius: 20,
                child: Text(
                  estudiante.nombreCompleto
                      .split(' ')
                      .map((e) => e[0])
                      .take(2)
                      .join()
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nombre
              Expanded(
                child: Text(
                  estudiante.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getColorEstado(estudiante.estado).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getColorEstado(estudiante.estado),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconoEstado(estudiante.estado),
                      size: 14,
                      color: _getColorEstado(estudiante.estado),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      EstadosAsistencia.getLabel(estudiante.estado),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getColorEstado(estudiante.estado),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Observaciones del estudiante
          if (estudiante.observaciones != null &&
              estudiante.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      estudiante.observaciones!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // 🚫 ERROR STATE
  // ========================================

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarRegistro,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🎨 HELPERS
  // ========================================

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'PRESENTE':
        return Colors.green;
      case 'AUSENTE':
        return Colors.red;
      case 'TARDANZA':
        return Colors.orange;
      case 'JUSTIFICADO':
        return Colors.blue;
      case 'PERMISO':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado) {
      case 'PRESENTE':
        return Icons.check_circle;
      case 'AUSENTE':
        return Icons.cancel;
      case 'TARDANZA':
        return Icons.access_time;
      case 'JUSTIFICADO':
        return Icons.assignment_late;
      case 'PERMISO':
        return Icons.shield;
      default:
        return Icons.help;
    }
  }

  Color _getColorPorcentaje(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 75) return Colors.blue;
    if (porcentaje >= 60) return Colors.orange;
    return Colors.red;
  }
}
