// lib/screens/perfil/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../models/usuario.dart';
import '../../services/perfil_rol_service.dart';
import '../../services/usuario_service.dart';
import '../../services/api_service.dart';
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
                  const SizedBox(height: 16),

                  // Sección legal (Política de Privacidad / Términos)
                  _buildLegalSection(),
                  const SizedBox(height: 16),

                  // Zona de peligro (Eliminar cuenta)
                  _buildDangerZone(),
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

  Widget _buildLegalSection() {
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
              '📄 Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildListItem(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFF0D9488),
            title: 'Política de Privacidad',
            description: 'Cómo tratamos y protegemos tus datos',
            onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
          ),
          const Divider(height: 1),
          _buildListItem(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF0D9488),
            title: 'Términos y Condiciones',
            description: 'Condiciones de uso del servicio',
            onTap: () => _openUrl(AppConfig.termsUrl),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    const dangerColor = Color(0xFFEF4444);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '⚠️ Zona de peligro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: dangerColor,
              ),
            ),
          ),
          InkWell(
            onTap: _confirmarEliminarCuenta,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.delete_forever_outlined,
                      color: dangerColor, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eliminar mi cuenta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: dangerColor,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Solicita eliminar tu cuenta y tus datos personales',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: dangerColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarCuenta() async {
    final eliminada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _EliminarCuentaDialog(),
    );

    if (eliminada == true && mounted) {
      // Cerrar sesión y volver al login
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace'),
        ),
      );
    }
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

/// Diálogo de confirmación para solicitar la eliminación de la cuenta.
/// Requiere la contraseña actual y permite un motivo opcional.
class _EliminarCuentaDialog extends StatefulWidget {
  const _EliminarCuentaDialog();

  @override
  State<_EliminarCuentaDialog> createState() => _EliminarCuentaDialogState();
}

class _EliminarCuentaDialogState extends State<_EliminarCuentaDialog> {
  final _passwordController = TextEditingController();
  final _motivoController = TextEditingController();
  final _usuarioService = UsuarioService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Ingresa tu contraseña para confirmar');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _usuarioService.solicitarEliminacionCuenta(
        password: password,
        motivo: _motivoController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'No se pudo completar la solicitud. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFEF4444);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: dangerColor),
          SizedBox(width: 8),
          Expanded(child: Text('Eliminar mi cuenta')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Al confirmar, tu cuenta se desactivará de inmediato y se enviará '
              'una solicitud al colegio para eliminar tus datos personales. '
              'No podrás volver a iniciar sesión.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivoController,
              enabled: !_loading,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: dangerColor, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: dangerColor),
          onPressed: _loading ? null : _eliminar,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Eliminar cuenta'),
        ),
      ],
    );
  }
}
