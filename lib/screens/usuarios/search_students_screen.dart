// lib/screens/usuarios/search_students_screen.dart
// 🔍 PANTALLA DE BÚSQUEDA DE ESTUDIANTES PARA ASOCIAR A ACUDIENTE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario.dart';
import '../../providers/usuario_provider.dart';

class SearchStudentsScreen extends StatefulWidget {
  final String acudienteId;
  final List<String> estudiantesYaAsociados;

  const SearchStudentsScreen({
    super.key,
    required this.acudienteId,
    required this.estudiantesYaAsociados,
  });

  @override
  State<SearchStudentsScreen> createState() => _SearchStudentsScreenState();
}

class _SearchStudentsScreenState extends State<SearchStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Usuario> _estudiantes = [];
  List<Usuario> _estudiantesFiltrados = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterEstudiantes(_searchController.text);
  }

  Future<void> _buscarEstudiantes() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un criterio de búsqueda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final provider = context.read<UsuarioProvider>();
      final resultados = await provider.buscarEstudiantesParaAsociar(
        query: _searchController.text.trim(),
      );

      // Filtrar estudiantes ya asociados
      final estudiantesDisponibles = resultados
          .where((e) => !widget.estudiantesYaAsociados.contains(e.id))
          .toList();

      setState(() {
        _estudiantes = estudiantesDisponibles;
        _estudiantesFiltrados = estudiantesDisponibles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error buscando estudiantes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterEstudiantes(String query) {
    if (query.isEmpty) {
      setState(() => _estudiantesFiltrados = _estudiantes);
      return;
    }

    final queryLower = query.toLowerCase();
    setState(() {
      _estudiantesFiltrados = _estudiantes.where((estudiante) {
        final nombreCompleto =
            '${estudiante.nombre} ${estudiante.apellidos}'.toLowerCase();
        final email = estudiante.email.toLowerCase();
        return nombreCompleto.contains(queryLower) ||
            email.contains(queryLower);
      }).toList();
    });
  }

  Future<void> _asociarEstudiante(Usuario estudiante) async {
    try {
      final provider = context.read<UsuarioProvider>();
      await provider.asociarEstudiante(
        acudienteId: widget.acudienteId,
        estudianteId: estudiante.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${estudiante.nombreCompleto} asociado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Retornar true para indicar que se asoció un estudiante
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error asociando estudiante: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        title: const Text('Buscar Estudiantes'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, apellido o email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscarEstudiantes(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _buscarEstudiantes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buscar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Resultados
          Expanded(
            child: _buildResultados(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Busca estudiantes para asociar',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa nombre, apellido o email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_estudiantesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron estudiantes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro criterio de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _estudiantesFiltrados.length,
      itemBuilder: (context, index) {
        final estudiante = _estudiantesFiltrados[index];
        return _buildEstudianteCard(estudiante);
      },
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
        trailing: ElevatedButton.icon(
          onPressed: () => _asociarEstudiante(estudiante),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Asociar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
