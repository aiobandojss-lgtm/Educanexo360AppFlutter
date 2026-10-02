// test/pantallas_pequenas_test.dart
// G2: las pantallas principales no se desbordan en un teléfono pequeño
// (360x640) con la fuente del sistema grande (130 %). Un overflow
// ("RenderFlex overflowed") o una excepción no capturada hace fallar la prueba.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:educanexo360_app/models/asistencia.dart';
import 'package:educanexo360_app/models/usuario.dart';
import 'package:educanexo360_app/providers/anuncio_provider.dart';
import 'package:educanexo360_app/providers/asistencia_provider.dart';
import 'package:educanexo360_app/providers/auth_provider.dart';
import 'package:educanexo360_app/providers/calendario_provider.dart';
import 'package:educanexo360_app/providers/curso_provider.dart';
import 'package:educanexo360_app/providers/message_provider.dart';
import 'package:educanexo360_app/providers/tarea_provider.dart';
import 'package:educanexo360_app/providers/usuario_provider.dart';
import 'package:educanexo360_app/screens/anuncios/anuncios_screen.dart';
import 'package:educanexo360_app/screens/anuncios/create_anuncio_screen.dart';
import 'package:educanexo360_app/screens/asistencia/lista_asistencia_screen.dart';
import 'package:educanexo360_app/screens/asistencia/registrar_asistencia_screen.dart';
import 'package:educanexo360_app/screens/auth/login_screen.dart';
import 'package:educanexo360_app/screens/calendario/calendario_screen.dart';
import 'package:educanexo360_app/screens/calendario/create_evento_screen.dart';
import 'package:educanexo360_app/screens/home/dashboard_screen.dart';
import 'package:educanexo360_app/screens/mensajes/create_message_screen.dart';
import 'package:educanexo360_app/screens/mensajes/messages_screen.dart';
import 'package:educanexo360_app/screens/perfil/perfil_screen.dart';
import 'package:educanexo360_app/screens/tareas/formulario_tarea_screen.dart';
import 'package:educanexo360_app/screens/tareas/lista_tareas_screen.dart';
import 'package:educanexo360_app/screens/tareas/mis_tareas_screen.dart';
import 'package:educanexo360_app/services/api_service.dart';
import 'package:educanexo360_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend simulado: listas vacías; preferencias de correo → 404 (oculta)
class _BackendVacio implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final status = options.path.contains('preferencias') ? 404 : 200;
    return ResponseBody.fromString(
      jsonEncode({
        'success': status == 200,
        'data': [],
        'meta': {'total': 0, 'pagina': 1, 'limite': 20, 'paginas': 1},
      }),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _montar(WidgetTester tester, Widget pantalla,
    {void Function(BuildContext context)? alMontar}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => pantalla),
    GoRoute(path: '/:resto(.*)', builder: (_, __) => const SizedBox()),
  ]);

  await tester.pumpWidget(MultiProvider(
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
    child: MaterialApp.router(
      routerConfig: router,
      // Fuente del sistema grande
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
    ),
  ));

  // Cargas iniciales (E/S simulada + reloj de la prueba)
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (alMontar != null) {
    alMontar(tester.element(find.byWidget(pantalla)));
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('es_ES'));

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      '@educanexo360_token': 't',
      '@educanexo360_refreshToken': 'r',
    });
    SharedPreferences.setMockInitialValues({});
    await StorageService.saveUser(Usuario.fromJson({
      '_id': 'u1',
      'nombre': 'María Fernanda',
      'apellidos': 'Rodríguez Castañeda',
      'email': 'maria.rodriguez@colegio.edu.co',
      'tipo': 'DOCENTE',
      'escuelaId': 'e1',
    }));
    ApiService().httpClientAdapter = _BackendVacio();
  });

  final pantallas = <String, Widget>{
    'Login': const LoginScreen(),
    'Inicio': const DashboardScreen(),
    'Mensajes': const MessagesScreen(),
    'Nuevo mensaje': const CreateMessageScreen(),
    'Anuncios': const AnunciosScreen(),
    'Nuevo anuncio': const CreateAnuncioScreen(),
    'Calendario': const CalendarioScreen(),
    'Nuevo evento': const CreateEventoScreen(),
    'Tareas (docente)': const ListaTareasScreen(),
    'Mis tareas': const MisTareasScreen(),
    'Nueva tarea': const FormularioTareaScreen(),
    'Asistencia': const ListaAsistenciaScreen(),
    'Perfil': const PerfilScreen(),
  };

  for (final entrada in pantallas.entries) {
    testWidgets('${entrada.key}: sin desborde en 360x640 con fuente grande',
        (tester) async {
      await _montar(tester, entrada.value);
    });
  }

  testWidgets(
      'Registrar asistencia con estudiantes: sin desborde en 360x640 '
      'con fuente grande (G2)', (tester) async {
    await _montar(
      tester,
      const RegistrarAsistenciaScreen(),
      alMontar: (context) {
        context.read<AsistenciaProvider>().establecerEstudiantes([
          for (var i = 0; i < 25; i++)
            EstudianteAsistencia(
              estudianteId: 's$i',
              nombre: 'Estudiante con nombre largo $i',
              apellidos: 'Apellido Compuesto',
              estado: i.isEven ? 'PRESENTE' : 'AUSENTE',
            ),
        ]);
      },
    );
    expect(find.text('Marcar todos como:'), findsOneWidget);
  });
}
