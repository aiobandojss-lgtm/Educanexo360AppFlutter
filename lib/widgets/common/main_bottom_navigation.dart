// lib/widgets/common/main_bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/permission_service.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../screens/mensajes/messages_screen.dart';
import '../../screens/calendario/calendario_screen.dart';
import '../../screens/anuncios/anuncios_screen.dart';
import '../../screens/asistencia/lista_asistencia_screen.dart';

/// Widget principal de navegación inferior con 5 tabs
/// Dashboard, Mensajes, Calendario, Anuncios, Asistencia
class MainBottomNavigation extends StatefulWidget {
  const MainBottomNavigation({super.key});

  @override
  State<MainBottomNavigation> createState() => _MainBottomNavigationState();
}

class _MainBottomNavigationState extends State<MainBottomNavigation> {
  int _currentIndex = 0;

  // Lista de pantallas según el índice
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const MessagesScreen(),
      const CalendarioScreen(),
      const AnunciosScreen(),
      const ListaAsistenciaScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Verificar que hay usuario autenticado
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: _buildDrawer(context, authProvider),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 0,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            activeIcon: Icon(Icons.mail),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Anuncios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Asistencia',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header del Drawer
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
                user.nombre.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            accountName: Text(
              user.nombreCompleto,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            accountEmail: Text(user.email),
          ),

          // Dashboard Principal (siempre visible)
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Dashboard Principal'),
            selected: _currentIndex == 0,
            onTap: () {
              Navigator.pop(context); // Cerrar drawer
              setState(() => _currentIndex = 0);
            },
          ),

          const Divider(),

          // 👥 Usuarios (solo con permiso)
          if (PermissionService.canAccess('usuarios.ver'))
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Usuarios'),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer PRIMERO
                // Usar push en lugar de go para mantener el stack
                context.push('/usuarios');
              },
            ),

          // 📚 Cursos (solo con permiso)
          if (PermissionService.canAccess('cursos.ver'))
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Cursos'),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer PRIMERO
                // Usar push en lugar de go para mantener el stack
                context.push('/cursos');
              },
            ),

          const Divider(),

          // 👤 Perfil (TODOS los usuarios)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context); // Cerrar drawer PRIMERO
              // Usar push en lugar de go para mantener el stack
              context.push('/perfil');
            },
          ),

          const Divider(),

          // 🚪 Cerrar Sesión (TODOS los usuarios)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context); // Cerrar drawer primero
              _showLogoutDialog(context, authProvider);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                authProvider.logout();
                context.go('/login');
              },
            ),
          ],
        );
      },
    );
  }
}
