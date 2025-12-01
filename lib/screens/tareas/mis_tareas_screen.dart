// lib/screens/tareas/mis_tareas_screen.dart
// âœ… Pantalla de tareas del estudiante con 3 tabs: Pendientes, Entregadas y Calificadas
// âœ… CORREGIDO: Overflow, navegaciÃ³n y eliminado mensaje rojo

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/tareas/tarea_card.dart';

class MisTareasScreen extends StatefulWidget {
  const MisTareasScreen({super.key});

  @override
  State<MisTareasScreen> createState() => _MisTareasScreenState();
}

class _MisTareasScreenState extends State<MisTareasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // âœ… CORREGIDO: Eliminar validaciÃ³n de estudiante que mostraba mensaje rojo
      // Cargar tareas del estudiante
      final tareaProvider = context.read<TareaProvider>();
      tareaProvider.cargarMisTareas(filtro: FiltroTareaEstudiante.pendientes);
    });
  }

  void _setupScrollListener() {
    // No hay paginaciÃ³n para mis tareas, solo scroll normal
    _scrollController.addListener(() {
      // AquÃ­ podrÃ­a agregarse lÃ³gica de paginaciÃ³n en el futuro
    });
  }

  Future<void> _onRefresh() async {
    final tareaProvider = context.read<TareaProvider>();
    await tareaProvider.refrescarMisTareas();
  }

  FiltroTareaEstudiante _getFiltroActual() {
    switch (_tabController.index) {
      case 0:
        return FiltroTareaEstudiante.pendientes;
      case 1:
        return FiltroTareaEstudiante.entregadas;
      case 2:
        return FiltroTareaEstudiante.calificadas;
      default:
        return FiltroTareaEstudiante.pendientes;
    }
  }

  void _onTabChanged(int index) {
    final tareaProvider = context.read<TareaProvider>();
    final filtro = _getFiltroActual();
    tareaProvider.cargarMisTareas(filtro: filtro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mis Tareas'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Header con estadÃ­sticas
          _buildHeader(),

          // Tabs
          _buildTabs(),

          // Lista de tareas - âœ… CORREGIDO: Expanded para evitar overflow
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final tareaProvider = context.watch<TareaProvider>();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF8B5CF6),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Tareas',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tareaProvider.isLoadingMisTareas
                ? 'Cargando...'
                : '${tareaProvider.misTareas.length} tareas asignadas',
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
    final tareaProvider = context.watch<TareaProvider>();

    return ClipRect(
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          onTap: _onTabChanged,
          labelColor: const Color(0xFF8B5CF6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8B5CF6),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.assignment_outlined, size: 18),
              text: 'Pendientes',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline, size: 18),
              text: 'Entregadas',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.star_outline, size: 18),
              text: 'Calificadas',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTabPanel(FiltroTareaEstudiante.pendientes),
        _buildTabPanel(FiltroTareaEstudiante.entregadas),
        _buildTabPanel(FiltroTareaEstudiante.calificadas),
      ],
    );
  }

  Widget _buildTabPanel(FiltroTareaEstudiante filtro) {
    final tareaProvider = context.watch<TareaProvider>();

    if (tareaProvider.isLoadingMisTareas && tareaProvider.misTareas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tareaProvider.misTareas.isEmpty) {
      return _buildEmptyState(filtro);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF8B5CF6),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: tareaProvider.misTareas.length,
        itemBuilder: (context, index) {
          final tarea = tareaProvider.misTareas[index];
          return TareaCard(
            tarea: tarea,
            // âœ… CORREGIDO: NavegaciÃ³n sin /detalle
            onTap: () => context.push('/tareas/${tarea.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(FiltroTareaEstudiante filtro) {
    //Emoji para "No hay tareas"
    String emoji = '📚';
    String titulo = 'No hay tareas';
    String mensaje = '';

    switch (filtro) {
      case FiltroTareaEstudiante.pendientes:
        //Emoji para "No tienes tareas pendientes"
        emoji = '✅';
        titulo = 'No tienes tareas pendientes';
        mensaje = 'Estás al día con tus entregas!';
        break;
      case FiltroTareaEstudiante.entregadas:
        //Emoji para "No tienes tareas entregadas"
        emoji = '📤';
        titulo = 'No tienes tareas entregadas';
        mensaje = 'Las tareas entregadas aparecerán aquí';
        break;
      case FiltroTareaEstudiante.calificadas:
        emoji = '⭐';
        titulo = 'No tienes tareas calificadas aún';
        mensaje = 'Tus calificaciones aparecerán aquí';
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
