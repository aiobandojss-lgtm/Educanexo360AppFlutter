// lib/screens/anuncios/anuncios_screen.dart
// ✅ CORREGIDO: Header con color sólido + AppBar con navegación

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/anuncio.dart';
import '../../providers/anuncio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/permission_service.dart';

class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});

  @override
  State<AnunciosScreen> createState() => _AnunciosScreenState();
}

class _AnunciosScreenState extends State<AnunciosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ✅ FILTROS SIN "BORRADORES" - Como React Native
  static const List<FiltroAnuncio> _filtros = [
    FiltroAnuncio.todos,
    FiltroAnuncio.destacados,
    FiltroAnuncio.estudiantes,
    FiltroAnuncio.docentes,
    FiltroAnuncio.padres,
  ];

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
      final anuncioProvider = context.read<AnuncioProvider>();
      final canCreate = PermissionService.canAccess('anuncios.crear');

      // Cargar con soloPublicados según permisos
      anuncioProvider.loadAnuncios(
        refresh: true,
        soloPublicados: !canCreate,
      );
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final anuncioProvider = context.read<AnuncioProvider>();
        if (anuncioProvider.hasMorePages && !anuncioProvider.isLoading) {
          final canCreate = PermissionService.canAccess('anuncios.crear');
          anuncioProvider.loadMore(soloPublicados: !canCreate);
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    final anuncioProvider = context.read<AnuncioProvider>();
    final canCreate = PermissionService.canAccess('anuncios.crear');
    await anuncioProvider.refresh(soloPublicados: !canCreate);
  }

  void _onFilterChanged(FiltroAnuncio filtro) {
    final anuncioProvider = context.read<AnuncioProvider>();
    final canCreate = PermissionService.canAccess('anuncios.crear');
    anuncioProvider.changeFilter(filtro, soloPublicados: !canCreate);
  }

  void _onSearch(String query) {
    final anuncioProvider = context.read<AnuncioProvider>();
    final canCreate = PermissionService.canAccess('anuncios.crear');

    if (query.isEmpty) {
      anuncioProvider.clearSearch(soloPublicados: !canCreate);
    } else {
      anuncioProvider.search(query, soloPublicados: !canCreate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = PermissionService.canAccess('anuncios.crear');

    return Scaffold(
      // ✅ AGREGAR AppBar con navegación
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Anuncios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // ✅ HEADER CON COLOR SÓLIDO - Sin gradient
          _buildHeader(),

          // Barra de búsqueda
          _buildSearchBar(),

          // Filtros
          _buildFilters(),

          // Info banner (solo admin/docentes)
          if (canCreate) _buildInfoBanner(),

          // Lista de anuncios
          Expanded(child: _buildAnunciosList()),
        ],
      ),

      // FAB solo si puede crear
      floatingActionButton: canCreate ? _buildFAB() : null,
    );
  }

  // ✅ HEADER CON COLOR SÓLIDO (sin gradient)
  Widget _buildHeader() {
    final anuncioProvider = context.watch<AnuncioProvider>();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF10B981), // ✅ Color sólido como React Native
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📢 Tablero de Anuncios',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${anuncioProvider.totalAnuncios} anuncios disponibles',
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
          hintText: 'Buscar anuncios...',
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

  Widget _buildFilters() {
    final anuncioProvider = context.watch<AnuncioProvider>();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtros.length,
        itemBuilder: (context, index) {
          final filtro = _filtros[index];
          final isActive = anuncioProvider.currentFilter == filtro;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isActive,
              label: Text(filtro.displayName),
              onSelected: (_) => _onFilterChanged(filtro),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF10B981),
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isActive ? const Color(0xFF10B981) : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Text('ℹ️', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estás viendo todos los anuncios, incluyendo borradores y publicados.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF0277BD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnunciosList() {
    return Consumer<AnuncioProvider>(
      builder: (context, anuncioProvider, _) {
        final anuncios = anuncioProvider.anuncios;
        final isLoading = anuncioProvider.isLoading;

        if (isLoading && anuncios.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (anuncios.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: anuncios.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == anuncios.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final anuncio = anuncios[index];
              return _buildAnuncioCard(anuncio);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnuncioCard(Anuncio anuncio) {
    return GestureDetector(
      onTap: () => context.push('/anuncios/${anuncio.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                anuncio.destacado ? const Color(0xFFF59E0B) : Colors.grey[300]!,
            width: anuncio.destacado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge destacado
            if (anuncio.destacado) _buildDestacadoBadge(),

            // Contenido
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                anuncio.destacado ? 16 : 16,
                16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: tipo + fecha
                  Row(
                    children: [
                      Text(anuncio.audienceIcon,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(anuncio.audienceColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          anuncio.audienceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(
                            anuncio.fechaPublicacion ?? anuncio.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título
                  Text(
                    anuncio.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Contenido preview
                  Text(
                    anuncio.contenido,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Footer: creador + badge borrador
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Por: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              anuncio.creador.fullName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badge borrador
                      if (anuncio.isDraft)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Borrador',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Adjuntos info
                  if (anuncio.hasAttachments) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📎', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '${anuncio.attachmentCount} adjunto${anuncio.attachmentCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestacadoBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF59E0B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('⭐', style: TextStyle(fontSize: 12)),
          SizedBox(width: 4),
          Text(
            'Destacado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📢', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'No se encontraron anuncios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => context.push('/anuncios/create'),
      backgroundColor: const Color(0xFF10B981),
      child: const Icon(Icons.add, size: 28),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'hoy';
    if (difference.inDays == 1) return 'ayer';
    if (difference.inDays < 7) return 'hace ${difference.inDays} días';
    if (difference.inDays < 30)
      return 'hace ${(difference.inDays / 7).floor()} semanas';
    return 'hace ${(difference.inDays / 30).floor()} meses';
  }
}
