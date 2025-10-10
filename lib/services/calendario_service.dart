// lib/services/calendario_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/evento.dart';
import 'api_service.dart';

/// 📅 SERVICIO DE CALENDARIO
/// Maneja todas las operaciones relacionadas con eventos del calendario
class CalendarioService {
  final ApiService _apiService = ApiService();

  // ==========================================
  // CRUD DE EVENTOS
  // ==========================================

  /// Obtener lista de eventos con filtros
  Future<List<Evento>> obtenerEventos({
    DateTime? inicio,
    DateTime? fin,
    String? cursoId,
    EventType? tipo,
    EventStatus? estado,
  }) async {
    try {
      print('🔍 Obteniendo eventos con filtros...');

      // Construir query parameters
      Map<String, dynamic> queryParams = {};

      if (inicio != null) {
        queryParams['inicio'] = inicio.toIso8601String();
      }
      if (fin != null) {
        queryParams['fin'] = fin.toIso8601String();
      }
      if (cursoId != null) {
        queryParams['cursoId'] = cursoId;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo.value;
      }
      if (estado != null) {
        queryParams['estado'] = estado.value;
      }

      print('📊 Query params: $queryParams');

      final response = await _apiService.get(
        '/calendario',
        queryParameters: queryParams,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> eventosData = response['data'] as List<dynamic>;
        final eventos = eventosData
            .map((json) => Evento.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ ${eventos.length} eventos obtenidos');
        return eventos;
      }

      print('⚠️ Respuesta sin datos');
      return [];
    } catch (e) {
      print('❌ Error obteniendo eventos: $e');
      rethrow;
    }
  }

  /// Obtener un evento por ID
  Future<Evento> obtenerEventoPorId(String id) async {
    try {
      print('🔍 Obteniendo evento con ID: $id');

      final response = await _apiService.get('/calendario/$id');

      if (response['success'] == true && response['data'] != null) {
        final evento =
            Evento.fromJson(response['data'] as Map<String, dynamic>);
        print('✅ Evento obtenido: ${evento.titulo}');
        return evento;
      }

      throw Exception('No se encontró el evento');
    } catch (e) {
      print('❌ Error obteniendo evento: $e');
      rethrow;
    }
  }

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
      print('📝 Creando nuevo evento: $titulo');

      // Si hay archivo adjunto, usar FormData
      if (archivoAdjunto != null) {
        return await _crearEventoConArchivo(
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
          archivo: archivoAdjunto,
        );
      }

      // Sin archivo adjunto
      final data = {
        'titulo': titulo,
        'descripcion': descripcion,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'todoElDia': todoElDia,
        if (lugar != null) 'lugar': lugar,
        'tipo': tipo.value,
        if (estado != null) 'estado': estado.value,
        if (color != null) 'color': color,
        if (cursoId != null) 'cursoId': cursoId,
      };

      final response = await _apiService.post('/calendario', data: data);

      if (response['success'] == true) {
        // El backend puede devolver data.data o data directamente
        final eventoData = response['data']['data'] ?? response['data'];
        final evento = Evento.fromJson(eventoData as Map<String, dynamic>);
        print('✅ Evento creado exitosamente: ${evento.id}');
        return evento;
      }

      throw Exception('Error al crear evento');
    } catch (e) {
      print('❌ Error creando evento: $e');
      rethrow;
    }
  }

  /// Crear evento con archivo adjunto usando FormData
  Future<Evento> _crearEventoConArchivo({
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
    required File archivo,
  }) async {
    try {
      print('📎 Creando evento con archivo adjunto...');

      final formData = FormData.fromMap({
        'titulo': titulo,
        'descripcion': descripcion,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'todoElDia': todoElDia,
        if (lugar != null) 'lugar': lugar,
        'tipo': tipo.value,
        if (estado != null) 'estado': estado.value,
        if (color != null) 'color': color,
        if (cursoId != null) 'cursoId': cursoId,
        'archivo': await MultipartFile.fromFile(
          archivo.path,
          filename: archivo.path.split('/').last,
        ),
      });

      final response = await _apiService.postFormData('/calendario', formData);

      if (response['success'] == true) {
        final eventoData = response['data']['data'] ?? response['data'];
        final evento = Evento.fromJson(eventoData as Map<String, dynamic>);
        print('✅ Evento con archivo creado: ${evento.id}');
        return evento;
      }

      throw Exception('Error al crear evento con archivo');
    } catch (e) {
      print('❌ Error creando evento con archivo: $e');
      rethrow;
    }
  }

  /// Actualizar un evento existente
  Future<Evento> actualizarEvento({
    required String id,
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
      print('✏️ Actualizando evento: $id');

      // Si hay archivo adjunto, usar FormData
      if (archivoAdjunto != null) {
        return await _actualizarEventoConArchivo(
          id: id,
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
          archivo: archivoAdjunto,
        );
      }

      // Sin archivo adjunto
      final data = <String, dynamic>{};
      if (titulo != null) data['titulo'] = titulo;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (fechaInicio != null)
        data['fechaInicio'] = fechaInicio.toIso8601String();
      if (fechaFin != null) data['fechaFin'] = fechaFin.toIso8601String();
      if (todoElDia != null) data['todoElDia'] = todoElDia;
      if (lugar != null) data['lugar'] = lugar;
      if (tipo != null) data['tipo'] = tipo.value;
      if (estado != null) data['estado'] = estado.value;
      if (color != null) data['color'] = color;
      if (cursoId != null) data['cursoId'] = cursoId;

      final response = await _apiService.put('/calendario/$id', data: data);

      if (response['success'] == true) {
        final eventoData = response['data']['data'] ?? response['data'];
        final evento = Evento.fromJson(eventoData as Map<String, dynamic>);
        print('✅ Evento actualizado: ${evento.id}');
        return evento;
      }

      throw Exception('Error al actualizar evento');
    } catch (e) {
      print('❌ Error actualizando evento: $e');
      rethrow;
    }
  }

  /// Actualizar evento con archivo adjunto usando FormData
  Future<Evento> _actualizarEventoConArchivo({
    required String id,
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
    required File archivo,
  }) async {
    try {
      print('📎 Actualizando evento con archivo adjunto...');

      final Map<String, dynamic> fields = {};
      if (titulo != null) fields['titulo'] = titulo;
      if (descripcion != null) fields['descripcion'] = descripcion;
      if (fechaInicio != null) {
        fields['fechaInicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) fields['fechaFin'] = fechaFin.toIso8601String();
      if (todoElDia != null) fields['todoElDia'] = todoElDia;
      if (lugar != null) fields['lugar'] = lugar;
      if (tipo != null) fields['tipo'] = tipo.value;
      if (estado != null) fields['estado'] = estado.value;
      if (color != null) fields['color'] = color;
      if (cursoId != null) fields['cursoId'] = cursoId;

      fields['archivo'] = await MultipartFile.fromFile(
        archivo.path,
        filename: archivo.path.split('/').last,
      );

      final formData = FormData.fromMap(fields);

      final response = await _apiService.postFormData(
        '/calendario/$id',
        formData,
      );

      if (response['success'] == true) {
        final eventoData = response['data']['data'] ?? response['data'];
        final evento = Evento.fromJson(eventoData as Map<String, dynamic>);
        print('✅ Evento con archivo actualizado: ${evento.id}');
        return evento;
      }

      throw Exception('Error al actualizar evento con archivo');
    } catch (e) {
      print('❌ Error actualizando evento con archivo: $e');
      rethrow;
    }
  }

  /// Eliminar un evento
  Future<void> eliminarEvento(String id) async {
    try {
      print('🗑️ Eliminando evento: $id');

      final response = await _apiService.delete('/calendario/$id');

      if (response['success'] == true) {
        print('✅ Evento eliminado exitosamente');
        return;
      }

      throw Exception('Error al eliminar evento');
    } catch (e) {
      print('❌ Error eliminando evento: $e');
      rethrow;
    }
  }

  // ==========================================
  // ARCHIVOS ADJUNTOS
  // ==========================================

  /// Obtener URL del adjunto de un evento
  String getAdjuntoUrl(String eventoId) {
    final url = '${AppConfig.baseUrl}/calendario/$eventoId/adjunto';
    print('📎 URL adjunto: $url');
    return url;
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Obtener eventos del mes actual
  Future<List<Evento>> obtenerEventosDelMes(DateTime mes) async {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fin = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);

    return obtenerEventos(inicio: inicio, fin: fin);
  }

  /// Obtener próximos eventos
  Future<List<Evento>> obtenerProximosEventos({int limite = 10}) async {
    try {
      print('📅 Obteniendo próximos $limite eventos...');

      final inicio = DateTime.now();
      final fin = DateTime.now().add(const Duration(days: 90));

      final eventos = await obtenerEventos(
        inicio: inicio,
        fin: fin,
        estado: EventStatus.activo,
      );

      // Ordenar por fecha y limitar
      eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
      final eventosFiltrados = eventos.take(limite).toList();

      print('✅ ${eventosFiltrados.length} próximos eventos');
      return eventosFiltrados;
    } catch (e) {
      print('❌ Error obteniendo próximos eventos: $e');
      rethrow;
    }
  }

  /// Obtener eventos de un día específico
  Future<List<Evento>> obtenerEventosDelDia(DateTime dia) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = DateTime(dia.year, dia.month, dia.day, 23, 59, 59);

    return obtenerEventos(inicio: inicio, fin: fin);
  }
}
