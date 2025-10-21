// lib/screens/cursos/courses_screen.dart
// 📚 PANTALLA DE GESTIÓN DE CURSOS - SIGUIENDO PATRÓN DE USUARIOS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/curso.dart';
import '../../providers/curso_provider.dart';
import '../../services/permission_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 🎨 COLORES POR NIVEL
  static const Map<NivelEducativo, Color> _nivelColors = {
    NivelEducativo.preescolar: Color(0xFFFF6B6B),
    NivelEducativo.primaria: Color(0xFF4ECDC4),
    NivelEducativo.secundaria: Color(0xFF45B7D1),
    NivelEducativo.media: Color(0xFF96CEB4),
  };

  // 🎨 ICONOS POR NIVEL
  static const Map<NivelEducativo, String> _nivelIcons = {
    NivelEducativo.preescolar: '🧸',
    NivelEducativo.primaria: '📚',
    NivelEducativo.secundaria: '🎓',
    NivelEducativo.media: '🎯',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CursoProvider>().loadCursos(refresh: true);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<CursoProvider>().refresh();
  }

  void _onSearch(String query) {
    final provider = context.read<CursoProvider>();
    if (query.isEmpty) {
      provider.clearSearch();
    } else {
      provider.search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canView = PermissionService.canAccess('cursos.ver');

    if (!canView) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          title: const Text('📚 Gestión de Cursos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔒', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text(
                'Acceso Restringido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('📚 Gestión de Cursos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildNivelFilters(),
          _buildJornadaFilters(),
          Expanded(child: _buildCoursesList()),
        ],
      ),
    );
  }

  // ========================================
  // 📋 HEADER CON COLOR SÓLIDO
  // ========================================

  Widget _buildHeader() {
    return Consumer<CursoProvider>(
      builder: (context, cursoProvider, _) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF6366F1),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📚 Gestión de Cursos',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${cursoProvider.totalCursos} curso${cursoProvider.totalCursos != 1 ? 's' : ''} registrado${cursoProvider.totalCursos != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
          hintText: '🔍 Buscar cursos, docentes...',
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
  // 🎯 FILTROS POR NIVEL
  // ========================================

  Widget _buildNivelFilters() {
    return Consumer<CursoProvider>(
      builder: (context, cursoProvider, _) {
        final contadores = cursoProvider.cursosPorNivel;
        final activeFilter = cursoProvider.currentNivelFilter;

        final filtros = [
          _FiltroChip(
            label: 'Todos',
            icon: '📚',
            count: cursoProvider.totalCursos,
            nivel: null,
          ),
          _FiltroChip(
            label: 'Preescolar',
            icon: _nivelIcons[NivelEducativo.preescolar]!,
            count: contadores[NivelEducativo.preescolar] ?? 0,
            nivel: NivelEducativo.preescolar,
          ),
          _FiltroChip(
            label: 'Primaria',
            icon: _nivelIcons[NivelEducativo.primaria]!,
            count: contadores[NivelEducativo.primaria] ?? 0,
            nivel: NivelEducativo.primaria,
          ),
          _FiltroChip(
            label: 'Secundaria',
            icon: _nivelIcons[NivelEducativo.secundaria]!,
            count: contadores[NivelEducativo.secundaria] ?? 0,
            nivel: NivelEducativo.secundaria,
          ),
          _FiltroChip(
            label: 'Media',
            icon: _nivelIcons[NivelEducativo.media]!,
            count: contadores[NivelEducativo.media] ?? 0,
            nivel: NivelEducativo.media,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Filtrar por Nivel:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtros.length,
                itemBuilder: (context, index) {
                  final filtro = filtros[index];
                  final isActive = activeFilter == filtro.nivel;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isActive,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(filtro.icon),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                filtro.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${filtro.count}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onSelected: (_) =>
                          cursoProvider.changeNivelFilter(filtro.nivel),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF6366F1),
                      labelStyle: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isActive
                            ? const Color(0xFF6366F1)
                            : Colors.grey[300]!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================
  // 🕐 FILTROS POR JORNADA
  // ========================================

  Widget _buildJornadaFilters() {
    return Consumer<CursoProvider>(
      builder: (context, cursoProvider, _) {
        final contadores = cursoProvider.cursosPorJornada;
        final activeFilter = cursoProvider.currentJornadaFilter;

        final filtros = [
          _FiltroJornadaChip(
            label: 'Todas',
            icon: '🕐',
            count: cursoProvider.totalCursos,
            jornada: null,
          ),
          _FiltroJornadaChip(
            label: 'Matutina',
            icon: Jornada.matutina.icono,
            count: contadores[Jornada.matutina] ?? 0,
            jornada: Jornada.matutina,
          ),
          _FiltroJornadaChip(
            label: 'Vespertina',
            icon: Jornada.vespertina.icono,
            count: contadores[Jornada.vespertina] ?? 0,
            jornada: Jornada.vespertina,
          ),
          _FiltroJornadaChip(
            label: 'Nocturna',
            icon: Jornada.nocturna.icono,
            count: contadores[Jornada.nocturna] ?? 0,
            jornada: Jornada.nocturna,
          ),
          _FiltroJornadaChip(
            label: 'Completa',
            icon: Jornada.completa.icono,
            count: contadores[Jornada.completa] ?? 0,
            jornada: Jornada.completa,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Filtrar por Jornada:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtros.length,
                itemBuilder: (context, index) {
                  final filtro = filtros[index];
                  final isActive = activeFilter == filtro.jornada;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isActive,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(filtro.icon),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                filtro.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${filtro.count}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onSelected: (_) =>
                          cursoProvider.changeJornadaFilter(filtro.jornada),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF6366F1),
                      labelStyle: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isActive
                            ? const Color(0xFF6366F1)
                            : Colors.grey[300]!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

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
    final nivelColor = _nivelColors[curso.nivel] ?? const Color(0xFF6366F1);
    final nivelIcon = _nivelIcons[curso.nivel] ?? '📚';

    return GestureDetector(
      onTap: () => context.push('/cursos/${curso.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                Text(nivelIcon, style: const TextStyle(fontSize: 20)),
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
                const Text('👩‍🏫', style: TextStyle(fontSize: 14)),
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
                const Text('👥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${curso.totalEstudiantes} estudiantes',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                const Text('📚', style: TextStyle(fontSize: 14)),
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
                  Text(curso.jornada!.icono,
                      style: const TextStyle(fontSize: 14)),
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
                Text(
                  '📅 ${curso.anoAcademico ?? 'Año no especificado'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
          const Text('📚', style: TextStyle(fontSize: 64)),
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
                backgroundColor: const Color(0xFF6366F1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('🧹 Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}

// ========================================
// 🎯 CLASES AUXILIARES PARA FILTROS
// ========================================

class _FiltroChip {
  final String label;
  final String icon;
  final int count;
  final NivelEducativo? nivel;

  _FiltroChip({
    required this.label,
    required this.icon,
    required this.count,
    this.nivel,
  });
}

class _FiltroJornadaChip {
  final String label;
  final String icon;
  final int count;
  final Jornada? jornada;

  _FiltroJornadaChip({
    required this.label,
    required this.icon,
    required this.count,
    this.jornada,
  });
}
