// lib/screens/home/dashboard_screen.dart
// ✅ VERSIÓN FINAL CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/permission_service.dart';
import '../../models/usuario.dart';
import '../../models/ultimo_mensaje.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Map<String, int> _stats = {
    'mensajesSinLeer': 0,
    'proximosEventos': 0,
    'anunciosRecientes': 0,
  };

  String _nombreEscuela = 'Cargando...';
  List<UltimoMensaje> _mensajes = [];
  int _totalMensajesSinLeer = 0;

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

      await Future.wait([
        _loadEscuelaInfo(user.escuelaId),
        _loadStats(),
        _loadMensajes(),
      ]);
    } catch (e) {
      print('❌ Error cargando dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEscuelaInfo(String? escuelaId) async {
    if (escuelaId != null && escuelaId.isNotEmpty) {
      try {
        final escuela = await DashboardService.getEscuelaInfo(escuelaId);
        if (escuela != null && mounted) {
          setState(() => _nombreEscuela = escuela.nombre);
        } else {
          setState(() => _nombreEscuela = 'EducaNexo360');
        }
      } catch (e) {
        if (mounted) setState(() => _nombreEscuela = 'EducaNexo360');
      }
    } else {
      setState(() => _nombreEscuela = 'EducaNexo360');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DashboardService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = {
            'mensajesSinLeer': stats.mensajesSinLeer,
            'proximosEventos': stats.eventosProximos,
            'anunciosRecientes': stats.anunciosRecientes,
          };
          _totalMensajesSinLeer = stats.mensajesSinLeer;
        });
      }
    } catch (e) {
      print('⚠️ Error cargando estadísticas: $e');
    }
  }

  Future<void> _loadMensajes() async {
    try {
      final mensajes = await DashboardService.getUltimosMensajes(limit: 3);
      if (mounted) {
        setState(() {
          _mensajes = mensajes;
          // ✅ Usar el contador de _stats (ya se cargó en _loadStats)
          // No hacer llamada extra a getContadorMensajesSinLeer()
        });
      }
    } catch (e) {
      print('⚠️ Error cargando mensajes: $e');
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
        return '📊';
      case UserRole.docente:
        return '👨‍🏫';
      case UserRole.estudiante:
        return '🎒';
      case UserRole.acudiente:
        return '👨‍👩‍👧';
      case UserRole.administrativo:
        return '💼';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final userName = '${user.nombre} ${user.apellidos.split(' ')[0]}';
    final userRole = user.tipo.value;
    final roleIcon = _getRoleIcon(user.tipo);
    final schoolName = _nombreEscuela;

    return Scaffold(
      drawer: _buildDrawer(context, authProvider, user),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: const Color(0xFF059669),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(userName, userRole, roleIcon, schoolName),
              Container(
                color: const Color(0xFFF0FDF4),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildMensajesCard(),
                      const SizedBox(height: 24),
                      _buildAccionesRapidas(context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DRAWER CON USUARIOS, CURSOS, ASISTENCIA, PERFIL
  // ==========================================
  Widget _buildDrawer(
      BuildContext context, AuthProvider authProvider, Usuario user) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header del drawer
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF047857), Color(0xFF14B8A6)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${user.nombre[0]}${user.apellidos[0]}',
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${user.nombre} ${user.apellidos}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.tipo.value,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Opciones del menú
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // USUARIOS
                  if (PermissionService.canAccess('usuarios.ver'))
                    _buildDrawerItem(
                      icon: Icons.people_outline,
                      title: 'Usuarios',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/usuarios');
                      },
                    ),
                  // CURSOS
                  if (PermissionService.canAccess('cursos.ver'))
                    _buildDrawerItem(
                      icon: Icons.school_outlined,
                      title: 'Cursos',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/cursos');
                      },
                    ),
                  // ASISTENCIA
                  /*if (PermissionService.canAccess('asistencia.ver'))
                    _buildDrawerItem(
                      icon: Icons.fact_check_outlined,
                      title: 'Asistencia',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/asistencia');
                      },
                    ),*/
                  const Divider(),
                  // PERFIL
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Mi Perfil',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/perfil');
                    },
                  ),
                ],
              ),
            ),
            // Botón cerrar sesión
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cerrar Sesión'),
                        content: const Text(
                            '¿Estás seguro de que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              authProvider.logout();
                              context.go('/login');
                            },
                            child: const Text('Cerrar Sesión',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Cerrar Sesión'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF047857)),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  // ==========================================
  // HEADER CON LOGO GRANDE + TEXTO
  // ==========================================
  Widget _buildHeader(
      String userName, String userRole, String roleIcon, String schoolName) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF047857), Color(0xFF0D9488)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  // Nombre
                  Text(
                    userName,
                    style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rol y escuela
                  Text(
                    '$roleIcon $userRole • $schoolName',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // ✅ LOGO GRANDE CENTRADO
                  /*Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_educanexo_blanco.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        // ✅ TEXTO DEBAJO DEL LOGO
                        const Text(
                          'La plataforma que une a toda la comunidad educativa',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),*/
                ],
              ),
            ),
          ),
        ),
        // Menú hamburguesa
        SafeArea(
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STATS ROW - SIN LINKS (SOLO INFORMATIVO)
  // ==========================================
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: _stats['proximosEventos'].toString(),
            label: 'EVENTOS',
            sublabel: '', //'próximos 30 días',
            color: const Color(0xFFF59E0B),
            icon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: _stats['anunciosRecientes'].toString(),
            label: 'ANUNCIOS',
            sublabel: '', //'últimos 7 días',
            color: const Color(0xFF10B981),
            icon: Icons.campaign_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required String sublabel,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MENSAJES CARD
  // ==========================================
  Widget _buildMensajesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mail_outline,
                        color: Color(0xFF059669), size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Últimos Mensajes',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857)),
                    ),
                    if (_totalMensajesSinLeer > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _totalMensajesSinLeer.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/mensajes'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver todos',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF059669), strokeWidth: 2)),
            )
          else if (_mensajes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.mail_outline,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No hay mensajes nuevos',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _mensajes.asMap().entries.map((entry) {
                final index = entry.key;
                final mensaje = entry.value;
                final avatarColors = [
                  const Color(0xFF0D9488),
                  const Color(0xFF059669),
                  const Color(0xFF047857),
                ];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border(
                      top: index == 0
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/mensajes/${mensaje.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: avatarColors[index % 3],
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                mensaje.remitente.iniciales,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mensaje.remitente.nombreCompleto,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '"${mensaje.preview}"',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  mensaje.tiempoRelativo,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF059669),
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // ACCIONES RÁPIDAS
  // ==========================================
  Widget _buildAccionesRapidas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF047857)),
        ),
        const SizedBox(height: 16),
        if (PermissionService.canAccess('mensajes.enviar'))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/mensajes/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Nuevo Mensaje',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'EducaNexo360 v1.0 • 2025',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
}
