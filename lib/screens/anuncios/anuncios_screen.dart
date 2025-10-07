// lib/screens/anuncios/anuncios_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/anuncio.dart';
import '../../providers/anuncio_provider.dart';
import '../../services/permission_service.dart';

class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});

  @override
  State<AnunciosScreen> createState() => _AnunciosScreenState();
}

class _AnunciosScreenState extends State<AnunciosScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<AnuncioProvider>();

    // Solo publicados para ESTUDIANTES y ACUDIENTES
    final soloPublicados = !PermissionService.canAccess('anuncios.crear');

    await provider.loadAnuncios(
      refresh: true,
      soloPublicados: soloPublicados,
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        final provider = context.read<AnuncioProvider>();
        if (!provider.isLoading && provider.hasMorePages) {
          final soloPublicados = !PermissionService.canAccess('anuncios.crear');
          provider.loadMore(soloPublicados: soloPublicados);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Verificar permisos
    final canCreateAnnouncements =
        PermissionService.canAccess('anuncios.crear');
    final soloPublicados = !canCreateAnnouncements;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchAndFilters(context, soloPublicados),
            Expanded(
              child: Consumer<AnuncioProvider>(
                builder: (context, provider, child) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        provider.refresh(soloPublicados: soloPublicados),
                    child: _buildContent(context, provider),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ✅ FAB solo si puede crear anuncios
      floatingActionButton: canCreateAnnouncements
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/anuncios/create'),
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📢 Anuncios',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<AnuncioProvider>(
            builder: (context, provider, child) {
              return Text(
                '${provider.totalAnuncios} anuncios disponibles',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, bool soloPublicados) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar anuncios...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<AnuncioProvider>()
                            .clearSearch(soloPublicados: soloPublicados);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
            ),
            onSubmitted: (value) {
              context
                  .read<AnuncioProvider>()
                  .search(value, soloPublicados: soloPublicados);
            },
          ),
          const SizedBox(height: 12),

          // Filtros
          Consumer<AnuncioProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: FiltroAnuncio.values.map((filtro) {
                    // Ocultar filtro de borradores si no puede crear
                    if (filtro == FiltroAnuncio.borradores && soloPublicados) {
                      return const SizedBox.shrink();
                    }

                    final isActive = provider.currentFilter == filtro;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(filtro.icon),
                            const SizedBox(width: 4),
                            Text(filtro.displayName),
                          ],
                        ),
                        selected: isActive,
                        onSelected: (_) {
                          provider.changeFilter(
                            filtro,
                            soloPublicados: soloPublicados,
                          );
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF10B981),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnuncioProvider provider) {
    // Loading inicial
    if (provider.isLoading && provider.anuncios.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      );
    }

    // Empty state
    if (provider.anuncios.isEmpty) {
      return _buildEmptyState(context);
    }

    // Lista de anuncios
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.anuncios.length + (provider.hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.anuncios.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            ),
          );
        }

        final anuncio = provider.anuncios[index];
        return _buildAnuncioCard(context, anuncio);
      },
    );
  }

  Widget _buildAnuncioCard(BuildContext context, Anuncio anuncio) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: anuncio.destacado
            ? const BorderSide(color: Color(0xFFF59E0B), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          context.push('/anuncios/${anuncio.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge destacado
            if (anuncio.destacado)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⭐', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'DESTACADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: tipo + fecha
                  Row(
                    children: [
                      Text(anuncio.audienceIcon,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(anuncio.audienceColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          anuncio.audienceText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(anuncio.audienceColor),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(
                            anuncio.fechaPublicacion ?? anuncio.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Contenido preview
                  Text(
                    anuncio.contenido,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer: creador + adjuntos + borrador
                  Row(
                    children: [
                      // Creador
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              'Por: ',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Expanded(
                              child: Text(
                                anuncio.creador.fullName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Adjuntos
                      if (anuncio.hasAttachments)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📎', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '${anuncio.attachmentCount}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Badge borrador
                      if (!anuncio.estaPublicado)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Borrador',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📢', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No hay anuncios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.read<AnuncioProvider>().searchQuery.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'No hay anuncios disponibles en este momento',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Hoy';
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    }

    return DateFormat('dd/MM/yyyy').format(date);
  }
}
