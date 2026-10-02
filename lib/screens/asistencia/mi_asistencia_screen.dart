// lib/screens/asistencia/mi_asistencia_screen.dart
//
// Vista de asistencia personal para ESTUDIANTE y ACUDIENTE.
// Tab "Resumen":  stats generales + desglose por materia.
// Tab "Historial": lista paginada con filtro por período.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/asistencia.dart';
import '../../providers/asistencia_provider.dart';
import '../../widgets/common/gradient_header.dart';

// ─────────────────────────────────────────────────────────────
// Helper privado: estadísticas por materia calculadas localmente
// ─────────────────────────────────────────────────────────────
class _MateriaStats {
  final String nombre;
  final String? cursoNombre;
  int presentes = 0;
  int ausentes = 0;
  int tardanzas = 0;
  int justificados = 0;
  int permisos = 0;

  _MateriaStats({required this.nombre, this.cursoNombre});

  void add(String estado) {
    switch (estado) {
      case EstadosAsistencia.presente:
        presentes++;
      case EstadosAsistencia.ausente:
        ausentes++;
      case EstadosAsistencia.tardanza:
        tardanzas++;
      case EstadosAsistencia.justificado:
        justificados++;
      case EstadosAsistencia.permiso:
        permisos++;
    }
  }

  int get total => presentes + ausentes + tardanzas + justificados + permisos;

  double get porcentaje {
    if (total == 0) return 0;
    return (presentes + tardanzas + justificados) / total * 100;
  }
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class MiAsistenciaScreen extends StatefulWidget {
  final String estudianteId;
  final String nombreEstudiante;
  final VoidCallback? onBack;

  const MiAsistenciaScreen({
    super.key,
    required this.estudianteId,
    required this.nombreEstudiante,
    this.onBack,
  });

  @override
  State<MiAsistenciaScreen> createState() => _MiAsistenciaScreenState();
}

class _MiAsistenciaScreenState extends State<MiAsistenciaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado del tab Historial
  String _filtroHistorial = 'año'; // 'mes' | 'trimestre' | 'año'
  int _limiteMostrados = 30;

  // ─────────────────────────────────
  // Ciclo de vida
  // ─────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<AsistenciaProvider>().prepareLoadingMiAsistencia();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      context.read<AsistenciaProvider>().limpiarMiAsistencia();
    });
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    final now = DateTime.now();
    final desde = DateFormat('yyyy-MM-dd').format(DateTime(now.year, 1, 1));
    final hasta = DateFormat('yyyy-MM-dd').format(now);

    await context.read<AsistenciaProvider>().cargarMiAsistencia(
          estudianteId: widget.estudianteId,
          desde: desde,
          hasta: hasta,
          refresh: true,
        );
  }

  // ─────────────────────────────────
  // BUILD PRINCIPAL
  // ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          GradientHeader(
            title: widget.nombreEstudiante,
            // Siempre: sin onBack vuelve a la pantalla anterior o al inicio
            showBack: true,
            onBack: widget.onBack,
            leadingIcon: Icons.fact_check,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(
                    icon: Icon(Icons.bar_chart_rounded, size: 18),
                    text: 'Resumen'),
                Tab(
                    icon: Icon(Icons.history_rounded, size: 18),
                    text: 'Historial'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<AsistenciaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingMiAsistencia) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  );
                }
                if (provider.error != null) {
                  return _buildError(provider.error!);
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabResumen(provider),
                    _buildTabHistorial(provider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB: RESUMEN
  // ─────────────────────────────────────────────────────────────

  Widget _buildTabResumen(AsistenciaProvider provider) {
    final registros = _sortedRegistros(provider.historialEstudiante?.registros);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: const Color(0xFF059669),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
        children: [
          _buildResumenCard(provider.estadisticasEstudiante),
          if (registros.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPorMateriaSection(registros),
          ],
          if (provider.alertas.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAlertasSection(provider.alertas),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB: HISTORIAL
  // ─────────────────────────────────────────────────────────────

  Widget _buildTabHistorial(AsistenciaProvider provider) {
    final registros = _sortedRegistros(provider.historialEstudiante?.registros);
    final filtered = _filtrarRegistros(registros);
    final mostrados = filtered.take(_limiteMostrados).toList();
    final items = _buildItemsList(mostrados);
    final hayMas = filtered.length > _limiteMostrados;
    final restantes = filtered.length - _limiteMostrados;
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Column(
      children: [
        // Barra de filtros
        _buildFiltros(),
        // Lista
        Expanded(
          child: filtered.isEmpty
              ? _buildHistorialVacio()
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  color: const Color(0xFF059669),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomPad),
                    itemCount: items.length + (hayMas ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (hayMas && index == items.length) {
                        return _buildVerMasButton(restantes);
                      }
                      final item = items[index];
                      if (item is String) return _buildMonthHeader(item);
                      return _buildHistorialItem(item as HistorialRegistro);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENTES: FILTROS
  // ─────────────────────────────────────────────────────────────

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFiltroChip('mes', 'Este mes'),
            const SizedBox(width: 8),
            _buildFiltroChip('trimestre', 'Últimos 3 meses'),
            const SizedBox(width: 8),
            _buildFiltroChip('año', 'Todo el año'),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label) {
    final selected = _filtroHistorial == valor;
    return GestureDetector(
      onTap: () => setState(() {
        _filtroHistorial = valor;
        _limiteMostrados = 30;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF059669) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF059669) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String mes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
      child: Text(
        mes.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildVerMasButton(int restantes) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _limiteMostrados += 30),
        icon: const Icon(Icons.expand_more, size: 18),
        label: Text('Ver $restantes registros más'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF059669),
          side: const BorderSide(color: Color(0xFF059669)),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorialVacio() {
    final label = switch (_filtroHistorial) {
      'mes' => 'Sin registros este mes',
      'trimestre' => 'Sin registros en los últimos 3 meses',
      _ => 'Sin registros este año',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(fontSize: 15, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENTES: POR MATERIA (tab Resumen)
  // ─────────────────────────────────────────────────────────────

  Widget _buildPorMateriaSection(List<HistorialRegistro> registros) {
    final stats = _calcularPorMateria(registros);
    if (stats.isEmpty) return const SizedBox.shrink();

    // Peor porcentaje primero → el padre ve los problemas al tope
    final sorted = stats.values.toList()
      ..sort((a, b) => a.porcentaje.compareTo(b.porcentaje));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por materia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...sorted.map(_buildMateriaCard),
      ],
    );
  }

  Widget _buildMateriaCard(_MateriaStats stats) {
    final color = stats.porcentaje >= 80
        ? const Color(0xFF10B981)
        : stats.porcentaje >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de color lateral
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          // Nombre + curso + mini stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (stats.cursoNombre != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    stats.cursoNombre!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _miniStat('P', stats.presentes, const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _miniStat('A', stats.ausentes, const Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    _miniStat('T', stats.tardanzas, const Color(0xFFF59E0B)),
                    if (stats.justificados > 0) ...[
                      const SizedBox(width: 12),
                      _miniStat('J', stats.justificados, const Color(0xFF3B82F6)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Badge de porcentaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${stats.porcentaje.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int valor, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          ':$valor',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENTES: STATS CARD (tab Resumen)
  // ─────────────────────────────────────────────────────────────

  Widget _buildResumenCard(EstadisticasEstudiante stats) {
    final porcentaje = stats.porcentajeAsistencia;
    final colorPorcentaje = _colorPorcentaje(porcentaje);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del año',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${porcentaje.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'de asistencia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: porcentaje / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(colorPorcentaje),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.check_circle, Colors.greenAccent,
                        stats.presentes, 'Presentes'),
                    _buildStatItem(Icons.cancel, Colors.redAccent,
                        stats.ausentes, 'Ausentes'),
                    _buildStatItem(Icons.access_time, Colors.orangeAccent,
                        stats.tardanzas, 'Tardanzas'),
                  ],
                ),
                if (stats.justificados > 0 || stats.permisos > 0) ...[
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (stats.justificados > 0)
                        _buildStatItem(Icons.assignment_late,
                            Colors.lightBlueAccent, stats.justificados,
                            'Justificados'),
                      if (stats.permisos > 0)
                        _buildStatItem(Icons.shield, Colors.tealAccent,
                            stats.permisos, 'Permisos'),
                      _buildStatItem(Icons.event_note, Colors.white70,
                          stats.totalClases, 'Total clases'),
                    ],
                  ),
                ] else ...[
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(Icons.event_note, Colors.white70,
                          stats.totalClases, 'Total clases'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, int valor, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          '$valor',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENTES: ALERTAS (tab Resumen)
  // ─────────────────────────────────────────────────────────────

  Widget _buildAlertasSection(List<AlertaAsistencia> alertas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas activas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        ...alertas.map(_buildAlertaChip),
      ],
    );
  }

  Widget _buildAlertaChip(AlertaAsistencia alerta) {
    final (color, bgColor, icono, titulo) = switch (alerta.nivel) {
      NivelesAlerta.inminente => (
          const Color(0xFF7F1D1D),
          const Color(0xFFFEE2E2),
          Icons.warning_rounded,
          'INMINENTE — Riesgo de reprobación',
        ),
      NivelesAlerta.critico => (
          const Color(0xFFEF4444),
          const Color(0xFFFEF2F2),
          Icons.error_rounded,
          'CRÍTICO',
        ),
      _ => (
          const Color(0xFFF59E0B),
          const Color(0xFFFFFBEB),
          Icons.warning_amber_rounded,
          'ALERTA',
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alerta.porcentajeAusencias.toStringAsFixed(1)}% de ausencias registradas',
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENTES: ITEM DEL HISTORIAL (tab Historial)
  // ─────────────────────────────────────────────────────────────

  Widget _buildHistorialItem(HistorialRegistro registro) {
    final color = _colorEstado(registro.estado);
    final icono = _iconoEstado(registro.estado);
    final label = _labelEstado(registro.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fecha compacta
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(registro.fecha),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  DateFormat('MMM', 'es_ES').format(registro.fecha),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Asignatura y curso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registro.asignaturaNombre ?? registro.cursoNombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (registro.asignaturaNombre != null)
                  Text(
                    registro.cursoNombre,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENTE: ERROR
  // ─────────────────────────────────────────────────────────────

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UTILIDADES: datos
  // ─────────────────────────────────────────────────────────────

  /// Devuelve los registros ordenados por fecha descendente.
  List<HistorialRegistro> _sortedRegistros(List<HistorialRegistro>? registros) {
    if (registros == null) return [];
    final sorted = List<HistorialRegistro>.from(registros);
    sorted.sort((a, b) => b.fecha.compareTo(a.fecha));
    return sorted;
  }

  /// Filtra registros según el período seleccionado.
  List<HistorialRegistro> _filtrarRegistros(List<HistorialRegistro> all) {
    final now = DateTime.now();
    return all.where((r) {
      switch (_filtroHistorial) {
        case 'mes':
          return r.fecha.year == now.year && r.fecha.month == now.month;
        case 'trimestre':
          final hace90 = now.subtract(const Duration(days: 90));
          return r.fecha.isAfter(hace90);
        default:
          return true;
      }
    }).toList();
  }

  /// Agrupa registros por materia y calcula stats por cada una.
  Map<String, _MateriaStats> _calcularPorMateria(
      List<HistorialRegistro> registros) {
    final Map<String, _MateriaStats> stats = {};
    for (final r in registros) {
      final key = r.asignaturaNombre ?? r.cursoNombre;
      if (!stats.containsKey(key)) {
        stats[key] = _MateriaStats(
          nombre: r.asignaturaNombre ?? r.cursoNombre,
          cursoNombre: r.asignaturaNombre != null ? r.cursoNombre : null,
        );
      }
      stats[key]!.add(r.estado);
    }
    return stats;
  }

  /// Construye lista plana intercalando headers de mes con los registros.
  List<dynamic> _buildItemsList(List<HistorialRegistro> registros) {
    final List<dynamic> items = [];
    String? lastMonth;
    for (final r in registros) {
      final month = DateFormat('MMMM yyyy', 'es_ES').format(r.fecha);
      if (month != lastMonth) {
        items.add(month);
        lastMonth = month;
      }
      items.add(r);
    }
    return items;
  }

  // ─────────────────────────────────────────────────────────────
  // UTILIDADES: estilos según estado/porcentaje
  // ─────────────────────────────────────────────────────────────

  Color _colorPorcentaje(double p) {
    if (p >= 90) return Colors.greenAccent;
    if (p >= 75) return Colors.lightBlueAccent;
    if (p >= 60) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case EstadosAsistencia.presente:
        return const Color(0xFF10B981);
      case EstadosAsistencia.ausente:
        return const Color(0xFFEF4444);
      case EstadosAsistencia.tardanza:
        return const Color(0xFFF59E0B);
      case EstadosAsistencia.justificado:
        return const Color(0xFF3B82F6);
      case EstadosAsistencia.permiso:
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case EstadosAsistencia.presente:
        return Icons.check_circle;
      case EstadosAsistencia.ausente:
        return Icons.cancel;
      case EstadosAsistencia.tardanza:
        return Icons.access_time;
      case EstadosAsistencia.justificado:
        return Icons.assignment_late;
      case EstadosAsistencia.permiso:
        return Icons.shield;
      default:
        return Icons.help;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case EstadosAsistencia.presente:
        return 'Presente';
      case EstadosAsistencia.ausente:
        return 'Ausente';
      case EstadosAsistencia.tardanza:
        return 'Tardanza';
      case EstadosAsistencia.justificado:
        return 'Justificado';
      case EstadosAsistencia.permiso:
        return 'Permiso';
      default:
        return estado;
    }
  }
}
