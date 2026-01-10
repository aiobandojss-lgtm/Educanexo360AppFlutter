// lib/screens/auth/login_screen.dart
// ✅ REESCRITURA COMPLETA - Basado en estructura React Native que funcionaba

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      debugPrint('✅ Login exitoso');
    } else {
      final error = authProvider.errorMessage ?? 'Error desconocido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF047857), // Emerald-700
              Color(0xFF14B8A6), // Teal-500
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'E360',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF059669), // Emerald-600
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // App Name
        const Text(
          'EDUCANEXO360',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),

        // Tagline
        const Text(
          'Tu colegio en tus manos',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Text(
          'La plataforma que une a toda la comunidad educativa',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.85),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tus credenciales',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email institucional',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                hintText: 'usuario@ejemplo.com',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.email_outlined,
                    color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu correo electrónico';
                }
                if (!value.contains('@')) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                hintText: '••••••••',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.lock_outline,
                    color: Colors.white.withOpacity(0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                if (value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Forgot Password (solo este botón, sin checkbox)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Próximamente: Recuperar contraseña')),
                  );
                },
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.9)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Login Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF059669), // Emerald-600
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF059669)), // Emerald-600
                          ),
                        )
                      : const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Footer
            Text(
              '¿Primera vez? Solicita tus credenciales en la institución',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
