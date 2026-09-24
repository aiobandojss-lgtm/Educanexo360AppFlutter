// lib/providers/curso_provider.dart
// 📚 PROVIDER DE CURSOS - Siguiendo patrón de usuario_provider.dart

import 'dart:math';
import '../utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/curso.dart';
import '../services/curso_service.dart';

class CursoProvider with ChangeNotifier {
  final CursoService _cursoService = CursoService();

  // ========================================
  // 📊 ESTADO
  // ========================================

  List<Curso> _todosCursos = [];
  List<Curso> _cursos = [];
  bool _isLoading = false;
  NivelEducativo? _currentNivelFilter;
  Jornada? _currentJornadaFilter;
  String _searchQuery = '';

  // ========================================
  // 🔍 GETTERS
  // ========================================

  List<Curso> get cursos => _cursos;
  bool get isLoading => _isLoading;
  NivelEducativo? get currentNivelFilter => _currentNivelFilter;
  Jornada? get currentJornadaFilter => _currentJornadaFilter;
  String get searchQuery => _searchQuery;

  // Contadores por nivel
  Map<NivelEducativo, int> get cursosPorNivel {
    final map = <NivelEducativo, int>{};
    for (final curso in _todosCursos) {
      map[curso.nivel] = (map[curso.nivel] ?? 0) + 1;
    }
    return map;
  }

  // Contadores por jornada
  Map<Jornada, int> get cursosPorJornada {
    final map = <Jornada, int>{};
    for (final curso in _todosCursos) {
      if (curso.jornada != null) {
        map[curso.jornada!] = (map[curso.jornada!] ?? 0) + 1;
      }
    }
    return map;
  }

  int get totalCursos => _todosCursos.length;

  // ========================================
  // ⚡ PREPARAR ESTADO DE CARGA (para initState)
  // ========================================

  void prepareLoading() {
    _isLoading = true;
  }

  // ========================================
  // 📋 CARGAR CURSOS
  // ========================================

  Future<void> loadCursos({
    bool refresh = false,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }

      dlog('📥 Cargando cursos... (refresh: $refresh, silent: $silent)');

      // Obtener TODOS los cursos del backend
      final cursos = await _cursoService.getCursos();

      // Guardar lista completa Y lista filtrada
      _todosCursos = cursos;

      // Aplicar filtros actuales
      _aplicarFiltros();

      _isLoading = false;

      dlog(
          '✅ Cursos cargados: ${_cursos.length} (total: ${_todosCursos.length})');
      notifyListeners();

      // Conteos de asignaturas en segundo plano (no bloquean la lista)
      _cargarConteosAsignaturas(cursos);
    } catch (e) {
      dlog('❌ Error cargando cursos: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 🎛️ FILTROS LOCALES
  // ========================================

  void _aplicarFiltros() {
    dlog('🎛️ Aplicando filtros localmente...');
    dlog('   Nivel: ${_currentNivelFilter?.displayName ?? "Todos"}');
    dlog('   Jornada: ${_currentJornadaFilter?.displayName ?? "Todas"}');
    dlog('   Búsqueda: $_searchQuery');

    List<Curso> filtered = [..._todosCursos];

    // Filtro por nivel
    if (_currentNivelFilter != null) {
      filtered = filtered.where((c) => c.nivel == _currentNivelFilter).toList();
      dlog('📚 Después de filtrar por nivel: ${filtered.length}');
    }

    // Filtro por jornada
    if (_currentJornadaFilter != null) {
      filtered =
          filtered.where((c) => c.jornada == _currentJornadaFilter).toList();
      dlog('🕐 Después de filtrar por jornada: ${filtered.length}');
    }

    // Filtro por búsqueda
    if (_searchQuery.trim().isNotEmpty) {
      final search = _searchQuery.toLowerCase();
      filtered = filtered
          .where((curso) =>
              curso.nombre.toLowerCase().contains(search) ||
              curso.nivel.value.toLowerCase().contains(search) ||
              (curso.directorGrupo?.nombre ?? '')
                  .toLowerCase()
                  .contains(search) ||
              (curso.directorGrupo?.apellidos ?? '')
                  .toLowerCase()
                  .contains(search) ||
              (curso.grado ?? '').toLowerCase().contains(search) ||
              (curso.grupo ?? '').toLowerCase().contains(search))
          .toList();
      dlog(
          '🔍 Después de filtrar por búsqueda "$_searchQuery": ${filtered.length}');
    }

    _cursos = filtered;
    dlog(
        '📊 Resultado final: ${_cursos.length} cursos filtrados de ${_todosCursos.length} totales');
  }

  // ========================================
  // 🔄 CAMBIAR FILTROS
  // ========================================

  Future<void> changeNivelFilter(NivelEducativo? newFilter) async {
    if (_currentNivelFilter == newFilter) return;

    dlog('🔄 Cambiando filtro de nivel: ${newFilter?.displayName ?? "Todos"}');

    _currentNivelFilter = newFilter;
    _aplicarFiltros();
    notifyListeners();
  }

  Future<void> changeJornadaFilter(Jornada? newFilter) async {
    if (_currentJornadaFilter == newFilter) return;

    dlog(
        '🔄 Cambiando filtro de jornada: ${newFilter?.displayName ?? "Todas"}');

    _currentJornadaFilter = newFilter;
    _aplicarFiltros();
    notifyListeners();
  }

  // ========================================
  // 🔍 BÚSQUEDA
  // ========================================

  Future<void> search(String query) async {
    dlog('🔍 Buscando: $query');
    _searchQuery = query;
    _aplicarFiltros();
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      dlog('🧹 Limpiando búsqueda');
      _searchQuery = '';
      _aplicarFiltros();
      notifyListeners();
    }
  }

  // ========================================
  // 📖 OBTENER CURSO POR ID
  // ========================================

  Future<Curso?> getCursoById(String id) async {
    try {
      dlog('🔍 Obteniendo curso: $id');

      // Buscar en cache local
      final localCurso = _cursos.where((c) => c.id == id).firstOrNull;
      if (localCurso != null) {
        dlog('✅ Curso encontrado en cache');
        // Pero obtener versión completa del servidor
        final cursoCompleto = await _cursoService.getCursoById(id);
        return cursoCompleto ?? localCurso;
      }

      // Obtener del servidor
      dlog('📡 Obteniendo del servidor...');
      final curso = await _cursoService.getCursoById(id);
      dlog('✅ Curso obtenido del servidor');
      return curso;
    } catch (e) {
      dlog('❌ Error obteniendo curso: $e');
      rethrow;
    }
  }

  // ========================================
  // 👥 ESTUDIANTES DEL CURSO
  // ========================================

  Future<List<EstudianteCurso>> getEstudiantesCurso(String cursoId) async {
    try {
      dlog('👥 Obteniendo estudiantes del curso...');
      return await _cursoService.getCursoEstudiantes(cursoId);
    } catch (e) {
      dlog('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }

  // ========================================
  // 📚 ASIGNATURAS DEL CURSO
  // ========================================

  Future<List<AsignaturaCurso>> getAsignaturasCurso(String cursoId) async {
    try {
      dlog('📚 Obteniendo asignaturas del curso...');
      return await _cursoService.getCursoAsignaturas(cursoId);
    } catch (e) {
      dlog('❌ Error obteniendo asignaturas: $e');
      return [];
    }
  }

  // ========================================
  // 🔄 REFRESCAR
  // ========================================

  Future<void> refresh() async {
    dlog('🔄 Refrescando lista...');
    await loadCursos(refresh: true);
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO
  // ========================================

  // ========================================
  // 📊 CONTEOS DE ASIGNATURAS (diferidos)
  // ========================================

  /// Máximo de peticiones simultáneas de conteo (nunca N a la vez)
  static const int _maxConteosSimultaneos = 4;

  // Se incrementa en cada carga y en clearState: invalida conteos en curso
  int _conteosGeneration = 0;

  Future<void> _cargarConteosAsignaturas(List<Curso> cursos) async {
    final generation = ++_conteosGeneration;
    final pendientes = cursos
        .where((c) => c.asignaturasCount == null && c.asignaturas == null)
        .map((c) => c.id)
        .toList();
    if (pendientes.isEmpty) return;

    var siguiente = 0;
    Future<void> worker() async {
      while (siguiente < pendientes.length) {
        final cursoId = pendientes[siguiente++];
        final count = await _cursoService.getAsignaturasCount(cursoId);
        if (generation != _conteosGeneration) return;
        _actualizarConteoAsignaturas(cursoId, count);
      }
    }

    await Future.wait(List.generate(
      min(_maxConteosSimultaneos, pendientes.length),
      (_) => worker(),
    ));
  }

  void _actualizarConteoAsignaturas(String cursoId, int count) {
    final index = _todosCursos.indexWhere((c) => c.id == cursoId);
    if (index == -1) return;
    _todosCursos[index] =
        _todosCursos[index].copyWith(asignaturasCount: count);
    _aplicarFiltros();
    notifyListeners();
  }

  void clearState() {
    dlog('🧹 Limpiando estado del provider');
    _conteosGeneration++;
    _cursos = [];
    _todosCursos = [];
    _currentNivelFilter = null;
    _currentJornadaFilter = null;
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }

  // ========================================
  // 🧹 LIMPIAR TODOS LOS FILTROS
  // ========================================

  void clearAllFilters() {
    dlog('🧹 Limpiando todos los filtros');
    _currentNivelFilter = null;
    _currentJornadaFilter = null;
    _searchQuery = '';
    _aplicarFiltros();
    notifyListeners();
  }
}
