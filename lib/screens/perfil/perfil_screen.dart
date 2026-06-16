// lib/screens/perfil/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/usuario.dart';
import '../../services/perfil_rol_service.dart';
import '../../widgets/common/gradient_header.dart';
import 'editar_perfil_screen.dart';
import 'cambiar_password_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;

  // Nombre del perfil personalizado (null = mostrar rol base)
  String? _perfilNombre;

  @override
  void initState() {
    super.initState();
    _cargarNombrePerfil();
  }

  Future<void> _cargarNombrePerfil() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.perfilRolId == null) return;
    final nombre = await PerfilRolService.getNombrePorId(user!.perfilRolId);
    if (mounted && nombre != null) {
      setState(() => _perfilNombre = nombre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header unificado (GradientHeader)
          const GradientHeader(
            title: 'Mi Perfil',
            showBack: true,
            leadingIcon: Icons.person,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tarjeta de perfil principal
                  _buildProfileCard(user),
                  const SizedBox(height: 16),

                  // Configuración de la cuenta
                  _buildAccountSettings(context, user),
                  const SizedBox(height: 16),

                  // Configuración de notificaciones
                  _buildNotificationsSettings(),
                  const SizedBox(height: 16),

                  // Información de la cuenta
                  _buildCuentaInfo(user),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Usuario user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getRoleColor(user.tipo),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  user.iniciales,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: _getRoleColor(user.tipo)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getRoleIcon(user.tipo)} ${_perfilNombre ?? user.tipo.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(user.tipo),
                      ),
                    ),
                  ),
                  if (user.infoContacto?.telefono != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${user.infoContacto!.telefono}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
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

  Widget _buildAccountSettings(BuildContext context, Usuario user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '⚙️ Configuración de la Cuenta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildListItem(
            icon: Icons.lock_outline,
            iconColor: const Color(0xFFF59E0B),
            title: 'Cambiar Contraseña',
            description: 'Actualiza tu contraseña de seguridad',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CambiarPasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildListItem(
            icon: Icons.edit_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Editar Perfil',
            description: 'Modifica tu información personal',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditarPerfilScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '🔔 Notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildSwitchItem(
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFF0D9488),
            title: 'Notificaciones Push',
            description: 'Recibe notificaciones en tu dispositivo',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          const Divider(height: 1),
          _buildSwitchItem(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF0D9488),
            title: 'Notificaciones por Email',
            description: 'Recibe notificaciones en tu correo',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCuentaInfo(Usuario user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'ℹ️ Información de la Cuenta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          _buildInfoItem(
            icon: Icons.calendar_today_outlined,
            title: 'Miembro desde',
            description: _formatDate(user.createdAt),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.school_outlined,
                    color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado de la cuenta',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.estado == UserStatus.activo ? 'Activa' : 'Inactiva',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.estado == UserStatus.activo
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.estado == UserStatus.activo ? 'Activa' : 'Inactiva',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return const Color(0xFFEF4444);
      case UserRole.rector:
        return const Color(0xFFF59E0B);
      case UserRole.coordinador:
        return const Color(0xFF0F766E);
      case UserRole.administrativo:
        return const Color(0xFF0891B2);
      case UserRole.docente:
        return const Color(0xFF10B981);
      case UserRole.estudiante:
        return const Color(0xFF3B82F6);
      case UserRole.acudiente:
        return const Color(0xFFEC4899);
    }
  }

  String _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return '👨‍💼';
      case UserRole.rector:
        return '👔';
      case UserRole.coordinador:
        return '📋';
      case UserRole.administrativo:
        return '💼';
      case UserRole.docente:
        return '👩‍🏫';
      case UserRole.estudiante:
        return '🎓';
      case UserRole.acudiente:
        return '👨‍👩‍👧‍👦';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no disponible';
    return DateFormat('dd/MM/yyyy').format(date);
  }

}
