// lib/screens/usuarios/manage_students_screen.dart
// 🎓 PANTALLA DE GESTIÓN DE ESTUDIANTES ASOCIADOS (ACUDIENTE)
// Basada en ManageStudentsScreen.tsx

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario.dart';
import '../../providers/usuario_provider.dart';

class ManageStudentsScreen extends StatefulWidget {
  final String acudienteId;

  const ManageStudentsScreen({
    super.key,
    required this.acudienteId,
  });

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Usuario> _estudiantesAsociados = [];

  @override
  void initState() {
    super.initState();
    _loadEstudiantes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEstudiantes() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<UsuarioProvider>();
      final estudiantes =
          await provider.getEstudiantesAsociados(widget.acudienteId);
      setState(() {
        _estudiantesAsociados = estudiantes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando estudiantes: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        title: const Text('Gestionar Estudiantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar búsqueda de estudiantes
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔍 Búsqueda de estudiantes - Próximamente'),
                  backgroundColor: Color(0xFF0891B2),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estudiantesAsociados.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _estudiantesAsociados.length,
                  itemBuilder: (context, index) {
                    final estudiante = _estudiantesAsociados[index];
                    return _buildEstudianteCard(estudiante);
                  },
                ),
    );
  }

  Widget _buildEstudianteCard(Usuario estudiante) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEC4899),
          child: Text(
            estudiante.iniciales,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          estudiante.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(estudiante.email),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () {
            // TODO: Implementar desasociar estudiante
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔗 Desasociar estudiante - Próximamente'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎓', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Sin estudiantes asociados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Presiona + para agregar estudiantes',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔍 Búsqueda de estudiantes - Próximamente'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Estudiante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
