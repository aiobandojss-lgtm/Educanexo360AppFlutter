// lib/screens/asistencia/informes/informes_asistencia_screen.dart
//
// Pantalla hub de Informes de Asistencia.
// Muestra 5 tarjetas de acceso, cada una lleva a su informe específico.
// Visible para: ADMIN, RECTOR, COORDINADOR, DOCENTE, ADMINISTRATIVO.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/permission_service.dart';

class InformesAsistenciaScreen extends StatelessWidget {
  const InformesAsistenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Informes de Asistencia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF047857), Color(0xFF14B8A6)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner informativo
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF059669),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analítica de Asistencia',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF064E3B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selecciona el tipo de informe que deseas consultar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta: Estudiantes en Riesgo (todos los roles con reportes)
          _InformeCard(
            titulo: 'Estudiantes en Riesgo',
            descripcion: 'Identifica estudiantes con bajo porcentaje de asistencia y nivel de criticidad.',
            icono: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            colorFondo: const Color(0xFFFEF2F2),
            onTap: () => context.push('/asistencia/informes/riesgo'),
          ),

          // Tarjeta: Tendencia (todos los roles con reportes)
          _InformeCard(
            titulo: 'Tendencia de Asistencia',
            descripcion: 'Evolución del porcentaje de asistencia en el tiempo, por semana o mes.',
            icono: Icons.trending_up_rounded,
            color: const Color(0xFF059669),
            colorFondo: const Color(0xFFECFDF5),
            onTap: () => context.push('/asistencia/informes/tendencia'),
          ),

          // Tarjeta: Ranking (solo ADMIN, RECTOR, COORDINADOR)
          if (PermissionService.canAccess('asistencia.reportes') &&
              !PermissionService.isDocente())
            _InformeCard(
              titulo: 'Ranking de Cursos',
              descripcion: 'Comparativa de asistencia entre todos los cursos de la institución.',
              icono: Icons.leaderboard_rounded,
              color: const Color(0xFF0D9488),
              colorFondo: const Color(0xFFF0FDFA),
              onTap: () => context.push('/asistencia/informes/ranking'),
            ),

          // Tarjeta: Patrón por días (todos los roles con reportes)
          _InformeCard(
            titulo: 'Patrón por Día de la Semana',
            descripcion: 'Descubre qué días tienen más ausentismo y tardanzas.',
            icono: Icons.calendar_view_week_rounded,
            color: const Color(0xFFF59E0B),
            colorFondo: const Color(0xFFFFFBEB),
            onTap: () => context.push('/asistencia/informes/patron-dias'),
          ),

          // Tarjeta: Historial de estudiante (todos los roles con reportes)
          _InformeCard(
            titulo: 'Historial de Estudiante',
            descripcion: 'Registro completo de asistencia de un estudiante en un período.',
            icono: Icons.person_search_rounded,
            color: const Color(0xFF0EA5E9),
            colorFondo: const Color(0xFFE0F2FE),
            onTap: () => context.push('/asistencia/informes/historial'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET PRIVADO — TARJETA DE INFORME
// ==========================================

class _InformeCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final Color colorFondo;
  final VoidCallback onTap;

  const _InformeCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.colorFondo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
