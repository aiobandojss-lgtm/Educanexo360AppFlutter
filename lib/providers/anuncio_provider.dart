// lib/providers/anuncio_provider.dart
// ✅ MEJORADO: Refrescamiento automático después de crear/editar/eliminar

import '../utils/logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/anuncio.dart';
import '../services/anuncio_service.dart';

/// 📢 PROVIDER DE ANUNCIOS
/// Maneja estado, operaciones y sincronización
class AnuncioProvider with ChangeNotifier {
  final AnuncioService _anuncioService = AnuncioService();

  // ========================================
  // 📊 ESTADO
  // ========================================

  List<Anuncio> _anuncios = [];
  Map<String, dynamic> _meta = {
    'total': 0,
    'pagina': 1,
    'limite': 20,
    'paginas': 1,
  };

  bool _isLoading = false;
  FiltroAnuncio _currentFilter = FiltroAnuncio.todos;
  String _searchQuery = '';

  // ========================================
  // 🔍 GETTERS
  // ========================================

  List<Anuncio> get anuncios => _anuncios;
  Map<String, dynamic> get meta => _meta;
  bool get isLoading => _isLoading;
  FiltroAnuncio get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  int get totalAnuncios => _meta['total'] ?? 0;
  int get currentPage => _meta['pagina'] ?? 1;
  int get totalPages => _meta['paginas'] ?? 1;
  bool get hasMorePages => currentPage < totalPages;

  // Contador de anuncios destacados
  int get destacadosCount {
    return _anuncios.where((a) => a.destacado).length;
  }

  // ========================================
  // ⚡ PREPARAR ESTADO DE CARGA (para initState)
  // ========================================

  void prepareLoading() {
    _isLoading = true;
  }

  // ========================================
  // 📋 CARGAR ANUNCIOS
  // ========================================

  Future<void> loadAnuncios({
    int page = 1,
    bool refresh = false,
    bool silent = false,
    bool soloPublicados = false,
  }) async {
    try {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }

      dlog(
          '📥 Cargando anuncios... (página $page, refresh: $refresh, silent: $silent)');

      final result = await _anuncioService.getAnuncios(
        page: page,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        filtro: _currentFilter,
        soloPublicados: soloPublicados,
      );

      if (refresh || page == 1) {
        _anuncios = result['anuncios'];
      } else {
        // Paginación: agregar anuncios nuevos
        _anuncios = [..._anuncios, ...result['anuncios']];
      }

      _meta = result['meta'];

      _isLoading = false;

      dlog('✅ Anuncios cargados: ${_anuncios.length}');

      // ✅ SIEMPRE notificar, incluso en silent
      notifyListeners();
    } catch (e) {
      dlog('❌ Error cargando anuncios: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 🔄 CAMBIAR FILTRO
  // ========================================

  Future<void> changeFilter(FiltroAnuncio newFilter,
      {bool soloPublicados = false}) async {
    if (_currentFilter == newFilter) return;

    dlog('🔄 Cambiando filtro: ${newFilter.displayName}');

    _currentFilter = newFilter;
    _searchQuery = ''; // Limpiar búsqueda al cambiar filtro
    notifyListeners();

    // Recargar con nuevo filtro
    await loadAnuncios(refresh: true, soloPublicados: soloPublicados);
  }

  // ========================================
  // 🔍 BÚSQUEDA
  // ========================================

  Future<void> search(String query, {bool soloPublicados = false}) async {
    dlog('🔍 Buscando: $query');
    _searchQuery = query;
    notifyListeners();
    await loadAnuncios(refresh: true, soloPublicados: soloPublicados);
  }

  void clearSearch({bool soloPublicados = false}) {
    if (_searchQuery.isNotEmpty) {
      dlog('🧹 Limpiando búsqueda');
      _searchQuery = '';
      loadAnuncios(refresh: true, soloPublicados: soloPublicados);
    }
  }

  // ========================================
  // ✉️ CREAR ANUNCIO
  // ========================================

  Future<Anuncio> createAnuncio({
    required String titulo,
    required String contenido,
    bool paraEstudiantes = false,
    bool paraDocentes = false,
    bool paraPadres = false,
    bool destacado = false,
    bool publicar = false,
    List<File>? adjuntos,
    File? imagenPortada,
  }) async {
    try {
      dlog('📝 Creando anuncio: $titulo (publicar: $publicar)');

      final anuncio = await _anuncioService.createAnuncio(
        titulo: titulo,
        contenido: contenido,
        paraEstudiantes: paraEstudiantes,
        paraDocentes: paraDocentes,
        paraPadres: paraPadres,
        destacado: destacado,
        publicar: publicar,
        adjuntos: adjuntos,
        imagenPortada: imagenPortada,
      );

      dlog('✅ Anuncio creado con ID: ${anuncio.id}');

      // ✅ REFRESCAR LISTA INMEDIATAMENTE (sin silent)
      await loadAnuncios(refresh: true, silent: false);

      return anuncio;
    } on AdjuntosNoSubidosException {
      // El anuncio sí se creó: mostrarlo en la lista y avisar a la pantalla
      await loadAnuncios(refresh: true, silent: true);
      rethrow;
    } catch (e) {
      dlog('❌ Error creando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 📝 ACTUALIZAR ANUNCIO
  // ========================================

  Future<Anuncio> updateAnuncio({
    required String anuncioId,
    required String titulo,
    required String contenido,
    bool paraEstudiantes = false,
    bool paraDocentes = false,
    bool paraPadres = false,
    bool destacado = false,
    List<File>? nuevosAdjuntos,
    File? nuevaImagenPortada,
  }) async {
    try {
      dlog('📝 Actualizando anuncio: $anuncioId');

      final anuncio = await _anuncioService.updateAnuncio(
        anuncioId: anuncioId,
        titulo: titulo,
        contenido: contenido,
        paraEstudiantes: paraEstudiantes,
        paraDocentes: paraDocentes,
        paraPadres: paraPadres,
        destacado: destacado,
        nuevosAdjuntos: nuevosAdjuntos,
        nuevaImagenPortada: nuevaImagenPortada,
      );

      // ✅ Actualizar en lista local
      final index = _anuncios.indexWhere((a) => a.id == anuncioId);
      if (index != -1) {
        _anuncios[index] = anuncio;
      }

      dlog('✅ Anuncio actualizado');
      notifyListeners();

      return anuncio;
    } on AdjuntosNoSubidosException catch (e) {
      // Los cambios sí se guardaron: reflejarlos en la lista y avisar
      final index = _anuncios.indexWhere((a) => a.id == anuncioId);
      if (index != -1) _anuncios[index] = e.anuncio;
      notifyListeners();
      rethrow;
    } catch (e) {
      dlog('❌ Error actualizando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 📢 PUBLICAR ANUNCIO
  // ========================================

  Future<Anuncio> publicarAnuncio(String anuncioId) async {
    try {
      dlog('📢 Publicando anuncio: $anuncioId');

      final anuncio = await _anuncioService.publicarAnuncio(anuncioId);

      // ✅ Actualizar en lista local
      final index = _anuncios.indexWhere((a) => a.id == anuncioId);
      if (index != -1) {
        _anuncios[index] = anuncio;
      }

      dlog('✅ Anuncio publicado');
      notifyListeners();

      return anuncio;
    } catch (e) {
      dlog('❌ Error publicando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗂️ ARCHIVAR ANUNCIO
  // ========================================

  Future<Anuncio> archivarAnuncio(String anuncioId) async {
    try {
      dlog('🗂️ Archivando anuncio: $anuncioId');

      final anuncio = await _anuncioService.archivarAnuncio(anuncioId);

      // ✅ Remover de lista local (se movió a archivados)
      _anuncios.removeWhere((a) => a.id == anuncioId);

      dlog('✅ Anuncio archivado');
      notifyListeners();

      return anuncio;
    } catch (e) {
      dlog('❌ Error archivando anuncio: $e');
      // En caso de error, recargar lista
      await loadAnuncios(refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR ANUNCIO
  // ========================================

  Future<void> deleteAnuncio(String anuncioId) async {
    try {
      dlog('🗑️ Eliminando anuncio: $anuncioId');

      // ✅ Optimistic update - remover inmediatamente de la UI
      _anuncios.removeWhere((a) => a.id == anuncioId);
      notifyListeners();

      // Llamar al backend
      await _anuncioService.deleteAnuncio(anuncioId);

      dlog('✅ Anuncio eliminado');
    } catch (e) {
      dlog('❌ Error eliminando anuncio: $e');
      // En caso de error, recargar lista para revertir el optimistic update
      await loadAnuncios(refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 📎 OBTENER ANUNCIO POR ID
  // ========================================

  Future<Anuncio?> getAnuncioById(String id) async {
    try {
      dlog('📥 Obteniendo anuncio: $id');

      // Primero buscar en lista local. Búsqueda nula: con la lista vacía
      // (p. ej. abierto desde una notificación antes de cargarla) el
      // antiguo orElse: _anuncios.first lanzaba StateError.
      final localAnuncio = _anuncios.where((a) => a.id == id).firstOrNull;
      if (localAnuncio != null) {
        dlog('✅ Anuncio encontrado en cache local');
        return localAnuncio;
      }

      // Si no está en local, obtener del servidor
      dlog('📡 Obteniendo del servidor...');
      final anuncio = await _anuncioService.getAnuncioById(id);

      if (anuncio != null) {
        dlog('✅ Anuncio obtenido del servidor');
      }

      return anuncio;
    } catch (e) {
      dlog('❌ Error obteniendo anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔄 REFRESCAR
  // ========================================

  Future<void> refresh({bool soloPublicados = false}) async {
    dlog('🔄 Refrescando lista...');
    await loadAnuncios(refresh: true, soloPublicados: soloPublicados);
  }

  // ========================================
  // 📄 CARGAR MÁS (PAGINACIÓN)
  // ========================================

  Future<void> loadMore({bool soloPublicados = false}) async {
    if (!hasMorePages || _isLoading) return;

    dlog('📄 Cargando más anuncios... (página ${currentPage + 1})');

    final nextPage = currentPage + 1;
    await loadAnuncios(
      page: nextPage,
      silent: false, // ✅ No silent para que se vea el loading
      soloPublicados: soloPublicados,
    );
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO
  // ========================================

  void clearState() {
    dlog('🧹 Limpiando estado del provider');
    _anuncios = [];
    _meta = {
      'total': 0,
      'pagina': 1,
      'limite': 20,
      'paginas': 1,
    };
    _currentFilter = FiltroAnuncio.todos;
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }
}
