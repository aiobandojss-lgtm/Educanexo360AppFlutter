// lib/screens/asistencia/registrar_asistencia_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/asistencia.dart';
import '../../providers/asistencia_provider.dart';

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

  @override
  void initState() {
    super.initState();

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

  // ✅ NUEVO - Cargar datos existentes para edición
  Future<void> _cargarDatosExistentes() async {
    setState(() => _cargandoDatos = true);

    final provider = context.read<AsistenciaProvider>();

    // Cargar el registro existente
    await provider.cargarRegistro(widget.asistenciaId!);

    // Cargar cursos
    await provider.cargarCursos();

    final registro = provider.registroActual;

    if (registro != null) {
      // Poblar campos con datos existentes
      setState(() {
        _fecha = registro.fecha;
        _cursoSeleccionado = registro.curso.id;
        _asignaturaSeleccionada = registro.asignatura?.id;
        _tipoSesion = registro.tipoSesion;

        // Parsear horas
        final inicioSplit = registro.horaInicio.split(':');
        _horaInicio = TimeOfDay(
          hour: int.parse(inicioSplit[0]),
          minute: int.parse(inicioSplit[1]),
        );

        final finSplit = registro.horaFin.split(':');
        _horaFin = TimeOfDay(
          hour: int.parse(finSplit[0]),
          minute: int.parse(finSplit[1]),
        );

        if (registro.observacionesGenerales != null) {
          _observacionesController.text = registro.observacionesGenerales!;
        }
      });

      // ✅ CRÍTICO: Cargar asignaturas del curso
      await provider.cargarAsignaturas(_cursoSeleccionado!);

      // ✅ CRÍTICO: Usar los estudiantes DEL REGISTRO, NO cargar frescos
      // Esto preserva los estados originales (Presente, Ausente, Permiso, etc.)
      provider.establecerEstudiantes(registro.estudiantes);

      print('✅ Datos cargados para edición:');
      print('   - Curso: ${registro.curso.nombreCompleto}');
      print('   - Asignatura: ${registro.asignatura?.nombre ?? "Ninguna"}');
      print('   - Estudiantes: ${registro.estudiantes.length}');

      // Debug: Mostrar estados de estudiantes
      for (var est in registro.estudiantes) {
        print('   - ${est.nombreCompleto}: ${est.estado}');
      }
    }

    setState(() => _cargandoDatos = false);
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
        print('🔧 Editando registro: ${widget.asistenciaId}');

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
        print('➕ Creando nuevo registro');

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
        _mostrarMensaje('Error: ${e.toString()}', tipo: 'error');
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
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            widget.isEditMode ? 'Editar Asistencia' : 'Registrar Asistencia'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
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
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarAsistencia,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: Form(
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
                  Icon(Icons.calendar_today, color: Colors.indigo[700]),
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
                value: _cursoSeleccionado,
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
                value: _asignaturaSeleccionada,
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

          const SizedBox(height: 12),

          // Tipo de sesión y horarios
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _tipoSesion,
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
          Text(
            'Marcar todos como:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                Expanded(
                  child: Text(
                    estudiante.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: EstadosAsistencia.todos.map((estado) {
                final seleccionado = estudiante.estado == estado;
                return InkWell(
                  onTap: () {
                    final provider = context.read<AsistenciaProvider>();
                    provider.actualizarEstadoEstudiante(
                      estudiante.estudianteId,
                      estado,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? _getColorEstado(estado)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: seleccionado
                            ? _getColorEstado(estado)
                            : Colors.grey[300]!,
                        width: seleccionado ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconoEstado(estado),
                          size: 16,
                          color: seleccionado ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          EstadosAsistencia.getLabel(estado),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                seleccionado ? Colors.white : Colors.grey[600],
                            fontWeight: seleccionado
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
              backgroundColor: Colors.indigo,
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
}
