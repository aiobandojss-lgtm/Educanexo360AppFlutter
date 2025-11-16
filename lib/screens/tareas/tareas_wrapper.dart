// lib/screens/tareas/tareas_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/usuario.dart';
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

    final tipoUsuario = usuario.tipo.toString().split('.').last.toUpperCase();

    print('=====================================');
    print('🔍 TareasWrapper');
    print('Usuario: ${usuario.nombreCompleto}');
    print('Tipo enum: ${usuario.tipo}');
    print('Tipo convertido: "$tipoUsuario"');
    print('=====================================');

    final esDocente = tipoUsuario == 'ADMIN' ||
        tipoUsuario == 'DOCENTE' ||
        tipoUsuario == 'RECTOR' ||
        tipoUsuario == 'COORDINADOR';

    final esAcudiente = tipoUsuario == 'ACUDIENTE';
    final esEstudiante = tipoUsuario == 'ESTUDIANTE';

    print('Es Docente: $esDocente');
    print('Es Acudiente: $esAcudiente');
    print('Es Estudiante: $esEstudiante');
    print(
        'Mostrará: ${esDocente ? "ListaTareasScreen" : (esAcudiente ? "SelectorHijoScreen" : "MisTareasScreen")}');
    print('=====================================');

    // Decidir qué pantalla mostrar
    if (esDocente) {
      return const ListaTareasScreen();
    } else if (esAcudiente) {
      // ✅ ÚNICO CAMBIO: Pasar parámetro isMainTab
      return const SelectorHijoScreen(isMainTab: true);
    } else {
      return const MisTareasScreen();
    }
  }
}
