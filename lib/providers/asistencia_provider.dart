// lib/providers/asistencia_provider.dart

import '../utils/logger.dart';
import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';
import '../services/asistencia_service.dart';
import '../services/api_service.dart' show mensajeDeError;
import '../utils/reintento.dart';

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

  // Phase 2: alertas, estadísticas de estudiante, historial
  List<AlertaAsistencia> _alertas = [];
  EstadisticasEstudiante _estadisticasEstudiante = EstadisticasEstudiante.vacia();
  HistorialEstudiante? _historialEstudiante;
  bool _isLoadingMiAsistencia = false;

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
  bool get isLoadingMiAsistencia => _isLoadingMiAsistencia;
  String? get error => _error;

  // Phase 2 getters
  List<AlertaAsistencia> get alertas => _alertas;
  EstadisticasEstudiante get estadisticasEstudiante => _estadisticasEstudiante;
  HistorialEstudiante? get historialEstudiante => _historialEstudiante;

  String? get cursoSeleccionado => _cursoSeleccionado;
  String? get fechaInicio => _fechaInicio;
  String? get fechaFin => _fechaFin;

  // ========================================
  // ⚡ PREPARAR ESTADO DE CARGA (para initState)
  // ========================================

  /// Marca el estado como cargando SIN notifyListeners.
  /// Llamar desde initState antes del primer frame para que el spinner
  /// aparezca desde la primera renderización (evita flash de pantalla vacía).
  void prepareLoading() {
    _isLoading = true;
  }

  void prepareLoadingMiAsistencia() {
    _isLoadingMiAsistencia = true;
  }

  // ========================================
  // 📋 CARGAR RESUMEN DE ASISTENCIA
  // ========================================

  Future<void> cargarResumen({
    bool refresh = false,
    String? cursoId,
    String? fechaInicio,
    String? fechaFin,
    String? estudianteId,
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
        estudianteId: estudianteId,
      );

      _resumenes = resumenes;
      dlog('✅ Provider: ${_resumenes.length} resumenes cargados');
    } catch (e) {
      _error = mensajeDeError(e, 'Error al cargar asistencia');
      dlog('❌ Provider error: $_error');
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

      dlog('✅ Provider: Registro cargado');
    } catch (e) {
      _error = mensajeDeError(e, 'Error al cargar registro');
      dlog('❌ Provider error: $_error');
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

      dlog('✅ Provider: ${_cursos.length} cursos cargados');
    } catch (e) {
      _error = mensajeDeError(e, 'Error al cargar cursos');
      dlog('❌ Provider error: $_error');
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

      dlog('✅ Provider: ${_estudiantes.length} estudiantes cargados');
    } catch (e) {
      _error = mensajeDeError(e, 'Error al cargar estudiantes');
      dlog('❌ Provider error: $_error');
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

      dlog('✅ Provider: ${_asignaturas.length} asignaturas cargadas');
    } catch (e) {
      _error = mensajeDeError(e, 'Error al cargar asignaturas');
      dlog('❌ Provider error: $_error');
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
      dlog('📝 Provider: Creando registro...');

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

      dlog('✅ Provider: Registro creado');
      return registro;
    } catch (e) {
      _error = mensajeDeError(e, 'Error al crear registro');
      dlog('❌ Provider error: $_error');
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
      dlog('✏️ Provider: Actualizando registro...');

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

      dlog('✅ Provider: Registro actualizado');
      return registro;
    } catch (e) {
      _error = mensajeDeError(e, 'Error al actualizar registro');
      dlog('❌ Provider error: $_error');
      notifyListeners();
      return null;
    }
  }

  // ========================================
  // ✅ FINALIZAR REGISTRO
  // ========================================

  Future<bool> finalizarRegistro(String id) async {
    try {
      dlog('✅ Provider: Finalizando registro...');

      final registro = await _asistenciaService.finalizarRegistroAsistencia(id);
      _registroActual = registro;
      notifyListeners(); // siempre notificar para que la pantalla de detalle actualice

      final index = _resumenes.indexWhere((r) => r.id == id);
      if (index != -1) {
        await cargarResumen(
          refresh: true,
          cursoId: _cursoSeleccionado,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        );
      }

      dlog('✅ Provider: Registro finalizado');
      return true;
    } catch (e) {
      _error = mensajeDeError(e, 'Error al finalizar registro');
      dlog('❌ Provider error: $_error');
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR REGISTRO
  // ========================================

  Future<bool> eliminarRegistro(String id) async {
    try {
      dlog('🗑️ Provider: Eliminando registro...');

      await _asistenciaService.eliminarRegistroAsistencia(id);

      // Remover de lista local
      _resumenes.removeWhere((r) => r.id == id);

      if (_registroActual?.id == id) {
        _registroActual = null;
      }

      dlog('✅ Provider: Registro eliminado');
      notifyListeners();
      return true;
    } catch (e) {
      _error = mensajeDeError(e, 'Error al eliminar registro');
      dlog('❌ Provider error: $_error');
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

  /// Limpiar todo el estado al cerrar sesión o cambiar de cuenta
  void clearState() {
    _resumenes = [];
    _registroActual = null;
    _cursos = [];
    _estudiantes = [];
    _asignaturas = [];
    _alertas = [];
    _estadisticasEstudiante = EstadisticasEstudiante.vacia();
    _historialEstudiante = null;
    _isLoadingMiAsistencia = false;
    _isLoading = false;
    _isLoadingCursos = false;
    _isLoadingEstudiantes = false;
    _isLoadingAsignaturas = false;
    _error = null;
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
    dlog(
        '✅ Provider: ${_estudiantes.length} estudiantes establecidos con sus estados');
  }

  // ========================================
  // 🚨 CARGAR ALERTAS + ESTADÍSTICAS + HISTORIAL
  // (para vista ESTUDIANTE / ACUDIENTE)
  // ========================================

  Future<void> cargarMiAsistencia({
    required String estudianteId,
    required String desde,
    required String hasta,
    bool refresh = false,
  }) async {
    if (_isLoadingMiAsistencia && !refresh) return;

    try {
      _isLoadingMiAsistencia = true;
      _error = null;
      notifyListeners();

      // GET /asistencia/estadisticas/estudiante/:id?desde=...&hasta=...
      // Devuelve datos del estudiante específico (no del salón completo).
      // Reintento automático único si la primera petición expira o falla
      // la red (G6): antes salía "Reintentar" y al reintentar funcionaba
      final data = await conReintentoUnico(
        () => _asistenciaService.obtenerEstadisticasPorEstudiante(
          estudianteId: estudianteId,
          desde: desde,
          hasta: hasta,
        ),
      );

      final estudianteJson = data['estudiante'] as Map<String, dynamic>? ?? {};
      final estadisticasJson = data['estadisticas'] as Map<String, dynamic>? ?? {};
      final registrosJson = data['registros'] as List<dynamic>? ?? [];

      _estadisticasEstudiante = EstadisticasEstudiante.fromJson(estadisticasJson);

      final historialRegistros = registrosJson
          .map((r) => HistorialRegistro.fromJson(r as Map<String, dynamic>))
          .toList();

      _historialEstudiante = HistorialEstudiante(
        nombre: estudianteJson['nombre'] ?? '',
        apellidos: estudianteJson['apellidos'] ?? '',
        resumen: _estadisticasEstudiante,
        registros: historialRegistros,
      );
      _alertas = [];

      dlog('✅ Asistencia cargada: ${_estadisticasEstudiante.totalClases} clases | '
          '${_estadisticasEstudiante.presentes} presentes | '
          '${_estadisticasEstudiante.ausentes} ausentes | '
          '${_estadisticasEstudiante.porcentajeAsistencia.toStringAsFixed(1)}%');
    } catch (e) {
      _error = mensajeDeError(e, 'Error al cargar asistencia');
      dlog('❌ Provider error: $_error');
    } finally {
      _isLoadingMiAsistencia = false;
      notifyListeners();
    }
  }

  void limpiarMiAsistencia() {
    _alertas = [];
    _estadisticasEstudiante = EstadisticasEstudiante.vacia();
    _historialEstudiante = null;
    notifyListeners();
  }
}
