// lib/providers/asistencia_provider.dart

import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';
import '../services/asistencia_service.dart';

/// 📋 PROVIDER DE ASISTENCIA
/// Gestiona el estado de registros de asistencia
class AsistenciaProvider extends ChangeNotifier {
  final AsistenciaService _asistenciaService = asistenciaService;

  // ========================================
  // ESTADO
  // ========================================

  List<ResumenAsistencia> _resumenes = [];
  RegistroAsistencia? _registroActual;
  List<CursoDisponible> _cursos = [];
  List<EstudianteAsistencia> _estudiantes = [];
  List<AsignaturaDisponible> _asignaturas = [];

  bool _isLoading = false;
  bool _isLoadingCursos = false;
  bool _isLoadingEstudiantes = false;
  bool _isLoadingAsignaturas = false;
  String? _error;

  // Filtros
  String? _cursoSeleccionado;
  String? _fechaInicio;
  String? _fechaFin;

  // ========================================
  // GETTERS
  // ========================================

  List<ResumenAsistencia> get resumenes => _resumenes;
  RegistroAsistencia? get registroActual => _registroActual;
  List<CursoDisponible> get cursos => _cursos;
  List<EstudianteAsistencia> get estudiantes => _estudiantes;
  List<AsignaturaDisponible> get asignaturas => _asignaturas;

  bool get isLoading => _isLoading;
  bool get isLoadingCursos => _isLoadingCursos;
  bool get isLoadingEstudiantes => _isLoadingEstudiantes;
  bool get isLoadingAsignaturas => _isLoadingAsignaturas;
  String? get error => _error;

  String? get cursoSeleccionado => _cursoSeleccionado;
  String? get fechaInicio => _fechaInicio;
  String? get fechaFin => _fechaFin;

  // ========================================
  // 📋 CARGAR RESUMEN DE ASISTENCIA
  // ========================================

  Future<void> cargarResumen({
    bool refresh = false,
    String? cursoId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    if (_isLoading && !refresh) return;

    try {
      _isLoading = true;
      _error = null;
      if (refresh) _resumenes = [];
      notifyListeners();

      // Actualizar filtros
      _cursoSeleccionado = cursoId;
      _fechaInicio = fechaInicio;
      _fechaFin = fechaFin;

      final resumenes = await _asistenciaService.obtenerResumenAsistencia(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        cursoId: cursoId,
      );

      _resumenes = resumenes;
      print('✅ Provider: ${_resumenes.length} resumenes cargados');
    } catch (e) {
      _error = 'Error al cargar asistencia: ${e.toString()}';
      print('❌ Provider error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // 📄 CARGAR REGISTRO ESPECÍFICO
  // ========================================

  Future<void> cargarRegistro(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final registro = await _asistenciaService.obtenerRegistroAsistencia(id);
      _registroActual = registro;

      print('✅ Provider: Registro cargado');
    } catch (e) {
      _error = 'Error al cargar registro: ${e.toString()}';
      print('❌ Provider error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // 📚 CARGAR CURSOS DISPONIBLES
  // ========================================

  Future<void> cargarCursos() async {
    if (_isLoadingCursos) return;

    try {
      _isLoadingCursos = true;
      _error = null;
      notifyListeners();

      final cursos = await _asistenciaService.obtenerCursosDisponibles();
      _cursos = cursos;

      print('✅ Provider: ${_cursos.length} cursos cargados');
    } catch (e) {
      _error = 'Error al cargar cursos: ${e.toString()}';
      print('❌ Provider error: $_error');
    } finally {
      _isLoadingCursos = false;
      notifyListeners();
    }
  }

  // ========================================
  // 👥 CARGAR ESTUDIANTES DE UN CURSO
  // ========================================

  Future<void> cargarEstudiantes(String cursoId) async {
    if (_isLoadingEstudiantes) return;

    try {
      _isLoadingEstudiantes = true;
      _error = null;
      notifyListeners();

      final estudiantes =
          await _asistenciaService.obtenerEstudiantesPorCurso(cursoId);
      _estudiantes = estudiantes;

      print('✅ Provider: ${_estudiantes.length} estudiantes cargados');
    } catch (e) {
      _error = 'Error al cargar estudiantes: ${e.toString()}';
      print('❌ Provider error: $_error');
      _estudiantes = [];
    } finally {
      _isLoadingEstudiantes = false;
      notifyListeners();
    }
  }

  // ========================================
  // 📚 CARGAR ASIGNATURAS DE UN CURSO
  // ========================================

  Future<void> cargarAsignaturas(String cursoId) async {
    if (_isLoadingAsignaturas) return;

    try {
      _isLoadingAsignaturas = true;
      _error = null;
      notifyListeners();

      final asignaturas =
          await _asistenciaService.obtenerAsignaturasPorCurso(cursoId);
      _asignaturas = asignaturas;

      print('✅ Provider: ${_asignaturas.length} asignaturas cargadas');
    } catch (e) {
      _error = 'Error al cargar asignaturas: ${e.toString()}';
      print('❌ Provider error: $_error');
      _asignaturas = [];
    } finally {
      _isLoadingAsignaturas = false;
      notifyListeners();
    }
  }

  // ========================================
  // ➕ CREAR REGISTRO DE ASISTENCIA
  // ========================================

  Future<RegistroAsistencia?> crearRegistro({
    required DateTime fecha,
    required String cursoId,
    String? asignaturaId,
    String? periodoId,
    required String tipoSesion,
    required String horaInicio,
    required String horaFin,
    required List<EstudianteAsistencia> estudiantes,
    String? observacionesGenerales,
  }) async {
    try {
      print('📝 Provider: Creando registro...');

      final registro = await _asistenciaService.crearRegistroAsistencia(
        fecha: fecha,
        cursoId: cursoId,
        asignaturaId: asignaturaId,
        periodoId: periodoId,
        tipoSesion: tipoSesion,
        horaInicio: horaInicio,
        horaFin: horaFin,
        estudiantes: estudiantes,
        observacionesGenerales: observacionesGenerales,
      );

      _registroActual = registro;

      // Recargar resumen
      await cargarResumen(
        refresh: true,
        cursoId: _cursoSeleccionado,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

      print('✅ Provider: Registro creado');
      return registro;
    } catch (e) {
      _error = 'Error al crear registro: ${e.toString()}';
      print('❌ Provider error: $_error');
      notifyListeners();
      return null;
    }
  }

  // ========================================
  // ✏️ ACTUALIZAR REGISTRO
  // ========================================

  Future<RegistroAsistencia?> actualizarRegistro({
    required String id,
    DateTime? fecha,
    String? cursoId,
    String? asignaturaId,
    String? periodoId,
    String? tipoSesion,
    String? horaInicio,
    String? horaFin,
    List<EstudianteAsistencia>? estudiantes,
    String? observacionesGenerales,
  }) async {
    try {
      print('✏️ Provider: Actualizando registro...');

      final registro = await _asistenciaService.actualizarRegistroAsistencia(
        id: id,
        fecha: fecha,
        cursoId: cursoId,
        asignaturaId: asignaturaId,
        periodoId: periodoId,
        tipoSesion: tipoSesion,
        horaInicio: horaInicio,
        horaFin: horaFin,
        estudiantes: estudiantes,
        observacionesGenerales: observacionesGenerales,
      );

      _registroActual = registro;

      // Actualizar en lista local
      final index = _resumenes.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Recargar resumen para obtener datos actualizados
        await cargarResumen(
          refresh: true,
          cursoId: _cursoSeleccionado,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        );
      }

      print('✅ Provider: Registro actualizado');
      return registro;
    } catch (e) {
      _error = 'Error al actualizar registro: ${e.toString()}';
      print('❌ Provider error: $_error');
      notifyListeners();
      return null;
    }
  }

  // ========================================
  // ✅ FINALIZAR REGISTRO
  // ========================================

  Future<bool> finalizarRegistro(String id) async {
    try {
      print('✅ Provider: Finalizando registro...');

      final registro = await _asistenciaService.finalizarRegistroAsistencia(id);
      _registroActual = registro;

      // Actualizar en lista local
      final index = _resumenes.indexWhere((r) => r.id == id);
      if (index != -1) {
        await cargarResumen(
          refresh: true,
          cursoId: _cursoSeleccionado,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        );
      }

      print('✅ Provider: Registro finalizado');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al finalizar registro: ${e.toString()}';
      print('❌ Provider error: $_error');
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR REGISTRO
  // ========================================

  Future<bool> eliminarRegistro(String id) async {
    try {
      print('🗑️ Provider: Eliminando registro...');

      await _asistenciaService.eliminarRegistroAsistencia(id);

      // Remover de lista local
      _resumenes.removeWhere((r) => r.id == id);

      if (_registroActual?.id == id) {
        _registroActual = null;
      }

      print('✅ Provider: Registro eliminado');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar registro: ${e.toString()}';
      print('❌ Provider error: $_error');
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // 🔄 REFRESCAR
  // ========================================

  Future<void> refresh() async {
    await cargarResumen(
      refresh: true,
      cursoId: _cursoSeleccionado,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO
  // ========================================

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void limpiarRegistroActual() {
    _registroActual = null;
    notifyListeners();
  }

  void limpiarEstudiantes() {
    _estudiantes = [];
    notifyListeners();
  }

  void limpiarAsignaturas() {
    _asignaturas = [];
    notifyListeners();
  }

  void limpiarFiltros() {
    _cursoSeleccionado = null;
    _fechaInicio = null;
    _fechaFin = null;
    notifyListeners();
  }

  // ========================================
  // 🔧 ACTUALIZAR ESTADO LOCAL DE ESTUDIANTE
  // ========================================

  void actualizarEstadoEstudiante(String estudianteId, String nuevoEstado) {
    final index =
        _estudiantes.indexWhere((e) => e.estudianteId == estudianteId);
    if (index != -1) {
      _estudiantes[index] = _estudiantes[index].copyWith(estado: nuevoEstado);
      notifyListeners();
    }
  }

  void actualizarObservacionEstudiante(
      String estudianteId, String observacion) {
    final index =
        _estudiantes.indexWhere((e) => e.estudianteId == estudianteId);
    if (index != -1) {
      _estudiantes[index] =
          _estudiantes[index].copyWith(observaciones: observacion);
      notifyListeners();
    }
  }

  void establecerEstudiantes(List<EstudianteAsistencia> estudiantes) {
    _estudiantes = estudiantes;
    notifyListeners();
    print(
        '✅ Provider: ${_estudiantes.length} estudiantes establecidos con sus estados');
  }
}
