// lib/screens/tareas/lista_tareas_screen.dart
// 📋 LISTA DE TAREAS - DOCENTES/ADMIN
// ✅ CORREGIDO: Verificación correcta de roles

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/tarea.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/tareas/tarea_card.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/vacio_refrescable.dart';

class ListaTareasScreen extends StatefulWidget {
  const ListaTareasScreen({super.key});

  @override
  State<ListaTareasScreen> createState() => _ListaTareasScreenState();
}

class _ListaTareasScreenState extends State<ListaTareasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  // (filtros se muestran en BottomSheet, no inline)

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final tareaProvider = context.read<TareaProvider>();
    if (tareaProvider.tareas.isEmpty) {
      tareaProvider.prepareLoading();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tareaProvider.listarTareas(refresh: true);
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

  // Al volver de un formulario o del detalle: refrescar la lista (G5)
  void _refrescarAlVolver() {
    if (mounted) _onRefresh();
  }

  Future<void> _onRefresh() async {
    final tareaProvider = context.read<TareaProvider>();
    await tareaProvider.refrescar();
  }

  void _onSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final tareaProvider = context.read<TareaProvider>();
      if (query.isEmpty) {
        tareaProvider.buscar('');
      } else {
        tareaProvider.buscar(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECCIÓN: Convertir enum a String para comparar
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.currentUser;

    // ✅ CORRECTO: usar .value en lugar de .toString().split('.').last
    final tipoUsuario = usuario?.tipo.value;

    // RECTOR puede ver tareas pero NO crear (solo supervisión)
    final canCreate = tipoUsuario == 'SUPER_ADMIN' ||
        tipoUsuario == 'ADMIN' ||
        tipoUsuario == 'DOCENTE' ||
        tipoUsuario == 'COORDINADOR';

    return Scaffold(
      body: Column(
        children: [
          // Header con estadísticas
          _buildHeader(),

          // Barra de búsqueda
          _buildSearchBar(),

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

    final cantFiltros = [
      tareaProvider.estadoFilter,
      tareaProvider.prioridadFilter,
      tareaProvider.cursoFilter,
      tareaProvider.asignaturaFilter,
    ].where((f) => f != null).length;

    return GradientHeader(
      title: 'Gestión de Tareas',
      leadingIcon: Icons.assignment,
      actions: [
        HeaderAction(
          icon: Icons.filter_list,
          onTap: _mostrarFiltros,
          tooltip: 'Filtros',
          badgeCount: cantFiltros,
        ),
      ],
      bottom: Row(
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
            Icon(icon, size: 20, color: const Color(0xFF059669)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF059669),
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
  // 🎛️ FILTROS — BOTTOM SHEET
  // ========================================

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer<TareaProvider>(
        builder: (ctx, provider, _) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título + limpiar
                Row(
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (provider.estadoFilter != null ||
                        provider.prioridadFilter != null ||
                        provider.cursoFilter != null ||
                        provider.asignaturaFilter != null)
                      TextButton.icon(
                        onPressed: () {
                          provider.limpiarFiltros();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Estado
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
                      isActive:
                          provider.estadoFilter == EstadoTarea.activa,
                      onTap: () => provider
                          .aplicarFiltroEstado(EstadoTarea.activa),
                    ),
                    const SizedBox(width: 8),
                    _buildFiltroChip(
                      label: '🔒 Cerrada',
                      isActive:
                          provider.estadoFilter == EstadoTarea.cerrada,
                      onTap: () => provider
                          .aplicarFiltroEstado(EstadoTarea.cerrada),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Prioridad
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
                      isActive: provider.prioridadFilter ==
                          PrioridadTarea.alta,
                      onTap: () => provider
                          .aplicarFiltroPrioridad(PrioridadTarea.alta),
                    ),
                    const SizedBox(width: 8),
                    _buildFiltroChip(
                      label: '🟡 Media',
                      isActive: provider.prioridadFilter ==
                          PrioridadTarea.media,
                      onTap: () => provider
                          .aplicarFiltroPrioridad(PrioridadTarea.media),
                    ),
                    const SizedBox(width: 8),
                    _buildFiltroChip(
                      label: '🟢 Baja',
                      isActive: provider.prioridadFilter ==
                          PrioridadTarea.baja,
                      onTap: () => provider
                          .aplicarFiltroPrioridad(PrioridadTarea.baja),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
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
          color: isActive ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF059669) : Colors.grey[300]!,
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
        color: const Color(0xFF059669).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF059669)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF059669),
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
      return VacioRefrescable(onRefresh: _onRefresh, child: _buildEmptyState());
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
            onTap: () => context.push('/tareas/${tarea.id}').then((_) => _refrescarAlVolver()),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hayFiltros
                  ? Icons.search_off_outlined
                  : Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
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
                  backgroundColor: const Color(0xFF059669),
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
      onPressed: () => context.push('/tareas/crear').then((_) => _refrescarAlVolver()),
      backgroundColor: const Color(0xFF059669),
      icon: const Icon(Icons.add, size: 24),
      label: const Text(
        'Crear Tarea',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
