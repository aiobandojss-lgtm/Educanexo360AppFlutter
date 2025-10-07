// lib/screens/perfil/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/usuario.dart';
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
  bool _showLogoutConfirmation = false;

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
      appBar: AppBar(
        title: const Text('👤 Mi Perfil'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
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

            // Soporte y legal
            _buildSupportSection(context),
            const SizedBox(height: 16),

            // Información de la app
            _buildAppInfo(user),
            const SizedBox(height: 24),

            // Logout
            _buildLogoutSection(context, authProvider),
            const SizedBox(height: 32),
          ],
        ),
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
                      '${_getRoleIcon(user.tipo)} ${user.tipo.displayName}',
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
            iconColor: const Color(0xFF8B5CF6),
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
            iconColor: const Color(0xFF8B5CF6),
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

  Widget _buildSupportSection(BuildContext context) {
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
              '🛠️ Soporte y Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildListItem(
            icon: Icons.help_outline,
            iconColor: Colors.grey.shade600,
            title: 'Centro de Ayuda',
            description: 'Obtén ayuda y soporte técnico',
            onTap: () => _showInfoDialog(
              context,
              'Centro de Ayuda',
              'Contacta con el administrador del sistema para obtener soporte técnico.',
            ),
          ),
          const Divider(height: 1),
          _buildListItem(
            icon: Icons.shield_outlined,
            iconColor: Colors.grey.shade600,
            title: 'Política de Privacidad',
            description: 'Revisa nuestra política de privacidad',
            onTap: () => _showInfoDialog(
              context,
              'Política de Privacidad',
              'Visita nuestro sitio web oficial para revisar la política de privacidad.',
            ),
          ),
          const Divider(height: 1),
          _buildListItem(
            icon: Icons.description_outlined,
            iconColor: Colors.grey.shade600,
            title: 'Términos y Condiciones',
            description: 'Lee los términos de uso',
            onTap: () => _showInfoDialog(
              context,
              'Términos y Condiciones',
              'Visita nuestro sitio web oficial para leer los términos de uso.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(Usuario user) {
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
              'ℹ️ Información de la App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildInfoItem(
            icon: Icons.info_outline,
            title: 'Versión',
            description: 'EDUCANEXO360 Mobile v1.0.0 (Build 1)',
          ),
          const Divider(height: 1),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.estado == UserStatus.activo
                            ? 'Activa'
                            : 'Inactiva',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        if (_showLogoutConfirmation)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '🚪 ¿Cerrar Sesión?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Estás seguro de que deseas cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _showLogoutConfirmation = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await authProvider.logout();
                          // GoRouter redirigirá automáticamente
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _showLogoutConfirmation = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '🚪 Cerrar Sesión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
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
            activeColor: const Color(0xFF6366F1),
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
        return const Color(0xFF8B5CF6);
      case UserRole.administrativo:
        return const Color(0xFF6366F1);
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

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
