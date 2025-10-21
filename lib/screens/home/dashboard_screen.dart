// lib/screens/home/dashboard_screen.dart
// ✅ CORREGIDO: Línea 276 - padding bottom de 0 a 80
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/permission_service.dart';
import '../../models/usuario.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Estadísticas reales (se cargarán del backend)
  Map<String, int> _stats = {
    'mensajesSinLeer': 0,
    'proximosEventos': 0,
    'anunciosRecientes': 0,
  };

  // Información de la escuela
  String _nombreEscuela = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user == null) return;

      // Usar user.tipo.value para obtener el string del enum
      print('🚀 Dashboard - Usuario: ${user.nombre} (${user.tipo.value})');
      print('🏫 Dashboard - EscuelaId: ${user.escuelaId}');

      // Cargar información de la escuela
      if (user.escuelaId != null && user.escuelaId!.isNotEmpty) {
        try {
          final escuela =
              await DashboardService.getEscuelaInfo(user.escuelaId!);
          if (escuela != null && mounted) {
            setState(() {
              _nombreEscuela = escuela.nombre;
            });
            print('✅ Nombre escuela cargado: ${escuela.nombre}');
          } else {
            // Si no se encuentra la escuela, usar nombre por defecto
            setState(() {
              _nombreEscuela = 'EducaNexo360';
            });
          }
        } catch (e) {
          print('⚠️ Error obteniendo escuela: $e');
          setState(() {
            _nombreEscuela = 'EducaNexo360';
          });
        }
      } else {
        // Si no hay escuelaId, usar nombre por defecto
        setState(() {
          _nombreEscuela = 'EducaNexo360';
        });
      }

      // Cargar estadísticas
      try {
        final stats = await DashboardService.getDashboardStats();
        if (mounted) {
          setState(() {
            _stats = {
              'mensajesSinLeer': stats.mensajesSinLeer,
              'proximosEventos': stats.eventosProximos,
              'anunciosRecientes': stats.anunciosRecientes,
            };
          });
        }
      } catch (e) {
        print('⚠️ Error cargando estadísticas: $e');
      }
    } catch (e) {
      print('❌ Error cargando dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadDashboardData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getRoleIcon(UserRole tipo) {
    switch (tipo) {
      case UserRole.admin:
      case UserRole.superAdmin:
        return '👑';
      case UserRole.rector:
        return '🎓';
      case UserRole.coordinador:
        return '📋';
      case UserRole.docente:
        return '👨‍🏫';
      case UserRole.estudiante:
        return '👨‍🎓';
      case UserRole.acudiente:
        return '👨‍👩‍👧';
      case UserRole.administrativo:
        return '💼';
      default:
        return '👤';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final userName = '${user.nombre} ${user.apellidos.split(' ')[0]}';
    final userRole = user.tipo.value; // Obtener el string del enum
    final roleIcon = _getRoleIcon(user.tipo);
    final schoolName = _nombreEscuela;

    // IMPORTANTE: NO usar Scaffold aquí, solo el contenido
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      color: const Color(0xFF6366F1),
      child: Stack(
        children: [
          // Fondo con gradiente sutil
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.05),
                  Colors.white,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // AppBar personalizado con menú hamburguesa
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFF6366F1),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        // Encontrar el Scaffold padre que tiene el drawer
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4), // ⭐ Agregar espacio
                          child: Text(
                            '$roleIcon $userRole • $schoolName',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    background: Container(
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
                    ),
                  ),
                ),

                // Contenido del dashboard
                // ✅ CAMBIO: padding bottom de 0 a 80
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Grid de estadísticas
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildStatsGrid(),

                      const SizedBox(height: 20),

                      // Botón Nuevo Mensaje
                      _buildActionButton(
                        context,
                        title: 'Nuevo Mensaje',
                        icon: Icons.mail_outline,
                        color: const Color(0xFF6366F1),
                        onTap: () => context.push('/mensajes/create'),
                      ),

                      const SizedBox(height: 24),

                      // Mensaje motivacional
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'La plataforma que une a toda la comunidad educativa en un solo lugar',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón Cerrar Sesión
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cerrar Sesión'),
                              content: const Text(
                                  '¿Estás seguro de que deseas cerrar sesión?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    authProvider.logout();
                                    context.go('/login');
                                  },
                                  child: const Text(
                                    'Cerrar Sesión',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildLogoCard(),
        _buildStatCard(
          value: _stats['mensajesSinLeer'].toString(),
          label: 'MENSAJES',
          color: const Color(0xFF6366F1),
          icon: Icons.mail_outline,
        ),
        _buildStatCard(
          value: _stats['proximosEventos'].toString(),
          label: 'EVENTOS',
          color: const Color(0xFFF59E0B),
          icon: Icons.calendar_today_outlined,
        ),
        _buildStatCard(
          value: _stats['anunciosRecientes'].toString(),
          label: 'ANUNCIOS',
          color: const Color(0xFF10B981),
          icon: Icons.campaign_outlined,
        ),
      ],
    );
  }

  Widget _buildLogoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9333EA),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'E360',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
