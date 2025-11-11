// lib/providers/tarea_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../services/tarea_service.dart';

/// 📚 PROVIDER DE TAREAS
/// Maneja estado, operaciones y sincronización
class TareaProvider with ChangeNotifier {
  final TareaService _tareaService = TareaService();

  // ========================================
  // 📊 ESTADO
  // ========================================

  // Para listado general (docentes/admin)
  List<Tarea> _tareas = [];
  Map<String, dynamic> _meta = {
    'total': 0,
    'pagina': 1,
    'limite': 20,
    'paginas': 1,
  };

  // Para estudiantes (mis tareas con filtros)
  List<Tarea> _misTareas = [];
  FiltroTareaEstudiante _currentFilter = FiltroTareaEstudiante.todas;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingMisTareas = false;

  // Filtros para listado general
  EstadoTarea? _estadoFilter;
  PrioridadTarea? _prioridadFilter;
  String? _cursoFilter;
  String? _asignaturaFilter;
  String _searchQuery = '';

  // ========================================
  // 🔍 GETTERS
  // ========================================

  // Listado general
  List<Tarea> get tareas => _tareas;
  Map<String, dynamic> get meta => _meta;
  bool get isLoading => _isLoading;

  // Mis tareas (estudiante)
  List<Tarea> get misTareas => _misTareas;
  FiltroTareaEstudiante get currentFilter => _currentFilter;
  bool get isLoadingMisTareas => _isLoadingMisTareas;

  // Filtros
  EstadoTarea? get estadoFilter => _estadoFilter;
  PrioridadTarea? get prioridadFilter => _prioridadFilter;
  String? get cursoFilter => _cursoFilter;
  String? get asignaturaFilter => _asignaturaFilter;
  String get searchQuery => _searchQuery;

  // Paginación
  int get totalTareas => _meta['total'] ?? 0;
  int get currentPage => _meta['pagina'] ?? 1;
  int get totalPages => _meta['paginas'] ?? 1;
  bool get hasMorePages => currentPage < totalPages;

  // Estadísticas rápidas de mis tareas
  int get misTareasPendientes =>
      _misTareas.where((t) => !t.estaVencida && !t.estaCerrada).length;
  int get misTareasVencidas => _misTareas.where((t) => t.estaVencida).length;

  // ========================================
  // 📋 LISTAR TAREAS (GENERAL - DOCENTES/ADMIN)
  // ========================================

  Future<void> listarTareas({
    int page = 1,
    bool refresh = false,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }

      print('🔥 Cargando tareas... (página $page)');

      final result = await _tareaService.listarTareas(
        page: page,
        estado: _estadoFilter,
        prioridad: _prioridadFilter,
        cursoId: _cursoFilter,
        asignaturaId: _asignaturaFilter,
        busqueda: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (refresh || page == 1) {
        _tareas = result['tareas'];
      } else {
        // Paginación: agregar tareas nuevas
        _tareas = [..._tareas, ...result['tareas']];
      }

      _meta = result['meta'];
      _isLoading = false;

      print('✅ Tareas cargadas: ${_tareas.length}');
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando tareas: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 🎯 MIS TAREAS (ESTUDIANTES)
  // ========================================

  Future<void> cargarMisTareas({
    FiltroTareaEstudiante? filtro,
    bool refresh = false,
  }) async {
    try {
      _isLoadingMisTareas = true;
      notifyListeners();

      print('🔥 Cargando mis tareas...');
      print('   Filtro: ${filtro?.displayName ?? "Todas"}');

      final tareas = await _tareaService.misTareas(filtro: filtro);

      _misTareas = tareas;
      if (filtro != null) {
        _currentFilter = filtro;
      }

      _isLoadingMisTareas = false;

      print('✅ Mis tareas cargadas: ${_misTareas.length}');
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando mis tareas: $e');
      _isLoadingMisTareas = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 🔄 CAMBIAR FILTRO (ESTUDIANTE)
  // ========================================

  Future<void> cambiarFiltro(FiltroTareaEstudiante filtro) async {
    if (_currentFilter == filtro) return;

    print('🔄 Cambiando filtro: ${filtro.displayName}');
    _currentFilter = filtro;
    notifyListeners();

    await cargarMisTareas(filtro: filtro, refresh: true);
  }

  // ========================================
  // 🔍 BÚSQUEDA Y FILTROS (DOCENTE)
  // ========================================

  Future<void> buscar(String query) async {
    print('🔍 Buscando: $query');
    _searchQuery = query;
    notifyListeners();
    await listarTareas(refresh: true);
  }

  void limpiarBusqueda() {
    if (_searchQuery.isNotEmpty) {
      print('🧹 Limpiando búsqueda');
      _searchQuery = '';
      listarTareas(refresh: true);
    }
  }

  void aplicarFiltroEstado(EstadoTarea? estado) {
    _estadoFilter = estado;
    notifyListeners();
    listarTareas(refresh: true);
  }

  void aplicarFiltroPrioridad(PrioridadTarea? prioridad) {
    _prioridadFilter = prioridad;
    notifyListeners();
    listarTareas(refresh: true);
  }

  void aplicarFiltroCurso(String? cursoId) {
    _cursoFilter = cursoId;
    notifyListeners();
    listarTareas(refresh: true);
  }

  void aplicarFiltroAsignatura(String? asignaturaId) {
    _asignaturaFilter = asignaturaId;
    notifyListeners();
    listarTareas(refresh: true);
  }

  void limpiarFiltros() {
    print('🧹 Limpiando filtros');
    _estadoFilter = null;
    _prioridadFilter = null;
    _cursoFilter = null;
    _asignaturaFilter = null;
    _searchQuery = '';
    listarTareas(refresh: true);
  }

  // ========================================
  // ✉️ CREAR TAREA
  // ========================================

  Future<Tarea> crearTarea({
    required String titulo,
    required String descripcion,
    required String asignaturaId,
    required String cursoId,
    required DateTime fechaLimite,
    required double calificacionMaxima,
    TipoTarea tipo = TipoTarea.individual,
    PrioridadTarea prioridad = PrioridadTarea.media,
    bool permiteTardias = false,
    double? pesoEvaluacion,
    List<String>? estudiantesIds,
    List<File>? archivosReferencia,
  }) async {
    try {
      print('📝 Creando tarea: $titulo');

      final tarea = await _tareaService.crearTarea(
        titulo: titulo,
        descripcion: descripcion,
        asignaturaId: asignaturaId,
        cursoId: cursoId,
        fechaLimite: fechaLimite,
        calificacionMaxima: calificacionMaxima,
        tipo: tipo,
        prioridad: prioridad,
        permiteTardias: permiteTardias,
        pesoEvaluacion: pesoEvaluacion,
        estudiantesIds: estudiantesIds,
        archivosReferencia: archivosReferencia,
      );

      print('✅ Tarea creada con ID: ${tarea.id}');

      // Refrescar lista
      await listarTareas(refresh: true);

      return tarea;
    } catch (e) {
      print('❌ Error creando tarea: $e');
      rethrow;
    }
  }

  // ========================================
  // 📝 ACTUALIZAR TAREA
  // ========================================

  Future<Tarea> actualizarTarea({
    required String tareaId,
    required String titulo,
    required String descripcion,
    required DateTime fechaLimite,
    required double calificacionMaxima,
    TipoTarea? tipo,
    PrioridadTarea? prioridad,
    bool? permiteTardias,
    double? pesoEvaluacion,
  }) async {
    try {
      print('📝 Actualizando tarea: $tareaId');

      final tarea = await _tareaService.actualizarTarea(
        tareaId: tareaId,
        titulo: titulo,
        descripcion: descripcion,
        fechaLimite: fechaLimite,
        calificacionMaxima: calificacionMaxima,
        tipo: tipo,
        prioridad: prioridad,
        permiteTardias: permiteTardias,
        pesoEvaluacion: pesoEvaluacion,
      );

      // Actualizar en lista local
      final index = _tareas.indexWhere((t) => t.id == tareaId);
      if (index != -1) {
        _tareas[index] = tarea;
      }

      print('✅ Tarea actualizada');
      notifyListeners();

      return tarea;
    } catch (e) {
      print('❌ Error actualizando tarea: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR TAREA
  // ========================================

  Future<void> eliminarTarea(String tareaId) async {
    try {
      print('🗑️ Eliminando tarea: $tareaId');

      // Optimistic update
      _tareas.removeWhere((t) => t.id == tareaId);
      notifyListeners();

      await _tareaService.eliminarTarea(tareaId);

      print('✅ Tarea eliminada');
    } catch (e) {
      print('❌ Error eliminando tarea: $e');
      // Recargar en caso de error
      await listarTareas(refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 🔒 CERRAR TAREA
  // ========================================

  Future<Tarea> cerrarTarea(String tareaId) async {
    try {
      print('🔒 Cerrando tarea: $tareaId');

      final tarea = await _tareaService.cerrarTarea(tareaId);

      // Actualizar en lista local
      final index = _tareas.indexWhere((t) => t.id == tareaId);
      if (index != -1) {
        _tareas[index] = tarea;
      }

      print('✅ Tarea cerrada');
      notifyListeners();

      return tarea;
    } catch (e) {
      print('❌ Error cerrando tarea: $e');
      rethrow;
    }
  }

  // ========================================
  // 📎 GESTIÓN DE ARCHIVOS DE REFERENCIA
  // ========================================

  Future<Tarea> subirArchivosReferencia({
    required String tareaId,
    required List<File> archivos,
  }) async {
    try {
      print('📎 Subiendo archivos de referencia a tarea: $tareaId');

      final tarea = await _tareaService.subirArchivosReferencia(
        tareaId: tareaId,
        archivos: archivos,
      );

      // Actualizar en lista local
      final index = _tareas.indexWhere((t) => t.id == tareaId);
      if (index != -1) {
        _tareas[index] = tarea;
      }

      print('✅ Archivos subidos');
      notifyListeners();

      return tarea;
    } catch (e) {
      print('❌ Error subiendo archivos: $e');
      rethrow;
    }
  }

  Future<Tarea> eliminarArchivoReferencia({
    required String tareaId,
    required String archivoId,
  }) async {
    try {
      print('🗑️ Eliminando archivo de referencia: $archivoId');

      final tarea = await _tareaService.eliminarArchivoReferencia(
        tareaId: tareaId,
        archivoId: archivoId,
      );

      // Actualizar en lista local
      final index = _tareas.indexWhere((t) => t.id == tareaId);
      if (index != -1) {
        _tareas[index] = tarea;
      }

      print('✅ Archivo eliminado');
      notifyListeners();

      return tarea;
    } catch (e) {
      print('❌ Error eliminando archivo: $e');
      rethrow;
    }
  }

  // ========================================
  // ✅ ENTREGAR TAREA (ESTUDIANTE)
  // ========================================

  Future<EntregaTarea> entregarTarea({
    required String tareaId,
    required List<File> archivos,
    String? comentarioEstudiante,
  }) async {
    try {
      print('📤 Entregando tarea: $tareaId');

      final entrega = await _tareaService.entregarTarea(
        tareaId: tareaId,
        archivos: archivos,
        comentarioEstudiante: comentarioEstudiante,
      );

      print('✅ Tarea entregada');

      // Refrescar mis tareas
      await cargarMisTareas(filtro: _currentFilter, refresh: true);

      return entrega;
    } catch (e) {
      print('❌ Error entregando tarea: $e');
      rethrow;
    }
  }

  // ========================================
  // 👁️ MARCAR COMO VISTA (ESTUDIANTE)
  // ========================================

  Future<void> marcarVista(String tareaId) async {
    try {
      print('👁️ Marcando tarea como vista: $tareaId');
      await _tareaService.marcarVista(tareaId);
      print('✅ Tarea marcada como vista');
    } catch (e) {
      print('❌ Error marcando vista: $e');
      // No hacer rethrow, es una operación de fondo
    }
  }

  // ========================================
  // ⭐ CALIFICAR ENTREGA (DOCENTE)
  // ========================================

  Future<EntregaTarea> calificarEntrega({
    required String tareaId,
    required String entregaId,
    required double calificacion,
    String? comentarioDocente,
  }) async {
    try {
      print('⭐ Calificando entrega: $entregaId');

      final entrega = await _tareaService.calificarEntrega(
        tareaId: tareaId,
        entregaId: entregaId,
        calificacion: calificacion,
        comentarioDocente: comentarioDocente,
      );

      print('✅ Entrega calificada');

      // Refrescar tarea actual si está en la lista
      final index = _tareas.indexWhere((t) => t.id == tareaId);
      if (index != -1) {
        // Refrescar la tarea completa para actualizar las entregas
        final tareaActualizada = await _tareaService.obtenerTarea(tareaId);
        if (tareaActualizada != null) {
          _tareas[index] = tareaActualizada;
          notifyListeners();
        }
      }

      return entrega;
    } catch (e) {
      print('❌ Error calificando entrega: $e');
      rethrow;
    }
  }

  // ========================================
  // 📖 OBTENER TAREA POR ID
  // ========================================

  Future<Tarea?> obtenerTarea(String tareaId) async {
    try {
      print('🔥 Obteniendo tarea: $tareaId');

      // Primero buscar en lista local
      final localTarea = _tareas.firstWhere(
        (t) => t.id == tareaId,
        orElse: () => _tareas.isNotEmpty
            ? _tareas.first
            : Tarea(
                id: '',
                titulo: '',
                descripcion: '',
                docente:
                    DocenteInfo(id: '', nombre: '', apellidos: '', email: ''),
                asignatura: AsignaturaInfo(id: '', nombre: ''),
                curso: CursoInfo(id: '', nombre: '', nivel: ''),
                escuelaId: '',
                estudiantesIds: [],
                fechaAsignacion: DateTime.now(),
                fechaLimite: DateTime.now(),
                tipo: TipoTarea.individual,
                prioridad: PrioridadTarea.media,
                permiteTardias: false,
                calificacionMaxima: 0,
                archivosReferencia: [],
                vistas: [],
                entregas: [],
                estado: EstadoTarea.activa,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      );

      if (localTarea.id == tareaId) {
        print('✅ Tarea encontrada en cache local');
        return localTarea;
      }

      // Si no está en local, obtener del servidor
      print('📡 Obteniendo del servidor...');
      final tarea = await _tareaService.obtenerTarea(tareaId);

      if (tarea != null) {
        print('✅ Tarea obtenida del servidor');
      }

      return tarea;
    } catch (e) {
      print('❌ Error obteniendo tarea: $e');
      rethrow;
    }
  }

  // ========================================
  // 📊 VER ENTREGAS (DOCENTE)
  // ========================================

  Future<List<EntregaTarea>> verEntregas(String tareaId) async {
    try {
      print('📊 Obteniendo entregas de tarea: $tareaId');
      final entregas = await _tareaService.verEntregas(tareaId);
      print('✅ Entregas obtenidas: ${entregas.length}');
      return entregas;
    } catch (e) {
      print('❌ Error obteniendo entregas: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔄 REFRESCAR
  // ========================================

  Future<void> refrescar() async {
    print('🔄 Refrescando lista...');
    await listarTareas(refresh: true);
  }

  Future<void> refrescarMisTareas() async {
    print('🔄 Refrescando mis tareas...');
    await cargarMisTareas(filtro: _currentFilter, refresh: true);
  }

  // ========================================
  // 📄 CARGAR MÁS (PAGINACIÓN)
  // ========================================

  Future<void> cargarMas() async {
    if (!hasMorePages || _isLoading) return;

    print('📄 Cargando más tareas... (página ${currentPage + 1})');

    final nextPage = currentPage + 1;
    await listarTareas(page: nextPage);
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO
  // ========================================

  void limpiarEstado() {
    print('🧹 Limpiando estado del provider');
    _tareas = [];
    _misTareas = [];
    _meta = {
      'total': 0,
      'pagina': 1,
      'limite': 20,
      'paginas': 1,
    };
    _currentFilter = FiltroTareaEstudiante.todas;
    _estadoFilter = null;
    _prioridadFilter = null;
    _cursoFilter = null;
    _asignaturaFilter = null;
    _searchQuery = '';
    _isLoading = false;
    _isLoadingMisTareas = false;
    notifyListeners();
  }
}
