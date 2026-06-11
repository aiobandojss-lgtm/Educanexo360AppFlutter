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

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRoutes.createRouter(_authProvider);

    // Registrar callback de navegación para notificaciones push (se asigna una vez)
    FcmService.instance.setNavigationCallback((route) {
      _router.go(route);
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => AnuncioProvider()),
        ChangeNotifierProvider(create: (_) => CalendarioProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => CursoProvider()),
        ChangeNotifierProvider(create: (_) => AsistenciaProvider()),
        ChangeNotifierProvider(create: (_) => TareaProvider()),
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
