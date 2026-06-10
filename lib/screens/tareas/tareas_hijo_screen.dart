// lib/screens/tareas/tareas_hijo_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../widgets/tareas/tarea_card.dart';

class TareasHijoScreen extends StatefulWidget {
  final String estudianteId;

  const TareasHijoScreen({
    super.key,
    required this.estudianteId,
  });

  @override
  State<TareasHijoScreen> createState() => _TareasHijoScreenState();
}

class _TareasHijoScreenState extends State<TareasHijoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FiltroTareaEstudiante _filtroActual = FiltroTareaEstudiante.pendientes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tareaProvider = context.read<TareaProvider>();
      tareaProvider.cargarTareasHijo(estudianteId: widget.estudianteId);
    });
  }

  Future<void> _onRefresh() async {
    final tareaProvider = context.read<TareaProvider>();
    await tareaProvider.cargarTareasHijo(
      estudianteId: widget.estudianteId,
      refresh: true,
    );
  }

  void _onTabChanged(int index) {
    setState(() {
      switch (index) {
        case 0:
          _filtroActual = FiltroTareaEstudiante.pendientes;
          break;
        case 1:
          _filtroActual = FiltroTareaEstudiante.entregadas;
          break;
        case 2:
          _filtroActual = FiltroTareaEstudiante.calificadas;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tareas del estudiante'),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(child: _buildTabContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pop();
        },
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Regresar'),
      ),
    );
  }

  Widget _buildHeader() {
    final tareaProvider = context.watch<TareaProvider>();
    final tareasFiltradas = tareaProvider.filtrarTareasPorEstado(_filtroActual);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF047857), // Verde Emerald-700
            Color(0xFF14B8A6), // Teal-500
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 Tareas',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tareaProvider.isLoadingTareasHijo
                ? 'Cargando...'
                : '${tareasFiltradas.length} tareas',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: _onTabChanged,
        labelColor: const Color(0xFF059669),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF059669),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Pendientes'),
          Tab(text: 'Entregadas'),
          Tab(text: 'Calificadas'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final tareaProvider = context.watch<TareaProvider>();

    if (tareaProvider.isLoadingTareasHijo && tareaProvider.tareasHijo.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final tareasFiltradas = tareaProvider.filtrarTareasPorEstado(_filtroActual);

    if (tareasFiltradas.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF059669),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tareasFiltradas.length,
        itemBuilder: (context, index) {
          final tarea = tareasFiltradas[index];
          final miEntrega =
              tarea.entregas.isNotEmpty ? tarea.entregas[0] : null;

          return TareaCard(
            tarea: tarea,
            miEntrega: miEntrega,
            onTap: () => context.push('/tareas/${tarea.id}'),
            isReadOnly: true, // ⬅️ IMPORTANTE: Activar modo read-only
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String emoji = '✅';
    String titulo = 'No hay tareas';
    String mensaje = 'No hay tareas en esta categoría';

    switch (_filtroActual) {
      case FiltroTareaEstudiante.pendientes:
        titulo = 'No hay tareas pendientes';
        mensaje = '¡El estudiante está al día!';
        break;
      case FiltroTareaEstudiante.entregadas:
        titulo = 'No hay tareas entregadas';
        break;
      case FiltroTareaEstudiante.calificadas:
        titulo = 'No hay tareas calificadas';
        break;
      default:
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
