// lib/screens/tareas/lista_entregas_screen.dart
// 📊 LISTA DE ENTREGAS DE UNA TAREA - DOCENTES

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../widgets/tareas/estado_badge.dart';

class ListaEntregasScreen extends StatefulWidget {
  final String tareaId;

  const ListaEntregasScreen({
    super.key,
    required this.tareaId,
  });

  @override
  State<ListaEntregasScreen> createState() => _ListaEntregasScreenState();
}

class _ListaEntregasScreenState extends State<ListaEntregasScreen> {
  bool _isLoading = false;
  Tarea? _tarea;
  List<EntregaTarea> _entregas = [];
  EstadoEntrega? _filtroEstado;
  String _ordenamiento = 'nombre'; // nombre, fecha, calificacion

  @override
  void initState() {
    super.initState();
    _loadData();
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

      // Obtener entregas
      final entregas = await tareaProvider.verEntregas(widget.tareaId);
      setState(() {
        _entregas = entregas;
        _aplicarFiltrosYOrdenamiento();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar entregas: $e'),
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

  void _aplicarFiltrosYOrdenamiento() {
    List<EntregaTarea> entregasFiltradas = List.from(_entregas);

    // Aplicar filtro de estado
    if (_filtroEstado != null) {
      entregasFiltradas =
          entregasFiltradas.where((e) => e.estado == _filtroEstado).toList();
    }

    // Aplicar ordenamiento
    switch (_ordenamiento) {
      case 'nombre':
        entregasFiltradas.sort((a, b) {
          final nombreA =
              '${a.estudiante?.nombre ?? ''} ${a.estudiante?.apellidos ?? ''}';
          final nombreB =
              '${b.estudiante?.nombre ?? ''} ${b.estudiante?.apellidos ?? ''}';
          return nombreA.compareTo(nombreB);
        });
        break;
      case 'fecha':
        entregasFiltradas.sort((a, b) {
          if (a.fechaEntrega == null && b.fechaEntrega == null) return 0;
          if (a.fechaEntrega == null) return 1;
          if (b.fechaEntrega == null) return -1;
          return b.fechaEntrega!.compareTo(a.fechaEntrega!);
        });
        break;
      case 'calificacion':
        entregasFiltradas.sort((a, b) {
          if (a.calificacion == null && b.calificacion == null) return 0;
          if (a.calificacion == null) return 1;
          if (b.calificacion == null) return -1;
          return b.calificacion!.compareTo(a.calificacion!);
        });
        break;
    }

    setState(() {
      _entregas = entregasFiltradas;
    });
  }

  Map<String, int> _calcularEstadisticas() {
    if (_tarea == null) {
      return {
        'total': 0,
        'entregadas': 0,
        'calificadas': 0,
        'pendientes': 0,
        'atrasadas': 0,
      };
    }

    final total = _tarea!.estudiantesIds.length;
    final entregadas = _entregas
        .where((e) =>
            e.estado == EstadoEntrega.entregada ||
            e.estado == EstadoEntrega.atrasada ||
            e.estado == EstadoEntrega.calificada)
        .length;
    final calificadas =
        _entregas.where((e) => e.estado == EstadoEntrega.calificada).length;
    final pendientes =
        _entregas.where((e) => e.estado == EstadoEntrega.pendiente).length;
    final atrasadas =
        _entregas.where((e) => e.estado == EstadoEntrega.atrasada).length;

    return {
      'total': total,
      'entregadas': entregadas,
      'calificadas': calificadas,
      'pendientes': pendientes,
      'atrasadas': atrasadas,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Entregas'),
        actions: [
          // Menú de ordenamiento
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _ordenamiento = value;
                _aplicarFiltrosYOrdenamiento();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'nombre',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Por nombre'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fecha',
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text('Por fecha de entrega'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'calificacion',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Por calificación'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con info de la tarea
                if (_tarea != null) _buildTareaHeader(),

                // Estadísticas
                _buildEstadisticas(),

                // Filtros
                _buildFiltros(),

                // Lista de entregas
                Expanded(child: _buildEntregasList()),
              ],
            ),
    );
  }

  // ========================================
  // 📋 HEADER DE LA TAREA
  // ========================================

  Widget _buildTareaHeader() {
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
            '📊 Entregas de la Tarea',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tarea!.titulo,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.book, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                _tarea!.asignatura.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.group, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                _tarea!.curso.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📊 ESTADÍSTICAS
  // ========================================

  Widget _buildEstadisticas() {
    final stats = _calcularEstadisticas();
    final porcentajeEntregadas = stats['total']! > 0
        ? ((stats['entregadas']! / stats['total']!) * 100).toStringAsFixed(1)
        : '0.0';
    final porcentajeCalificadas = stats['total']! > 0
        ? ((stats['calificadas']! / stats['total']!) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de progreso de entregas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso de entregas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$porcentajeEntregadas%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stats['total']! > 0
                  ? stats['entregadas']! / stats['total']!
                  : 0,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 16),

          // Cards de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  label: 'Total',
                  value: stats['total'].toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Entregadas',
                  value: stats['entregadas'].toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  label: 'Calificadas',
                  value: stats['calificadas'].toString(),
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.hourglass_empty,
                  label: 'Pendientes',
                  value: stats['pendientes'].toString(),
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.warning,
                  label: 'Atrasadas',
                  value: stats['atrasadas'].toString(),
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              // Espacio vacío para mantener el diseño
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🎛️ FILTROS
  // ========================================

  Widget _buildFiltros() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFiltroChip(
            label: 'Todas',
            isActive: _filtroEstado == null,
            onTap: () {
              setState(() {
                _filtroEstado = null;
                _loadData();
              });
            },
          ),
          const SizedBox(width: 8),
          ...EstadoEntrega.values.map((estado) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFiltroChip(
                label: estado.displayName,
                icon: estado.icon,
                color: Color(estado.color),
                isActive: _filtroEstado == estado,
                onTap: () {
                  setState(() {
                    _filtroEstado = estado;
                    _loadData();
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFiltroChip({
    required String label,
    String? icon,
    Color? color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? const Color(0xFF8B5CF6);

    return FilterChip(
      selected: isActive,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.grey[700],
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: isActive ? chipColor : Colors.grey[300]!,
      ),
    );
  }

  // ========================================
  // 📋 LISTA DE ENTREGAS
  // ========================================

  Widget _buildEntregasList() {
    if (_entregas.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entregas.length,
        itemBuilder: (context, index) {
          final entrega = _entregas[index];
          return _buildEntregaCard(entrega);
        },
      ),
    );
  }

  Widget _buildEntregaCard(EntregaTarea entrega) {
    final estadoColor = Color(entrega.estado.color);
    final puedeCalificar = entrega.fueEntregada && !entrega.estaCalificada;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estadoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: entrega.fueEntregada
            ? () => context.push(
                  '/tareas/${widget.tareaId}/entregas/${entrega.id}/calificar',
                )
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nombre y estado
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '👤',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entrega.estudiante?.nombre ?? ''} ${entrega.estudiante?.apellidos ?? ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          entrega.estudiante?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  EstadoBadge(
                    estado: entrega.estado,
                    compacto: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Información de la entrega
              if (entrega.fueEntregada) ...[
                _buildInfoRow(
                  icon: Icons.access_time,
                  label: 'Fecha de entrega:',
                  value: _formatearFecha(entrega.fechaEntrega!),
                ),
                if (entrega.archivos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.attach_file,
                    label: 'Archivos:',
                    value: '${entrega.archivos.length} archivo(s)',
                  ),
                ],
                if (entrega.comentarioEstudiante != null &&
                    entrega.comentarioEstudiante!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.comment,
                    label: 'Comentario:',
                    value: entrega.comentarioEstudiante!,
                    maxLines: 2,
                  ),
                ],
              ],

              // Calificación
              if (entrega.estaCalificada) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Calificación: ${entrega.calificacion!.toStringAsFixed(1)} / ${_tarea!.calificacionMaxima.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botón calificar
              if (puedeCalificar) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '/tareas/${widget.tareaId}/entregas/${entrega.id}/calificar',
                    ),
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text(
                      'Calificar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // 🔍 ESTADO VACÍO
  // ========================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            _filtroEstado != null
                ? 'No hay entregas con este estado'
                : 'Aún no hay entregas',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filtroEstado != null
                ? 'Intenta ajustar los filtros'
                : 'Los estudiantes aún no han entregado la tarea',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
