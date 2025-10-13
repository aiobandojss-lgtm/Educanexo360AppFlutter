// lib/screens/home/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/permission_service.dart';
import '../../config/routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EducaNexo360'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones - Próximamente')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, authProvider),
          ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con bienvenida
              _buildHeader(user?.nombreCompleto ?? 'Usuario',
                  user?.tipo.value ?? 'Usuario'),
              const SizedBox(height: 24),

              // Cards de acceso rápido según permisos
              _buildQuickAccessCards(context),
              const SizedBox(height: 24),

              // Estadísticas (si tiene permisos)
              if (PermissionService.canAccessAny([
                'calificaciones.ver',
                'asistencia.ver',
                'usuarios.ver',
              ]))
                _buildStatsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, String userRole) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 32,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userRole,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCards(BuildContext context) {
    final cards = <Widget>[];

    // Mensajes - Todos tienen acceso
    if (PermissionService.canAccess('mensajes.enviar')) {
      cards.add(_buildAccessCard(
        context,
        title: 'Mensajes',
        icon: Icons.mail_outline,
        color: const Color(0xFF3B82F6),
        onTap: () => context.push(AppRoutes.mensajes),
      ));
    }

    // 👥 Usuarios (NUEVO)
    if (PermissionService.canAccess('usuarios.ver')) {
      cards.add(_buildAccessCard(
        context,
        title: 'Usuarios',
        icon: Icons.people_outline,
        color: const Color(0xFF6366F1),
        onTap: () => context.push('/usuarios'),
      ));
    }

    // 📚 Cursos (NUEVO - Placeholder)
    if (PermissionService.canAccess('cursos.ver')) {
      cards.add(_buildAccessCard(
        context,
        title: 'Cursos',
        icon: Icons.school_outlined,
        color: const Color(0xFF0891B2),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📚 Módulo de Cursos - Próximamente'),
              backgroundColor: Color(0xFF0891B2),
            ),
          );
        },
      ));
    }

    // Calificaciones
    if (PermissionService.canAccess('calificaciones.ver')) {
      cards.add(_buildAccessCard(
        context,
        title: 'Calificaciones',
        icon: Icons.grade_outlined,
        color: const Color(0xFF10B981),
        onTap: () => context.push(AppRoutes.calificaciones),
      ));
    }

    // Calendario
    if (PermissionService.canAccess('calendario.ver')) {
      cards.add(_buildAccessCard(
        context,
        title: 'Calendario',
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () => context.push(AppRoutes.calendario),
      ));
    }

    // Asistencia
    if (PermissionService.canAccess('asistencia.ver')) {
      cards.add(_buildAccessCard(
        context,
        title: 'Asistencia',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF8B5CF6),
        onTap: () => context.push(AppRoutes.asistencia),
      ));
    }

    // Anuncios
    if (PermissionService.canAccess('anuncios.ver')) {
      cards.add(_buildAccessCard(
        context,
        title: 'Anuncios',
        icon: Icons.campaign_outlined,
        color: const Color(0xFFEC4899),
        onTap: () => context.push(AppRoutes.anuncios),
      ));
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }

  Widget _buildAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Mensajes',
                value: '12',
                subtitle: 'sin leer',
                icon: Icons.mail_outline,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Eventos',
                value: '3',
                subtitle: 'próximos',
                icon: Icons.event_outlined,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            accountName: Text(
              user?.nombreCompleto ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            accountEmail: Text(user?.email ?? ''),
          ),

          // Inicio
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.dashboard);
            },
          ),

          const Divider(),

          // Opciones según permisos
          if (PermissionService.canAccess('mensajes.enviar'))
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Mensajes'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.mensajes);
              },
            ),

          if (PermissionService.canAccess('calificaciones.ver'))
            ListTile(
              leading: const Icon(Icons.grade_outlined),
              title: const Text('Calificaciones'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.calificaciones);
              },
            ),

          if (PermissionService.canAccess('calendario.ver'))
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Calendario'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.calendario);
              },
            ),

          if (PermissionService.canAccess('asistencia.ver'))
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Asistencia'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.asistencia);
              },
            ),

          if (PermissionService.canAccess('anuncios.ver'))
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Anuncios'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.anuncios);
              },
            ),

          // 👥 Usuarios (NUEVO)
          if (PermissionService.canAccess('usuarios.ver'))
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Usuarios'),
              onTap: () {
                Navigator.pop(context);
                context.push('/usuarios');
              },
            ),

          // 📚 Cursos (NUEVO - Placeholder)
          if (PermissionService.canAccess('cursos.ver'))
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Cursos'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📚 Módulo de Cursos - Próximamente'),
                    backgroundColor: Color(0xFF0891B2),
                  ),
                );
              },
            ),

          const Divider(),

          // Perfil
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.perfil);
            },
          ),

          // Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _handleLogout(context, authProvider),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(
      BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.logout();
      // GoRouter redirigirá automáticamente al login
    }
  }
}
