// lib/services/message_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../models/message.dart';
import 'api_service.dart';
import 'package:path_provider/path_provider.dart';

/// 📨 SERVICIO DE MENSAJERÍA
/// Maneja TODOS los endpoints de mensajes, borradores, adjuntos, etc.
class MessageService {
  final ApiService _apiService = ApiService();

  // ========================================
  // 📬 OBTENER MENSAJES POR BANDEJA
  // ========================================

  Future<Map<String, dynamic>> getMessages({
    required Bandeja bandeja,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      print('📥 Obteniendo mensajes de bandeja: ${bandeja.name}');

      final queryParams = {
        'bandeja': bandeja.name,
        'pagina': page,
        'limite': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['busqueda'] = search;
      }

      final response = await _apiService.get(
        '/mensajes',
        queryParameters: queryParams,
      );

      final data = response['data'] as List<dynamic>? ?? [];
      final messages = data.map((json) => Message.fromJson(json)).toList();

      final meta = response['meta'] ??
          {
            'total': 0,
            'pagina': 1,
            'limite': 20,
            'totalPaginas': 1,
          };

      print('✅ Mensajes obtenidos: ${messages.length}');

      return {
        'messages': messages,
        'meta': meta,
      };
    } catch (e) {
      print('❌ Error obteniendo mensajes: $e');
      return {
        'messages': <Message>[],
        'meta': {
          'total': 0,
          'pagina': 1,
          'limite': 20,
          'totalPaginas': 1,
        },
      };
    }
  }

  // ========================================
  // 📖 OBTENER MENSAJE POR ID
  // ========================================

  Future<Message?> getMessageById(String id) async {
    try {
      print('📥 Obteniendo mensaje: $id');
      final response = await _apiService.get('/mensajes/$id');

      if (response['data'] != null) {
        return Message.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 📝 OBTENER BORRADOR POR ID
  // ========================================

  Future<Message?> getDraftById(String id) async {
    try {
      print('📥 Obteniendo borrador: $id');

      // ✅ AGREGAR populate para destinatarios
      final response = await _apiService.get('/mensajes/borradores/$id',
          queryParameters: {'populate': 'destinatarios'} // ← AGREGAR ESTO
          );

      if (response['data'] != null) {
        return Message.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // ✉️ CREAR MENSAJE NUEVO
  // ========================================

  Future<Message> createMessage({
    List<String>? destinatarios,
    List<String>? cursoIds,
    required String asunto,
    required String contenido,
    Prioridad prioridad = Prioridad.normal,
    List<File>? adjuntos,
  }) async {
    try {
      print('📤 Creando mensaje...');
      print('   Destinatarios: ${destinatarios?.length ?? 0}');
      print('   Cursos: ${cursoIds?.length ?? 0}');
      print('   Adjuntos: ${adjuntos?.length ?? 0}');

      // Validar que haya al menos destinatarios o cursos
      if ((destinatarios == null || destinatarios.isEmpty) &&
          (cursoIds == null || cursoIds.isEmpty)) {
        throw Exception('Debe seleccionar al menos un destinatario o curso');
      }

      FormData formData = FormData.fromMap({
        'asunto': asunto,
        'contenido': contenido,
        'prioridad': prioridad.name.toUpperCase(),
      });

      // Agregar destinatarios
      if (destinatarios != null && destinatarios.isNotEmpty) {
        for (String destId in destinatarios) {
          formData.fields.add(MapEntry('destinatarios', destId));
        }
      }

      // Agregar cursos
      if (cursoIds != null && cursoIds.isNotEmpty) {
        for (String cursoId in cursoIds) {
          formData.fields.add(MapEntry('cursoIds', cursoId));
        }
      }

      // Agregar adjuntos
      if (adjuntos != null && adjuntos.isNotEmpty) {
        for (File file in adjuntos) {
          String fileName = file.path.split('/').last;
          formData.files.add(MapEntry(
            'adjuntos',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ));
        }
      }

      final response = await _apiService.post(
        '/mensajes',
        data: formData,
      );

      print('✅ Mensaje creado exitosamente');
      return Message.fromJson(response['data']);
    } catch (e) {
      print('❌ Error creando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 💾 GUARDAR BORRADOR
  // ========================================

  Future<Message> saveDraft({
    List<String>? destinatarios,
    List<String>? cursoIds,
    required String asunto,
    required String contenido,
    Prioridad prioridad = Prioridad.normal,
    List<File>? adjuntos,
  }) async {
    try {
      print('💾 Guardando borrador...');

      // Validación mínima
      if (asunto.trim().isEmpty && contenido.trim().isEmpty) {
        throw Exception('Debe escribir al menos el asunto o el contenido');
      }

      // Si hay adjuntos, usar FormData
      if (adjuntos != null && adjuntos.isNotEmpty) {
        FormData formData = FormData.fromMap({
          'asunto': asunto.isEmpty ? '(Sin asunto)' : asunto,
          'contenido': contenido,
          'prioridad': prioridad.name.toUpperCase(),
        });

        // Agregar destinatarios
        if (destinatarios != null && destinatarios.isNotEmpty) {
          for (String destId in destinatarios) {
            formData.fields.add(MapEntry('destinatarios[]', destId));
          }
        }

        // Agregar cursos
        if (cursoIds != null && cursoIds.isNotEmpty) {
          for (String cursoId in cursoIds) {
            formData.fields.add(MapEntry('cursoIds[]', cursoId));
          }
        }

        // Agregar adjuntos
        for (File file in adjuntos) {
          String fileName = file.path.split('/').last;
          formData.files.add(MapEntry(
            'adjuntos',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ));
        }

        final response = await _apiService.post(
          '/mensajes/borradores',
          data: formData,
        );

        print('✅ Borrador guardado con adjuntos');
        return Message.fromJson(response['data']);
      } else {
        // Sin adjuntos, usar JSON
        final response = await _apiService.post(
          '/mensajes/borradores',
          data: {
            'destinatarios': destinatarios ?? [],
            'cursoIds': cursoIds ?? [],
            'asunto': asunto.isEmpty ? '(Sin asunto)' : asunto,
            'contenido': contenido,
            'prioridad': prioridad.name.toUpperCase(),
          },
        );

        print('✅ Borrador guardado sin adjuntos');
        return Message.fromJson(response['data']);
      }
    } catch (e) {
      print('❌ Error guardando borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // 📝 ACTUALIZAR BORRADOR
  // ========================================

  Future<Message> updateDraft({
    required String draftId,
    List<String>? destinatarios,
    List<String>? cursoIds,
    required String asunto,
    required String contenido,
    Prioridad prioridad = Prioridad.normal,
    List<File>? adjuntos,
    bool clearExistingAttachments = false,
  }) async {
    try {
      print('📝 Actualizando borrador: $draftId');

      // Si hay adjuntos nuevos, usar FormData
      if (adjuntos != null && adjuntos.isNotEmpty) {
        FormData formData = FormData.fromMap({
          'asunto': asunto.isEmpty ? '(Sin asunto)' : asunto,
          'contenido': contenido,
          'prioridad': prioridad.name.toUpperCase(),
          'clearExistingAttachments': clearExistingAttachments,
        });

        // Agregar destinatarios
        if (destinatarios != null && destinatarios.isNotEmpty) {
          for (String destId in destinatarios) {
            formData.fields.add(MapEntry('destinatarios[]', destId));
          }
        }

        // Agregar cursos
        if (cursoIds != null && cursoIds.isNotEmpty) {
          for (String cursoId in cursoIds) {
            formData.fields.add(MapEntry('cursoIds[]', cursoId));
          }
        }

        // Agregar adjuntos
        for (File file in adjuntos) {
          String fileName = file.path.split('/').last;
          formData.files.add(MapEntry(
            'adjuntos',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ));
        }

        final response = await _apiService.put(
          '/mensajes/borradores/$draftId',
          data: formData,
        );

        print('✅ Borrador actualizado con adjuntos');
        return Message.fromJson(response['data']);
      } else {
        // Sin adjuntos nuevos
        final response = await _apiService.put(
          '/mensajes/borradores/$draftId',
          data: {
            'destinatarios': destinatarios ?? [],
            'cursoIds': cursoIds ?? [],
            'asunto': asunto.isEmpty ? '(Sin asunto)' : asunto,
            'contenido': contenido,
            'prioridad': prioridad.name.toUpperCase(),
            'clearExistingAttachments': clearExistingAttachments,
          },
        );

        print('✅ Borrador actualizado');
        return Message.fromJson(response['data']);
      }
    } catch (e) {
      print('❌ Error actualizando borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR BORRADOR
  // ========================================

  Future<void> deleteDraft(String draftId) async {
    try {
      print('🗑️ Eliminando borrador: $draftId');
      await _apiService.delete('/mensajes/borradores/$draftId');
      print('✅ Borrador eliminado');
    } catch (e) {
      print('❌ Error eliminando borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // 🚀 ENVIAR BORRADOR
  // ========================================

  Future<Message> sendDraft(String draftId) async {
    try {
      print('🚀 Enviando borrador: $draftId');

      // Obtener datos completos del borrador
      final draft = await getDraftById(draftId);
      if (draft == null) {
        throw Exception('Borrador no encontrado');
      }

      // Crear mensaje normal (esto maneja copias a acudientes automáticamente)
      final messageData = {
        'destinatarios': draft.destinatarios.map((d) => d.id).toList(),
        'asunto': draft.asunto,
        'contenido': draft.contenido,
        'prioridad': draft.prioridad.name.toUpperCase(),
      };

      print('📤 Creando mensaje desde borrador...');
      final response = await _apiService.post('/mensajes', data: messageData);

      // Eliminar el borrador original
      print('🗑️ Eliminando borrador original...');
      await deleteDraft(draftId);

      print('✅ Borrador enviado exitosamente');
      return Message.fromJson(response['data']);
    } catch (e) {
      print('❌ Error enviando borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // 💬 RESPONDER MENSAJE
  // ========================================

  Future<Message> replyMessage({
    required String originalId,
    required String contenido,
    String? asunto,
    List<File>? adjuntos,
  }) async {
    try {
      print('💬 Respondiendo mensaje: $originalId');

      if (adjuntos != null && adjuntos.isNotEmpty) {
        // Con adjuntos
        FormData formData = FormData.fromMap({
          'contenido': contenido,
          'asunto': asunto,
        });

        for (File file in adjuntos) {
          String fileName = file.path.split('/').last;
          formData.files.add(MapEntry(
            'adjuntos',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ));
        }

        final response = await _apiService.post(
          '/mensajes/$originalId/responder',
          data: formData,
        );

        print('✅ Respuesta enviada con adjuntos');
        return Message.fromJson(response['data']);
      } else {
        // Sin adjuntos
        final response = await _apiService.post(
          '/mensajes/$originalId/responder',
          data: {
            'contenido': contenido,
            'asunto': asunto,
          },
        );

        print('✅ Respuesta enviada');
        return Message.fromJson(response['data']);
      }
    } catch (e) {
      print('❌ Error respondiendo mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 👁️ MARCAR COMO LEÍDO
  // ========================================

  Future<void> markAsRead(String messageId) async {
    try {
      print('👁️ Marcando como leído: $messageId');
      await _apiService.put('/mensajes/$messageId/leer');
      print('✅ Mensaje marcado como leído');
    } catch (e) {
      print('❌ Error marcando como leído: $e');
      // No lanzar error, es una operación secundaria
    }
  }

  // ========================================
  // 🗂️ ARCHIVAR MENSAJE
  // ========================================

  Future<void> archiveMessage(String messageId) async {
    try {
      print('🗂️ Archivando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/archivar');
      print('✅ Mensaje archivado');
    } catch (e) {
      print('❌ Error archivando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 📤 DESARCHIVAR MENSAJE
  // ========================================

  Future<void> unarchiveMessage(String messageId) async {
    try {
      print('📤 Desarchivando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/desarchivar');
      print('✅ Mensaje desarchivado');
    } catch (e) {
      print('❌ Error desarchivando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR MENSAJE (a papelera)
  // ========================================

  Future<void> deleteMessage(String messageId) async {
    try {
      print('🗑️ Eliminando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/eliminar');
      print('✅ Mensaje movido a papelera');
    } catch (e) {
      print('❌ Error eliminando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // ♻️ RESTAURAR MENSAJE
  // ========================================

  Future<void> restoreMessage(String messageId) async {
    try {
      print('♻️ Restaurando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/restaurar');
      print('✅ Mensaje restaurado');
    } catch (e) {
      print('❌ Error restaurando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 💥 ELIMINAR PERMANENTEMENTE
  // ========================================

  Future<void> deletePermanently(String messageId) async {
    try {
      print('💥 Eliminando permanentemente: $messageId');
      await _apiService.delete('/mensajes/$messageId');
      print('✅ Mensaje eliminado definitivamente');
    } catch (e) {
      print('❌ Error eliminando permanentemente: $e');
      rethrow;
    }
  }

  // ========================================
  // 📎 DESCARGAR ADJUNTO
  // ========================================

// ========================================
// 📎 DESCARGAR ADJUNTO - IMPLEMENTACIÓN COMPLETA
// ========================================

  Future<Map<String, dynamic>> downloadAttachment(
    String messageId,
    String attachmentId,
    String fileName,
  ) async {
    try {
      print('📎 Descargando adjunto: $fileName');
      print('   Mensaje ID: $messageId');
      print('   Adjunto ID: $attachmentId');

      // 1️⃣ Obtener la ruta de descarga
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsPath =
              directory.path.split('/Android')[0] + '/Download';
          directory = Directory(downloadsPath);

          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('No se pudo obtener el directorio de descarga');
      }

      final filePath = '${directory.path}/$fileName';
      print('💾 Ruta de descarga: $filePath');

      // 2️⃣ Descargar el archivo
      final url = '/mensajes/$messageId/adjuntos/$attachmentId';
      print('🌐 URL: $url');

      await _apiService.download(url, filePath);

      print('✅ Archivo descargado exitosamente en: $filePath');

      // 3️⃣ Retornar resultado exitoso
      return {
        'success': true,
        'message': 'Archivo descargado exitosamente',
        'path': filePath,
      };
    } catch (e) {
      print('❌ Error descargando adjunto: $e');
      return {
        'success': false,
        'message': 'Error al descargar: $e',
      };
    }
  }

  Future<void> _scanFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        print('📱 Archivo guardado correctamente');
      }
    } catch (e) {
      print('⚠️ Error: $e');
    }
  }

  // ========================================
  // 👥 OBTENER DESTINATARIOS DISPONIBLES
  // ========================================

  Future<List<User>> getAvailableRecipients() async {
    try {
      print('👥 Obteniendo destinatarios disponibles...');

      final response =
          await _apiService.get('/mensajes/destinatarios-disponibles');

      final data = response['data'] as List<dynamic>? ?? [];
      final recipients = data.map((json) => User.fromJson(json)).toList();

      print('✅ Destinatarios obtenidos: ${recipients.length}');
      return recipients;
    } catch (e) {
      print('❌ Error obteniendo destinatarios: $e');
      return [];
    }
  }

  // ========================================
  // 📚 OBTENER CURSOS DISPONIBLES
  // ========================================

  Future<List<Course>> getAvailableCourses() async {
    try {
      print('📚 Obteniendo cursos disponibles...');

      final response = await _apiService.get('/mensajes/cursos-disponibles');

      final data = response['data'] as List<dynamic>? ?? [];
      final courses = data.map((json) => Course.fromJson(json)).toList();

      print('✅ Cursos obtenidos: ${courses.length}');
      return courses;
    } catch (e) {
      print('❌ Error obteniendo cursos: $e');
      return [];
    }
  }
}
