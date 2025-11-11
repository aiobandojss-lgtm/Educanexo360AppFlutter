// lib/screens/tareas/tareas_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/usuario.dart'; // Para acceder al enum UserRole
import 'mis_tareas_screen.dart';
import 'lista_tareas_screen.dart';

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

    // ✅ SOLUCIÓN: Convertir el enum a string y comparar
    // usuario.tipo es UserRole.admin, UserRole.docente, etc.
    // Lo convertimos a String y extraemos solo el nombre (admin, docente, etc.)
    // Luego lo pasamos a mayúsculas para comparar
    final tipoUsuario = usuario.tipo.toString().split('.').last.toUpperCase();

    print('=====================================');
    print('🔍 TareasWrapper');
    print('Usuario: ${usuario.nombreCompleto}');
    print('Tipo enum: ${usuario.tipo}');
    print('Tipo convertido: "$tipoUsuario"');
    print('=====================================');

    // ✅ COMPARACIÓN CORRECTA después de convertir a String
    final esDocente = tipoUsuario == 'ADMIN' ||
        tipoUsuario == 'DOCENTE' ||
        tipoUsuario == 'RECTOR' ||
        tipoUsuario == 'COORDINADOR';

    print('Es Docente: $esDocente');
    print('Mostrará: ${esDocente ? "ListaTareasScreen" : "MisTareasScreen"}');
    print('=====================================');

    // Decidir qué pantalla mostrar
    if (esDocente) {
      return const ListaTareasScreen();
    } else {
      return const MisTareasScreen();
    }
  }
}
