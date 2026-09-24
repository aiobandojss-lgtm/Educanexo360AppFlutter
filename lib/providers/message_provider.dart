// lib/providers/message_provider.dart

import '../utils/logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/message_service.dart';

/// 🎯 EVENT BUS PARA SINCRONIZACIÓN
/// Permite comunicación entre pantallas sin dependencias directas
class MessageEventBus {
  static final MessageEventBus _instance = MessageEventBus._internal();
  factory MessageEventBus() => _instance;
  MessageEventBus._internal();

  final _messageCreatedController = StreamController<void>.broadcast();
  final _draftSavedController = StreamController<void>.broadcast();
  final _messageDeletedController = StreamController<void>.broadcast();
  final _messageArchivedController = StreamController<void>.broadcast();
  final _messageRestoredController = StreamController<void>.broadcast();

  Stream<void> get onMessageCreated => _messageCreatedController.stream;
  Stream<void> get onDraftSaved => _draftSavedController.stream;
  Stream<void> get onMessageDeleted => _messageDeletedController.stream;
  Stream<void> get onMessageArchived => _messageArchivedController.stream;
  Stream<void> get onMessageRestored => _messageRestoredController.stream;

  void notifyMessageCreated() => _messageCreatedController.add(null);
  void notifyDraftSaved() => _draftSavedController.add(null);
  void notifyMessageDeleted() => _messageDeletedController.add(null);
  void notifyMessageArchived() => _messageArchivedController.add(null);
  void notifyMessageRestored() => _messageRestoredController.add(null);

  void dispose() {
    _messageCreatedController.close();
    _draftSavedController.close();
    _messageDeletedController.close();
    _messageArchivedController.close();
    _messageRestoredController.close();
  }
}

/// 📨 PROVIDER DE MENSAJERÍA
/// Maneja estado, operaciones y sincronización entre pantallas
class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  final MessageEventBus _eventBus = MessageEventBus();

  // ========================================
  // 📊 ESTADO
  // ========================================

  // Mensajes por bandeja
  final Map<Bandeja, List<Message>> _messagesByBandeja = {
    Bandeja.recibidos: [],
    Bandeja.enviados: [],
    Bandeja.borradores: [],
    Bandeja.archivados: [],
    Bandeja.eliminados: [],
  };

  // Metadata de paginación por bandeja
  final Map<Bandeja, Map<String, dynamic>> _metaByBandeja = {
    Bandeja.recibidos: {
      'total': 0,
      'pagina': 1,
      'limite': 20,
      'totalPaginas': 1
    },
    Bandeja.enviados: {
      'total': 0,
      'pagina': 1,
      'limite': 20,
      'totalPaginas': 1
    },
    Bandeja.borradores: {
      'total': 0,
      'pagina': 1,
      'limite': 20,
      'totalPaginas': 1
    },
    Bandeja.archivados: {
      'total': 0,
      'pagina': 1,
      'limite': 20,
      'totalPaginas': 1
    },
    Bandeja.eliminados: {
      'total': 0,
      'pagina': 1,
      'limite': 20,
      'totalPaginas': 1
    },
  };

  // Estados de loading por bandeja
  final Map<Bandeja, bool> _loadingByBandeja = {
    Bandeja.recibidos: false,
    Bandeja.enviados: false,
    Bandeja.borradores: false,
    Bandeja.archivados: false,
    Bandeja.eliminados: false,
  };

  // Bandeja actual
  Bandeja _currentBandeja = Bandeja.recibidos;

  // Búsqueda
  String _searchQuery = '';

  // Destinatarios y cursos disponibles
  List<User> _availableRecipients = [];
  List<Course> _availableCourses = [];

  // ========================================
  // 🔍 GETTERS
  // ========================================

  List<Message> get currentMessages =>
      _messagesByBandeja[_currentBandeja] ?? [];
  Map<String, dynamic> get currentMeta => _metaByBandeja[_currentBandeja] ?? {};
  bool get isLoading => _loadingByBandeja[_currentBandeja] ?? false;
  Bandeja get currentBandeja => _currentBandeja;
  String get searchQuery => _searchQuery;
  List<User> get availableRecipients => _availableRecipients;
  List<Course> get availableCourses => _availableCourses;

  // Getters por bandeja específica
  List<Message> getMessagesForBandeja(Bandeja bandeja) =>
      _messagesByBandeja[bandeja] ?? [];
  int getTotalForBandeja(Bandeja bandeja) =>
      _metaByBandeja[bandeja]?['total'] ?? 0;

  // Contador de no leídos
  int get unreadCount {
    return _messagesByBandeja[Bandeja.recibidos]
            ?.where((msg) =>
                !msg.isReadByUser('current_user_id')) // TODO: Usar user real
            .length ??
        0;
  }

  // ========================================
  // 🎯 INICIALIZACIÓN Y EVENT BUS
  // ========================================

  MessageProvider() {
    _setupEventBusListeners();
  }

  void _setupEventBusListeners() {
    // Cuando se crea un mensaje, refrescar ENVIADOS y RECIBIDOS
    _eventBus.onMessageCreated.listen((_) {
      dlog('🔔 Event: Mensaje creado - Refrescando bandejas');
      loadMessages(Bandeja.enviados, refresh: true, silent: true);
      loadMessages(Bandeja.recibidos, refresh: true, silent: true);
    });

    // Cuando se guarda un borrador, refrescar BORRADORES
    _eventBus.onDraftSaved.listen((_) {
      dlog('🔔 Event: Borrador guardado - Refrescando borradores');
      loadMessages(Bandeja.borradores, refresh: true, silent: true);
    });

    // Cuando se elimina un mensaje, refrescar bandeja actual y ELIMINADOS
    _eventBus.onMessageDeleted.listen((_) {
      dlog('🔔 Event: Mensaje eliminado - Refrescando bandejas');
      loadMessages(_currentBandeja, refresh: true, silent: true);
      loadMessages(Bandeja.eliminados, refresh: true, silent: true);
    });

    // Cuando se archiva, refrescar RECIBIDOS y ARCHIVADOS
    _eventBus.onMessageArchived.listen((_) {
      dlog('🔔 Event: Mensaje archivado - Refrescando bandejas');
      loadMessages(Bandeja.recibidos, refresh: true, silent: true);
      loadMessages(Bandeja.archivados, refresh: true, silent: true);
    });

    // Cuando se restaura, refrescar ELIMINADOS y bandeja destino
    _eventBus.onMessageRestored.listen((_) {
      dlog('🔔 Event: Mensaje restaurado - Refrescando bandejas');
      loadMessages(Bandeja.eliminados, refresh: true, silent: true);
      loadMessages(Bandeja.recibidos, refresh: true, silent: true);
    });
  }

  // ========================================
  // ⚡ PREPARAR ESTADO DE CARGA (para initState)
  // ========================================

  void prepareLoading() {
    _loadingByBandeja[_currentBandeja] = true;
  }

  // ========================================
  // 📬 CARGAR MENSAJES
  // ========================================

  Future<void> loadMessages(
    Bandeja bandeja, {
    int page = 1,
    bool refresh = false,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        _loadingByBandeja[bandeja] = true;
        notifyListeners();
      }

      final result = await _messageService.getMessages(
        bandeja: bandeja,
        page: page,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (refresh || page == 1) {
        _messagesByBandeja[bandeja] = result['messages'];
      } else {
        // Paginación: agregar mensajes nuevos
        final currentMessages = _messagesByBandeja[bandeja] ?? [];
        _messagesByBandeja[bandeja] = [
          ...currentMessages,
          ...result['messages']
        ];
      }

      _metaByBandeja[bandeja] = result['meta'];

      _loadingByBandeja[bandeja] = false;
      notifyListeners();
    } catch (e) {
      dlog('❌ Error cargando mensajes: $e');
      _loadingByBandeja[bandeja] = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 🔄 CAMBIAR BANDEJA
  // ========================================

  Future<void> changeBandeja(Bandeja newBandeja) async {
    if (_currentBandeja == newBandeja) return;

    _currentBandeja = newBandeja;
    _searchQuery = '';
    notifyListeners();

    // Siempre refrescar al cambiar bandeja para mostrar cambios recientes.
    // Si ya hay datos: recargar en silencio (sin spinner) para no interrumpir.
    final hasData = (_messagesByBandeja[newBandeja] ?? []).isNotEmpty;
    await loadMessages(newBandeja, refresh: true, silent: hasData);
  }

  // ========================================
  // 🔍 BÚSQUEDA
  // ========================================

  Future<void> search(String query) async {
    _searchQuery = query;
    notifyListeners();
    await loadMessages(_currentBandeja, refresh: true);
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      loadMessages(_currentBandeja, refresh: true);
    }
  }

  // ========================================
  // ✉️ CREAR MENSAJE
  // ========================================

  Future<Message> createMessage({
    List<String>? destinatarios,
    List<String>? cursoIds,
    required String asunto,
    required String contenido,
    Prioridad prioridad = Prioridad.normal,
    List<File>? adjuntos,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final message = await _messageService.createMessage(
        destinatarios: destinatarios,
        cursoIds: cursoIds,
        asunto: asunto,
        contenido: contenido,
        prioridad: prioridad,
        adjuntos: adjuntos,
        onSendProgress: onSendProgress,
      );

      // Notificar evento
      _eventBus.notifyMessageCreated();

      return message;
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
      final draft = await _messageService.saveDraft(
        destinatarios: destinatarios,
        cursoIds: cursoIds,
        asunto: asunto,
        contenido: contenido,
        prioridad: prioridad,
        adjuntos: adjuntos,
      );

      await loadMessages(Bandeja.borradores, refresh: true, silent: true);

      // Notificar evento
      _eventBus.notifyDraftSaved();

      return draft;
    } catch (e) {
      dlog('❌ Error guardando borrador: $e');
      rethrow;
    }
  }

  /// 📤 ENVIAR BORRADOR (NUEVO)
  Future<Message> sendDraft(String draftId) async {
    try {
      dlog('📤 Enviando borrador: $draftId');

      final message = await _messageService.sendDraft(draftId);

      // Limpiar borrador de la lista
      _messagesByBandeja[Bandeja.borradores]
          ?.removeWhere((m) => m.id == draftId);

      // Notificar evento
      _eventBus.notifyMessageCreated();

      // Recargar bandejas
      await loadMessages(Bandeja.borradores, refresh: true);
      await loadMessages(Bandeja.enviados, refresh: true);

      dlog('✅ Borrador enviado correctamente');

      return message;
    } catch (e) {
      dlog('❌ Error enviando borrador: $e');
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
      final draft = await _messageService.updateDraft(
        draftId: draftId,
        destinatarios: destinatarios,
        cursoIds: cursoIds,
        asunto: asunto,
        contenido: contenido,
        prioridad: prioridad,
        adjuntos: adjuntos,
        clearExistingAttachments: clearExistingAttachments,
      );

      // Notificar evento
      _eventBus.notifyDraftSaved();

      return draft;
    } catch (e) {
      dlog('❌ Error actualizando borrador: $e');
      rethrow;
    }
  }

  // ========================================
  // 🚀 ENVIAR BORRADOR
  // ========================================

  /* Future<Message> sendDraft(String draftId) async {
    try {
      final message = await _messageService.sendDraft(draftId);

      // Notificar evento (elimina de borradores, agrega a enviados)
      _eventBus.notifyMessageCreated();
      _eventBus.notifyDraftSaved();

      return message;
    } catch (e) {
      dlog('❌ Error enviando borrador: $e');
      rethrow;
    }
  }*/

  // ========================================
  // 💬 RESPONDER MENSAJE
  // ========================================

  Future<Message> replyMessage({
    required String originalId,
    required String contenido,
    String? asunto,
    List<File>? adjuntos,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final message = await _messageService.replyMessage(
        originalId: originalId,
        contenido: contenido,
        asunto: asunto,
        adjuntos: adjuntos,
        onSendProgress: onSendProgress,
      );

      // Notificar evento
      _eventBus.notifyMessageCreated();

      return message;
    } catch (e) {
      dlog('❌ Error respondiendo mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 🗂️ ARCHIVAR MENSAJE
  // ========================================

  Future<void> archiveMessage(String messageId) async {
    try {
      // Optimistic update
      _removeMessageFromCurrentBandeja(messageId);

      await _messageService.archiveMessage(messageId);

      // Notificar evento
      _eventBus.notifyMessageArchived();
    } catch (e) {
      dlog('❌ Error archivando: $e');
      // Recargar en caso de error
      await loadMessages(_currentBandeja, refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 📤 DESARCHIVAR MENSAJE
  // ========================================

  Future<void> unarchiveMessage(String messageId) async {
    try {
      // Optimistic update
      _removeMessageFromCurrentBandeja(messageId);

      await _messageService.unarchiveMessage(messageId);

      // Notificar evento
      _eventBus.notifyMessageArchived();
    } catch (e) {
      dlog('❌ Error desarchivando: $e');
      await loadMessages(_currentBandeja, refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR MENSAJE (papelera)
  // ========================================

  Future<void> deleteMessage(String messageId) async {
    try {
      // Optimistic update
      _removeMessageFromCurrentBandeja(messageId);

      await _messageService.deleteMessage(messageId);

      // Notificar evento
      _eventBus.notifyMessageDeleted();
    } catch (e) {
      dlog('❌ Error eliminando: $e');
      await loadMessages(_currentBandeja, refresh: true);
      rethrow;
    }
  }

  // ========================================
  // ♻️ RESTAURAR MENSAJE
  // ========================================

  Future<void> restoreMessage(String messageId) async {
    try {
      dlog('🔄 Restaurando mensaje: $messageId');

      await _messageService.restoreMessage(messageId);

      // ✅ SOLUCIÓN: Forzar recarga completa de AMBAS bandejas
      // Esto evita que el mensaje quede duplicado
      dlog('📥 Recargando bandeja de eliminados...');
      await loadMessages(Bandeja.eliminados, refresh: true);

      dlog('📥 Recargando bandeja de recibidos...');
      await loadMessages(Bandeja.recibidos, refresh: true);

      // Notificar evento
      _eventBus.notifyMessageRestored();

      dlog('✅ Mensaje restaurado correctamente');
    } catch (e) {
      dlog('❌ Error restaurando mensaje: $e');
      rethrow;
    }
  }

  // ========================================
  // 💥 ELIMINAR DEFINITIVAMENTE
  // ========================================

  Future<void> deletePermanently(String messageId) async {
    try {
      // Optimistic update
      _removeMessageFromCurrentBandeja(messageId);

      await _messageService.deletePermanently(messageId);

      // No notificar evento, solo afecta bandeja actual
    } catch (e) {
      dlog('❌ Error eliminando permanentemente: $e');
      await loadMessages(_currentBandeja, refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 🗑️ ELIMINAR BORRADOR
  // ========================================

  Future<void> deleteDraft(String draftId) async {
    try {
      // Optimistic update
      _removeMessageFromCurrentBandeja(draftId);

      await _messageService.deleteDraft(draftId);

      // Notificar evento
      _eventBus.notifyDraftSaved();
    } catch (e) {
      dlog('❌ Error eliminando borrador: $e');
      await loadMessages(_currentBandeja, refresh: true);
      rethrow;
    }
  }

  // ========================================
  // 📎 CARGAR DESTINATARIOS Y CURSOS
  // ========================================

  Future<void> loadRecipientsAndCourses() async {
    try {
      final results = await Future.wait([
        _messageService.getAvailableRecipients(),
        _messageService.getAvailableCourses(),
      ]);

      _availableRecipients = results[0] as List<User>;
      _availableCourses = results[1] as List<Course>;

      notifyListeners();
    } catch (e) {
      dlog('❌ Error cargando destinatarios/cursos: $e');
    }
  }

  // ========================================
  // 🔧 HELPERS PRIVADOS
  // ========================================

  void _removeMessageFromCurrentBandeja(String messageId) {
    final messages = _messagesByBandeja[_currentBandeja] ?? [];
    _messagesByBandeja[_currentBandeja] =
        messages.where((m) => m.id != messageId).toList();
    notifyListeners();
  }

  // ========================================
  // 🧹 LIMPIAR ESTADO (logout / cambio de cuenta)
  // ========================================

  void clearState() {
    dlog('🧹 Limpiando estado del provider de mensajes');
    for (final bandeja in Bandeja.values) {
      _messagesByBandeja[bandeja] = [];
      _metaByBandeja[bandeja] = {
        'total': 0,
        'pagina': 1,
        'limite': 20,
        'totalPaginas': 1
      };
      _loadingByBandeja[bandeja] = false;
    }
    _currentBandeja = Bandeja.recibidos;
    _searchQuery = '';
    _availableRecipients = [];
    _availableCourses = [];
    notifyListeners();
  }

  // ========================================
  // 🧹 CLEANUP
  // ========================================

  @override
  void dispose() {
    // No cerrar el event bus aquí porque es singleton
    super.dispose();
  }
}
