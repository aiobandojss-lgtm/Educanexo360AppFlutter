// lib/screens/cursos/course_detail_screen.dart
// 📚 PANTALLA DE DETALLE DE CURSO - CON 3 PESTAÑAS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/curso.dart';
import '../../providers/curso_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final String cursoId;

  const CourseDetailScreen({
    super.key,
    required this.cursoId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Curso? _curso;
  List<EstudianteCurso> _estudiantes = [];
  List<AsignaturaCurso> _asignaturas = [];
  bool _isLoading = true;
  bool _loadingEstudiantes = false;
  bool _loadingAsignaturas = false;

  int _selectedTabIndex = 0;

  // 🎨 COLORES POR NIVEL
  static const Map<NivelEducativo, Color> _nivelColors = {
    NivelEducativo.preescolar: Color(0xFFFF6B6B),
    NivelEducativo.primaria: Color(0xFF4ECDC4),
    NivelEducativo.secundaria: Color(0xFF45B7D1),
    NivelEducativo.media: Color(0xFF96CEB4),
  };

  // 🎨 ICONOS POR NIVEL
  static const Map<NivelEducativo, String> _nivelIcons = {
    NivelEducativo.preescolar: '🧸',
    NivelEducativo.primaria: '📚',
    NivelEducativo.secundaria: '🎓',
    NivelEducativo.media: '🎯',
  };

  @override
  void initState() {
    super.initState();
    _loadCurso();
  }

  Future<void> _loadCurso() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<CursoProvider>();
      final curso = await provider.getCursoById(widget.cursoId);

      if (curso != null) {
        setState(() => _curso = curso);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar curso');
      context.pop();
    }
  }

  Future<void> _loadEstudiantes() async {
    if (_estudiantes.isNotEmpty) return;

    try {
      setState(() => _loadingEstudiantes = true);

      final provider = context.read<CursoProvider>();
      final estudiantes = await provider.getEstudiantesCurso(widget.cursoId);

      setState(() {
        _estudiantes = estudiantes;
        _loadingEstudiantes = false;
      });

      // Actualizar conteo en el curso
      if (_curso != null && _curso!.estudiantesCount != estudiantes.length) {
        setState(() {
          _curso = _curso!.copyWith(estudiantesCount: estudiantes.length);
        });
      }
    } catch (e) {
      setState(() => _loadingEstudiantes = false);
      _showError('Error al cargar estudiantes');
    }
  }

  Future<void> _loadAsignaturas() async {
    if (_asignaturas.isNotEmpty) return;

    try {
      setState(() => _loadingAsignaturas = true);

      final provider = context.read<CursoProvider>();
      final asignaturas = await provider.getAsignaturasCurso(widget.cursoId);

      setState(() {
        _asignaturas = asignaturas;
        _loadingAsignaturas = false;
      });

      // Actualizar conteo en el curso
      if (_curso != null && _curso!.asignaturasCount != asignaturas.length) {
        setState(() {
          _curso = _curso!.copyWith(asignaturasCount: asignaturas.length);
        });
      }
    } catch (e) {
      setState(() => _loadingAsignaturas = false);
      _showError('Error al cargar asignaturas');
    }
  }

  void _handleTabChange(int index) {
    setState(() => _selectedTabIndex = index);

    if (index == 1 && _estudiantes.isEmpty) {
      _loadEstudiantes();
    } else if (index == 2 && _asignaturas.isEmpty) {
      _loadAsignaturas();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getInitials(String nombre, String apellidos) {
    final first = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final last = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _curso == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          title: const Text('Cargando...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final nivelColor = _nivelColors[_curso!.nivel] ?? const Color(0xFF6366F1);
    final nivelIcon = _nivelIcons[_curso!.nivel] ?? '📚';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(nivelColor, nivelIcon),
            _buildTabs(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 📋 HEADER
  // ========================================

  Widget _buildHeader(Color nivelColor, String nivelIcon) {
    return Container(
      decoration: BoxDecoration(color: nivelColor),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(nivelIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _curso!.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_curso!.nivel.displayName} • ${_curso!.gradoDisplay}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
  // 🔖 PESTAÑAS
  // ========================================

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              0,
              'ℹ️ Información',
              _selectedTabIndex == 0,
            ),
          ),
          Expanded(
            child: _buildTab(
              1,
              '👥 Estudiantes (${_curso!.estudiantesCount ?? _estudiantes.length})',
              _selectedTabIndex == 1,
            ),
          ),
          Expanded(
            child: _buildTab(
              2,
              '📚 Asignaturas (${_curso!.asignaturasCount ?? _asignaturas.length})',
              _selectedTabIndex == 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, bool isActive) {
    return InkWell(
      onTap: () => _handleTabChange(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ========================================
  // 📋 CONTENIDO DE PESTAÑAS
  // ========================================

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildInfoTab();
      case 1:
        return _buildEstudiantesTab();
      case 2:
        return _buildAsignaturasTab();
      default:
        return const SizedBox();
    }
  }

  // ========================================
  // ℹ️ PESTAÑA INFORMACIÓN
  // ========================================

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información General
          const Text(
            '📊 Información General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(),

          const SizedBox(height: 16),

          // Director de Grupo
          const Text(
            '👩‍🏫 Director de Grupo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildDirectorCard(),

          const SizedBox(height: 16),

          // Estadísticas
          const Text(
            '📊 Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow('Nivel:', _curso!.nivel.displayName),
          _buildInfoRow('Grado y Grupo:', _curso!.gradoDisplay),
          _buildInfoRow(
              'Año Académico:', _curso!.anoAcademico ?? 'No especificado'),
          if (_curso!.jornada != null)
            _buildInfoRow('Jornada:', _curso!.jornada!.displayName),
          if (_curso!.capacidad != null)
            _buildInfoRow('Capacidad:', '${_curso!.capacidad} estudiantes'),
          _buildInfoRow(
            'Estado:',
            _curso!.estado.value,
            valueColor: _curso!.estado == EstadoCurso.activo
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                _getInitials(
                  _curso!.directorGrupo?.nombre ?? '',
                  _curso!.directorGrupo?.apellidos ?? '',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _curso!.nombreDirector,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_curso!.directorGrupo?.email != null)
                  Text(
                    _curso!.directorGrupo!.email!,
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

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  '${_curso!.estudiantesCount ?? _estudiantes.length}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const Text(
                  'Estudiantes',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  '${_curso!.asignaturasCount ?? _asignaturas.length}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const Text(
                  'Asignaturas',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // 👥 PESTAÑA ESTUDIANTES
  // ========================================

  Widget _buildEstudiantesTab() {
    if (_loadingEstudiantes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_estudiantes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👥', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No hay estudiantes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Este curso aún no tiene estudiantes matriculados.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _estudiantes.length,
      itemBuilder: (context, index) {
        final estudiante = _estudiantes[index];
        return _buildEstudianteCard(estudiante);
      },
    );
  }

  Widget _buildEstudianteCard(EstudianteCurso estudiante) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899),
              borderRadius: BorderRadius.circular(22.5),
            ),
            child: Center(
              child: Text(
                estudiante.iniciales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
                  ),
                ),
                Text(
                  estudiante.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (estudiante.genero != null)
                  Text(
                    estudiante.genero == 'M'
                        ? '👨‍🎓 Masculino'
                        : '👩‍🎓 Femenino',
                    style: TextStyle(
                      fontSize: 11,
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
  // 📚 PESTAÑA ASIGNATURAS
  // ========================================

  Widget _buildAsignaturasTab() {
    if (_loadingAsignaturas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_asignaturas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📚', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No hay asignaturas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Este curso aún no tiene asignaturas asignadas.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _asignaturas.length,
      itemBuilder: (context, index) {
        final asignatura = _asignaturas[index];
        return _buildAsignaturaCard(asignatura);
      },
    );
  }

  Widget _buildAsignaturaCard(AsignaturaCurso asignatura) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asignatura.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (asignatura.codigo != null)
                      Text(
                        asignatura.codigo!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (asignatura.creditos != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${asignatura.creditos} créditos',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('👩‍🏫', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  asignatura.docente != null
                      ? asignatura.docente!.nombreCompleto
                      : 'Docente no asignado',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          if (asignatura.intensidadHoraria != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${asignatura.intensidadHoraria} horas semanales',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
