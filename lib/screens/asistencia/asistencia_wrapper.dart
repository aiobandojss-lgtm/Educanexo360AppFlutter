// lib/screens/asistencia/asistencia_wrapper.dart
//
// Decide qué pantalla de asistencia mostrar según el rol del usuario:
//   ESTUDIANTE           → MiAsistenciaScreen (su propia asistencia)
//   ACUDIENTE 1 hijo     → MiAsistenciaScreen (del hijo)
//   ACUDIENTE N hijos    → selector de hijo embebido
//   Demás roles          → ListaAsistenciaScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../utils/logger.dart';
import 'lista_asistencia_screen.dart';
import 'mi_asistencia_screen.dart';

class AsistenciaWrapper extends StatelessWidget {
  const AsistenciaWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().currentUser;

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tipo = usuario.tipo.value;

    dlog('🔍 AsistenciaWrapper → tipo: "$tipo"');

    if (tipo == 'ESTUDIANTE') {
      return MiAsistenciaScreen(
        estudianteId: usuario.id,
        nombreEstudiante: 'Mi asistencia',
      );
    }

    if (tipo == 'ACUDIENTE') {
      final hijos = usuario.infoAcademica?.estudiantesAsociados ?? [];

      if (hijos.isEmpty) {
        return const _SinHijosScreen();
      }

      if (hijos.length == 1) {
        return _AsistenciaHijoLoader(hijoId: hijos.first);
      }

      return _SelectorHijosAsistencia(hijosIds: hijos);
    }

    // DOCENTE, ADMIN, RECTOR, COORDINADOR, etc.
    return const ListaAsistenciaScreen();
  }
}

// ──────────────────────────────────────────────────
// Carga datos del hijo único y muestra MiAsistenciaScreen
// ──────────────────────────────────────────────────
class _AsistenciaHijoLoader extends StatefulWidget {
  final String hijoId;
  const _AsistenciaHijoLoader({required this.hijoId});

  @override
  State<_AsistenciaHijoLoader> createState() => _AsistenciaHijoLoaderState();
}

class _AsistenciaHijoLoaderState extends State<_AsistenciaHijoLoader> {
  final ApiService _api = ApiService();
  String _nombre = 'Mi hijo';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    try {
      final res = await _api.get('/usuarios/${widget.hijoId}');
      final data = res['data'] ?? res;
      final u = Usuario.fromJson(data);
      if (mounted) setState(() => _nombre = u.nombreCompleto);
    } catch (_) {
      // Si falla, usamos el nombre por defecto
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MiAsistenciaScreen(
      estudianteId: widget.hijoId,
      nombreEstudiante: _nombre,
    );
  }
}

// ──────────────────────────────────────────────────
// Selector de hijo cuando el acudiente tiene varios
// ──────────────────────────────────────────────────
class _SelectorHijosAsistencia extends StatefulWidget {
  final List<String> hijosIds;
  const _SelectorHijosAsistencia({required this.hijosIds});

  @override
  State<_SelectorHijosAsistencia> createState() =>
      _SelectorHijosAsistenciaState();
}

class _SelectorHijosAsistenciaState extends State<_SelectorHijosAsistencia> {
  final ApiService _api = ApiService();
  List<Usuario> _hijos = [];
  bool _cargando = true;
  Usuario? _hijoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarHijos();
  }

  Future<void> _cargarHijos() async {
    final List<Usuario> temp = [];
    for (final id in widget.hijosIds) {
      try {
        final res = await _api.get('/usuarios/$id');
        final data = res['data'] ?? res;
        temp.add(Usuario.fromJson(data));
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _hijos = temp;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hijoSeleccionado != null) {
      return MiAsistenciaScreen(
        key: ValueKey(_hijoSeleccionado!.id),
        estudianteId: _hijoSeleccionado!.id,
        nombreEstudiante: _hijoSeleccionado!.nombreCompleto,
        onBack: () => setState(() => _hijoSeleccionado = null),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF047857), Color(0xFF14B8A6)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Selecciona un hijo para ver su asistencia',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ..._hijos.map((hijo) => _buildHijoCard(context, hijo)),
              ],
            ),
    );
  }

  Widget _buildHijoCard(BuildContext context, Usuario hijo) {
    final iniciales = hijo.nombreCompleto
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _hijoSeleccionado = hijo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF059669),
                radius: 24,
                child: Text(
                  iniciales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  hijo.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Pantalla vacía para acudiente sin hijos asociados
// ──────────────────────────────────────────────────
class _SinHijosScreen extends StatelessWidget {
  const _SinHijosScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Sin estudiantes asociados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu cuenta no tiene estudiantes vinculados aún. Contacta al administrador.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
