// lib/screens/tareas/lista_tareas_screen.dart
// 📋 LISTA DE TAREAS - DOCENTES/ADMIN
// ✅ CORREGIDO: Verificación correcta de roles

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/tareas/tarea_card.dart';

class ListaTareasScreen extends StatefulWidget {
  const ListaTareasScreen({super.key});

  @override
  State<ListaTareasScreen> createState() => _ListaTareasScreenState();
}

class _ListaTareasScreenState extends State<ListaTareasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Estados de filtros expandidos
  bool _filtrosExpandidos = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tareaProvider = context.read<TareaProvider>();
      tareaProvider.listarTareas(refresh: true);
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final tareaProvider = context.read<TareaProvider>();
        if (tareaProvider.hasMorePages && !tareaProvider.isLoading) {
          tareaProvider.cargarMas();
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    final tareaProvider = context.read<TareaProvider>();
    await tareaProvider.refrescar();
  }

  void _onSearch(String query) {
    final tareaProvider = context.read<TareaProvider>();
    if (query.isEmpty) {
      tareaProvider.buscar('');
    } else {
      tareaProvider.buscar(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECCIÓN: Convertir enum a String para comparar
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.currentUser;

    // Convertir enum UserRole a String en mayúsculas
    final tipoUsuario = usuario?.tipo.toString().split('.').last.toUpperCase();

    final canCreate = tipoUsuario == 'ADMIN' ||
        tipoUsuario == 'DOCENTE' ||
        tipoUsuario == 'RECTOR' ||
        tipoUsuario == 'COORDINADOR';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mis Tareas'),
        automaticallyImplyLeading: false,
        actions: [
          // Botón para mostrar/ocultar filtros
          IconButton(
            icon: Icon(
                _filtrosExpandidos ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _filtrosExpandidos = !_filtrosExpandidos;
              });
            },
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          _buildHeader(),

          // Barra de búsqueda
          _buildSearchBar(),

          // Panel de filtros (expandible)
          if (_filtrosExpandidos) _buildFiltrosPanel(),

          // Filtros activos (chips)
          _buildFiltrosActivos(),

          // Lista de tareas
          Expanded(child: _buildTareasList()),
        ],
      ),

      // FAB solo si puede crear
      floatingActionButton: canCreate ? _buildFAB() : null,
    );
  }

  // ========================================
  // 📊 HEADER CON ESTADÍSTICAS
  // ========================================

  Widget _buildHeader() {
    final tareaProvider = context.watch<TareaProvider>();

    // Calcular estadísticas
    final tareas = tareaProvider.tareas;
    final totalActivas =
        tareas.where((t) => t.estado == EstadoTarea.activa).length;
    final totalCerradas =
        tareas.where((t) => t.estado == EstadoTarea.cerrada).length;

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
            '📚 Gestión de Tareas',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEstadisticaChip(
                icon: Icons.assignment,
                label: 'Total',
                valor: '${tareaProvider.totalTareas}',
              ),
              const SizedBox(width: 12),
              _buildEstadisticaChip(
                icon: Icons.check_circle,
                label: 'Activas',
                valor: '$totalActivas',
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildEstadisticaChip(
                icon: Icons.lock,
                label: 'Cerradas',
                valor: '$totalCerradas',
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaChip({
    required IconData icon,
    required String label,
    required String valor,
    Color color = Colors.white,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔍 BARRA DE BÚSQUEDA
  // ========================================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Buscar tareas por título...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ========================================
  // 🎛️ PANEL DE FILTROS
  // ========================================

  Widget _buildFiltrosPanel() {
    final tareaProvider = context.watch<TareaProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Filtro por estado
          const Text(
            'Estado',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFiltroChip(
                label: '✅ Activa',
                isActive: tareaProvider.estadoFilter == EstadoTarea.activa,
                onTap: () =>
                    tareaProvider.aplicarFiltroEstado(EstadoTarea.activa),
              ),
              const SizedBox(width: 8),
              _buildFiltroChip(
                label: '🔒 Cerrada',
                isActive: tareaProvider.estadoFilter == EstadoTarea.cerrada,
                onTap: () =>
                    tareaProvider.aplicarFiltroEstado(EstadoTarea.cerrada),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filtro por prioridad
          const Text(
            'Prioridad',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFiltroChip(
                label: '🔴 Alta',
                isActive: tareaProvider.prioridadFilter == PrioridadTarea.alta,
                onTap: () =>
                    tareaProvider.aplicarFiltroPrioridad(PrioridadTarea.alta),
              ),
              const SizedBox(width: 8),
              _buildFiltroChip(
                label: '🟡 Media',
                isActive: tareaProvider.prioridadFilter == PrioridadTarea.media,
                onTap: () =>
                    tareaProvider.aplicarFiltroPrioridad(PrioridadTarea.media),
              ),
              const SizedBox(width: 8),
              _buildFiltroChip(
                label: '🟢 Baja',
                isActive: tareaProvider.prioridadFilter == PrioridadTarea.baja,
                onTap: () =>
                    tareaProvider.aplicarFiltroPrioridad(PrioridadTarea.baja),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botón limpiar filtros
          if (tareaProvider.estadoFilter != null ||
              tareaProvider.prioridadFilter != null ||
              tareaProvider.cursoFilter != null ||
              tareaProvider.asignaturaFilter != null)
            Center(
              child: TextButton.icon(
                onPressed: () => tareaProvider.limpiarFiltros(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar todos los filtros'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // ========================================
  // 🏷️ FILTROS ACTIVOS (CHIPS)
  // ========================================

  Widget _buildFiltrosActivos() {
    final tareaProvider = context.watch<TareaProvider>();
    final List<Widget> chips = [];

    // Chip de estado
    if (tareaProvider.estadoFilter != null) {
      chips.add(_buildActiveFiltroChip(
        label: 'Estado: ${tareaProvider.estadoFilter!.displayName}',
        onRemove: () => tareaProvider.aplicarFiltroEstado(null),
      ));
    }

    // Chip de prioridad
    if (tareaProvider.prioridadFilter != null) {
      chips.add(_buildActiveFiltroChip(
        label: 'Prioridad: ${tareaProvider.prioridadFilter!.displayName}',
        onRemove: () => tareaProvider.aplicarFiltroPrioridad(null),
      ));
    }

    // Chip de búsqueda
    if (tareaProvider.searchQuery.isNotEmpty) {
      chips.add(_buildActiveFiltroChip(
        label: 'Búsqueda: "${tareaProvider.searchQuery}"',
        onRemove: () {
          _searchController.clear();
          tareaProvider.buscar('');
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildActiveFiltroChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📋 LISTA DE TAREAS
  // ========================================

  Widget _buildTareasList() {
    final tareaProvider = context.watch<TareaProvider>();

    if (tareaProvider.isLoading && tareaProvider.tareas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tareaProvider.tareas.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount:
            tareaProvider.tareas.length + (tareaProvider.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator para paginación
          if (index == tareaProvider.tareas.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final tarea = tareaProvider.tareas[index];

          return TareaCard(
            tarea: tarea,
            onTap: () => context.push('/tareas/${tarea.id}'),
            mostrarDocente: false, // No mostrar docente en su propia lista
          );
        },
      ),
    );
  }

  // ========================================
  // 📄 ESTADO VACÍO
  // ========================================

  Widget _buildEmptyState() {
    final tareaProvider = context.watch<TareaProvider>();
    final hayFiltros = tareaProvider.estadoFilter != null ||
        tareaProvider.prioridadFilter != null ||
        tareaProvider.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              hayFiltros
                  ? 'No se encontraron tareas'
                  : 'Aún no has creado tareas',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hayFiltros
                  ? 'Intenta ajustar los filtros de búsqueda'
                  : 'Comienza creando tu primera tarea',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (hayFiltros) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => tareaProvider.limpiarFiltros(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================
  // ➕ FAB
  // ========================================

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/tareas/crear'),
      backgroundColor: const Color(0xFF8B5CF6),
      icon: const Icon(Icons.add, size: 24),
      label: const Text(
        'Crear Tarea',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
