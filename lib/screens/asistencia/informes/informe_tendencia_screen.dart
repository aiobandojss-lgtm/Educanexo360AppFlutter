// lib/screens/asistencia/informes/informe_tendencia_screen.dart
//
// Informe 2: Tendencia de asistencia en el tiempo.
// Filtros: rango de fechas (requerido), agrupación semana/mes, curso.
// Muestra gráfica de línea con fl_chart + tabla de puntos.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/asistencia_informes.dart';
import '../../../providers/asistencia_provider.dart';
import '../../../services/asistencia_informes_service.dart';

class InformeTendenciaScreen extends StatefulWidget {
  const InformeTendenciaScreen({super.key});

  @override
  State<InformeTendenciaScreen> createState() => _InformeTendenciaScreenState();
}

class _InformeTendenciaScreenState extends State<InformeTendenciaScreen> {
  final _service = asistenciaInformesService;

  // Filtros
  DateTime _desde = DateTime.now().subtract(const Duration(days: 60));
  DateTime _hasta = DateTime.now();
  String _agrupacion = 'semana';
  String? _cursoId;

  // Estado
  bool _isLoading = false;
  String? _error;
  InformeTendenciaResponse? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AsistenciaProvider>().cargarCursos();
      _cargar();
    });
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.obtenerTendencia(
        desde: DateFormat('yyyy-MM-dd').format(_desde),
        hasta: DateFormat('yyyy-MM-dd').format(_hasta),
        agrupacion: _agrupacion,
        cursoId: _cursoId,
      );
      setState(() => _data = result);
    } catch (e) {
      setState(
          () => _error = 'No se pudo cargar el informe. Verifica tu conexión.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _desde = fecha;
          if (_desde.isAfter(_hasta)) _hasta = _desde;
        } else {
          _hasta = fecha;
          if (_hasta.isBefore(_desde)) _desde = _hasta;
        }
      });
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tendencia de Asistencia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF047857), Color(0xFF14B8A6)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargar,
              tooltip: 'Actualizar'),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _data == null
                        ? const SizedBox.shrink()
                        : _buildContenido(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FILTROS
  // ==========================================

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Fechas
          Row(
            children: [
              Expanded(
                child: _buildFechaBtn(
                    label: 'Desde',
                    fecha: _desde,
                    onTap: () => _seleccionarFecha(true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFechaBtn(
                    label: 'Hasta',
                    fecha: _hasta,
                    onTap: () => _seleccionarFecha(false)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Agrupación + Curso
          Row(
            children: [
              // Toggle semana/mes
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildAgrupacionBtn('semana', 'Semanal'),
                      _buildAgrupacionBtn('mes', 'Mensual'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Curso
          Consumer<AsistenciaProvider>(
            builder: (context, provider, _) {
              return DropdownButtonFormField<String>(
                initialValue: _cursoId,
                decoration: InputDecoration(
                  labelText: 'Curso (opcional)',
                  prefixIcon: const Icon(Icons.school, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Todos los cursos')),
                  ...provider.cursos.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nombreCompleto),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _cursoId = v);
                  _cargar();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgrupacionBtn(String valor, String label) {
    final selected = _agrupacion == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!selected) {
            setState(() => _agrupacion = valor);
            _cargar();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF059669) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFechaBtn({
    required String label,
    required DateTime fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 16, color: Color(0xFF047857)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text(DateFormat('dd/MM/yyyy').format(fecha),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONTENIDO
  // ==========================================

  Widget _buildContenido() {
    final data = _data!;

    if (data.tendencia.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gráfica de línea
          _buildLineChart(data.tendencia),
          const SizedBox(height: 20),
          // Tabla de puntos
          _buildTablaPuntos(data.tendencia),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<PuntoTendencia> puntos) {
    final spots = puntos.asMap().entries.map((entry) {
      return FlSpot(
          entry.key.toDouble(), entry.value.porcentajeAsistencia);
    }).toList();

    final minY =
        (puntos.map((p) => p.porcentajeAsistencia).reduce((a, b) => a < b ? a : b) - 10)
            .clamp(0.0, 100.0);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 16),
              child: Text(
                '% Asistencia',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500]),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: puntos.length > 8
                            ? (puntos.length / 4).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= puntos.length) {
                            return const SizedBox.shrink();
                          }
                          final p = puntos[idx];
                          final label = _agrupacion == 'mes'
                              ? DateFormat('MMM', 'es_ES').format(p.fechaInicio)
                              : DateFormat('d/M').format(p.fechaInicio);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500])),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minY,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF059669),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF059669),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaPuntos(List<PuntoTendencia> puntos) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Detalle por período',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const Divider(height: 1),
          // Encabezado
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Período',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]))),
                Expanded(
                    child: Text('Asist.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]))),
                Expanded(
                    child: Text('Aus.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]))),
                Expanded(
                    child: Text('%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...puntos.map((p) {
            final color = _colorPorPorcentaje(p.porcentajeAsistencia);
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      p.periodo,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.presentes.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF059669)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.ausentes.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFFEF4444)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${p.porcentajeAsistencia.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _colorPorPorcentaje(double p) {
    if (p >= 90) return const Color(0xFF059669);
    if (p >= 75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Sin datos para el período',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
              'Ajusta el rango de fechas para ver la tendencia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
