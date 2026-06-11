// lib/services/fcm_service.dart
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_service.dart';

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

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
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

  // Callback de navegación — se asigna desde main.dart
  void Function(String route)? _onNavigate;

  void setNavigationCallback(void Function(String route) callback) {
    _onNavigate = callback;
  }

  // ==========================================
  // INICIALIZACIÓN
  // ==========================================

  Future<void> initialize() async {
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
      _fcm.onTokenRefresh.listen(_onTokenRefresh);

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
      return await _fcm.getToken();
    } catch (e) {
      dlog('❌ [FCM] Error obteniendo token: $e');
      return null;
    }
  }

  Future<void> registerTokenToBackend() async {
    try {
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

  Future<void> clearTokenFromBackend() async {
    try {
      await apiService.post(
        AppConfig.notificacionesFcmToken,
        data: {'fcmToken': null},
      );
      dlog('✅ [FCM] Token eliminado del backend');
    } catch (e) {
      dlog('⚠️ [FCM] No se pudo eliminar token del backend: $e');
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
    // App en foreground → mostrar notificación local manualmente (FCM no lo hace)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App en background → tap abre la app (el mensaje ya fue mostrado por FCM)
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
