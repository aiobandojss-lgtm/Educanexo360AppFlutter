// lib/screens/asistencia/informes/informe_riesgo_screen.dart
//
// Informe 1: Estudiantes en riesgo de inasistencia.
// Filtros: umbral (%), rango de fechas, curso.
// Muestra badge CRÍTICO (rojo) / ALERTA (naranja) + tarjetas resumen.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/asistencia_informes.dart';
import '../../../providers/asistencia_provider.dart';
import '../../../services/asistencia_informes_service.dart';
import '../../../widgets/common/gradient_header.dart';

class InformeRiesgoScreen extends StatefulWidget {
  const InformeRiesgoScreen({super.key});

  @override
  State<InformeRiesgoScreen> createState() => _InformeRiesgoScreenState();
}

class _InformeRiesgoScreenState extends State<InformeRiesgoScreen> {
  final _service = asistenciaInformesService;

  // Filtros
  int _umbral = 80;
  DateTime _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _hasta = DateTime.now();
  String? _cursoId;

  // Estado
  bool _isLoading = false;
  String? _error;
  InformeRiesgoResponse? _data;

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
      final result = await _service.obtenerRiesgo(
        umbral: _umbral,
        cursoId: _cursoId,
        desde: DateFormat('yyyy-MM-dd').format(_desde),
        hasta: DateFormat('yyyy-MM-dd').format(_hasta),
      );
      setState(() => _data = result);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar el informe. Verifica tu conexión.');
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
      body: Column(
        children: [
          GradientHeader(
            title: 'Estudiantes en Riesgo',
            showBack: true,
            leadingIcon: Icons.warning_amber,
            actions: [
              HeaderAction(
                icon: Icons.refresh,
                onTap: _cargar,
                tooltip: 'Actualizar',
              ),
            ],
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Umbral
          Row(
            children: [
              const Text('Umbral de asistencia:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(width: 8),
              Text(
                '$_umbral%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Slider(
            value: _umbral.toDouble(),
            min: 50,
            max: 100,
            divisions: 10,
            activeColor: const Color(0xFF059669),
            label: '$_umbral%',
            onChanged: (v) => setState(() => _umbral = v.round()),
            onChangeEnd: (_) => _cargar(),
          ),

          const SizedBox(height: 8),

          // Fechas
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

          // Selector de curso
          Consumer<AsistenciaProvider>(
            builder: (context, provider, _) {
              return DropdownButtonFormField<String>(
                initialValue: _cursoId,
                decoration: InputDecoration(
                  labelText: 'Curso (opcional)',
                  prefixIcon: const Icon(Icons.school, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
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
    final data = _data!;

    if (data.estudiantes.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjetas resumen
          _buildResumen(data),
          const SizedBox(height: 16),
          // Lista de estudiantes
          ...data.estudiantes.map((e) => _buildEstudianteCard(e)),
        ],
      ),
    );
  }

  Widget _buildResumen(InformeRiesgoResponse data) {
    return Row(
      children: [
        _buildResumenCard(
          valor: data.total.toString(),
          label: 'En riesgo',
          color: const Color(0xFFF59E0B),
          icono: Icons.people,
        ),
        const SizedBox(width: 8),
        _buildResumenCard(
          valor: data.criticos.toString(),
          label: 'Críticos',
          color: const Color(0xFFEF4444),
          icono: Icons.warning_rounded,
        ),
        const SizedBox(width: 8),
        _buildResumenCard(
          valor: data.alertas.toString(),
          label: 'Alertas',
          color: const Color(0xFFF59E0B),
          icono: Icons.notifications_active,
        ),
      ],
    );
  }

  Widget _buildResumenCard({
    required String valor,
    required String label,
    required Color color,
    required IconData icono,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstudianteCard(EstudianteRiesgo e) {
    final esCritico = e.nivelRiesgo == 'CRITICO';
    final color = esCritico ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final bgColor = esCritico ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: bgColor,
                  radius: 20,
                  child: Text(
                    e.nombre.isNotEmpty ? e.nombre[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.nombreCompleto,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        e.curso.nombreCompleto,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Badge nivel de riesgo
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    esCritico ? 'CRÍTICO' : 'ALERTA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de porcentaje
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Asistencia',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  '${e.porcentajeAsistencia.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: e.porcentajeAsistencia / 100,
                minHeight: 7,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 10),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                    label: 'Clases', valor: e.clasesTotales.toString()),
                _buildStat(
                    label: 'Ausencias',
                    valor: e.ausencias.toString(),
                    color: const Color(0xFFEF4444)),
                _buildStat(
                    label: 'Tardanzas',
                    valor: e.tardanzas.toString(),
                    color: const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
      {required String label, required String valor, Color? color}) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color ?? const Color(0xFF1F2937),
          ),
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 72, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              '¡Sin estudiantes en riesgo!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Ningún estudiante tiene asistencia por debajo del $_umbral% en el período seleccionado.',
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
