// lib/screens/tareas/formulario_tarea_screen.dart
// 📝 FORMULARIO DE TAREA - CREAR/EDITAR

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../widgets/tareas/file_uploader_widget.dart';
import '../../widgets/tareas/archivo_tile.dart';
import '../../services/api_service.dart';

class FormularioTareaScreen extends StatefulWidget {
  final String? tareaId; // null = crear, con valor = editar

  const FormularioTareaScreen({
    super.key,
    this.tareaId,
  });

  @override
  State<FormularioTareaScreen> createState() => _FormularioTareaScreenState();
}

class _FormularioTareaScreenState extends State<FormularioTareaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _calificacionMaxController =
      TextEditingController(text: '10.0');
  final TextEditingController _pesoEvaluacionController =
      TextEditingController();

  // Estados
  bool _isLoading = false;
  bool _isSaving = false;
  Tarea? _tareaOriginal;

  // Datos de formulario
  String? _cursoSeleccionado;
  String? _asignaturaSeleccionada;
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 7));
  TipoTarea _tipo = TipoTarea.individual;
  PrioridadTarea _prioridad = PrioridadTarea.media;
  bool _permiteTardias = false;

  // Archivos
  List<File> _archivosNuevos = [];
  List<ArchivoTarea> _archivosExistentes = [];

  // Datos para dropdowns
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _asignaturas = [];
  List<Map<String, dynamic>> _asignaturasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _calificacionMaxController.dispose();
    _pesoEvaluacionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar cursos y asignaturas
      await _loadCursosYAsignaturas();

      // Si es modo edición, cargar la tarea
      if (widget.tareaId != null) {
        await _loadTarea();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
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

  Future<void> _loadCursosYAsignaturas() async {
    try {
      final apiService = ApiService();

      // Cargar cursos
      final cursosResponse = await apiService.get('/cursos');
      if (cursosResponse['success'] == true) {
        _cursos = List<Map<String, dynamic>>.from(cursosResponse['data']);
      }

      // Cargar asignaturas
      final asignaturasResponse = await apiService.get('/asignaturas');
      if (asignaturasResponse['success'] == true) {
        _asignaturas =
            List<Map<String, dynamic>>.from(asignaturasResponse['data']);
        _asignaturasFiltradas = _asignaturas;
      }
    } catch (e) {
      print('Error cargando cursos y asignaturas: $e');
      rethrow;
    }
  }

  Future<void> _loadTarea() async {
    try {
      final tareaProvider = context.read<TareaProvider>();
      final tarea = await tareaProvider.obtenerTarea(widget.tareaId!);

      if (tarea != null) {
        setState(() {
          _tareaOriginal = tarea;
          _tituloController.text = tarea.titulo;
          _descripcionController.text = tarea.descripcion;
          _cursoSeleccionado = tarea.curso.id;
          _asignaturaSeleccionada = tarea.asignatura.id;
          _fechaLimite = tarea.fechaLimite;
          _calificacionMaxController.text = tarea.calificacionMaxima.toString();
          _pesoEvaluacionController.text =
              tarea.pesoEvaluacion?.toString() ?? '';
          _tipo = tarea.tipo;
          _prioridad = tarea.prioridad;
          _permiteTardias = tarea.permiteTardias;
          _archivosExistentes = List.from(tarea.archivosReferencia);
        });

        // Filtrar asignaturas del curso
        _filtrarAsignaturasPorCurso(_cursoSeleccionado!);
      }
    } catch (e) {
      print('Error cargando tarea: $e');
      rethrow;
    }
  }

  void _filtrarAsignaturasPorCurso(String cursoId) {
    print('🔍 FILTRAR ASIGNATURAS - Curso ID: $cursoId');
    print('   Total asignaturas disponibles: ${_asignaturas.length}');

    // Filtrar asignaturas que tienen este cursoId
    final asignaturasFiltradas = _asignaturas.where((asignatura) {
      // Obtener el cursoId de la asignatura
      final asignaturaCursoId = asignatura['cursoId'];

      // Puede venir como String directo o como objeto {$oid: "..."}
      String cursoIdDeAsignatura;
      if (asignaturaCursoId is String) {
        cursoIdDeAsignatura = asignaturaCursoId;
      } else if (asignaturaCursoId is Map) {
        cursoIdDeAsignatura =
            asignaturaCursoId['\$oid'] ?? asignaturaCursoId['_id'] ?? '';
      } else {
        cursoIdDeAsignatura = asignaturaCursoId.toString();
      }

      final coincide = cursoIdDeAsignatura == cursoId;

      if (coincide) {
        print(
            '   ✅ ${asignatura['nombre']} - INCLUIDA (cursoId: $cursoIdDeAsignatura)');
      }

      return coincide;
    }).toList();

    print('   Asignaturas filtradas: ${asignaturasFiltradas.length}');

    setState(() {
      _asignaturasFiltradas = asignaturasFiltradas;

      if (_asignaturaSeleccionada != null) {
        final asignaturaEstaEnCurso = asignaturasFiltradas.any(
          (a) => a['_id'] == _asignaturaSeleccionada,
        );

        if (!asignaturaEstaEnCurso) {
          print(
              '   ⚠️ Asignatura previamente seleccionada no está en este curso');
          _asignaturaSeleccionada = null;
        }
      }
    });

    print('   _asignaturasFiltradas final: ${_asignaturasFiltradas.length}');
  }

  Future<void> _seleccionarFechaLimite() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaLimite,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B5CF6),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      // Seleccionar hora
      if (mounted) {
        final hora = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_fechaLimite),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF8B5CF6),
                ),
              ),
              child: child!,
            );
          },
        );

        if (hora != null) {
          setState(() {
            _fechaLimite = DateTime(
              fecha.year,
              fecha.month,
              fecha.day,
              hora.hour,
              hora.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _eliminarArchivoExistente(ArchivoTarea archivo) async {
    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('¿Eliminar "${archivo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final tareaProvider = context.read<TareaProvider>();
        await tareaProvider.eliminarArchivoReferencia(
          tareaId: widget.tareaId!,
          archivoId: archivo.fileId,
        );

        setState(() {
          _archivosExistentes.removeWhere((a) => a.fileId == archivo.fileId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar archivo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_cursoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un curso'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_asignaturaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una asignatura'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final tareaProvider = context.read<TareaProvider>();
      final calificacionMax = double.parse(_calificacionMaxController.text);
      final pesoEval = _pesoEvaluacionController.text.isNotEmpty
          ? double.parse(_pesoEvaluacionController.text)
          : null;

      if (widget.tareaId == null) {
        // CREAR
        final tarea = await tareaProvider.crearTarea(
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          asignaturaId: _asignaturaSeleccionada!,
          cursoId: _cursoSeleccionado!,
          fechaLimite: _fechaLimite,
          calificacionMaxima: calificacionMax,
          tipo: _tipo,
          prioridad: _prioridad,
          permiteTardias: _permiteTardias,
          pesoEvaluacion: pesoEval,
          archivosReferencia:
              _archivosNuevos.isNotEmpty ? _archivosNuevos : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Tarea creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar al detalle de la tarea creada
          context.go('/tareas/${tarea.id}');
        }
      } else {
        // ACTUALIZAR
        await tareaProvider.actualizarTarea(
          tareaId: widget.tareaId!,
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          fechaLimite: _fechaLimite,
          calificacionMaxima: calificacionMax,
          tipo: _tipo,
          prioridad: _prioridad,
          permiteTardias: _permiteTardias,
          pesoEvaluacion: pesoEval,
        );

        // Si hay archivos nuevos, subirlos
        if (_archivosNuevos.isNotEmpty) {
          await tareaProvider.subirArchivosReferencia(
            tareaId: widget.tareaId!,
            archivos: _archivosNuevos,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Tarea actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.tareaId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(esEdicion ? 'Editar Tarea' : 'Crear Nueva Tarea'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _isSaving,
              child: Opacity(
                opacity: _isSaving ? 0.6 : 1.0,
                child: Column(
                  children: [
                    // Header
                    _buildHeader(esEdicion),

                    // Formulario
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título
                              _buildTituloField(),
                              const SizedBox(height: 20),

                              // Descripción
                              _buildDescripcionField(),
                              const SizedBox(height: 20),

                              // Curso
                              _buildCursoDropdown(),
                              const SizedBox(height: 20),

                              // Asignatura
                              _buildAsignaturaDropdown(),
                              const SizedBox(height: 20),

                              // Fecha límite
                              _buildFechaLimiteSelector(),
                              const SizedBox(height: 20),

                              // Calificación máxima
                              _buildCalificacionField(),
                              const SizedBox(height: 20),

                              // Peso en evaluación (opcional)
                              _buildPesoEvaluacionField(),
                              const SizedBox(height: 20),

                              // Tipo de tarea
                              _buildTipoTareaSelector(),
                              const SizedBox(height: 20),

                              // Prioridad
                              _buildPrioridadSelector(),
                              const SizedBox(height: 20),

                              // Permite tardías
                              _buildPermiteTardiasSwitch(),
                              const SizedBox(height: 30),

                              // Archivos existentes (solo en modo edición)
                              if (esEdicion && _archivosExistentes.isNotEmpty)
                                _buildArchivosExistentes(),

                              // Nuevos archivos
                              _buildFileUploader(),
                              const SizedBox(height: 30),

                              // Botones de acción
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ========================================
  // 🎨 HEADER
  // ========================================

  Widget _buildHeader(bool esEdicion) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF8B5CF6),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            esEdicion ? '📝 Editar Tarea' : '✏️ Nueva Tarea',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            esEdicion
                ? 'Modifica los campos que necesites'
                : 'Completa la información de la tarea',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📝 CAMPOS DE FORMULARIO
  // ========================================

  Widget _buildTituloField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Título *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tituloController,
          decoration: InputDecoration(
            hintText: 'Ej: Tarea de Matemáticas - Capítulo 5',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El título es requerido';
            }
            if (value.trim().length < 5) {
              return 'El título debe tener al menos 5 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescripcionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descripcionController,
          decoration: InputDecoration(
            hintText: 'Describe las instrucciones de la tarea...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descripción es requerida';
            }
            if (value.trim().length < 10) {
              return 'La descripción debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCursoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curso *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _cursoSeleccionado,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.group),
          ),
          hint: const Text('Selecciona un curso'),
          items: _cursos.map((curso) {
            return DropdownMenuItem<String>(
              value: curso['_id'],
              child: Text('${curso['nivel']} ${curso['nombre']}'),
            );
          }).toList(),
          onChanged: (value) {
            print('📌 CURSO SELECCIONADO: $value');
            setState(() {
              _cursoSeleccionado = value;
              print('   _cursoSeleccionado ahora es: $_cursoSeleccionado');
              _asignaturaSeleccionada = null; // Resetear asignatura
              if (value != null) {
                _filtrarAsignaturasPorCurso(value);
              }
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona un curso';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAsignaturaDropdown() {
    print(
        '🎨 BUILD Dropdown Asignaturas - _cursoSeleccionado: $_cursoSeleccionado');
    print('   _asignaturasFiltradas length: ${_asignaturasFiltradas.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asignatura *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _asignaturaSeleccionada,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.book),
          ),
          hint: Text(_cursoSeleccionado == null
              ? 'Primero selecciona un curso'
              : 'Selecciona una asignatura'),
          items: _cursoSeleccionado == null
              ? []
              : _asignaturasFiltradas.map((asignatura) {
                  return DropdownMenuItem<String>(
                    value: asignatura['_id'],
                    child: Text(asignatura['nombre']),
                  );
                }).toList(),
          onChanged: _cursoSeleccionado == null
              ? null
              : (value) {
                  setState(() {
                    _asignaturaSeleccionada = value;
                  });
                },
          validator: (value) {
            if (value == null) {
              return 'Selecciona una asignatura';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFechaLimiteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha límite *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _seleccionarFechaLimite,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                            .format(_fechaLimite),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm', 'es_ES').format(_fechaLimite),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalificacionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calificación máxima *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _calificacionMaxController,
          decoration: InputDecoration(
            hintText: '10.0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.star),
            suffixText: 'puntos',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La calificación es requerida';
            }
            final calificacion = double.tryParse(value);
            if (calificacion == null || calificacion <= 0) {
              return 'Ingresa una calificación válida mayor a 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPesoEvaluacionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peso en la evaluación (opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Porcentaje que representa en la nota final',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pesoEvaluacionController,
          decoration: InputDecoration(
            hintText: 'Ej: 15',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.percent),
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final peso = double.tryParse(value);
              if (peso == null || peso <= 0 || peso > 100) {
                return 'Ingresa un valor entre 0 y 100';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTipoTareaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de tarea *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<TipoTarea>(
                title: const Text('Individual'),
                value: TipoTarea.individual,
                groupValue: _tipo,
                onChanged: (value) {
                  setState(() {
                    _tipo = value!;
                  });
                },
                activeColor: const Color(0xFF8B5CF6),
                tileColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _tipo == TipoTarea.individual
                        ? const Color(0xFF8B5CF6)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RadioListTile<TipoTarea>(
                title: const Text('Grupal'),
                value: TipoTarea.grupal,
                groupValue: _tipo,
                onChanged: (value) {
                  setState(() {
                    _tipo = value!;
                  });
                },
                activeColor: const Color(0xFF8B5CF6),
                tileColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _tipo == TipoTarea.grupal
                        ? const Color(0xFF8B5CF6)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrioridadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioridad *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: PrioridadTarea.values.map((prioridad) {
            final isSelected = _prioridad == prioridad;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _prioridad = prioridad;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Color(prioridad.color) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(prioridad.color),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          prioridad.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prioridad.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : Color(prioridad.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPermiteTardiasSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_off, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permitir entregas tardías',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Los estudiantes pueden entregar después de la fecha límite',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _permiteTardias,
            onChanged: (value) {
              setState(() {
                _permiteTardias = value;
              });
            },
            activeColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📎 ARCHIVOS
  // ========================================

  Widget _buildArchivosExistentes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Archivos de referencia actuales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._archivosExistentes.map((archivo) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ArchivoTile(
              archivo: archivo,
              onDelete: () => _eliminarArchivoExistente(archivo),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFileUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.tareaId != null
              ? 'Agregar más archivos (opcional)'
              : 'Archivos de referencia (opcional)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Material de apoyo para los estudiantes',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        FileUploader(
          archivosSeleccionados: _archivosNuevos,
          onArchivosChanged: (archivos) {
            setState(() {
              _archivosNuevos = archivos;
            });
          },
          maxArchivos: 5,
          maxTamanoMB: 10,
          titulo: 'Arrastra archivos aquí',
          descripcion: 'PDF, Word, Excel, PowerPoint',
        ),
      ],
    );
  }

  // ========================================
  // 🔘 BOTONES DE ACCIÓN
  // ========================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.tareaId != null ? 'Actualizar' : 'Crear Tarea',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
