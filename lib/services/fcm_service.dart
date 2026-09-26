// lib/services/fcm_service.dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_service.dart';
import 'storage_service.dart';

// Handler que corre en un isolate separado (background/terminated)
// DEBE ser una función de nivel superior (no puede ser un método de clase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  dlog('🔔 [FCM-BG] Mensaje recibido en background: ${message.notification?.title}');
}

class FcmService {
  FcmService._internal();
  static final FcmService instance = FcmService._internal();

  // Getter (no campo): FirebaseMessaging.instance exige Firebase inicializado
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  // Dio aparte, sin interceptores, para desvincular el token en el logout: un
  // 401 aquí no debe disparar el refresh ni afectar la sesión de un usuario
  // que inicie sesión después. El token de la sesión que se cierra va por
  // petición.
  final Dio _unregisterDio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Solo para pruebas: adaptador HTTP del Dio de desvinculación.
  @visibleForTesting
  set unregisterHttpClientAdapter(HttpClientAdapter adapter) =>
      _unregisterDio.httpClientAdapter = adapter;

  /// Solo para pruebas: reemplaza la obtención del token FCM.
  @visibleForTesting
  Future<String?> Function()? debugTokenOverride;

  /// Solo para pruebas: desvinculación en curso.
  @visibleForTesting
  Future<void>? get pendingUnregister => _pendingUnregister;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal Android — debe coincidir con el configurado en el backend
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'educanexo360_messages',
    'EducaNexo360',
    description: 'Notificaciones de la plataforma educativa EducaNexo360',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Se inicializa una sola vez por ejecución de la app (login y restauración
  // de sesión la llaman varias veces): evita listeners y notificaciones duplicados
  bool _initialized = false;
  Future<void>? _initializing;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  // deleteToken() en curso de un logout; el siguiente registro lo espera para
  // no invalidar el token recién obtenido por el nuevo usuario
  Future<void>? _pendingUnregister;

  // Límite de espera para llamadas a Firebase (red débil)
  static const Duration _firebaseTimeout = Duration(seconds: 10);

  // Callback de navegación — se asigna desde main.dart
  void Function(String route)? _onNavigate;

  void setNavigationCallback(void Function(String route) callback) {
    _onNavigate = callback;
  }

  // ==========================================
  // INICIALIZACIÓN
  // ==========================================

  Future<void> initialize() {
    if (_initialized) {
      dlog('🔔 [FCM] Ya inicializado, se omite');
      return Future.value();
    }
    // Si ya hay una inicialización en curso, esperar esa misma
    return _initializing ??=
        _initialize().whenComplete(() => _initializing = null);
  }

  Future<void> _initialize() async {
    try {
      dlog('🔔 [FCM] Inicializando...');

      // Solicitar permisos (iOS requiere esto explícitamente)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      dlog('🔔 [FCM] Permiso: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        dlog('⚠️ [FCM] Permiso denegado por el usuario');
        return;
      }

      // Crear canal de notificaciones en Android
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // Inicializar flutter_local_notifications
      const initSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsIOS,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );

      // Configurar handlers de mensajes
      _setupMessageHandlers();

      // Obtener el token FCM para depuración
      final token = await getToken();
      dlog('🔔 [FCM] Token obtenido: ${token?.substring(0, 30)}...');

      // Escuchar renovaciones de token
      await _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = _fcm.onTokenRefresh.listen(_onTokenRefresh);

      _initialized = true;
      dlog('✅ [FCM] Inicialización completa');
    } catch (e) {
      // FCM puede fallar si google-services.json no está → no romper la app
      dlog('❌ [FCM] Error en inicialización (app sigue funcionando): $e');
    }
  }

  // ==========================================
  // TOKEN
  // ==========================================

  Future<String?> getToken() async {
    try {
      final override = debugTokenOverride;
      if (override != null) return await override();
      return await _fcm.getToken().timeout(_firebaseTimeout);
    } catch (e) {
      dlog('❌ [FCM] Error obteniendo token: $e');
      return null;
    }
  }

  Future<void> registerTokenToBackend() async {
    try {
      // Esperar a que termine la desvinculación de un logout anterior
      final pending = _pendingUnregister;
      if (pending != null) {
        await pending.timeout(_firebaseTimeout, onTimeout: () {
          dlog('⚠️ [FCM] deleteToken tardó demasiado, se continúa');
        });
      }

      // Sin sesión no se registra (un onTokenRefresh tras el logout
      // provocaría un 401 y el flujo de renovación de token)
      if (await StorageService.getToken() == null) {
        dlog('⚠️ [FCM] Sin sesión activa, no se registra el token');
        return;
      }

      final token = await getToken();
      if (token == null) return;

      final platform = Platform.isAndroid ? 'android' : 'ios';

      await apiService.post(
        AppConfig.notificacionesFcmToken,
        data: {
          'fcmToken': token,
          'platform': platform,
          'deviceInfo': {
            'platform': platform,
            'version': Platform.operatingSystemVersion,
          },
        },
      );

      dlog('✅ [FCM] Token registrado en backend ($platform)');
    } catch (e) {
      // No crítico: la app funciona sin push, no propagar el error
      dlog('⚠️ [FCM] No se pudo registrar token en backend: $e');
    }
  }

  /// Desvincula este dispositivo al cerrar sesión.
  /// Invalida el token FCM local (deleteToken): el backend ya no podrá enviar
  /// push del usuario anterior a este dispositivo. El siguiente login obtiene y
  /// registra un token nuevo. [accessToken] es el token de la sesión que se
  /// cierra, capturado antes de limpiar el almacenamiento.
  Future<void> unregisterDevice({String? accessToken}) {
    // Se asigna de forma síncrona para que un login inmediato lo espere
    return _pendingUnregister = _unregisterDevice(accessToken);
  }

  Future<void> _unregisterDevice(String? accessToken) async {
    if (AppConfig.fcmUnregisterEnabled && accessToken != null) {
      try {
        final token = await getToken();
        // Sin token FCM no hay nada que desvincular (el backend responde 400)
        if (token != null) {
          final response = await _unregisterDio.post(
            AppConfig.notificacionesFcmUnregister,
            data: {'fcmToken': token},
            options: Options(
              headers: {'Authorization': 'Bearer $accessToken'},
            ),
          );
          dlog('✅ [FCM] Token desvinculado en backend: '
              '${response.data is Map ? response.data['data'] : ''}');
        }
      } catch (e) {
        dlog('⚠️ [FCM] No se pudo desvincular el token en backend: $e');
      }
    }

    try {
      await _fcm.deleteToken().timeout(_firebaseTimeout);
      dlog('✅ [FCM] Token del dispositivo invalidado');
    } catch (e) {
      dlog('⚠️ [FCM] No se pudo invalidar el token del dispositivo: $e');
    }
  }

  void _onTokenRefresh(String newToken) {
    dlog('🔄 [FCM] Token renovado, registrando...');
    registerTokenToBackend();
  }

  // ==========================================
  // HANDLERS DE MENSAJES
  // ==========================================

  void _setupMessageHandlers() {
    // Cancelar suscripciones previas para no duplicar handlers
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();

    // App en foreground → mostrar notificación local manualmente (FCM no lo hace)
    _onMessageSub =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App en background → tap abre la app (el mensaje ya fue mostrado por FCM)
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App terminada → recuperar el mensaje que abrió la app
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        dlog('🔔 [FCM] App abierta desde notificación (terminated): ${message.notification?.title}');
        // Pequeño delay para que la navegación esté lista
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(message);
        });
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    dlog('🔔 [FCM] Mensaje en foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Mostrar notificación local mientras la app está abierta
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF059669),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Guardamos el payload para navegar al hacer tap
      payload: _buildPayload(message.data),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final route = _routeFromPayload(payload);
      if (route != null) _navigate(route);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    dlog('🔔 [FCM] Tap en notificación: ${message.notification?.title}');
    final route = _routeFromData(message.data);
    if (route != null) _navigate(route);
  }

  // ==========================================
  // DEEP LINKING
  // ==========================================

  String? _routeFromData(Map<String, dynamic> data) {
    final tipo = data['tipo'] as String?;
    if (tipo == null) return null;

    switch (tipo) {
      case 'mensaje':
        final id = data['mensajeId'] ?? data['entidadId'];
        if (id != null) return '/mensajes/$id';
        return '/mensajes';
      case 'tarea':
        final id = data['tareaId'] ?? data['entidadId'];
        if (id != null) return '/tareas/$id';
        return '/tareas';
      case 'anuncio':
        final id = data['anuncioId'] ?? data['entidadId'];
        if (id != null) return '/anuncios/$id';
        return '/anuncios';
      case 'evento':
        return '/calendario';
      case 'ausencia':
        return '/asistencia';
      case 'calificacion':
        return '/calificaciones';
      default:
        return null;
    }
  }

  String _buildPayload(Map<String, dynamic> data) {
    final tipo = data['tipo'] ?? '';
    final entidadId = data['mensajeId'] ??
        data['tareaId'] ??
        data['anuncioId'] ??
        data['entidadId'] ??
        '';
    return '$tipo:$entidadId';
  }

  String? _routeFromPayload(String payload) {
    final parts = payload.split(':');
    if (parts.isEmpty) return null;
    final tipo = parts[0];
    final id = parts.length > 1 ? parts[1] : '';

    return _routeFromData({
      'tipo': tipo,
      'entidadId': id,
      '${tipo}Id': id,
    });
  }

  void _navigate(String route) {
    if (_onNavigate != null) {
      dlog('🔔 [FCM] Navegando a: $route');
      _onNavigate!(route);
    } else {
      dlog('⚠️ [FCM] No hay callback de navegación registrado, ignorando: $route');
    }
  }
}
