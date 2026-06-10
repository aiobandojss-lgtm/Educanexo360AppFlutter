// lib/screens/tareas/tareas_wrapper.dart
import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'mis_tareas_screen.dart';
import 'lista_tareas_screen.dart';
import 'selector_hijo_screen.dart';

/// Wrapper que decide qué pantalla de tareas mostrar según el rol
class TareasWrapper extends StatelessWidget {
  const TareasWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.currentUser;

    // Si no hay usuario, mostrar loading
    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ CORRECTO: usar .value en lugar de .toString().split('.').last
    final tipoUsuario = usuario.tipo.value;

    dlog('=====================================');
    dlog('🔍 TareasWrapper');
    dlog('Usuario: ${usuario.nombreCompleto}');
    dlog('Tipo: "$tipoUsuario"');
    dlog('=====================================');

    // Roles que gestionan tareas (pueden ver la lista de tareas del colegio)
    // RECTOR puede ver todas las tareas pero sin botón de crear
    // COORDINADOR puede crear tareas igual que DOCENTE
    final esGestorTareas = tipoUsuario == 'SUPER_ADMIN' ||
        tipoUsuario == 'ADMIN' ||
        tipoUsuario == 'DOCENTE' ||
        tipoUsuario == 'RECTOR' ||
        tipoUsuario == 'COORDINADOR';

    final esAcudiente = tipoUsuario == 'ACUDIENTE';
    final esAdministrativo = tipoUsuario == 'ADMINISTRATIVO';

    // Decidir qué pantalla mostrar
    if (esAdministrativo) {
      return const _TareasNoAplicaScreen();
    } else if (esGestorTareas) {
      return const ListaTareasScreen();
    } else if (esAcudiente) {
      return const SelectorHijoScreen(isMainTab: true);
    } else {
      // ESTUDIANTE y cualquier otro rol no mapeado
      return const MisTareasScreen();
    }
  }
}

/// Pantalla para roles que no participan en el flujo de tareas (ej: ADMINISTRATIVO)
class _TareasNoAplicaScreen extends StatelessWidget {
  const _TareasNoAplicaScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0FDF4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No disponible',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La gestión de tareas no aplica para tu rol.\nConsulta otros módulos disponibles en el menú.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
