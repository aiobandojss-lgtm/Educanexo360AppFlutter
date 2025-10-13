// lib/screens/perfil/editar_perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/usuario_service.dart';
import '../../models/usuario.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _loading = false;
  bool _canEditEmail = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nombreController.text = user.nombre;
      _apellidosController.text = user.apellidos;
      _emailController.text = user.email;
      _telefonoController.text = user.infoContacto?.telefono ?? '';

      // Solo ADMIN puede editar email
      _canEditEmail = user.tipo.value == 'ADMIN';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      _showError('No hay usuario autenticado');
      return;
    }

    setState(() => _loading = true);

    try {
      print('📝 Actualizando perfil...');

      final updatedUser = await UsuarioService().updateUser(
        user.id,
        nombre: _nombreController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        email: _canEditEmail ? _emailController.text.trim() : null,
        telefono: _telefonoController.text.trim(),
      );

      print('✅ Perfil actualizado correctamente');

      // Actualizar el usuario en el AuthProvider
      await authProvider.refreshUser();

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil actualizado exitosamente'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Volver a la pantalla anterior
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      _showError('Error al actualizar el perfil: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Si hay cambios no guardados, preguntar
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final hasChanges = _nombreController.text != user.nombre ||
          _apellidosController.text != user.apellidos ||
          (_canEditEmail && _emailController.text != user.email) ||
          _telefonoController.text != (user.infoContacto?.telefono ?? '');

      if (hasChanges) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Descartar cambios?'),
            content: const Text(
              '¿Estás seguro de que deseas salir? Los cambios no guardados se perderán.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        return result ?? false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Perfil'),
          backgroundColor: const Color(0xFF10B981), // Verde
          actions: [
            TextButton(
              onPressed: _loading ? null : _handleSave,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'GUARDAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      user?.iniciales ?? 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.tipo.displayName ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Formulario
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📝 Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nombre
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: '👤 Nombre',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es requerido';
                            }
                            if (value.trim().length > 50) {
                              return 'Máximo 50 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Apellidos
                        TextFormField(
                          controller: _apellidosController,
                          decoration: const InputDecoration(
                            labelText: '👤 Apellidos',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Los apellidos son requeridos';
                            }
                            if (value.trim().length > 50) {
                              return 'Máximo 50 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Teléfono
                        TextFormField(
                          controller: _telefonoController,
                          decoration: const InputDecoration(
                            labelText: '📞 Teléfono',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length > 20) {
                              return 'Máximo 20 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: '📧 Email',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.email_outlined),
                            enabled: _canEditEmail,
                            helperText: _canEditEmail
                                ? null
                                : 'Solo los administradores pueden cambiar el email',
                            helperMaxLines: 2,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (_canEditEmail) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El email es requerido';
                              }
                              if (!value.contains('@')) {
                                return 'Email inválido';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0EA5E9),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ℹ️ Información',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Solo puedes editar tu información personal básica',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Para cambiar tu contraseña, usa la opción específica en el perfil',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      if (!_canEditEmail) ...[
                        const SizedBox(height: 4),
                        const Text(
                          '• Solo los administradores pueden cambiar el email',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ],
                    ],
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
