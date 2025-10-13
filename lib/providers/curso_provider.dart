// lib/providers/curso_provider.dart
// 📚 PROVIDER DE CURSOS - Siguiendo patrón de usuario_provider.dart

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

      print('📥 Cargando cursos... (refresh: $refresh, silent: $silent)');

      // Obtener TODOS los cursos del backend
      final cursos = await _cursoService.getCursos();

      // Guardar lista completa Y lista filtrada
      _todosCursos = cursos;

      // Aplicar filtros actuales
      _aplicarFiltros();

      _isLoading = false;

      print(
          '✅ Cursos cargados: ${_cursos.length} (total: ${_todosCursos.length})');
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando cursos: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 🎛️ FILTROS LOCALES
  // ========================================

  void _aplicarFiltros() {
    print('🎛️ Aplicando filtros localmente...');
    print('   Nivel: ${_currentNivelFilter?.displayName ?? "Todos"}');
    print('   Jornada: ${_currentJornadaFilter?.displayName ?? "Todas"}');
    print('   Búsqueda: $_searchQuery');

    List<Curso> filtered = [..._todosCursos];

    // Filtro por nivel
    if (_currentNivelFilter != null) {
      filtered = filtered.where((c) => c.nivel == _currentNivelFilter).toList();
      print('📚 Después de filtrar por nivel: ${filtered.length}');
    }

    // Filtro por jornada
    if (_currentJornadaFilter != null) {
      filtered =
          filtered.where((c) => c.jornada == _currentJornadaFilter).toList();
      print('🕐 Después de filtrar por jornada: ${filtered.length}');
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
      print(
          '🔍 Después de filtrar por búsqueda "$_searchQuery": ${filtered.length}');
    }

    _cursos = filtered;
    print(
        '📊 Resultado final: ${_cursos.length} cursos filtrados de ${_todosCursos.length} totales');
  }

  // ========================================
  // 🔄 CAMBIAR FILTROS
  // ========================================

  Future<void> changeNivelFilter(NivelEducativo? newFilter) async {
    if (_currentNivelFilter == newFilter) return;

    print('🔄 Cambiando filtro de nivel: ${newFilter?.displayName ?? "Todos"}');

    _currentNivelFilter = newFilter;
    _aplicarFiltros();
    notifyListeners();
  }

  Future<void> changeJornadaFilter(Jornada? newFilter) async {
    if (_currentJornadaFilter == newFilter) return;

    print(
        '🔄 Cambiando filtro de jornada: ${newFilter?.displayName ?? "Todas"}');

    _currentJornadaFilter = newFilter;
    _aplicarFiltros();
    notifyListeners();
  }

  // ========================================
  // 🔍 BÚSQUEDA
  // ========================================

  Future<void> search(String query) async {
    print('🔍 Buscando: $query');
    _searchQuery = query;
    _aplicarFiltros();
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      print('🧹 Limpiando búsqueda');
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
      print('🔍 Obteniendo curso: $id');

      // Buscar en cache local
      final localCurso = _cursos.where((c) => c.id == id).firstOrNull;
      if (localCurso != null) {
        print('✅ Curso encontrado en cache');
        // Pero obtener versión completa del servidor
        final cursoCompleto = await _cursoService.getCursoById(id);
        return cursoCompleto ?? localCurso;
      }

      // Obtener del servidor
      print('📡 Obteniendo del servidor...');
      final curso = await _cursoService.getCursoById(id);
      print('✅ Curso obtenido del servidor');
      return curso;
    } catch (e) {
      print('❌ Error obteniendo curso: $e');
      rethrow;
    }
  }

  // ========================================
  // 👥 ESTUDIANTES DEL CURSO
  // ========================================

  Future<List<EstudianteCurso>> getEstudiantesCurso(String cursoId) async {
    try {
      print('👥 Obteniendo estudiantes del curso...');
      return await _cursoService.getCursoEstudiantes(cursoId);
    } catch (e) {
      print('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }

  // ========================================
  // 📚 ASIGNATURAS DEL CURSO
  // ========================================

  Future<List<AsignaturaCurso>> getAsignaturasCurso(String cursoId) async {
    try {
      print('📚 Obteniendo asignaturas del curso...');
      return await _cursoService.getCursoAsignaturas(cursoId);
    } catch (e) {
      print('❌ Error obteniendo asignaturas: $e');
      return [];
    }
  }

  // ========================================
  // 🔄 REFRESCAR
  // ========================================

  Future<void> refresh() async {
    print('🔄 Refrescando lista...');
    await loadCursos(refresh: true);
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO
  // ========================================

  void clearState() {
    print('🧹 Limpiando estado del provider');
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
    print('🧹 Limpiando todos los filtros');
    _currentNivelFilter = null;
    _currentJornadaFilter = null;
    _searchQuery = '';
    _aplicarFiltros();
    notifyListeners();
  }
}
