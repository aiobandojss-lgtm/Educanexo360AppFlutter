// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/message_provider.dart';
import 'providers/anuncio_provider.dart'; // ← NUEVO IMPORT
import 'services/storage_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formatos de fecha en español
  await initializeDateFormatting('es', null);

  // Mostrar configuración
  AppConfig.printConfig();

  print('\n🧪 ===== VERIFICANDO SERVICIOS =====\n');

  // Test rápido de conectividad
  await _testBackendConnection();

  print('\n🚀 Iniciando aplicación...\n');

  runApp(const MyApp());
}

Future<void> _testBackendConnection() async {
  print('🌐 === TEST CONEXIÓN BACKEND ===');

  final isConnected = await apiService.checkConnection();
  print('📡 Backend disponible: $isConnected');

  if (!isConnected) {
    print('⚠️  Backend no disponible - Verifica que esté corriendo');
    print('⚠️  URL: ${AppConfig.baseUrl}');
  } else {
    print('✅ Backend conectado correctamente\n');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ MultiProvider con todos los providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(
            create: (_) => AnuncioProvider()), // ← NUEVO PROVIDER
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();

          return MaterialApp.router(
            title: 'EducaNexo360',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,

            // Configuración de GoRouter
            routerConfig: AppRoutes.createRouter(authProvider),
          );
        },
      ),
    );
  }
}
