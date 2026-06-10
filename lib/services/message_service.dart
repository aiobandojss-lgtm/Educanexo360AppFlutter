// lib/services/message_service.dart

import '../utils/logger.dart';
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
      dlog('📥 Obteniendo mensajes de bandeja: ${bandeja.name}');

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

      dlog('✅ Mensajes obtenidos: ${messages.length}');

      return {
        'messages': messages,
        'meta': meta,
      };
    } catch (e) {
      dlog('❌ Error obteniendo mensajes: $e');
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
      dlog('📥 Obteniendo mensaje: $id');
      final response = await _apiService.get('/mensajes/$id');

      if (response['data'] != null) {
        return Message.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      dlog('❌ Error obteniendo mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 📝 OBTENER BORRADOR POR ID
  // ========================================

  Future<Message?> getDraftById(String id) async {
    try {
      dlog('📥 Obteniendo borrador: $id');

      // ✅ AGREGAR populate para destinatarios
      final response = await _apiService.get('/mensajes/borradores/$id',
          queryParameters: {'populate': 'destinatarios'} // ← AGREGAR ESTO
          );

      if (response['data'] != null) {
        return Message.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      dlog('❌ Error obteniendo borrador: $e');
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
      dlog('📤 Creando mensaje...');
      dlog('   Destinatarios: ${destinatarios?.length ?? 0}');
      dlog('   Cursos: ${cursoIds?.length ?? 0}');
      dlog('   Adjuntos: ${adjuntos?.length ?? 0}');

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

      dlog('✅ Mensaje creado exitosamente');
      return Message.fromJson(response['data']);
    } catch (e) {
      dlog('❌ Error creando mensaje: $e');
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
      dlog('💾 Guardando borrador...');

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

        dlog('✅ Borrador guardado con adjuntos');
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

        dlog('✅ Borrador guardado sin adjuntos');
        return Message.fromJson(response['data']);
      }
    } catch (e) {
      dlog('❌ Error guardando borrador: $e');
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
      dlog('📝 Actualizando borrador: $draftId');

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

        dlog('✅ Borrador actualizado con adjuntos');
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

        dlog('✅ Borrador actualizado');
        return Message.fromJson(response['data']);
      }
    } catch (e) {
      dlog('❌ Error actualizando borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR BORRADOR
  // ========================================

  Future<void> deleteDraft(String draftId) async {
    try {
      dlog('🗑️ Eliminando borrador: $draftId');
      await _apiService.delete('/mensajes/borradores/$draftId');
      dlog('✅ Borrador eliminado');
    } catch (e) {
      dlog('❌ Error eliminando borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // 🚀 ENVIAR BORRADOR
  // ========================================

  Future<Message> sendDraft(String draftId) async {
    try {
      dlog('🚀 Enviando borrador: $draftId');

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

      dlog('📤 Creando mensaje desde borrador...');
      final response = await _apiService.post('/mensajes', data: messageData);

      // Eliminar el borrador original
      dlog('🗑️ Eliminando borrador original...');
      await deleteDraft(draftId);

      dlog('✅ Borrador enviado exitosamente');
      return Message.fromJson(response['data']);
    } catch (e) {
      dlog('❌ Error enviando borrador: $e');
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
      dlog('💬 Respondiendo mensaje: $originalId');

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

        dlog('✅ Respuesta enviada con adjuntos');
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

        dlog('✅ Respuesta enviada');
        return Message.fromJson(response['data']);
      }
    } catch (e) {
      dlog('❌ Error respondiendo mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 👁️ MARCAR COMO LEÍDO
  // ========================================

  Future<void> markAsRead(String messageId) async {
    try {
      dlog('👁️ Marcando como leído: $messageId');
      await _apiService.put('/mensajes/$messageId/leer');
      dlog('✅ Mensaje marcado como leído');
    } catch (e) {
      dlog('❌ Error marcando como leído: $e');
      // No lanzar error, es una operación secundaria
    }
  }

  // ========================================
  // 🗂️ ARCHIVAR MENSAJE
  // ========================================

  Future<void> archiveMessage(String messageId) async {
    try {
      dlog('🗂️ Archivando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/archivar');
      dlog('✅ Mensaje archivado');
    } catch (e) {
      dlog('❌ Error archivando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 📤 DESARCHIVAR MENSAJE
  // ========================================

  Future<void> unarchiveMessage(String messageId) async {
    try {
      dlog('📤 Desarchivando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/desarchivar');
      dlog('✅ Mensaje desarchivado');
    } catch (e) {
      dlog('❌ Error desarchivando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR MENSAJE (a papelera)
  // ========================================

  Future<void> deleteMessage(String messageId) async {
    try {
      dlog('🗑️ Eliminando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/eliminar');
      dlog('✅ Mensaje movido a papelera');
    } catch (e) {
      dlog('❌ Error eliminando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // ♻️ RESTAURAR MENSAJE
  // ========================================

  Future<void> restoreMessage(String messageId) async {
    try {
      dlog('♻️ Restaurando mensaje: $messageId');
      await _apiService.put('/mensajes/$messageId/restaurar');
      dlog('✅ Mensaje restaurado');
    } catch (e) {
      dlog('❌ Error restaurando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 💥 ELIMINAR PERMANENTEMENTE
  // ========================================

  Future<void> deletePermanently(String messageId) async {
    try {
      dlog('💥 Eliminando permanentemente: $messageId');
      await _apiService.delete('/mensajes/$messageId');
      dlog('✅ Mensaje eliminado definitivamente');
    } catch (e) {
      dlog('❌ Error eliminando permanentemente: $e');
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
      dlog('📎 Descargando adjunto: $fileName');
      dlog('   Mensaje ID: $messageId');
      dlog('   Adjunto ID: $attachmentId');

      // 1️⃣ Obtener la ruta de descarga
      // Android 10+: no se puede escribir en /Download sin permiso WRITE_EXTERNAL_STORAGE
      // (removido en Android 13+). Usamos el directorio privado de la app en
      // almacenamiento externo: /storage/emulated/0/Android/data/<package>/files/
      // No requiere ningún permiso y es accesible desde el administrador de archivos.
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        directory ??= await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('No se pudo obtener el directorio de descarga');
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = '${directory.path}/$fileName';
      dlog('💾 Ruta de descarga: $filePath');

      // 2️⃣ Descargar el archivo
      final url = '/mensajes/$messageId/adjuntos/$attachmentId';
      dlog('🌐 URL: $url');

      await _apiService.download(url, filePath);

      dlog('✅ Archivo descargado exitosamente en: $filePath');

      // 3️⃣ Retornar resultado exitoso
      return {
        'success': true,
        'message': 'Archivo descargado exitosamente',
        'path': filePath,
      };
    } catch (e) {
      dlog('❌ Error descargando adjunto: $e');
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
        dlog('📱 Archivo guardado correctamente');
      }
    } catch (e) {
      dlog('⚠️ Error: $e');
    }
  }

  // ========================================
  // 👥 OBTENER DESTINATARIOS DISPONIBLES
  // ========================================

  Future<List<User>> getAvailableRecipients() async {
    try {
      dlog('👥 Obteniendo destinatarios disponibles...');

      final response =
          await _apiService.get('/mensajes/destinatarios-disponibles');

      final data = response['data'] as List<dynamic>? ?? [];
      final recipients = data.map((json) => User.fromJson(json)).toList();

      dlog('✅ Destinatarios obtenidos: ${recipients.length}');
      return recipients;
    } catch (e) {
      dlog('❌ Error obteniendo destinatarios: $e');
      return [];
    }
  }

  // ========================================
  // 📚 OBTENER CURSOS DISPONIBLES
  // ========================================

  Future<List<Course>> getAvailableCourses() async {
    try {
      dlog('📚 Obteniendo cursos disponibles...');

      final response = await _apiService.get('/mensajes/cursos-disponibles');

      final data = response['data'] as List<dynamic>? ?? [];
      final courses = data.map((json) => Course.fromJson(json)).toList();

      dlog('✅ Cursos obtenidos: ${courses.length}');
      return courses;
    } catch (e) {
      dlog('❌ Error obteniendo cursos: $e');
      return [];
    }
  }
}
