// lib/screens/asistencia/informes/informe_patron_dias_screen.dart
//
// Informe 4: Patrón de ausentismo por día de la semana.
// Muestra qué días tienen más ausencias/tardanzas en un período.
// Filtros: rango de fechas (requerido) + curso (opcional).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/asistencia_informes.dart';
import '../../../providers/asistencia_provider.dart';
import '../../../services/asistencia_informes_service.dart';

class InformePatronDiasScreen extends StatefulWidget {
  const InformePatronDiasScreen({super.key});

  @override
  State<InformePatronDiasScreen> createState() =>
      _InformePatronDiasScreenState();
}

class _InformePatronDiasScreenState extends State<InformePatronDiasScreen> {
  final _service = asistenciaInformesService;

  DateTime _desde = DateTime.now().subtract(const Duration(days: 60));
  DateTime _hasta = DateTime.now();
  String? _cursoId;

  bool _isLoading = false;
  String? _error;
  InformePatronDiasResponse? _data;

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
      final result = await _service.obtenerPatronDias(
        desde: DateFormat('yyyy-MM-dd').format(_desde),
        hasta: DateFormat('yyyy-MM-dd').format(_hasta),
        cursoId: _cursoId,
      );
      setState(() => _data = result);
    } catch (e) {
      setState(() =>
          _error = 'No se pudo cargar el informe. Verifica tu conexión.');
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
        title: const Text('Patrón por Día'),
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
            tooltip: 'Actualizar',
          ),
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
          Row(
            children: [
              Expanded(
                child: _buildFechaBtn(
                  label: 'Desde',
                  fecha: _desde,
                  onTap: () => _seleccionarFecha(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFechaBtn(
                  label: 'Hasta',
                  fecha: _hasta,
                  onTap: () => _seleccionarFecha(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    final dias = _data!.dias;

    if (dias.isEmpty) {
      return _buildEmpty();
    }

    // Máximo de ausentismo para normalizar las barras
    final maxAusentismo =
        dias.map((d) => d.porcentajeAusentismo).reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBanner(),
          const SizedBox(height: 16),
          _buildGraficaDias(dias, maxAusentismo),
          const SizedBox(height: 16),
          _buildTablaDetalle(dias),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_view_week_rounded,
              color: Color(0xFF059669), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patrón de ausentismo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF064E3B),
                  ),
                ),
                Text(
                  'Porcentaje de estudiantes ausentes por día de la semana',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficaDias(List<PatronDia> dias, double maxAusentismo) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '% Ausentismo por día',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...dias.map((dia) => _buildBarraDia(dia, maxAusentismo)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraDia(PatronDia dia, double maxAusentismo) {
    final porcentaje = dia.porcentajeAusentismo;
    final color = _colorAusentismo(porcentaje);
    final barWidth = maxAusentismo > 0 ? porcentaje / maxAusentismo : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Nombre del día
          SizedBox(
            width: 60,
            child: Text(
              dia.nombreDia,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          // Barra
          Expanded(
            child: Stack(
              children: [
                // Fondo
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Relleno
                FractionallySizedBox(
                  widthFactor: barWidth.clamp(0.0, 1.0),
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // Texto dentro de la barra
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${porcentaje.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              barWidth > 0.3 ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteo de ausencias
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '${dia.ausencias} aus.',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaDetalle(List<PatronDia> dias) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Detalle por día',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                    flex: 2,
                    child: Text('Día',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]))),
                Expanded(
                    child: Text('Clases',
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
                    child: Text('Tard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]))),
                Expanded(
                    child: Text('Ausen.',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...dias.map((dia) {
            final color = _colorAusentismo(dia.porcentajeAusentismo);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text(dia.nombreDia,
                              style: const TextStyle(fontSize: 13))),
                      Expanded(
                          child: Text(dia.totalClases.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13))),
                      Expanded(
                          child: Text(dia.ausencias.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFEF4444)))),
                      Expanded(
                          child: Text(dia.tardanzas.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFF59E0B)))),
                      Expanded(
                          child: Text(
                              '${dia.porcentajeAusentismo.toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: color))),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[100]),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  Color _colorAusentismo(double porcentaje) {
    if (porcentaje <= 10) return const Color(0xFF059669);
    if (porcentaje <= 20) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_week_outlined,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Sin datos para el período',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
              'Ajusta el rango de fechas para ver el patrón.',
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
