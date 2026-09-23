// lib/main.dart
import 'utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/message_provider.dart';
import 'providers/anuncio_provider.dart';
import 'providers/calendario_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/curso_provider.dart';
import 'providers/asistencia_provider.dart';
import 'providers/tarea_provider.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (requerido antes de cualquier uso de firebase_messaging)
  await Firebase.initializeApp();

  // Registrar handler para mensajes recibidos con la app cerrada/background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inicializar formatos de fecha en español
  await initializeDateFormatting('es_ES', null);

  // Mostrar configuración
  AppConfig.printConfig();

  dlog('\n🧪 ===== VERIFICANDO SERVICIOS =====\n');

  // Test rápido de conectividad
  await _testBackendConnection();

  dlog('\n🚀 Iniciando aplicación...\n');

  runApp(const MyApp());
}

Future<void> _testBackendConnection() async {
  dlog('🌐 === TEST CONEXIÓN BACKEND ===');

  final isConnected = await apiService.checkConnection();
  dlog('📡 Backend disponible: $isConnected');

  if (!isConnected) {
    dlog('⚠️  Backend no disponible - Verifica que esté corriendo');
    dlog('⚠️  URL: ${AppConfig.baseUrl}');
  } else {
    dlog('✅ Backend conectado correctamente\n');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  // Providers creados aquí para poder limpiar su estado al cerrar sesión
  final _messageProvider = MessageProvider();
  final _anuncioProvider = AnuncioProvider();
  final _calendarioProvider = CalendarioProvider();
  final _usuarioProvider = UsuarioProvider();
  final _cursoProvider = CursoProvider();
  final _asistenciaProvider = AsistenciaProvider();
  final _tareaProvider = TareaProvider();

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRoutes.createRouter(_authProvider);

    // Al cerrar o expirar la sesión no deben quedar datos del usuario anterior
    _authProvider.onSessionCleared = () {
      _messageProvider.clearState();
      _anuncioProvider.clearState();
      _calendarioProvider.clearState();
      _usuarioProvider.clearState();
      _cursoProvider.clearState();
      _asistenciaProvider.clearState();
      _tareaProvider.clearState();
    };

    // Registrar callback de navegación para notificaciones push (se asigna una vez)
    // Primero va a home para que el bottom nav quede como base del stack,
    // luego empuja la pantalla de detalle encima.
    FcmService.instance.setNavigationCallback((route) {
      _router.go('/');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _router.push(route);
      });
    });
  }

  @override
  void dispose() {
    _router.dispose();
    _messageProvider.dispose();
    _anuncioProvider.dispose();
    _calendarioProvider.dispose();
    _usuarioProvider.dispose();
    _cursoProvider.dispose();
    _asistenciaProvider.dispose();
    _tareaProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _messageProvider),
        ChangeNotifierProvider.value(value: _anuncioProvider),
        ChangeNotifierProvider.value(value: _calendarioProvider),
        ChangeNotifierProvider.value(value: _usuarioProvider),
        ChangeNotifierProvider.value(value: _cursoProvider),
        ChangeNotifierProvider.value(value: _asistenciaProvider),
        ChangeNotifierProvider.value(value: _tareaProvider),
      ],
      child: MaterialApp.router(
        title: 'EducaNexo360',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // ✅ LOCALIZACIONES EN ESPAÑOL - CRÍTICO
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        locale: const Locale('es', 'ES'),

        routerConfig: _router,
      ),
    );
  }
}
