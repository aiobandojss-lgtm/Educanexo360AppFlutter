// lib/screens/home/dashboard_screen.dart
// ✅ VERSIÓN FINAL CORREGIDA
import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/permission_service.dart';
import '../../models/usuario.dart';
import '../../models/ultimo_mensaje.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoadingMessages = true;
  bool _isLoadingStats = true;
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
  ProximoEvento? _proximoEvento;

  @override
  void initState() {
    super.initState();
    // Diferir la carga hasta después del primer frame para evitar el freeze
    // durante la transición de navegación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoadingMessages = true;
        _isLoadingStats = true;
      });
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    await Future.wait([
      _loadEscuelaInfo(user.escuelaId),
      _loadStats(),
      _loadMensajes(),
    ]);
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
          _proximoEvento = stats.proximoEvento;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      dlog('⚠️ Error cargando estadísticas: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadMensajes() async {
    try {
      final mensajes = await DashboardService.getUltimosMensajes(limit: 3);
      if (mounted) {
        setState(() {
          _mensajes = mensajes;
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      dlog('⚠️ Error cargando mensajes: $e');
      if (mounted) setState(() => _isLoadingMessages = false);
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
    // context.select solo rebuild cuando currentUser cambia, no ante cualquier
    // cambio en AuthProvider (ej. isLoading)
    final user = context.select<AuthProvider, Usuario?>((p) => p.currentUser);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final authProvider = context.read<AuthProvider>();
    final userName = '${user.nombre} ${user.apellidos.split(' ')[0]}';
    final userRole = user.tipo.value;
    final roleIcon = _getRoleIcon(user.tipo);
    final schoolName = _nombreEscuela;

    return Scaffold(
      drawer: _buildDrawer(context, authProvider, user),
      floatingActionButton: PermissionService.canAccess('mensajes.enviar')
          ? FloatingActionButton(
              onPressed: () => context.push('/mensajes/create'),
              backgroundColor: const Color(0xFF059669),
              tooltip: 'Nuevo Mensaje',
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            )
          : null,
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
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      _buildMensajeDestacado(),
                      const SizedBox(height: 16),
                      _buildProximoEvento(),
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
                  if (PermissionService.canAccess('asistencia.ver'))
                    _buildDrawerItem(
                      icon: Icons.fact_check_outlined,
                      title: 'Asistencia',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/asistencia');
                      },
                    ),
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
              colors: [Color(0xFF047857), Color(0xFF14B8A6)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
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
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                    maxLines: 2,
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
                    maxLines: 2,
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
  // STATS ROW
  // ==========================================
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: _isLoadingStats ? '—' : _totalMensajesSinLeer.toString(),
            label: 'MENSAJES',
            sublabel: 'sin leer',
            color: const Color(0xFF0D9488),
            icon: Icons.mail_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: _isLoadingStats ? '—' : _stats['proximosEventos'].toString(),
            label: 'EVENTOS',
            sublabel: 'próximos',
            color: const Color(0xFFF59E0B),
            icon: Icons.calendar_today_outlined,
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
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
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
              Icon(icon, color: color, size: 22),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sublabel,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MENSAJE DESTACADO (último recibido)
  // ==========================================
  Widget _buildMensajeDestacado() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                const Icon(Icons.mail_outline,
                    color: Color(0xFF059669), size: 18),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'ÚLTIMO MENSAJE',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
                if (_totalMensajesSinLeer > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${_totalMensajesSinLeer - 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(1);
                    } else {
                      context.push('/mensajes');
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver todos',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          // Contenido
          if (_isLoadingMessages)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF059669), strokeWidth: 2),
              ),
            )
          else if (_mensajes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: Color(0xFF059669), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Todo al día',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No tienes mensajes pendientes',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: () => context.push('/mensajes/${_mensajes.first.id}'),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D9488),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _mensajes.first.remitente.iniciales,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _mensajes.first.remitente.nombreCompleto,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _mensajes.first.tiempoRelativo,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mensajes.first.preview,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right,
                        color: Colors.grey.shade300, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // PRÓXIMO EVENTO
  // ==========================================
  Widget _buildProximoEvento() {
    if (_isLoadingStats) {
      return Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: Color(0xFFF59E0B), strokeWidth: 2),
          ),
        ),
      );
    }

    if (_proximoEvento == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(2);
        } else {
          context.push('/calendario');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_outlined,
                  color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRÓXIMO EVENTO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _proximoEvento!.titulo,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatEventDate(_proximoEvento!.fecha),
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(DateTime fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(fecha.year, fecha.month, fecha.day);
    final diff = eventDay.difference(today).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 7) return 'En $diff días';

    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }
}
