// lib/main.dart
import 'utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/message_provider.dart';
import 'providers/anuncio_provider.dart';
import 'providers/calendario_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/curso_provider.dart';
import 'providers/asistencia_provider.dart'; // ✅ NUEVO IMPORT
import 'providers/tarea_provider.dart'; // ✅ NUEVO IMPORT
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => AnuncioProvider()),
        ChangeNotifierProvider(create: (_) => CalendarioProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => CursoProvider()),
        ChangeNotifierProvider(create: (_) => AsistenciaProvider()),
        ChangeNotifierProvider(create: (_) => TareaProvider()),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();

          return MaterialApp.router(
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
              Locale('es', 'ES'), // Español
              Locale('en', 'US'), // Inglés (fallback)
            ],
            locale: const Locale('es', 'ES'),

            // Configuración de GoRouter
            routerConfig: AppRoutes.createRouter(authProvider),
          );
        },
      ),
    );
  }
}
