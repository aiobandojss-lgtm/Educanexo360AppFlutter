// lib/screens/asistencia/lista_asistencia_screen.dart

import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/asistencia.dart';
import '../../models/usuario.dart';
import '../../providers/asistencia_provider.dart';
import '../../services/api_service.dart';
import '../../services/permission_service.dart';
import '../../widgets/common/gradient_header.dart';

class ListaAsistenciaScreen extends StatefulWidget {
  const ListaAsistenciaScreen({super.key});

  @override
  State<ListaAsistenciaScreen> createState() => _ListaAsistenciaScreenState();
}

class _ListaAsistenciaScreenState extends State<ListaAsistenciaScreen> {
  final ApiService _apiService = ApiService();

  String? _cursoSeleccionado;
  // Para ACUDIENTE: ID del hijo seleccionado actualmente
  String? _estudianteIdSeleccionado;
  // Datos completos de hijos del acudiente (con nombres reales)
  List<Usuario> _hijosUsuarios = [];
  // Panel de filtros visible (colapsable)
  bool _filtrosVisibles = true;

  DateTime _fechaInicio = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _fechaFin = DateTime.now();

  bool get _esEstudiante =>
      PermissionService.getCurrentUser()?.tipo.value == 'ESTUDIANTE';
  bool get _esAcudiente =>
      PermissionService.getCurrentUser()?.tipo.value == 'ACUDIENTE';
  bool get _esRectorOCoordinador {
    final tipo = PermissionService.getCurrentUser()?.tipo.value ?? '';
    return tipo == 'RECTOR' || tipo == 'COORDINADOR';
  }

  @override
  void initState() {
    super.initState();
    _filtrosVisibles = !_esEstudiante;

    final provider = context.read<AsistenciaProvider>();
    if (provider.resumenes.isEmpty) {
      provider.prepareLoading();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inicializarRol();
    });
  }

  void _inicializarRol() {
    final user = PermissionService.getCurrentUser();
    if (user == null) return;

    if (_esEstudiante) {
      // ESTUDIANTE: filtra por su propio ID
      _estudianteIdSeleccionado = user.id;
      _cargarDatos();
    } else if (_esAcudiente) {
      // ACUDIENTE: cargar datos reales de cada hijo para mostrar su nombre
      final hijosIds = user.infoAcademica?.estudiantesAsociados ?? [];
      if (hijosIds.isNotEmpty) {
        _estudianteIdSeleccionado = hijosIds.first;
        _cargarNombresHijos(hijosIds);
      } else {
        _cargarDatos();
      }
    } else {
      _cargarDatos();
    }
  }

  Future<void> _cargarNombresHijos(List<String> ids) async {
    final futures = ids.map((id) async {
      try {
        final response = await _apiService.get('/usuarios/$id');
        final data = response['data'] ?? response;
        return Usuario.fromJson(data);
      } catch (e) {
        dlog('⚠️ No se pudo cargar nombre del hijo $id: $e');
        return null;
      }
    });

    final results = await Future.wait(futures);
    if (!mounted) return;
    setState(() => _hijosUsuarios = results.whereType<Usuario>().toList());
    await _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final provider = context.read<AsistenciaProvider>();

    if (!_esEstudiante && !_esAcudiente) {
      // Docente/Admin: cursos y resumen en paralelo
      await Future.wait([
        provider.cargarCursos(),
        provider.cargarResumen(
          refresh: true,
          fechaInicio: DateFormat('yyyy-MM-dd').format(_fechaInicio),
          fechaFin: DateFormat('yyyy-MM-dd').format(_fechaFin),
          cursoId: _cursoSeleccionado,
          estudianteId: _estudianteIdSeleccionado,
        ),
      ]);
    } else {
      await provider.cargarResumen(
        refresh: true,
        fechaInicio: DateFormat('yyyy-MM-dd').format(_fechaInicio),
        fechaFin: DateFormat('yyyy-MM-dd').format(_fechaFin),
        cursoId: _cursoSeleccionado,
        estudianteId: _estudianteIdSeleccionado,
      );
    }
  }

  Future<void> _onRefresh() async {
    await _cargarDatos();
  }

  void _aplicarFiltros() {
    final provider = context.read<AsistenciaProvider>();
    provider.cargarResumen(
      refresh: true,
      fechaInicio: DateFormat('yyyy-MM-dd').format(_fechaInicio),
      fechaFin: DateFormat('yyyy-MM-dd').format(_fechaFin),
      cursoId: _cursoSeleccionado,
      estudianteId: _estudianteIdSeleccionado,
    );
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
          if (_fechaInicio.isAfter(_fechaFin)) {
            _fechaFin = _fechaInicio;
          }
        } else {
          _fechaFin = fecha;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaInicio = _fechaFin;
          }
        }
      });
      _aplicarFiltros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header unificado (GradientHeader)
          GradientHeader(
            title: 'Control de Asistencia',
            showBack: true,
            leadingIcon: Icons.fact_check,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            actions: [
              HeaderAction(
                icon: _filtrosVisibles
                    ? Icons.filter_list_off
                    : Icons.filter_list,
                onTap: () =>
                    setState(() => _filtrosVisibles = !_filtrosVisibles),
                tooltip: _filtrosVisibles ? 'Ocultar filtros' : 'Mostrar filtros',
              ),
            ],
          ),

          // 🔍 PANEL DE FILTROS
          if (_filtrosVisibles) _buildFiltrosPanel(),

          // 🚨 BANNER RIESGO (solo RECTOR / COORDINADOR)
          if (_esRectorOCoordinador) _buildBannerRiesgo(),

          // 📋 LISTA DE REGISTROS
          Expanded(
            child: Consumer<AsistenciaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.resumenes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return _buildError(provider.error!);
                }

                if (provider.resumenes.isEmpty) {
                  return _buildEmpty();
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.resumenes.length,
                    itemBuilder: (context, index) {
                      final resumen = provider.resumenes[index];
                      return _buildRegistroCard(resumen);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ➕ BOTÓN REGISTRAR (solo DOCENTE/COORDINADOR)
      floatingActionButton: PermissionService.canAccess('asistencia.registrar')
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/asistencia/registrar'),
              backgroundColor: const Color(0xFF059669),
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            )
          : null,
    );
  }

  // ========================================
  // 🚨 BANNER ESTUDIANTES EN RIESGO
  // ========================================

  Widget _buildBannerRiesgo() {
    return InkWell(
      onTap: () => context.push('/asistencia/informes/riesgo'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFFEF2F2),
          border: Border(
            bottom: BorderSide(color: Color(0xFFFECACA)),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ver estudiantes en riesgo de ausencias',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: Color(0xFFEF4444), size: 20),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔍 PANEL DE FILTROS
  // ========================================

  Widget _buildFiltrosPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── SELECTOR DE CURSO (solo para roles que ven todos los cursos) ──
          if (!_esEstudiante && !_esAcudiente)
            Consumer<AsistenciaProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<String>(
                  initialValue: _cursoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Curso',
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los cursos'),
                    ),
                    ...provider.cursos.map((curso) {
                      return DropdownMenuItem(
                        value: curso.id,
                        child: Text(curso.nombreCompleto),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _cursoSeleccionado = value);
                    _aplicarFiltros();
                  },
                );
              },
            ),

          // ── SELECTOR DE HIJO (solo ACUDIENTE con múltiples hijos) ──
          if (_esAcudiente && _hijosUsuarios.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _estudianteIdSeleccionado,
              decoration: InputDecoration(
                labelText: 'Seleccionar hijo',
                prefixIcon: const Icon(Icons.child_care),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _hijosUsuarios.map((hijo) {
                return DropdownMenuItem<String>(
                  value: hijo.id,
                  child: Text(hijo.nombreCompleto),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _estudianteIdSeleccionado = value);
                _aplicarFiltros();
              },
            ),
          ],

          // ── LABEL ESTUDIANTE (solo rol ESTUDIANTE) ──
          if (_esEstudiante)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_outline,
                      color: Color(0xFF047857), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Viendo mi propia asistencia',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // ── LABEL ACUDIENTE hijo único ──
          if (_esAcudiente && _hijosUsuarios.length == 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.child_care, color: Color(0xFF047857), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Viendo asistencia de tu hijo',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          if (!_esEstudiante && !_esAcudiente) const SizedBox(height: 12),
          if (_esEstudiante || _esAcudiente) const SizedBox(height: 12),

          // ── SELECTORES DE FECHA (todos los roles) ──
          Row(
            children: [
              Expanded(
                child: _buildFechaSelector(
                  label: 'Desde',
                  fecha: _fechaInicio,
                  onTap: () => _seleccionarFecha(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFechaSelector(
                  label: 'Hasta',
                  fecha: _fechaFin,
                  onTap: () => _seleccionarFecha(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFechaSelector({
    required String label,
    required DateTime fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: Color(0xFF047857)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(fecha),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 📋 CARD DE REGISTRO
  // ========================================

  Widget _buildRegistroCard(ResumenAsistencia resumen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/asistencia/${resumen.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Fecha y curso
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF047857),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resumen.curso.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                              .format(resumen.fecha),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de finalizado
                  if (resumen.finalizado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Finalizado',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const Divider(height: 24),

              // Estadísticas - PRIMERA FILA
              Row(
                children: [
                  _buildEstadistica(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: 'Presentes',
                    valor: resumen.presentes,
                  ),
                  _buildEstadistica(
                    icon: Icons.cancel,
                    color: Colors.red,
                    label: 'Ausentes',
                    valor: resumen.ausentes,
                  ),
                  _buildEstadistica(
                    icon: Icons.access_time,
                    color: Colors.orange,
                    label: 'Tardanzas',
                    valor: resumen.tardanzas,
                  ),
                ],
              ),

              // ✅ SEGUNDA FILA - Justificados y Permisos
              if (resumen.justificados > 0 || resumen.permisos > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (resumen.justificados > 0)
                      _buildEstadistica(
                        icon: Icons.assignment_late,
                        color: Colors.blue,
                        label: 'Justificados',
                        valor: resumen.justificados,
                      ),
                    if (resumen.permisos > 0)
                      _buildEstadistica(
                        icon: Icons.shield,
                        color: const Color(0xFF059669),
                        label: 'Permisos',
                        valor: resumen.permisos,
                      ),
                    // Spacer para mantener alineación
                    if (resumen.justificados == 0 || resumen.permisos == 0)
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ],

              // ✅ ASIGNATURA - Mostrar si existe
              if (resumen.asignatura != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.book,
                          size: 16, color: Color(0xFF047857)),
                      const SizedBox(width: 6),
                      Text(
                        'Asignatura: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          resumen.asignatura!.nombre,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Barra de porcentaje
              _buildBarraAsistencia(resumen.porcentajeAsistencia),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadistica({
    required IconData icon,
    required Color color,
    required String label,
    required int valor,
  }) {
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _buildBarraAsistencia(double porcentaje) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Porcentaje de asistencia',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${porcentaje.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getColorPorcentaje(porcentaje),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: porcentaje / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(
              _getColorPorcentaje(porcentaje),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorPorcentaje(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 75) return Colors.blue;
    if (porcentaje >= 60) return Colors.orange;
    return Colors.red;
  }

  // ========================================
  // 🚫 ERROR Y EMPTY STATES
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
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay registros de asistencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron registros para los filtros seleccionados',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (PermissionService.canAccess('asistencia.registrar')) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/asistencia/registrar'),
                icon: const Icon(Icons.add),
                label: const Text('Registrar Asistencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
