// lib/screens/tareas/tareas_hijo_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../widgets/tareas/tarea_card.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/vacio_refrescable.dart';

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

    return GradientHeader(
      title: 'Tareas del estudiante',
      subtitle: tareaProvider.isLoadingTareasHijo
          ? 'Cargando...'
          : '${tareasFiltradas.length} tareas',
      showBack: true,
      leadingIcon: Icons.assignment,
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
      return VacioRefrescable(onRefresh: _onRefresh, child: _buildEmptyState());
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF059669),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: tareasFiltradas.length,
        itemBuilder: (context, index) {
          final tarea = tareasFiltradas[index];
          final miEntrega =
              tarea.entregas.isNotEmpty ? tarea.entregas[0] : null;

          return TareaCard(
            tarea: tarea,
            miEntrega: miEntrega,
            onTap: () => context.push(
                '/tareas/${tarea.id}?estudianteId=${widget.estudianteId}'),
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
