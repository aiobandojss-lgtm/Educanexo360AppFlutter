// lib/screens/usuarios/user_detail_screen.dart
// 👤 PANTALLA DE DETALLE DE USUARIO
// Basada en UserDetailScreen.tsx - DISEÑO FIEL AL ORIGINAL

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/usuario.dart';
import '../../providers/usuario_provider.dart';
import '../../services/permission_service.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Usuario? _usuario;
  List<Usuario> _estudiantesAsociados = [];
  bool _isLoading = true;

  // 🎨 COLORES POR ROL
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
    _loadUsuario();
  }

  Future<void> _loadUsuario() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<UsuarioProvider>();
      final usuario = await provider.getUsuarioById(widget.userId);

      if (usuario != null) {
        setState(() => _usuario = usuario);

        // Si es acudiente, cargar estudiantes asociados
        if (usuario.tipo == UserRole.acudiente) {
          await _loadEstudiantesAsociados();
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar usuario');
    }
  }

  Future<void> _loadEstudiantesAsociados() async {
    try {
      final provider = context.read<UsuarioProvider>();
      final estudiantes = await provider.getEstudiantesAsociados(widget.userId);
      setState(() => _estudiantesAsociados = estudiantes);
    } catch (e) {
      print('Error cargando estudiantes asociados: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    context.pop();
  }

  bool _canEdit() {
    if (_usuario == null) return false;

    final currentUser = PermissionService.getCurrentUser();
    if (currentUser != null && _usuario!.id == currentUser.id) {
      return true;
    }

    return PermissionService.canAccess('usuarios.editar');
  }

  String _getInitials(String nombre, String apellidos) {
    final first = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final last = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$first$last';
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${_usuario!.nombreCompleto}?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final provider = context.read<UsuarioProvider>();
        await provider.deleteUsuario(widget.userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Usuario eliminado exitosamente'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          context.pop();
        }
      } catch (e) {
        _showError('Error al eliminar usuario: $e');
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña Actual',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final provider = context.read<UsuarioProvider>();
        await provider.changePassword(
          userId: widget.userId,
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Contraseña cambiada exitosamente'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        _showError('Error al cambiar contraseña: $e');
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _usuario == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          title: const Text('Cargando...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 12),
                    _buildContactSection(),
                    const SizedBox(height: 12),
                    if (_usuario!.infoAcademica != null)
                      _buildAcademicSection(),
                    if (_usuario!.infoAcademica != null)
                      const SizedBox(height: 12),
                    if (_usuario!.tipo == UserRole.acudiente)
                      _buildEstudiantesSection(),
                    if (_usuario!.tipo == UserRole.acudiente)
                      const SizedBox(height: 12),
                    _buildActionsSection(),
                    const SizedBox(height: 12),
                    _buildSystemInfoSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _canEdit() ? _buildEditFAB() : null,
    );
  }

  // ========================================
  // 📋 HEADER
  // ========================================

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF6366F1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalle de Usuario',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _usuario!.tipo.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 👤 PERFIL
  // ========================================

  Widget _buildProfileSection() {
    final roleColor = _roleColors[_usuario!.tipo]!;
    final roleIcon = _roleIcons[_usuario!.tipo]!;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: roleColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _getInitials(_usuario!.nombre, _usuario!.apellidos),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _usuario!.nombreCompleto,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(roleIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  _usuario!.tipo.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _usuario!.estado == UserStatus.activo
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _usuario!.estado == UserStatus.activo
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _usuario!.estado == UserStatus.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _usuario!.estado == UserStatus.activo
                        ? const Color(0xFF065F46)
                        : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📞 CONTACTO
  // ========================================

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📞 Información de Contacto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Email', _usuario!.email,
              onTap: () => _launchEmail(_usuario!.email)),
          if (_usuario!.infoContacto?.telefono != null)
            _buildInfoRow(
              'Teléfono',
              _usuario!.infoContacto!.telefono!,
              onTap: () => _launchPhone(_usuario!.infoContacto!.telefono!),
            ),
          if (_usuario!.infoContacto?.direccion != null)
            _buildInfoRow('Dirección', _usuario!.infoContacto!.direccion!),
          if (_usuario!.infoContacto?.ciudad != null)
            _buildInfoRow('Ciudad', _usuario!.infoContacto!.ciudad!),
        ],
      ),
    );
  }

  // ========================================
  // 🎓 INFORMACIÓN ACADÉMICA
  // ========================================

  Widget _buildAcademicSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎓 Información Académica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_usuario!.infoAcademica?.grado != null)
            _buildInfoRow('Grado', _usuario!.infoAcademica!.grado!),
          if (_usuario!.infoAcademica?.cursos != null)
            _buildInfoRow(
              'Cursos',
              '${_usuario!.infoAcademica!.cursos!.length} curso(s) asignado(s)',
            ),
        ],
      ),
    );
  }

  // ========================================
  // 👨‍👩‍👧‍👦 ESTUDIANTES ASOCIADOS
  // ========================================

  Widget _buildEstudiantesSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 Estudiantes Asociados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_estudiantesAsociados.isEmpty)
            const Text(
              'No hay estudiantes asociados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._estudiantesAsociados.map((estudiante) {
              return _buildEstudianteItem(estudiante);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEstudianteItem(Usuario estudiante) {
    final roleColor = _roleColors[estudiante.tipo]!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: roleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getInitials(estudiante.nombre, estudiante.apellidos),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estudiante.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estudiante.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ⚙️ ACCIONES
  // ========================================

  Widget _buildActionsSection() {
    final canDelete = PermissionService.canAccess('usuarios.eliminar');
    final canChangePassword =
        PermissionService.canAccess('usuarios.cambiar_password');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Acciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_canEdit())
            _buildActionButton(
              'Editar Usuario',
              Icons.edit_outlined,
              const Color(0xFF6366F1),
              () => context.push('/usuarios/edit/${widget.userId}'),
            ),
          if (_usuario!.tipo == UserRole.acudiente &&
              PermissionService.canAccess('usuarios.editar')) ...[
            const SizedBox(height: 12),
            _buildActionButton(
              'Gestionar Estudiantes',
              Icons.school_outlined,
              const Color(0xFF0891B2),
              () => context.push('/usuarios/manage-students/${widget.userId}'),
            ),
          ],
          if (canChangePassword) ...[
            const SizedBox(height: 12),
            _buildActionButton(
              'Cambiar Contraseña',
              Icons.lock_outline,
              const Color(0xFFF59E0B),
              _handleChangePassword,
            ),
          ],
          if (canDelete) ...[
            const SizedBox(height: 12),
            _buildActionButton(
              'Eliminar Usuario',
              Icons.delete_outline,
              const Color(0xFFEF4444),
              _handleDelete,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  // ========================================
  // ⚙️ INFORMACIÓN DEL SISTEMA
  // ========================================

  Widget _buildSystemInfoSection() {
    final dateFormat = DateFormat('d MMMM yyyy', 'es');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Información del Sistema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_usuario!.createdAt != null)
            _buildInfoRow(
              'Fecha de registro',
              dateFormat.format(_usuario!.createdAt!),
            ),
          if (_usuario!.updatedAt != null)
            _buildInfoRow(
              'Última actualización',
              dateFormat.format(_usuario!.updatedAt!),
            ),
          if (_usuario!.ultimoAcceso != null)
            _buildInfoRow(
              'Último acceso',
              dateFormat.format(_usuario!.ultimoAcceso!),
            ),
          _buildInfoRow(
            'ID del usuario',
            _usuario!.id,
            mono: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool mono = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ✏️ FAB PARA EDITAR
  // ========================================

  Widget _buildEditFAB() {
    return FloatingActionButton(
      onPressed: () => context.push('/usuarios/edit/${widget.userId}'),
      backgroundColor: const Color(0xFF6366F1),
      child: const Icon(Icons.edit, size: 20),
    );
  }
}
