// lib/screens/usuarios/manage_students_screen.dart
// 🎓 PANTALLA DE GESTIÓN DE ESTUDIANTES ASOCIADOS (ACUDIENTE) - COMPLETA

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario.dart';
import '../../providers/usuario_provider.dart';
import 'search_students_screen.dart';

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
  bool _isLoading = true;
  List<Usuario> _estudiantesAsociados = [];

  @override
  void initState() {
    super.initState();
    _loadEstudiantes();
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _abrirBusquedaEstudiantes() async {
    final estudiantesIds = _estudiantesAsociados.map((e) => e.id).toList();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SearchStudentsScreen(
          acudienteId: widget.acudienteId,
          estudiantesYaAsociados: estudiantesIds,
        ),
      ),
    );

    // Si se asoció un estudiante, recargar la lista
    if (result == true) {
      await _loadEstudiantes();
    }
  }

  Future<void> _confirmarDesasociacion(Usuario estudiante) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar desasociación'),
        content: Text(
          '¿Estás seguro de que deseas desasociar a ${estudiante.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Desasociar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _desasociarEstudiante(estudiante);
    }
  }

  Future<void> _desasociarEstudiante(Usuario estudiante) async {
    try {
      final provider = context.read<UsuarioProvider>();
      await provider.desasociarEstudiante(
        acudienteId: widget.acudienteId,
        estudianteId: estudiante.id,
      );

      _showSuccess('${estudiante.nombreCompleto} desasociado correctamente');

      // Recargar lista
      await _loadEstudiantes();
    } catch (e) {
      _showError('Error desasociando estudiante: $e');
    }
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
            onPressed: _abrirBusquedaEstudiantes,
            tooltip: 'Agregar estudiante',
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEC4899),
          radius: 28,
          child: Text(
            estudiante.iniciales,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          estudiante.nombreCompleto,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              estudiante.email,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (estudiante.infoAcademica?.grado != null) ...[
              const SizedBox(height: 4),
              Text(
                'Grado: ${estudiante.infoAcademica!.grado}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: Colors.red,
          tooltip: 'Desasociar estudiante',
          onPressed: () => _confirmarDesasociacion(estudiante),
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
          Text(
            'Presiona + para agregar estudiantes',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _abrirBusquedaEstudiantes,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Estudiante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
