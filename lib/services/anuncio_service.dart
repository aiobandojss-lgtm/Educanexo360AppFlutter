// lib/services/anuncio_service.dart

import '../utils/logger.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/anuncio.dart';
import 'api_service.dart';

/// 📢 SERVICIO DE ANUNCIOS
/// Maneja TODOS los endpoints de anuncios
class AnuncioService {
  final ApiService _apiService = ApiService();

  // ========================================
  // 📋 OBTENER ANUNCIOS CON FILTROS
  // ========================================

  Future<Map<String, dynamic>> getAnuncios({
    int page = 1,
    int limit = 20,
    String? search,
    FiltroAnuncio filtro = FiltroAnuncio.todos,
    bool soloPublicados = false,
  }) async {
    try {
      dlog('📥 Obteniendo anuncios...');
      dlog('   Filtro: ${filtro.displayName}');
      dlog('   Solo publicados: $soloPublicados');

      final queryParams = <String, dynamic>{
        'pagina': page,
        'limite': limit,
      };

      // Solo publicados (para estudiantes/padres)
      if (soloPublicados) {
        queryParams['soloPublicados'] = true;
      }

      // Filtros específicos - ✅ SIN CASO BORRADORES
      switch (filtro) {
        case FiltroAnuncio.destacados:
          queryParams['soloDestacados'] = true;
          break;
        case FiltroAnuncio.estudiantes:
          queryParams['paraRol'] = 'ESTUDIANTE';
          break;
        case FiltroAnuncio.docentes:
          queryParams['paraRol'] = 'DOCENTE';
          break;
        case FiltroAnuncio.padres:
          queryParams['paraRol'] = 'ACUDIENTE';
          break;
        case FiltroAnuncio.todos:
          // Sin filtros adicionales
          break;
      }

      // Búsqueda
      if (search != null && search.isNotEmpty) {
        queryParams['busqueda'] = search;
      }

      final response = await _apiService.get(
        '/anuncios',
        queryParameters: queryParams,
      );

      final data = response['data'] as List<dynamic>? ?? [];
      final anuncios = data.map((json) => Anuncio.fromJson(json)).toList();

      final meta = response['meta'] ??
          {
            'total': 0,
            'pagina': 1,
            'limite': 20,
            'paginas': 1,
          };

      dlog('✅ Anuncios obtenidos: ${anuncios.length}');

      return {
        'anuncios': anuncios,
        'meta': meta,
      };
    } catch (e) {
      dlog('❌ Error obteniendo anuncios: $e');
      return {
        'anuncios': <Anuncio>[],
        'meta': {
          'total': 0,
          'pagina': 1,
          'limite': 20,
          'paginas': 1,
        },
      };
    }
  }

  // ========================================
  // 📖 OBTENER ANUNCIO POR ID
  // ========================================

  Future<Anuncio?> getAnuncioById(String id) async {
    try {
      dlog('📥 Obteniendo anuncio: $id');
      final response = await _apiService.get('/anuncios/$id');

      if (response['data'] != null) {
        return Anuncio.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      dlog('❌ Error obteniendo anuncio: $e');
      rethrow;
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
      dlog('📤 Creando anuncio...');
      dlog('   Título: $titulo');
      dlog('   Publicar: $publicar');
      dlog('   Adjuntos: ${adjuntos?.length ?? 0}');

      // Validar que tenga al menos una audiencia
      if (!paraEstudiantes && !paraDocentes && !paraPadres) {
        throw Exception('Debe seleccionar al menos una audiencia');
      }

      // POST /anuncios solo recibe JSON (no multer): los adjuntos se suben
      // después a POST /anuncios/:id/adjuntos, como hace la web
      final response = await _apiService.post(
        '/anuncios',
        data: {
          'titulo': titulo,
          'contenido': contenido,
          'paraEstudiantes': paraEstudiantes,
          'paraDocentes': paraDocentes,
          'paraPadres': paraPadres,
          'destacado': destacado,
          'estaPublicado': publicar,
        },
      );
      final anuncio = Anuncio.fromJson(response['data']);
      dlog('✅ Anuncio creado: ${anuncio.id}');

      _avisarPortadaNoSoportada(imagenPortada);
      return await _conAdjuntos(anuncio, adjuntos);
    } catch (e) {
      dlog('❌ Error creando anuncio: $e');
      rethrow;
    }
  }

  /// Sube [adjuntos] al anuncio ya guardado y lo devuelve con ellos. Si la
  /// subida falla, lanza [AdjuntosNoSubidosException] con el anuncio (que ya
  /// existe en el servidor) para no provocar un duplicado al reintentar.
  Future<Anuncio> _conAdjuntos(Anuncio anuncio, List<File>? adjuntos) async {
    if (adjuntos == null || adjuntos.isEmpty) return anuncio;
    try {
      final formData = FormData();
      for (final file in adjuntos) {
        formData.files.add(MapEntry(
          'archivos',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split('/').last),
        ));
      }
      final response = await _apiService.postFormData(
        '/anuncios/${anuncio.id}/adjuntos',
        formData,
      );
      final lista = (response['data'] as List<dynamic>? ?? [])
          .map((adj) => ArchivoAdjunto.fromJson(adj as Map<String, dynamic>))
          .toList();
      dlog('✅ ${lista.length} adjunto(s) en el anuncio');
      return anuncio.copyWith(archivosAdjuntos: lista);
    } catch (e) {
      dlog('❌ El anuncio se guardó pero los adjuntos fallaron: $e');
      throw AdjuntosNoSubidosException(
        anuncio: anuncio,
        motivo: e is ApiException ? e.message : 'Error de conexión',
      );
    }
  }

  // El backend no tiene ruta para la imagen de portada (solo adjuntos) y
  // ninguna pantalla la envía hoy: se ignora con aviso en el log.
  void _avisarPortadaNoSoportada(File? imagen) {
    if (imagen != null) {
      dlog('⚠️ Imagen de portada no soportada por el backend: se ignora');
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

      // Validar audiencia
      if (!paraEstudiantes && !paraDocentes && !paraPadres) {
        throw Exception('Debe seleccionar al menos una audiencia');
      }

      // PUT /anuncios/:id solo recibe JSON; los adjuntos nuevos se suben
      // después a POST /anuncios/:id/adjuntos
      final response = await _apiService.put(
        '/anuncios/$anuncioId',
        data: {
          'titulo': titulo,
          'contenido': contenido,
          'paraEstudiantes': paraEstudiantes,
          'paraDocentes': paraDocentes,
          'paraPadres': paraPadres,
          'destacado': destacado,
        },
      );
      final anuncio = Anuncio.fromJson(response['data']);
      dlog('✅ Anuncio actualizado');

      _avisarPortadaNoSoportada(nuevaImagenPortada);
      return await _conAdjuntos(anuncio, nuevosAdjuntos);
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

      final response = await _apiService.patch('/anuncios/$anuncioId/publicar');

      dlog('✅ Anuncio publicado');
      return Anuncio.fromJson(response['data']);
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

      final response = await _apiService.patch('/anuncios/$anuncioId/archivar');

      dlog('✅ Anuncio archivado');
      return Anuncio.fromJson(response['data']);
    } catch (e) {
      dlog('❌ Error archivando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR ANUNCIO
  // ========================================

  Future<void> deleteAnuncio(String anuncioId) async {
    try {
      dlog('🗑️ Eliminando anuncio: $anuncioId');
      await _apiService.delete('/anuncios/$anuncioId');
      dlog('✅ Anuncio eliminado');
    } catch (e) {
      dlog('❌ Error eliminando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 📎 DESCARGAR ADJUNTO
  // ========================================

  Future<void> downloadAttachment(
    String anuncioId,
    String adjuntoId,
    String fileName,
  ) async {
    try {
      dlog('📎 Descargando adjunto: $fileName');

      final url = '/anuncios/$anuncioId/adjunto/$adjuntoId';

      // TODO: Implementar descarga real según plataforma
      dlog('🔗 URL de descarga: $url');
      dlog('ℹ️ Implementar descarga de archivos según plataforma');
    } catch (e) {
      dlog('❌ Error descargando adjunto: $e');
      rethrow;
    }
  }

  // ========================================
  // 🖼️ OBTENER URL IMAGEN PORTADA
  // ========================================

  String getImagenPortadaUrl(String anuncioId, String imagenId) {
    return '/anuncios/$anuncioId/imagen/$imagenId';
  }
}

/// El anuncio se guardó en el servidor, pero los adjuntos no se pudieron
/// subir (p. ej. tipo de archivo no permitido o sin conexión).
class AdjuntosNoSubidosException implements Exception {
  AdjuntosNoSubidosException({required this.anuncio, required this.motivo});

  final Anuncio anuncio;
  final String motivo;

  @override
  String toString() => 'AdjuntosNoSubidosException: $motivo';
}
