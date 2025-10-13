// lib/screens/usuarios/users_management_screen.dart
// 👥 PANTALLA DE GESTIÓN DE USUARIOS - FIX CONTADORES

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario.dart';
import '../../providers/usuario_provider.dart';
import '../../services/permission_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 🎨 COLORES POR ROL (igual que React Native)
  static const Map<UserRole, Color> _roleColors = {
    UserRole.superAdmin: Color(0xFF7C3AED),
    UserRole.admin: Color(0xFF6366F1),
    UserRole.rector: Color(0xFF0284C7),
    UserRole.coordinador: Color(0xFF0891B2),
    UserRole.administrativo: Color(0xFF10B981),
    UserRole.docente: Color(0xFFF59E0B),
    UserRole.estudiante: Color(0xFFEC4899),
    UserRole.acudiente: Color(0xFFEF4444),
  };

  // 🎨 ICONOS POR ROL
  static const Map<UserRole, String> _roleIcons = {
    UserRole.superAdmin: '⚡',
    UserRole.admin: '⚙️',
    UserRole.rector: '🏛️',
    UserRole.coordinador: '📊',
    UserRole.administrativo: '📋',
    UserRole.docente: '👩‍🏫',
    UserRole.estudiante: '🎓',
    UserRole.acudiente: '👨‍👩‍👧‍👦',
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
      context.read<UsuarioProvider>().loadUsuarios(refresh: true);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<UsuarioProvider>().refresh();
  }

  void _onSearch(String query) {
    final provider = context.read<UsuarioProvider>();
    if (query.isEmpty) {
      provider.clearSearch();
    } else {
      provider.search(query);
    }
  }

  String _getInitials(String nombre, String apellidos) {
    final first = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final last = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = PermissionService.canAccess('usuarios.crear');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Gestión de Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Header con info
          _buildHeader(),

          // Barra de búsqueda
          _buildSearchBar(),

          // Filtros por rol
          _buildFilters(),

          // Lista de usuarios
          Expanded(child: _buildUsersList()),
        ],
      ),

      // FAB para crear usuario (solo admin)
      floatingActionButton: canCreate ? _buildFAB() : null,
    );
  }

  // ========================================
  // 📋 HEADER CON COLOR SÓLIDO
  // ========================================

  Widget _buildHeader() {
    // ✅ FIX: Usar Consumer para actualizar cuando cambien los usuarios
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, _) {
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
                '👥 Gestión de Usuarios',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${usuarioProvider.totalUsuarios} usuario${usuarioProvider.totalUsuarios != 1 ? 's' : ''} registrado${usuarioProvider.totalUsuarios != 1 ? 's' : ''}',
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
          hintText: '🔍 Buscar por nombre, email...',
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
  // 🎯 FILTROS POR ROL (como React Native)
  // ========================================

  Widget _buildFilters() {
    // ✅ FIX: Usar Consumer para actualizar contadores
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, _) {
        final contadores = usuarioProvider.usuariosPorRol;

        final filtros = [
          _FiltroChip(
            label: 'Todos',
            icon: '👥',
            count: usuarioProvider.totalUsuarios,
            rol: null,
          ),
          _FiltroChip(
            label: 'Rectores',
            icon: _roleIcons[UserRole.rector]!,
            count: contadores[UserRole.rector] ?? 0,
            rol: UserRole.rector,
          ),
          _FiltroChip(
            label: 'Admins',
            icon: _roleIcons[UserRole.admin]!,
            count: contadores[UserRole.admin] ?? 0,
            rol: UserRole.admin,
          ),
          _FiltroChip(
            label: 'Admin.',
            icon: _roleIcons[UserRole.administrativo]!,
            count: contadores[UserRole.administrativo] ?? 0,
            rol: UserRole.administrativo,
          ),
          _FiltroChip(
            label: 'Docentes',
            icon: _roleIcons[UserRole.docente]!,
            count: contadores[UserRole.docente] ?? 0,
            rol: UserRole.docente,
          ),
          _FiltroChip(
            label: 'Acudientes',
            icon: _roleIcons[UserRole.acudiente]!,
            count: contadores[UserRole.acudiente] ?? 0,
            rol: UserRole.acudiente,
          ),
          _FiltroChip(
            label: 'Estudiantes',
            icon: _roleIcons[UserRole.estudiante]!,
            count: contadores[UserRole.estudiante] ?? 0,
            rol: UserRole.estudiante,
          ),
        ];

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtros.length,
            itemBuilder: (context, index) {
              final filtro = filtros[index];
              final isActive = usuarioProvider.currentFilter == filtro.rol;

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
                  onSelected: (_) => usuarioProvider.changeFilter(filtro.rol),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF6366F1),
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color:
                        isActive ? const Color(0xFF6366F1) : Colors.grey[300]!,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ========================================
  // 📋 LISTA DE USUARIOS
  // ========================================

  Widget _buildUsersList() {
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, _) {
        final usuarios = usuarioProvider.usuarios;
        final isLoading = usuarioProvider.isLoading;

        if (isLoading && usuarios.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (usuarios.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return _buildUserCard(usuario);
            },
          ),
        );
      },
    );
  }

  // ========================================
  // 👤 CARD DE USUARIO (como React Native)
  // ========================================

  Widget _buildUserCard(Usuario usuario) {
    final roleColor = _roleColors[usuario.tipo] ?? const Color(0xFF6366F1);
    final roleIcon = _roleIcons[usuario.tipo] ?? '👤';

    return GestureDetector(
      onTap: () => context.push('/usuarios/${usuario.id}'),
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _getInitials(usuario.nombre, usuario.apellidos),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usuario.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(roleIcon, style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        usuario.tipo.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: roleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Indicador de estado + chevron
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: usuario.estado == UserStatus.activo
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '›',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w300,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('👥', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
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

  // ========================================
  // ➕ FAB PARA CREAR USUARIO
  // ========================================

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => context.push('/usuarios/create'),
      backgroundColor: const Color(0xFF6366F1),
      child: const Icon(Icons.add, size: 28),
    );
  }
}

// ========================================
// 🎯 CLASE AUXILIAR PARA FILTROS
// ========================================

class _FiltroChip {
  final String label;
  final String icon;
  final int count;
  final UserRole? rol;

  _FiltroChip({
    required this.label,
    required this.icon,
    required this.count,
    this.rol,
  });
}
