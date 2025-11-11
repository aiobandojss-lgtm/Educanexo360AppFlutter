// lib/screens/tareas/tareas_screen_wrapper.dart
// ✅ Wrapper que decide qué pantalla de tareas mostrar según el rol del usuario

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/permission_service.dart';
import 'mis_tareas_screen.dart';
import 'lista_tareas_screen.dart';

/// Widget que decide automáticamente qué pantalla de tareas mostrar
/// - ESTUDIANTES → MisTareasScreen (vista de tareas asignadas)
/// - DOCENTES/ADMIN → ListaTareasScreen (gestión de tareas)
class TareasScreenWrapper extends StatelessWidget {
  const TareasScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Validar que hay usuario autenticado
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determinar qué pantalla mostrar según el rol
    final esEstudiante = user.tipo == 'ESTUDIANTE';
    final puedeCrearTareas = PermissionService.canAccess('tareas.crear');

    // Si es estudiante → Vista de MIS TAREAS
    if (esEstudiante) {
      return const MisTareasScreen();
    }

    // Si es docente/admin → Vista de GESTIÓN DE TAREAS
    if (puedeCrearTareas) {
      return const ListaTareasScreen();
    }

    // Fallback: Si no tiene ningún rol claro, mostrar estudiante
    // (esto no debería pasar en producción)
    return const MisTareasScreen();
  }
}
