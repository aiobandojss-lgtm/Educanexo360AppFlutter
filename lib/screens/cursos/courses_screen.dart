// lib/screens/cursos/courses_screen.dart
// 📚 PANTALLA DE GESTIÓN DE CURSOS - SIGUIENDO PATRÓN DE USUARIOS

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/curso.dart';
import '../../providers/curso_provider.dart';
import '../../services/permission_service.dart';
import '../../widgets/common/gradient_header.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // 🎨 COLORES POR NIVEL
  static const Map<NivelEducativo, Color> _nivelColors = {
    NivelEducativo.preescolar: Color(0xFF10B981),
    NivelEducativo.primaria: Color(0xFF0D9488),
    NivelEducativo.secundaria: Color(0xFF0284C7),
    NivelEducativo.media: Color(0xFF059669),
  };

  // 🎨 ICONOS POR NIVEL
  static const Map<NivelEducativo, IconData> _nivelIcons = {
    NivelEducativo.preescolar: Icons.child_friendly,
    NivelEducativo.primaria: Icons.menu_book,
    NivelEducativo.secundaria: Icons.school,
    NivelEducativo.media: Icons.emoji_events,
  };

  // 🎨 ICONOS POR JORNADA
  static const Map<Jornada, IconData> _jornadaIconData = {
    Jornada.matutina: Icons.wb_sunny,
    Jornada.vespertina: Icons.wb_twilight,
    Jornada.nocturna: Icons.nights_stay,
    Jornada.completa: Icons.calendar_today,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final provider = context.read<CursoProvider>();
    if (provider.cursos.isEmpty) {
      provider.prepareLoading();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CursoProvider>().loadCursos(refresh: true);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<CursoProvider>().refresh();
  }

  void _onSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final provider = context.read<CursoProvider>();
      if (query.isEmpty) {
        provider.clearSearch();
      } else {
        provider.search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canView = PermissionService.canAccess('cursos.ver');

    if (!canView) {
      return Scaffold(
        body: const Column(
          children: [
            GradientHeader(
              title: 'Gestión de Cursos',
              showBack: true,
              leadingIcon: Icons.school,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 64, color: Color(0xFF059669)),
                    SizedBox(height: 16),
                    Text(
                      'Acceso Restringido',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Esta sección está disponible solo para\npersonal administrativo y docente.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildCoursesList()),
        ],
      ),
    );
  }

  // ========================================
  // 📋 HEADER UNIFICADO (GradientHeader)
  // ========================================

  Widget _buildHeader() {
    return Consumer<CursoProvider>(
      builder: (context, cursoProvider, _) {
        final cantFiltros = (cursoProvider.currentNivelFilter != null ? 1 : 0) +
            (cursoProvider.currentJornadaFilter != null ? 1 : 0);
        return GradientHeader(
          title: 'Gestión de Cursos',
          subtitle:
              '${cursoProvider.totalCursos} curso${cursoProvider.totalCursos != 1 ? 's' : ''} registrado${cursoProvider.totalCursos != 1 ? 's' : ''}',
          showBack: true,
          leadingIcon: Icons.school,
          actions: [
            HeaderAction(
              icon: Icons.filter_list,
              onTap: _mostrarFiltros,
              tooltip: 'Filtros',
              badgeCount: cantFiltros,
            ),
          ],
        );
      },
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
          hintText: 'Buscar cursos, docentes...',
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ========================================
  // 🎛️ FILTROS — BOTTOM SHEET (Nivel + Jornada)
  // ========================================

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer<CursoProvider>(
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
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (provider.currentNivelFilter != null ||
                        provider.currentJornadaFilter != null)
                      TextButton.icon(
                        onPressed: () {
                          provider.changeNivelFilter(null);
                          provider.changeJornadaFilter(null);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filtro por Nivel
                const Text(
                  'Nivel educativo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFiltroChip(
                      label: 'Todos',
                      icon: Icons.menu_book,
                      count: provider.totalCursos,
                      isActive: provider.currentNivelFilter == null,
                      onTap: () => provider.changeNivelFilter(null),
                    ),
                    ...NivelEducativo.values.map((nivel) => _buildFiltroChip(
                          label: nivel.displayName,
                          icon: _nivelIcons[nivel] ?? Icons.menu_book,
                          count: provider.cursosPorNivel[nivel] ?? 0,
                          isActive: provider.currentNivelFilter == nivel,
                          onTap: () => provider.changeNivelFilter(nivel),
                        )),
                  ],
                ),

                const SizedBox(height: 20),

                // Filtro por Jornada
                const Text(
                  'Jornada',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFiltroChip(
                      label: 'Todas',
                      icon: Icons.access_time,
                      count: provider.totalCursos,
                      isActive: provider.currentJornadaFilter == null,
                      onTap: () => provider.changeJornadaFilter(null),
                    ),
                    ...Jornada.values.map((jornada) => _buildFiltroChip(
                          label: jornada.displayName,
                          icon: _jornadaIconData[jornada] ?? Icons.schedule,
                          count: provider.cursosPorJornada[jornada] ?? 0,
                          isActive:
                              provider.currentJornadaFilter == jornada,
                          onTap: () =>
                              provider.changeJornadaFilter(jornada),
                        )),
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
    required IconData icon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF059669) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 5),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🎯 FILTROS POR NIVEL
  // ========================================

  // ========================================
  // 📋 LISTA DE CURSOS
  // ========================================

  Widget _buildCoursesList() {
    return Consumer<CursoProvider>(
      builder: (context, cursoProvider, _) {
        final cursos = cursoProvider.cursos;
        final isLoading = cursoProvider.isLoading;

        if (isLoading && cursos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cursos.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: cursos.length,
            itemBuilder: (context, index) {
              final curso = cursos[index];
              return _buildCourseCard(curso);
            },
          ),
        );
      },
    );
  }

  // ========================================
  // 📚 CARD DE CURSO
  // ========================================

  Widget _buildCourseCard(Curso curso) {
    final nivelColor = _nivelColors[curso.nivel] ?? const Color(0xFF059669);
    final nivelIcon = _nivelIcons[curso.nivel] ?? Icons.menu_book;

    return GestureDetector(
      onTap: () => context.push('/cursos/${curso.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(nivelIcon, size: 20, color: nivelColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        curso.gradoDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: nivelColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    curso.nivel.displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Detalles
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    curso.nombreDirector,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  '${curso.totalEstudiantes} estudiantes',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.menu_book, size: 14, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  '${curso.totalAsignaturas} asignaturas',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),

            if (curso.jornada != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(_jornadaIconData[curso.jornada!] ?? Icons.schedule,
                      size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text(
                    curso.jornada!.displayName,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      curso.anoAcademico ?? 'Año no especificado',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: curso.estado == EstadoCurso.activo
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    curso.estado.value,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔭 ESTADO VACÍO
  // ========================================

  Widget _buildEmptyState() {
    final provider = context.read<CursoProvider>();
    final hayFiltros = provider.searchQuery.isNotEmpty ||
        provider.currentNivelFilter != null ||
        provider.currentJornadaFilter != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 64, color: Color(0xFF059669)),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron cursos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hayFiltros
                ? 'Intenta con otros términos de búsqueda o filtros'
                : 'No hay cursos disponibles',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (hayFiltros) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                provider.clearAllFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}
