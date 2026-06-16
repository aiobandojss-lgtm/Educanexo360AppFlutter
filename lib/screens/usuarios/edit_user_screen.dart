// lib/screens/usuarios/edit_user_screen.dart
// ✏️ PANTALLA DE CREAR/EDITAR USUARIO - CORREGIDA
// Basada en EditUserScreen.tsx - SIN CAMPO TELÉFONO

import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario.dart';
import '../../providers/usuario_provider.dart';
import '../../services/auth_service.dart'; // ✅ AGREGADO
import '../../widgets/common/gradient_header.dart';

class EditUserScreen extends StatefulWidget {
  final String? userId; // null = crear, con valor = editar

  const EditUserScreen({
    super.key,
    this.userId,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Usuario? _usuario;
  bool _isLoading = false;
  bool _isSaving = false;

  UserRole _selectedRole = UserRole.estudiante;
  UserStatus _selectedStatus = UserStatus.activo;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _showRoleSelector = false;

  // 🎨 DESCRIPCIONES POR ROL
  static const Map<UserRole, String> _roleDescriptions = {
    UserRole.superAdmin: 'Acceso total al sistema',
    UserRole.admin: 'Gestiona toda la institución',
    UserRole.rector: 'Supervisión académica y administrativa',
    UserRole.coordinador: 'Coordinación de cursos y docentes',
    UserRole.administrativo: 'Funciones administrativas generales',
    UserRole.docente: 'Cursos, tareas y calificaciones',
    UserRole.estudiante: 'Ve tareas, entregas y calificaciones',
    UserRole.acudiente: 'Seguimiento de sus hijos asociados',
  };

  // 🎨 COLORES POR ROL
  static const Map<UserRole, Color> _roleColors = {
    UserRole.superAdmin: Color(0xFF0F766E),
    UserRole.admin: Color(0xFF059669),
    UserRole.rector: Color(0xFF0284C7),
    UserRole.coordinador: Color(0xFF0891B2),
    UserRole.administrativo: Color(0xFF10B981),
    UserRole.docente: Color(0xFFF59E0B),
    UserRole.estudiante: Color(0xFF2563EB),
    UserRole.acudiente: Color(0xFFEF4444),
  };

  bool get _isEditing => widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadUsuario();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsuario() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<UsuarioProvider>();
      final usuario = await provider.getUsuarioById(widget.userId!);

      if (usuario != null) {
        setState(() {
          _usuario = usuario;
          _nombreController.text = usuario.nombre;
          _apellidosController.text = usuario.apellidos;
          _emailController.text = usuario.email;
          _selectedRole = usuario.tipo;
          _selectedStatus = usuario.estado;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar usuario');
      context.pop();
    }
  }

  String? _validateForm() {
    if (_nombreController.text.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (_apellidosController.text.trim().isEmpty) {
      return 'Los apellidos son requeridos';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      return 'Email inválido';
    }

    // Validar contraseña solo al crear
    if (!_isEditing) {
      if (_passwordController.text.length < 6) {
        return 'La contraseña debe tener al menos 6 caracteres';
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        return 'Las contraseñas no coinciden';
      }
    }

    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validationError = _validateForm();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<UsuarioProvider>();

      if (_isEditing) {
        // Actualizar usuario existente
        await provider.updateUsuario(
          id: widget.userId!,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          tipo: _selectedRole,
          estado: _selectedStatus,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Usuario actualizado exitosamente\n\n💡 Para cambiar la contraseña, el usuario debe hacerlo desde su perfil.',
              ),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 4),
            ),
          );
          context.pop();
        }
      } else {
        // ✅ FIX: Obtener escuelaId del AuthService correctamente
        final authService = AuthService(); // Singleton
        final escuelaId = authService.currentUser?.escuelaId;

        if (escuelaId == null || escuelaId.isEmpty) {
          _showError(
              '❌ No se pudo obtener la escuela. Intenta cerrar sesión y volver a entrar.');
          setState(() => _isSaving = false);
          return;
        }

        dlog('🏫 Usando escuelaId: $escuelaId');

        // Crear nuevo usuario
        final usuario = await provider.createUsuario(
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
          tipo: _selectedRole,
          estado: _selectedStatus,
          escuelaId: escuelaId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Usuario ${usuario.nombreCompleto} creado exitosamente',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      dlog('❌ Error completo: $e');
      _showError('Error al guardar usuario: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Cargando...',
              showBack: true,
              leadingIcon: Icons.person,
            ),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Contenido principal
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildPersonalInfoCard(),
                          const SizedBox(height: 16),
                          if (!_isEditing) _buildPasswordCard(),
                          if (!_isEditing) const SizedBox(height: 16),
                          _buildSystemConfigCard(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),

        // Modal de selector de rol
        if (_showRoleSelector) _buildRoleSelectorModal(),
      ],
    );
  }

  // ========================================
  // 📋 HEADER
  // ========================================

  Widget _buildHeader() {
    return GradientHeader(
      title: _isEditing ? 'Editar Usuario' : 'Crear Usuario',
      showBack: true,
      leadingIcon: _isEditing ? Icons.edit : Icons.person_add,
      onBack: () => context.pop(),
    );
  }

  // ========================================
  // 👤 INFORMACIÓN PERSONAL
  // ========================================

  Widget _buildPersonalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.person, 'Información Personal'),
            const SizedBox(height: 16),

            // Nombre
            _buildTextField(
              label: 'Nombre *',
              controller: _nombreController,
              hint: 'Nombre del usuario',
            ),

            const SizedBox(height: 16),

            // Apellidos
            _buildTextField(
              label: 'Apellidos *',
              controller: _apellidosController,
              hint: 'Apellidos del usuario',
            ),

            const SizedBox(height: 16),

            // Email
            _buildTextField(
              label: 'Email *',
              controller: _emailController,
              hint: 'correo@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
            ),

            // Aviso de contraseña en modo edición
            if (_isEditing) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: Color(0xFF92400E)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Para cambiar la contraseña, ve al Detalle del usuario → Cambiar Contraseña.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔒 CONTRASEÑA (solo al crear)
  // ========================================

  Widget _buildPasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.lock, 'Contraseña'),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0369A1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 20, color: Color(0xFF0369A1)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La contraseña se encriptará automáticamente en el servidor',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0369A1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contraseña
            _buildPasswordField(
              label: 'Contraseña *',
              controller: _passwordController,
              showPassword: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
            ),

            const SizedBox(height: 16),

            // Confirmar contraseña
            _buildPasswordField(
              label: 'Confirmar Contraseña *',
              controller: _confirmPasswordController,
              showPassword: _showConfirmPassword,
              onToggle: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // ⚙️ CONFIGURACIÓN DEL SISTEMA
  // ========================================

  Widget _buildSystemConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.settings, 'Configuración del Sistema'),
            const SizedBox(height: 16),

            // Selector de rol
            const Text(
              'Rol del Usuario *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showRoleSelector = true),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _roleColors[_selectedRole],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedRole.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Text(
                      '›',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estado
            const Text(
              'Estado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedStatus == UserStatus.activo
                          ? 'Activo'
                          : 'Inactivo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _selectedStatus == UserStatus.activo,
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus =
                            value ? UserStatus.activo : UserStatus.inactivo;
                      });
                    },
                    activeThumbColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔧 WIDGETS AUXILIARES
  // ========================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: 'Contraseña',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ========================================
  // 📋 BOTTOM BAR CON BOTONES
  // ========================================

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
        children: [
          // Botón cancelar
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón guardar
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Actualizar' : 'Crear Usuario',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ========================================
  // 🎯 MODAL SELECTOR DE ROL - CORREGIDO
  // ========================================

  Widget _buildRoleSelectorModal() {
    const roles = UserRole.values;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(
            maxHeight: 500,
            maxWidth: 400,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del modal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const Text(
                  'Seleccionar Rol',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Lista con scroll
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...roles.map((role) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRole = role;
                              _showRoleSelector = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _selectedRole == role
                                  ? const Color(0xFFF8FAFC)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == role
                                    ? _roleColors[role]!
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _roleColors[role],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.displayName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: _selectedRole == role
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: _selectedRole == role
                                              ? _roleColors[role]
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _roleDescriptions[role] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Footer con botón cancelar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    setState(() => _showRoleSelector = false);
                  },
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
