// lib/providers/calendario_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/evento.dart';
import '../services/calendario_service.dart';

/// 📅 PROVIDER DE CALENDARIO
/// Maneja el estado de los eventos del calendario
class CalendarioProvider extends ChangeNotifier {
  final CalendarioService _calendarioService = CalendarioService();

  // ==========================================
  // ESTADO
  // ==========================================

  List<Evento> _todosLosEventosDelMes =
      []; // TODOS los eventos del mes sin filtros
  bool _isLoading = false;
  String? _errorMessage;

  // Mes actual
  DateTime _mesActual = DateTime.now();

  // Cache local para detalles
  final Map<String, Evento> _eventosCache = {};

  // ==========================================
  // GETTERS
  // ==========================================

  List<Evento> get eventos => _todosLosEventosDelMes; // Ahora retorna todos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get mesActual => _mesActual;

  /// Próximos eventos ordenados por fecha (solo ACTIVOS)
  List<Evento> get proximosEventos {
    final ahora = DateTime.now();
    final proximos = _todosLosEventosDelMes.where((evento) {
      return evento.fechaInicio.isAfter(ahora) &&
          evento.estado == EventStatus.activo;
    }).toList();

    proximos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return proximos.take(10).toList();
  }

  /// ✅ OBTENER EVENTOS DEL DÍA CON FILTRO POR ROL
  ///
  /// Para ADMIN, DOCENTE, RECTOR, COORDINADOR, ADMINISTRATIVO:
  /// - Todos los eventos del día (todos los tipos, todos los estados)
  ///
  /// Para ESTUDIANTE, ACUDIENTE:
  /// - Solo eventos ACTIVOS del día (todos los tipos)
  ///
  /// Todos ordenados por tipo
  List<Evento> getEventosDelDia(DateTime dia, String? tipoUsuario) {
    print('🔍 Buscando eventos para: ${dia.day}/${dia.month}/${dia.year}');
    print('   Rol del usuario: $tipoUsuario');
    print('   Total eventos del mes: ${_todosLosEventosDelMes.length}');

    // Roles que pueden ver TODOS los estados
    final rolesAdmin = [
      'ADMIN',
      'SUPER_ADMIN',
      'DOCENTE',
      'RECTOR',
      'COORDINADOR',
      'ADMINISTRATIVO'
    ];
    final esAdmin =
        tipoUsuario != null && rolesAdmin.contains(tipoUsuario.toUpperCase());

    // Filtrar eventos del día
    var eventosDia = _todosLosEventosDelMes.where((evento) {
      final fechaEvento = evento.fechaInicio;
      final coincideDia = fechaEvento.year == dia.year &&
          fechaEvento.month == dia.month &&
          fechaEvento.day == dia.day;

      if (!coincideDia) return false;

      // Si es ADMIN/DOCENTE/etc → mostrar todos los estados
      if (esAdmin) return true;

      // Si es ESTUDIANTE/ACUDIENTE → solo ACTIVOS
      return evento.estado == EventStatus.activo;
    }).toList();

    // Ordenar por tipo de evento
    eventosDia.sort((a, b) {
      // Primero por tipo
      final tipoCompare = a.tipo.value.compareTo(b.tipo.value);
      if (tipoCompare != 0) return tipoCompare;
      // Luego por hora
      return a.fechaInicio.compareTo(b.fechaInicio);
    });

    print('   ✅ Eventos del día encontrados: ${eventosDia.length}');
    print('   Es admin: $esAdmin');

    return eventosDia;
  }

  // ==========================================
  // CARGAR EVENTOS
  // ==========================================

  /// Cargar TODOS los eventos del mes (sin filtros)
  Future<void> loadEventos({
    bool refresh = false,
    bool silent = false,
  }) async {
    if (_isLoading && !refresh) {
      print('⏳ Ya hay una carga en proceso');
      return;
    }

    try {
      if (!silent) {
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();
      }

      print(
          '📅 Cargando TODOS los eventos del mes: ${_mesActual.month}/${_mesActual.year}');

      // Calcular inicio y fin del mes
      final inicio = DateTime(_mesActual.year, _mesActual.month, 1);
      final fin =
          DateTime(_mesActual.year, _mesActual.month + 1, 0, 23, 59, 59);

      // Cargar TODOS los eventos del mes SIN filtros
      final todosLosEventos = await _calendarioService.obtenerEventos(
        inicio: inicio,
        fin: fin,
        // SIN filtros de tipo ni estado
      );

      _todosLosEventosDelMes = todosLosEventos;
      print('   ✅ Total eventos cargados: ${_todosLosEventosDelMes.length}');

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar eventos: $e';
      print('❌ $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refrescar eventos
  Future<void> refresh() async {
    print('🔄 Refrescando eventos...');
    await loadEventos(refresh: true);
  }

  // ==========================================
  // NAVEGACIÓN DE MES
  // ==========================================

  /// Ir al mes anterior
  Future<void> mesAnterior() async {
    _mesActual = DateTime(_mesActual.year, _mesActual.month - 1);
    print('◀️ Mes anterior: ${_mesActual.month}/${_mesActual.year}');
    await loadEventos();
  }

  /// Ir al mes siguiente
  Future<void> mesSiguiente() async {
    _mesActual = DateTime(_mesActual.year, _mesActual.month + 1);
    print('▶️ Mes siguiente: ${_mesActual.month}/${_mesActual.year}');
    await loadEventos();
  }

  /// Ir al mes actual (hoy)
  Future<void> mesActualHoy() async {
    _mesActual = DateTime.now();
    print('🏠 Mes actual: ${_mesActual.month}/${_mesActual.year}');
    await loadEventos();
  }

  /// Ir a un mes específico
  Future<void> irAMes(DateTime mes) async {
    _mesActual = DateTime(mes.year, mes.month);
    print('📅 Ir a mes: ${_mesActual.month}/${_mesActual.year}');
    await loadEventos();
  }

  // ==========================================
  // CRUD DE EVENTOS
  // ==========================================

  /// Crear un nuevo evento
  Future<Evento> crearEvento({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required bool todoElDia,
    String? lugar,
    required EventType tipo,
    EventStatus? estado,
    String? color,
    String? cursoId,
    File? archivoAdjunto,
  }) async {
    try {
      print('📝 Creando evento: $titulo');

      final evento = await _calendarioService.crearEvento(
        titulo: titulo,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        todoElDia: todoElDia,
        lugar: lugar,
        tipo: tipo,
        estado: estado,
        color: color,
        cursoId: cursoId,
        archivoAdjunto: archivoAdjunto,
      );

      print('✅ Evento creado: ${evento.id}');

      // Agregar a cache
      _eventosCache[evento.id] = evento;

      // Refrescar para ver el nuevo evento
      await loadEventos(refresh: true);

      return evento;
    } catch (e) {
      print('❌ Error creando evento: $e');
      rethrow;
    }
  }

  /// Actualizar un evento existente
  Future<Evento> actualizarEvento({
    required String eventoId,
    String? titulo,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? todoElDia,
    String? lugar,
    EventType? tipo,
    EventStatus? estado,
    String? color,
    String? cursoId,
    File? archivoAdjunto,
  }) async {
    try {
      print('✏️ Actualizando evento: $eventoId');
      if (estado != null) {
        print('   Nuevo estado: ${estado.value}');
      }

      final evento = await _calendarioService.actualizarEvento(
        id: eventoId,
        titulo: titulo,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        todoElDia: todoElDia,
        lugar: lugar,
        tipo: tipo,
        estado: estado,
        color: color,
        cursoId: cursoId,
        archivoAdjunto: archivoAdjunto,
      );

      print('✅ Evento actualizado: ${evento.id}');

      // Actualizar cache
      _eventosCache[evento.id] = evento;

      // Refrescar para ver los cambios
      await loadEventos(refresh: true);

      return evento;
    } catch (e) {
      print('❌ Error actualizando evento: $e');
      rethrow;
    }
  }

  /// Eliminar un evento
  Future<void> eliminarEvento(String eventoId) async {
    try {
      print('🗑️ Eliminando evento: $eventoId');

      // Optimistic update: remover de la lista inmediatamente
      final index = _todosLosEventosDelMes.indexWhere((e) => e.id == eventoId);
      Evento? eventoEliminado;

      if (index != -1) {
        eventoEliminado = _todosLosEventosDelMes[index];
        _todosLosEventosDelMes.removeAt(index);
        notifyListeners();
      }

      try {
        // Llamar al servicio
        await _calendarioService.eliminarEvento(eventoId);

        print('✅ Evento eliminado exitosamente');

        // Remover del cache
        _eventosCache.remove(eventoId);

        // Refrescar para sincronizar con el backend
        await loadEventos(refresh: true, silent: true);
      } catch (e) {
        // Si falla, revertir el cambio optimista
        if (eventoEliminado != null && index != -1) {
          _todosLosEventosDelMes.insert(index, eventoEliminado);
          notifyListeners();
        }
        rethrow;
      }
    } catch (e) {
      print('❌ Error eliminando evento: $e');
      rethrow;
    }
  }

  // ==========================================
  // OBTENER EVENTO POR ID
  // ==========================================

  /// Obtener un evento por ID (primero busca en cache, luego en API)
  Future<Evento?> getEventoById(String id) async {
    try {
      print('🔍 Buscando evento por ID: $id');

      // Buscar primero en cache local
      if (_eventosCache.containsKey(id)) {
        print('✅ Evento encontrado en cache');
        return _eventosCache[id];
      }

      // Buscar en la lista completa del mes
      try {
        final eventoEnLista =
            _todosLosEventosDelMes.firstWhere((e) => e.id == id);
        print('✅ Evento encontrado en lista del mes');
        _eventosCache[id] = eventoEnLista;
        return eventoEnLista;
      } catch (e) {
        // No está en la lista
      }

      // Si no está, buscar en API
      print('🌐 Buscando evento en API...');
      final evento = await _calendarioService.obtenerEventoPorId(id);
      _eventosCache[id] = evento;

      print('✅ Evento encontrado en API');
      return evento;
    } catch (e) {
      print('❌ Error obteniendo evento: $e');
      return null;
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Limpiar cache
  void limpiarCache() {
    _eventosCache.clear();
    print('🧹 Cache limpiado');
  }

  /// Limpiar todo el estado
  void limpiarEstado() {
    _todosLosEventosDelMes = [];
    _eventosCache.clear();
    _mesActual = DateTime.now();
    _errorMessage = null;
    print('🧹 Estado completo limpiado');
    notifyListeners();
  }

  /// Debug: Imprimir estado actual
  void debugPrint() {
    print('\n📅 ===== CALENDARIO PROVIDER DEBUG =====');
    print('Total eventos del mes: ${_todosLosEventosDelMes.length}');
    print('Próximos eventos: ${proximosEventos.length}');
    print('Mes actual: ${_mesActual.month}/${_mesActual.year}');
    print('Loading: $_isLoading');
    print('Error: $_errorMessage');
    print('Cache size: ${_eventosCache.length}');
    print('=========================================\n');
  }
}
