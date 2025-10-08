// lib/services/anuncio_service.dart

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
      print('📥 Obteniendo anuncios...');
      print('   Filtro: ${filtro.displayName}');
      print('   Solo publicados: $soloPublicados');

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

      print('✅ Anuncios obtenidos: ${anuncios.length}');

      return {
        'anuncios': anuncios,
        'meta': meta,
      };
    } catch (e) {
      print('❌ Error obteniendo anuncios: $e');
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
      print('📥 Obteniendo anuncio: $id');
      final response = await _apiService.get('/anuncios/$id');

      if (response['data'] != null) {
        return Anuncio.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo anuncio: $e');
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
      print('📤 Creando anuncio...');
      print('   Título: $titulo');
      print('   Publicar: $publicar');
      print('   Adjuntos: ${adjuntos?.length ?? 0}');

      // Validar que tenga al menos una audiencia
      if (!paraEstudiantes && !paraDocentes && !paraPadres) {
        throw Exception('Debe seleccionar al menos una audiencia');
      }

      // Si hay adjuntos o imagen, usar FormData
      if ((adjuntos != null && adjuntos.isNotEmpty) || imagenPortada != null) {
        FormData formData = FormData.fromMap({
          'titulo': titulo,
          'contenido': contenido,
          'paraEstudiantes': paraEstudiantes,
          'paraDocentes': paraDocentes,
          'paraPadres': paraPadres,
          'destacado': destacado,
          'estaPublicado': publicar,
        });

        // Agregar imagen de portada
        if (imagenPortada != null) {
          String fileName = imagenPortada.path.split('/').last;
          formData.files.add(MapEntry(
            'imagenPortada',
            await MultipartFile.fromFile(
              imagenPortada.path,
              filename: fileName,
            ),
          ));
        }

        // Agregar adjuntos
        if (adjuntos != null && adjuntos.isNotEmpty) {
          for (File file in adjuntos) {
            String fileName = file.path.split('/').last;
            formData.files.add(MapEntry(
              'archivos',
              await MultipartFile.fromFile(file.path, filename: fileName),
            ));
          }
        }

        final response = await _apiService.post(
          '/anuncios',
          data: formData,
        );

        print('✅ Anuncio creado con archivos');
        return Anuncio.fromJson(response['data']);
      } else {
        // Sin archivos, usar JSON
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

        print('✅ Anuncio creado sin archivos');
        return Anuncio.fromJson(response['data']);
      }
    } catch (e) {
      print('❌ Error creando anuncio: $e');
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
      print('📝 Actualizando anuncio: $anuncioId');

      // Validar audiencia
      if (!paraEstudiantes && !paraDocentes && !paraPadres) {
        throw Exception('Debe seleccionar al menos una audiencia');
      }

      // Si hay archivos nuevos, usar FormData
      if ((nuevosAdjuntos != null && nuevosAdjuntos.isNotEmpty) ||
          nuevaImagenPortada != null) {
        FormData formData = FormData.fromMap({
          'titulo': titulo,
          'contenido': contenido,
          'paraEstudiantes': paraEstudiantes,
          'paraDocentes': paraDocentes,
          'paraPadres': paraPadres,
          'destacado': destacado,
        });

        // Nueva imagen de portada
        if (nuevaImagenPortada != null) {
          String fileName = nuevaImagenPortada.path.split('/').last;
          formData.files.add(MapEntry(
            'imagenPortada',
            await MultipartFile.fromFile(
              nuevaImagenPortada.path,
              filename: fileName,
            ),
          ));
        }

        // Nuevos adjuntos
        if (nuevosAdjuntos != null && nuevosAdjuntos.isNotEmpty) {
          for (File file in nuevosAdjuntos) {
            String fileName = file.path.split('/').last;
            formData.files.add(MapEntry(
              'archivos',
              await MultipartFile.fromFile(file.path, filename: fileName),
            ));
          }
        }

        final response = await _apiService.put(
          '/anuncios/$anuncioId',
          data: formData,
        );

        print('✅ Anuncio actualizado con archivos');
        return Anuncio.fromJson(response['data']);
      } else {
        // Sin archivos nuevos, usar JSON
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

        print('✅ Anuncio actualizado');
        return Anuncio.fromJson(response['data']);
      }
    } catch (e) {
      print('❌ Error actualizando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 📢 PUBLICAR ANUNCIO
  // ========================================

  Future<Anuncio> publicarAnuncio(String anuncioId) async {
    try {
      print('📢 Publicando anuncio: $anuncioId');

      final response = await _apiService.patch('/anuncios/$anuncioId/publicar');

      print('✅ Anuncio publicado');
      return Anuncio.fromJson(response['data']);
    } catch (e) {
      print('❌ Error publicando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗂️ ARCHIVAR ANUNCIO
  // ========================================

  Future<Anuncio> archivarAnuncio(String anuncioId) async {
    try {
      print('🗂️ Archivando anuncio: $anuncioId');

      final response = await _apiService.patch('/anuncios/$anuncioId/archivar');

      print('✅ Anuncio archivado');
      return Anuncio.fromJson(response['data']);
    } catch (e) {
      print('❌ Error archivando anuncio: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR ANUNCIO
  // ========================================

  Future<void> deleteAnuncio(String anuncioId) async {
    try {
      print('🗑️ Eliminando anuncio: $anuncioId');
      await _apiService.delete('/anuncios/$anuncioId');
      print('✅ Anuncio eliminado');
    } catch (e) {
      print('❌ Error eliminando anuncio: $e');
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
      print('📎 Descargando adjunto: $fileName');

      final url = '/anuncios/$anuncioId/adjunto/$adjuntoId';

      // TODO: Implementar descarga real según plataforma
      print('🔗 URL de descarga: $url');
      print('ℹ️ Implementar descarga de archivos según plataforma');
    } catch (e) {
      print('❌ Error descargando adjunto: $e');
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
