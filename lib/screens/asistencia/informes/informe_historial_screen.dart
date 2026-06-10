// lib/screens/asistencia/informes/informe_historial_screen.dart
//
// Informe 5: Historial completo de asistencia de un estudiante.
// Para uso de DOCENTE, RECTOR, COORDINADOR — pueden buscar cualquier estudiante.
// Flujo: seleccionar curso → seleccionar estudiante → rango de fechas → ver historial.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/asistencia.dart';
import '../../../models/asistencia_informes.dart';
import '../../../providers/asistencia_provider.dart';
import '../../../services/asistencia_informes_service.dart';

class InformeHistorialScreen extends StatefulWidget {
  const InformeHistorialScreen({super.key});

  @override
  State<InformeHistorialScreen> createState() =>
      _InformeHistorialScreenState();
}

class _InformeHistorialScreenState extends State<InformeHistorialScreen> {
  final _service = asistenciaInformesService;

  // Selección
  String? _cursoId;
  String? _estudianteId;

  // Fechas
  DateTime _desde = DateTime(DateTime.now().year, 1, 1);
  DateTime _hasta = DateTime.now();

  // Estado
  bool _isLoading = false;
  bool _isLoadingEstudiantes = false;
  String? _error;
  InformeHistorialResponse? _data;
  List<EstudianteAsistencia> _estudiantesCurso = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AsistenciaProvider>().cargarCursos();
    });
  }

  Future<void> _cargarEstudiantes(String cursoId) async {
    setState(() {
      _isLoadingEstudiantes = true;
      _estudiantesCurso = [];
      _estudianteId = null;
      _data = null;
    });
    try {
      final provider = context.read<AsistenciaProvider>();
      await provider.cargarEstudiantes(cursoId);
      setState(() => _estudiantesCurso = provider.estudiantes);
    } catch (_) {
    } finally {
      setState(() => _isLoadingEstudiantes = false);
    }
  }

  Future<void> _cargar() async {
    if (_estudianteId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.obtenerHistorialEstudiante(
        estudianteId: _estudianteId!,
        desde: DateFormat('yyyy-MM-dd').format(_desde),
        hasta: DateFormat('yyyy-MM-dd').format(_hasta),
      );
      setState(() => _data = result);
    } catch (e) {
      setState(
          () => _error = 'No se pudo cargar el historial. Verifica tu conexión.');
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
      if (_estudianteId != null) _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Historial de Estudiante'),
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
          if (_estudianteId != null)
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
            child: _buildCuerpo(),
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
          // Selector de curso
          Consumer<AsistenciaProvider>(
            builder: (context, provider, _) {
              return DropdownButtonFormField<String>(
                initialValue: _cursoId,
                decoration: InputDecoration(
                  labelText: 'Curso',
                  prefixIcon: const Icon(Icons.school, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                hint: const Text('Selecciona un curso'),
                items: provider.cursos
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nombreCompleto),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _cursoId = v);
                    _cargarEstudiantes(v);
                  }
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Selector de estudiante (visible cuando hay curso)
          if (_cursoId != null)
            _isLoadingEstudiantes
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: _estudianteId,
                    decoration: InputDecoration(
                      labelText: 'Estudiante',
                      prefixIcon:
                          const Icon(Icons.person_search, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    hint: const Text('Selecciona un estudiante'),
                    items: _estudiantesCurso
                        .map((e) => DropdownMenuItem(
                              value: e.estudianteId,
                              child: Text(e.nombreCompleto),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _estudianteId = v;
                          _data = null;
                        });
                        _cargar();
                      }
                    },
                  ),

          // Rango de fechas (visible cuando hay estudiante)
          if (_estudianteId != null) ...[
            const SizedBox(height: 12),
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
          ],
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
  // CUERPO PRINCIPAL
  // ==========================================

  Widget _buildCuerpo() {
    if (_estudianteId == null) {
      return _buildInstrucciones();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_data == null) {
      return const SizedBox.shrink();
    }

    if (_data!.registros.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCabezaEstudiante(),
          const SizedBox(height: 12),
          _buildResumenCard(),
          const SizedBox(height: 16),
          _buildListaRegistros(),
        ],
      ),
    );
  }

  Widget _buildInstrucciones() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Selecciona curso y estudiante',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige un curso y luego el estudiante para ver su historial de asistencia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONTENIDO DEL HISTORIAL
  // ==========================================

  Widget _buildCabezaEstudiante() {
    final est = _data!.estudiante;
    final iniciales = est.nombreCompleto
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF059669),
            radius: 26,
            child: Text(
              iniciales,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  est.nombreCompleto,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  est.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    final r = _data!.resumen;
    final color = _colorPorcentaje(r.porcentajeAsistencia);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${r.porcentajeAsistencia.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'de asistencia',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: r.porcentajeAsistencia / 100,
                        minHeight: 8,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.25),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(Icons.check_circle, Colors.greenAccent,
                    r.presentes, 'Presentes'),
                _buildStat(
                    Icons.cancel, Colors.redAccent, r.ausentes, 'Ausentes'),
                _buildStat(Icons.access_time, Colors.orangeAccent,
                    r.tardanzas, 'Tardanzas'),
                _buildStat(Icons.event_note, Colors.white70,
                    r.clasesTotales, 'Total'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
      IconData icon, Color color, int valor, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          '$valor',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildListaRegistros() {
    final registros = _data!.registros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Historial de clases',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${registros.length} registros',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: registros.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) =>
                _buildRegistroItem(registros[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistroItem(RegistroHistorial registro) {
    final color = _colorEstado(registro.estado);
    final icono = _iconoEstado(registro.estado);
    final label = _labelEstado(registro.estado);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Fecha
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(registro.fecha),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM', 'es_ES').format(registro.fecha),
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registro.asignatura?.nombre ?? registro.curso.nombre,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (registro.asignatura != null)
                  Text(
                    registro.curso.nombre,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (registro.observaciones != null &&
                    registro.observaciones!.isNotEmpty)
                  Text(
                    registro.observaciones!,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 12, color: color),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  Color _colorPorcentaje(double p) {
    if (p >= 90) return Colors.greenAccent;
    if (p >= 75) return Colors.lightBlueAccent;
    if (p >= 60) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PRESENTE':
        return const Color(0xFF10B981);
      case 'AUSENTE':
        return const Color(0xFFEF4444);
      case 'TARDANZA':
        return const Color(0xFFF59E0B);
      case 'JUSTIFICADO':
        return const Color(0xFF3B82F6);
      case 'PERMISO':
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  IconData _iconoEstado(String estado) {
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

  String _labelEstado(String estado) {
    switch (estado) {
      case 'PRESENTE':
        return 'Pres.';
      case 'AUSENTE':
        return 'Aus.';
      case 'TARDANZA':
        return 'Tard.';
      case 'JUSTIFICADO':
        return 'Just.';
      case 'PERMISO':
        return 'Perm.';
      default:
        return estado;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sin registros en el período',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'El estudiante no tiene registros de asistencia en el rango de fechas seleccionado.',
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
