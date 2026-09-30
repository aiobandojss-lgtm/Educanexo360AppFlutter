// lib/screens/asistencia/registrar_asistencia_screen.dart

import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/asistencia.dart';
import '../../providers/asistencia_provider.dart';
import '../../widgets/common/gradient_header.dart';
import '../../services/api_service.dart' show mensajeDeError;

class RegistrarAsistenciaScreen extends StatefulWidget {
  final String? asistenciaId; // ✅ NUEVO - Para modo edición
  final bool isEditMode; // ✅ NUEVO - Indica si es edición

  const RegistrarAsistenciaScreen({
    super.key,
    this.asistenciaId,
    this.isEditMode = false,
  });

  @override
  State<RegistrarAsistenciaScreen> createState() =>
      _RegistrarAsistenciaScreenState();
}

class _RegistrarAsistenciaScreenState extends State<RegistrarAsistenciaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Campos del formulario
  DateTime _fecha = DateTime.now();
  String? _cursoSeleccionado;
  String? _asignaturaSeleccionada;
  String _tipoSesion = TiposSesion.clase;
  TimeOfDay _horaInicio = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _observacionesController =
      TextEditingController();

  // Estado
  bool _guardando = false;
  bool _cargandoEstudiantes = false;
  bool _cargandoDatos = false; // ✅ NUEVO - Para cargar datos en edición
  bool _mostrarOpcionesAvanzadas = false;

  @override
  void initState() {
    super.initState();

    _mostrarOpcionesAvanzadas = widget.isEditMode;

    if (widget.isEditMode && widget.asistenciaId != null) {
      // ✅ Modo edición: cargar datos existentes
      _cargarDatosExistentes();
    } else {
      // Modo creación: cargar cursos normalmente
      _cargarCursos();
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  // Cargar datos existentes para edición
  Future<void> _cargarDatosExistentes() async {
    setState(() => _cargandoDatos = true);

    final provider = context.read<AsistenciaProvider>();

    try {
      await provider.cargarRegistro(widget.asistenciaId!);
      await provider.cargarCursos();

      final registro = provider.registroActual;

      if (registro == null) {
        if (mounted) {
          _mostrarMensaje(
            'No se pudo cargar el registro. Verifica tu conexión.',
            tipo: 'error',
          );
          context.go('/asistencia');
        }
        return;
      }

      setState(() {
        _fecha = registro.fecha;
        _cursoSeleccionado = registro.curso.id;
        _asignaturaSeleccionada = registro.asignatura?.id;
        _tipoSesion = registro.tipoSesion;
        _horaInicio = _parseHora(
            registro.horaInicio, const TimeOfDay(hour: 7, minute: 0));
        _horaFin =
            _parseHora(registro.horaFin, const TimeOfDay(hour: 8, minute: 0));
        if (registro.observacionesGenerales != null) {
          _observacionesController.text = registro.observacionesGenerales!;
        }
      });

      await provider.cargarAsignaturas(_cursoSeleccionado!);
      provider.establecerEstudiantes(registro.estudiantes);

      dlog('✅ Datos cargados para edición — ${registro.estudiantes.length} estudiantes');
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(mensajeDeError(e, 'Error al cargar'), tipo: 'error');
        context.go('/asistencia');
      }
    } finally {
      if (mounted) setState(() => _cargandoDatos = false);
    }
  }

  // Helper seguro para parsear hora "HH:mm" con fallback
  TimeOfDay _parseHora(String hora, TimeOfDay fallback) {
    if (hora.isEmpty || !hora.contains(':')) return fallback;
    final parts = hora.split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _cargarCursos() async {
    final provider = context.read<AsistenciaProvider>();
    await provider.cargarCursos();
  }

  Future<void> _cargarEstudiantes(String cursoId) async {
    setState(() => _cargandoEstudiantes = true);
    final provider = context.read<AsistenciaProvider>();

    await Future.wait([
      provider.cargarAsignaturas(cursoId),
      provider.cargarEstudiantes(cursoId),
    ]);

    setState(() => _cargandoEstudiantes = false);
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      setState(() => _fecha = fecha);
    }
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = hora;
        } else {
          _horaFin = hora;
        }
      });
    }
  }

  // ✅ ACTUALIZADO - Soporta crear Y editar
  Future<void> _guardarAsistencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cursoSeleccionado == null) {
      _mostrarMensaje('Por favor selecciona un curso');
      return;
    }

    final provider = context.read<AsistenciaProvider>();

    if (provider.estudiantes.isEmpty) {
      _mostrarMensaje('No hay estudiantes en este curso');
      return;
    }

    setState(() => _guardando = true);

    try {
      if (widget.isEditMode && widget.asistenciaId != null) {
        // ✅ MODO EDICIÓN
        dlog('🔧 Editando registro: ${widget.asistenciaId}');

        final registro = await provider.actualizarRegistro(
          id: widget.asistenciaId!,
          fecha: _fecha,
          cursoId: _cursoSeleccionado!,
          asignaturaId: _asignaturaSeleccionada,
          tipoSesion: _tipoSesion,
          horaInicio:
              '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}',
          horaFin:
              '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}',
          estudiantes: provider.estudiantes,
          observacionesGenerales: _observacionesController.text.isEmpty
              ? null
              : _observacionesController.text,
        );

        if (registro != null && mounted) {
          _mostrarMensaje('Asistencia actualizada exitosamente', tipo: 'exito');
          context.go('/asistencia/${widget.asistenciaId}');
        } else if (mounted) {
          _mostrarMensaje('Error al actualizar la asistencia', tipo: 'error');
        }
      } else {
        // ✅ MODO CREACIÓN (código original)
        dlog('➕ Creando nuevo registro');

        final registro = await provider.crearRegistro(
          fecha: _fecha,
          cursoId: _cursoSeleccionado!,
          asignaturaId: _asignaturaSeleccionada,
          tipoSesion: _tipoSesion,
          horaInicio:
              '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}',
          horaFin:
              '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}',
          estudiantes: provider.estudiantes,
          observacionesGenerales: _observacionesController.text.isEmpty
              ? null
              : _observacionesController.text,
        );

        if (registro != null && mounted) {
          _mostrarMensaje('Asistencia registrada exitosamente', tipo: 'exito');
          context.go('/asistencia');
        } else if (mounted) {
          _mostrarMensaje('Error al guardar la asistencia', tipo: 'error');
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(mensajeDeError(e, 'Ocurrió un error. Intenta de nuevo.'), tipo: 'error');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
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

  void _marcarTodos(String estado) {
    final provider = context.read<AsistenciaProvider>();
    for (var estudiante in provider.estudiantes) {
      provider.actualizarEstadoEstudiante(estudiante.estudianteId, estado);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Mostrar loading mientras carga datos en modo edición
    if (_cargandoDatos) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Column(
          children: [
            GradientHeader(
              title: 'Cargando...',
              showBack: true,
              leadingIcon: Icons.fact_check,
            ),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          GradientHeader(
            title:
                widget.isEditMode ? 'Editar Asistencia' : 'Registrar Asistencia',
            showBack: true,
            leadingIcon: Icons.edit_calendar,
            actions: [
              if (_guardando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                )
              else
                HeaderAction(
                  icon: Icons.save,
                  onTap: _guardarAsistencia,
                  tooltip: 'Guardar',
                ),
            ],
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
            // 📋 INFORMACIÓN GENERAL
            _buildInfoGeneralPanel(),

            // 👥 LISTA DE ESTUDIANTES
            Expanded(
              child: _buildListaEstudiantes(),
            ),

            // 💾 BOTÓN GUARDAR
            _buildGuardarButton(),
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📋 PANEL DE INFORMACIÓN GENERAL
  // ========================================

  Widget _buildInfoGeneralPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Fecha
          InkWell(
            onTap: _seleccionarFecha,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF047857)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                              .format(_fecha),
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
          ),

          const SizedBox(height: 12),

          // Curso
          Consumer<AsistenciaProvider>(
            builder: (context, provider, _) {
              return DropdownButtonFormField<String>(
                initialValue: _cursoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Curso *',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: provider.cursos.map((curso) {
                  return DropdownMenuItem(
                    value: curso.id,
                    child: Text(curso.nombreCompleto),
                  );
                }).toList(),
                onChanged: widget.isEditMode
                    ? null // ✅ Deshabilitar en modo edición (no se puede cambiar curso)
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _cursoSeleccionado = value;
                            _asignaturaSeleccionada = null;
                          });
                          _cargarEstudiantes(value);
                        }
                      },
                validator: (value) {
                  if (value == null) return 'Selecciona un curso';
                  return null;
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Asignatura (opcional)
          Consumer<AsistenciaProvider>(
            builder: (context, provider, _) {
              if (_cursoSeleccionado == null) {
                return const SizedBox.shrink();
              }

              if (provider.isLoadingAsignaturas) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cargando asignaturas...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (provider.asignaturas.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No hay asignaturas para este curso',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                initialValue: _asignaturaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Asignatura (opcional)',
                  prefixIcon: const Icon(Icons.book),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Selecciona la materia que estás dictando',
                  helperMaxLines: 2,
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin asignatura específica'),
                  ),
                  ...provider.asignaturas.map((asignatura) {
                    return DropdownMenuItem(
                      value: asignatura.id,
                      child: Text(asignatura.nombre),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _asignaturaSeleccionada = value);
                },
              );
            },
          ),

          const SizedBox(height: 8),

          // Toggle opciones avanzadas
          InkWell(
            onTap: () => setState(
                () => _mostrarOpcionesAvanzadas = !_mostrarOpcionesAvanzadas),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _mostrarOpcionesAvanzadas
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: const Color(0xFF047857),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _mostrarOpcionesAvanzadas
                        ? 'Ocultar opciones'
                        : 'Opciones avanzadas',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tipo de sesión, horas y observaciones (colapsable)
          if (_mostrarOpcionesAvanzadas) ...[
            const SizedBox(height: 12),

            // Tipo de sesión y horarios
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _tipoSesion,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: TiposSesion.todos.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(TiposSesion.getLabel(tipo)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _tipoSesion = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarHora(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inicio',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _horaInicio.format(context),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarHora(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fin',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _horaFin.format(context),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Observaciones generales
            TextFormField(
              controller: _observacionesController,
              decoration: InputDecoration(
                labelText: 'Observaciones generales (opcional)',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // 👥 LISTA DE ESTUDIANTES
  // ========================================

  Widget _buildListaEstudiantes() {
    return Consumer<AsistenciaProvider>(
      builder: (context, provider, _) {
        if (_cargandoEstudiantes) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.estudiantes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    _cursoSeleccionado == null
                        ? 'Selecciona un curso para comenzar'
                        : 'No hay estudiantes en este curso',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildAccionesRapidas(),
            _buildContadorEstudiantes(provider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.estudiantes.length,
                itemBuilder: (context, index) {
                  final estudiante = provider.estudiantes[index];
                  return _buildEstudianteCard(estudiante);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccionesRapidas() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'Marcar todos como:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildBotonRapido(
            label: 'Presentes',
            icon: Icons.check_circle,
            color: Colors.green,
            onTap: () => _marcarTodos(EstadosAsistencia.presente),
          ),
          _buildBotonRapido(
            label: 'Ausentes',
            icon: Icons.cancel,
            color: Colors.red,
            onTap: () => _marcarTodos(EstadosAsistencia.ausente),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonRapido({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstudianteCard(EstudianteAsistencia estudiante) {
    final colorEstado = _getColorEstado(estudiante.estado);
    final esEspecial = estudiante.estado == EstadosAsistencia.justificado ||
        estudiante.estado == EstadosAsistencia.permiso;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: colorEstado.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorEstado.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorEstado,
              radius: 18,
              child: Text(
                estudiante.nombreCompleto
                    .split(' ')
                    .where((p) => p.isNotEmpty)
                    .map((p) => p[0])
                    .take(2)
                    .join()
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudiante.nombreCompleto,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (estudiante.observaciones != null &&
                      estudiante.observaciones!.isNotEmpty)
                    Text(
                      estudiante.observaciones!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _buildBotonEstado(estudiante, EstadosAsistencia.presente,
                Icons.check_circle, Colors.green),
            _buildBotonEstado(
                estudiante, EstadosAsistencia.ausente, Icons.cancel, Colors.red),
            _buildBotonEstado(estudiante, EstadosAsistencia.tardanza,
                Icons.access_time, Colors.orange),
            // Botón estados especiales (Justificado / Permiso)
            GestureDetector(
              onTap: () => _mostrarOpcionesEstudiante(estudiante),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: esEspecial
                      ? colorEstado.withValues(alpha: 0.15)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: esEspecial ? colorEstado : Colors.grey[300]!,
                  ),
                ),
                child: Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: esEspecial ? colorEstado : Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _guardando ? null : _guardarAsistencia,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_guardando
                ? (widget.isEditMode ? 'Actualizando...' : 'Guardando...')
                : (widget.isEditMode
                    ? 'Actualizar Asistencia'
                    : 'Guardar Asistencia')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // 📊 CONTADOR EN TIEMPO REAL
  // ========================================

  Widget _buildContadorEstudiantes(AsistenciaProvider provider) {
    if (provider.estudiantes.isEmpty) return const SizedBox.shrink();

    final total = provider.estudiantes.length;
    final presentes = provider.estudiantes
        .where((e) => e.estado == EstadosAsistencia.presente)
        .length;
    final ausentes = provider.estudiantes
        .where((e) => e.estado == EstadosAsistencia.ausente)
        .length;
    final tardanzas = provider.estudiantes
        .where((e) => e.estado == EstadosAsistencia.tardanza)
        .length;
    final otros = total - presentes - ausentes - tardanzas;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(
          bottom: BorderSide(color: Color(0xFFBBF7D0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat(Icons.check_circle, Colors.green, presentes, 'Pres.'),
          _buildMiniStat(Icons.cancel, Colors.red, ausentes, 'Aus.'),
          _buildMiniStat(Icons.access_time, Colors.orange, tardanzas, 'Tard.'),
          if (otros > 0)
            _buildMiniStat(Icons.more_horiz, Colors.blue, otros, 'Otros'),
          Text(
            'Total: $total',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icon, Color color, int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ========================================
  // 🎯 BOTÓN DE ESTADO (card compacta)
  // ========================================

  Widget _buildBotonEstado(
    EstudianteAsistencia estudiante,
    String estado,
    IconData icono,
    Color color,
  ) {
    final seleccionado = estudiante.estado == estado;
    return GestureDetector(
      onTap: () => context
          .read<AsistenciaProvider>()
          .actualizarEstadoEstudiante(estudiante.estudianteId, estado),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: seleccionado ? color : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: seleccionado ? color : Colors.grey[300]!,
          ),
        ),
        child: Icon(
          icono,
          size: 18,
          color: seleccionado ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }

  // ========================================
  // ⚙️ BOTTOM SHEET: ESTADOS ESPECIALES
  // ========================================

  void _mostrarOpcionesEstudiante(EstudianteAsistencia estudianteInicial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String estadoSeleccionado = estudianteInicial.estado;
        final obsController =
            TextEditingController(text: estudianteInicial.observaciones ?? '');

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    estudianteInicial.nombreCompleto,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estado especial para este estudiante',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOpcionSheet(
                          estado: EstadosAsistencia.justificado,
                          label: 'Justificado',
                          icon: Icons.assignment_late,
                          color: Colors.blue,
                          estadoActual: estadoSeleccionado,
                          onTap: () => setSheetState(() => estadoSeleccionado =
                              EstadosAsistencia.justificado),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOpcionSheet(
                          estado: EstadosAsistencia.permiso,
                          label: 'Permiso',
                          icon: Icons.shield,
                          color: const Color(0xFF059669),
                          estadoActual: estadoSeleccionado,
                          onTap: () => setSheetState(
                              () => estadoSeleccionado = EstadosAsistencia.permiso),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: obsController,
                    decoration: InputDecoration(
                      labelText: 'Observaciones (opcional)',
                      hintText: 'Ej: Presenta permiso médico',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final provider = context.read<AsistenciaProvider>();
                        provider.actualizarEstadoEstudiante(
                            estudianteInicial.estudianteId, estadoSeleccionado);
                        if (obsController.text.isNotEmpty) {
                          provider.actualizarObservacionEstudiante(
                              estudianteInicial.estudianteId,
                              obsController.text);
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Aplicar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOpcionSheet({
    required String estado,
    required String label,
    required IconData icon,
    required Color color,
    required String estadoActual,
    required VoidCallback onTap,
  }) {
    final seleccionado = estadoActual == estado;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              seleccionado ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : Colors.grey[200]!,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: seleccionado ? color : Colors.grey[400], size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    seleccionado ? FontWeight.bold : FontWeight.normal,
                color: seleccionado ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

}
