// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../widgets/common/main_bottom_navigation.dart';
import '../screens/perfil/perfil_screen.dart';
import '../screens/mensajes/messages_screen.dart';
import '../screens/mensajes/message_detail_screen.dart';
import '../screens/mensajes/create_message_screen.dart';
import '../screens/anuncios/anuncios_screen.dart';
import '../screens/anuncios/anuncio_detail_screen.dart';
import '../screens/anuncios/create_anuncio_screen.dart';
import '../models/anuncio.dart';
import '../screens/calendario/calendario_screen.dart';
import '../screens/usuarios/users_management_screen.dart';
import '../screens/usuarios/user_detail_screen.dart';
import '../screens/usuarios/edit_user_screen.dart';
import '../screens/usuarios/manage_students_screen.dart';
import '../screens/cursos/courses_screen.dart';
import '../screens/cursos/course_detail_screen.dart';
import '../screens/asistencia/lista_asistencia_screen.dart';
import '../screens/asistencia/registrar_asistencia_screen.dart';
import '../screens/asistencia/detalle_asistencia_screen.dart';
// Imports de TAREAS
import '../screens/tareas/mis_tareas_screen.dart';
import '../screens/tareas/detalle_tarea_screen.dart';
import '../screens/tareas/entregar_tarea_screen.dart';
import '../screens/tareas/lista_tareas_screen.dart';
import '../screens/tareas/formulario_tarea_screen.dart';
import '../screens/tareas/lista_entregas_screen.dart';
import '../screens/tareas/calificar_entrega_screen.dart';
import '../models/tarea.dart';
import '../screens/tareas/tareas_wrapper.dart';

/// ConfiguraciÃ³n de rutas de la aplicaciÃ³n con GoRouter
class AppRoutes {
  // Nombres de rutas
  static const String login = '/login';
  static const String home = '/'; // Nueva ruta principal
  static const String mensajes = '/mensajes';
  static const String calificaciones = '/calificaciones';
  static const String calendario = '/calendario';
  static const String asistencia = '/asistencia';
  static const String anuncios = '/anuncios';
  static const String perfil = '/perfil';
  static const String usuarios = '/usuarios';
  static const String cursos = '/cursos';
  static const String tareas = '/tareas';

  /// Crear configuraciÃ³n de GoRouter
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: login,
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == login;

        print('ðŸ”€ Router: Redireccionando...');
        print('   Autenticado: $isAuthenticated');
        print('   UbicaciÃ³n: ${state.matchedLocation}');

        if (!isAuthenticated && !isLoggingIn) {
          print('   â†’ Redirigiendo a LOGIN');
          return login;
        }

        if (isAuthenticated && isLoggingIn) {
          print('   â†’ Redirigiendo a HOME');
          return home;
        }

        return null;
      },
      routes: [
        // ==================== AUTH ====================
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),

        // ==================== HOME (MainBottomNavigation) ====================
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const MainBottomNavigation(),
        ),

        // ==================== MENSAJES ====================
        GoRoute(
          path: mensajes,
          name: 'mensajes',
          builder: (context, state) => const MessagesScreen(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'message-create',
              builder: (context, state) => const CreateMessageScreen(),
            ),
            GoRoute(
              path: ':messageId',
              name: 'message-detail',
              builder: (context, state) {
                final messageId = state.pathParameters['messageId']!;
                return MessageDetailScreen(messageId: messageId);
              },
            ),
          ],
        ),

        // ==================== ANUNCIOS ====================
        GoRoute(
          path: anuncios,
          name: 'anuncios',
          builder: (context, state) => const AnunciosScreen(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'anuncio-create',
              builder: (context, state) {
                final anuncio = state.extra as Anuncio?;
                return CreateAnuncioScreen(anuncio: anuncio);
              },
            ),
            GoRoute(
              path: ':anuncioId',
              name: 'anuncio-detail',
              builder: (context, state) {
                final anuncioId = state.pathParameters['anuncioId']!;
                return AnuncioDetailScreen(anuncioId: anuncioId);
              },
            ),
          ],
        ),

        // ==================== CALIFICACIONES ====================
        GoRoute(
          path: calificaciones,
          name: 'calificaciones',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Calificaciones - PrÃ³ximamente')),
          ),
        ),

        // ==================== CALENDARIO ====================
        GoRoute(
          path: calendario,
          name: 'calendario',
          builder: (context, state) => const CalendarioScreen(),
        ),

        // ==================== ASISTENCIA ====================
        GoRoute(
          path: asistencia,
          name: 'asistencia',
          builder: (context, state) => const ListaAsistenciaScreen(),
          routes: [
            GoRoute(
              path: 'registrar',
              name: 'asistencia-registrar',
              builder: (context, state) => const RegistrarAsistenciaScreen(),
            ),
            GoRoute(
              path: 'editar/:asistenciaId',
              name: 'asistencia-editar',
              builder: (context, state) {
                final asistenciaId = state.pathParameters['asistenciaId']!;
                return RegistrarAsistenciaScreen(
                  asistenciaId: asistenciaId,
                  isEditMode: true,
                );
              },
            ),
            GoRoute(
              path: ':asistenciaId',
              name: 'asistencia-detail',
              builder: (context, state) {
                final asistenciaId = state.pathParameters['asistenciaId']!;
                return DetalleAsistenciaScreen(asistenciaId: asistenciaId);
              },
            ),
          ],
        ),

        // ==================== PERFIL ====================
        GoRoute(
          path: perfil,
          name: 'perfil',
          builder: (context, state) => const PerfilScreen(),
        ),

        // ==================== USUARIOS ====================
        GoRoute(
          path: usuarios,
          name: 'usuarios',
          builder: (context, state) => const UsersManagementScreen(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'usuario-create',
              builder: (context, state) => const EditUserScreen(),
            ),
            GoRoute(
              path: ':userId',
              name: 'usuario-detail',
              builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return UserDetailScreen(userId: userId);
              },
            ),
            GoRoute(
              path: 'edit/:userId',
              name: 'usuario-edit',
              builder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return EditUserScreen(userId: userId);
              },
            ),
            GoRoute(
              path: 'manage-students/:acudienteId',
              name: 'manage-students',
              pageBuilder: (context, state) {
                final acudienteId = state.pathParameters['acudienteId']!;
                return NoTransitionPage(
                  child: ManageStudentsScreen(acudienteId: acudienteId),
                );
              },
            ),
          ],
        ),

        // ==================== CURSOS ====================
        GoRoute(
          path: cursos,
          name: 'cursos',
          builder: (context, state) => const CoursesScreen(),
          routes: [
            GoRoute(
              path: ':cursoId',
              name: 'curso-detail',
              builder: (context, state) {
                final cursoId = state.pathParameters['cursoId']!;
                return CourseDetailScreen(cursoId: cursoId);
              },
            ),
          ],
        ),

        // ==================== TAREAS ====================
        GoRoute(
          path: tareas,
          name: 'tareas',
          builder: (context, state) {
            return const TareasWrapper();
          },
          routes: [
            // Crear nueva tarea (docentes)
            GoRoute(
              path: 'crear',
              name: 'tarea-crear',
              builder: (context, state) => const FormularioTareaScreen(),
            ),
            // Editar tarea (docentes)
            GoRoute(
              path: 'editar/:tareaId',
              name: 'tarea-editar',
              builder: (context, state) {
                final tareaId = state.pathParameters['tareaId']!;
                return FormularioTareaScreen(tareaId: tareaId);
              },
            ),
            // Detalle de tarea
            GoRoute(
              path: ':tareaId',
              name: 'tarea-detalle',
              builder: (context, state) {
                final tareaId = state.pathParameters['tareaId']!;
                return DetalleTareaScreen(tareaId: tareaId);
              },
            ),
            // Entregar tarea (estudiantes)
            GoRoute(
              path: ':tareaId/entregar',
              name: 'tarea-entregar',
              builder: (context, state) {
                final tareaId = state.pathParameters['tareaId']!;
                return EntregarTareaScreen(tareaId: tareaId);
              },
            ),
            // Ver entregas de una tarea (docentes)
            GoRoute(
              path: ':tareaId/entregas',
              name: 'tarea-entregas',
              builder: (context, state) {
                final tareaId = state.pathParameters['tareaId']!;
                return ListaEntregasScreen(tareaId: tareaId);
              },
            ),
            // Calificar una entrega especÃ­fica (docentes)
            GoRoute(
              path: ':tareaId/entregas/:entregaId',
              name: 'tarea-calificar',
              builder: (context, state) {
                final tareaId = state.pathParameters['tareaId']!;
                final entregaId = state.pathParameters['entregaId']!;
                return CalificarEntregaScreen(
                  tareaId: tareaId,
                  entregaId: entregaId,
                );
              },
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'PÃ¡gina no encontrada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ruta: ${state.matchedLocation}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(home),
                child: const Text('Ir al Inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper para navegar con reemplazo de stack
  static void navigateAndRemoveUntil(BuildContext context, String route) {
    while (context.canPop()) {
      context.pop();
    }
    context.go(route);
  }
}
