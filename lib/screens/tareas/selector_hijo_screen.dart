// lib/screens/tareas/selector_hijo_screen.dart
// ✅ VERSIÓN DEBUG - Para diagnosticar problema de estudiantes asociados

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';

/// Pantalla para que el acudiente seleccione cuál hijo ver
class SelectorHijoScreen extends StatefulWidget {
  /// Si es true, está siendo mostrada como tab principal (no debe tener botón atrás)
  /// Si es false, fue navegada con push (debe tener botón atrás)
  final bool isMainTab;

  const SelectorHijoScreen({
    super.key,
    this.isMainTab = false,
  });

  @override
  State<SelectorHijoScreen> createState() => _SelectorHijoScreenState();
}

class _SelectorHijoScreenState extends State<SelectorHijoScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Usuario> _estudiantes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  Future<void> _cargarEstudiantes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = context.read<AuthProvider>();

      // 🔍 DEBUG COMPLETO DEL USUARIO
      print('\n═══════════════════════════════════════');
      print('🔍 DEBUG COMPLETO - SELECTOR HIJO');
      print('═══════════════════════════════════════');
      print('👤 Usuario completo:');
      print('   Nombre: ${authProvider.currentUser?.nombreCompleto}');
      print('   Tipo: ${authProvider.currentUser?.tipo}');
      print('   ID: ${authProvider.currentUser?.id}');
      print('\n📊 Info Académica:');
      print(
          '   infoAcademica != null: ${authProvider.currentUser?.infoAcademica != null}');
      if (authProvider.currentUser?.infoAcademica != null) {
        print('   grado: ${authProvider.currentUser?.infoAcademica?.grado}');
        print('   cursos: ${authProvider.currentUser?.infoAcademica?.cursos}');
        print(
            '   asignaturas: ${authProvider.currentUser?.infoAcademica?.asignaturas}');
        print(
            '   estudiantesAsociados: ${authProvider.currentUser?.infoAcademica?.estudiantesAsociados}');
        print(
            '   estudiantesAsociados length: ${authProvider.currentUser?.infoAcademica?.estudiantesAsociados?.length ?? 0}');
      } else {
        print('   ⚠️ infoAcademica es NULL - Este es el problema');
      }
      print('═══════════════════════════════════════\n');

      final estudiantesIds =
          authProvider.currentUser?.infoAcademica?.estudiantesAsociados ?? [];

      print('📚 SELECTOR HIJO - CARGANDO ESTUDIANTES');
      print('👤 Acudiente: ${authProvider.currentUser?.nombreCompleto}');
      print('📋 IDs de estudiantes asociados: ${estudiantesIds.length}');
      print('   IDs: $estudiantesIds');
      print('🔧 isMainTab: ${widget.isMainTab}');
      print('───────────────────────────────────────');

      if (estudiantesIds.isEmpty) {
        print('⚠️ No hay estudiantes asociados');
        setState(() {
          _isLoading = false;
          _error = null;
          _estudiantes = [];
        });
        return;
      }

      // Cargar información de cada estudiante
      final List<Usuario> estudiantesTemp = [];
      int contador = 0;

      for (final estudianteId in estudiantesIds) {
        contador++;
        try {
          print(
              '\n🔍 [$contador/${estudiantesIds.length}] Cargando: $estudianteId');

          final response = await _apiService.get('/usuarios/$estudianteId');

          print('   📦 Respuesta recibida:');
          print('      Keys: ${response.keys.toList()}');
          print('      success: ${response['success']}');
          print('      data != null: ${response['data'] != null}');

          // ✅ MEJORA: Manejar diferentes formatos de respuesta
          Usuario? estudiante;

          if (response['success'] == true) {
            if (response['data'] != null) {
              print('   ✅ Formato: { success: true, data: {...} }');
              estudiante = Usuario.fromJson(response['data']);
            } else {
              print('   ✅ Formato: { success: true, ...campos directos }');
              estudiante = Usuario.fromJson(response);
            }
          } else if (response['data'] != null) {
            print('   ✅ Formato: { data: {...} }');
            estudiante = Usuario.fromJson(response['data']);
          } else {
            print('   ✅ Formato: Datos directos');
            estudiante = Usuario.fromJson(response);
          }

          if (estudiante != null) {
            print('   ✅ Estudiante cargado:');
            print('      Nombre: ${estudiante.nombre}');
            print('      Apellidos: ${estudiante.apellidos}');
            print('      Nombre completo: ${estudiante.nombreCompleto}');
            print(
                '      Curso: ${estudiante.infoAcademica?.grado ?? "Sin curso"}');

            estudiantesTemp.add(estudiante);
          } else {
            print('   ❌ No se pudo parsear el estudiante');
          }
        } catch (e, stackTrace) {
          print('   ❌ Error cargando estudiante $estudianteId:');
          print('      Error: $e');
          print(
              '      Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
        }
      }

      print('\n═══════════════════════════════════════');
      print('✅ CARGA COMPLETADA');
      print(
          '   Total estudiantes cargados: ${estudiantesTemp.length}/${estudiantesIds.length}');
      print('═══════════════════════════════════════\n');

      setState(() {
        _estudiantes = estudiantesTemp;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('\n❌ ERROR GENERAL CARGANDO ESTUDIANTES');
      print('   Error: $e');
      print(
          '   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');

      setState(() {
        _error = 'Error al cargar estudiantes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text('Tareas de mis hijos'),
        elevation: 0,
        // ✅ CRÍTICO: Solo mostrar botón atrás si NO es el tab principal
        automaticallyImplyLeading: !widget.isMainTab,
        // Si es el tab principal, agregar un leading vacío
        leading: widget.isMainTab ? const SizedBox.shrink() : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF10B981),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando información...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarEstudiantes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_estudiantes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No tienes estudiantes asociados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Contacta al administrador de tu escuela para asociar estudiantes a tu cuenta',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📚 Selecciona un estudiante',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tienes ${_estudiantes.length} estudiante${_estudiantes.length != 1 ? 's' : ''} asociado${_estudiantes.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Lista de estudiantes
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarEstudiantes,
            color: const Color(0xFF10B981),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _estudiantes.length,
              itemBuilder: (context, index) {
                final estudiante = _estudiantes[index];
                return _buildEstudianteCard(estudiante);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstudianteCard(Usuario estudiante) {
    final inicial =
        estudiante.nombre.isNotEmpty ? estudiante.nombre[0].toUpperCase() : 'E';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          print('🔗 Navegando a tareas de: ${estudiante.nombreCompleto}');
          print('   ID: ${estudiante.id}');
          print('   Usando: context.push("/tareas/hijo/${estudiante.id}")');

          // ✅ NAVEGACIÓN: Esto DEBE salir del tab y abrir pantalla completa
          context.push(
            '/tareas/hijo/${estudiante.id}',
            extra: estudiante.nombreCompleto,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar con inicial
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                child: Text(
                  inicial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información del estudiante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estudiante.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            estudiante.infoAcademica?.grado ??
                                'Sin curso asignado',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flecha
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
