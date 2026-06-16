// lib/screens/asistencia/informes/informe_ranking_screen.dart
//
// Informe 3: Ranking de cursos por porcentaje de asistencia.
// Solo visible para: ADMIN, RECTOR, COORDINADOR.
// Filtros: rango de fechas (requerido).
// Muestra lista ordenada con barra de progreso coloreada.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/asistencia_informes.dart';
import '../../../services/asistencia_informes_service.dart';
import '../../../widgets/common/gradient_header.dart';

class InformeRankingScreen extends StatefulWidget {
  const InformeRankingScreen({super.key});

  @override
  State<InformeRankingScreen> createState() => _InformeRankingScreenState();
}

class _InformeRankingScreenState extends State<InformeRankingScreen> {
  final _service = asistenciaInformesService;

  DateTime _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _hasta = DateTime.now();

  bool _isLoading = false;
  String? _error;
  InformeRankingResponse? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.obtenerRankingCursos(
        desde: DateFormat('yyyy-MM-dd').format(_desde),
        hasta: DateFormat('yyyy-MM-dd').format(_hasta),
      );
      setState(() => _data = result);
    } catch (e) {
      setState(() =>
          _error = 'No se pudo cargar el ranking. Verifica tu conexión.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _desde = fecha;
          if (_desde.isAfter(_hasta)) _hasta = _desde;
        } else {
          _hasta = fecha;
          if (_hasta.isBefore(_desde)) _desde = _hasta;
        }
      });
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          GradientHeader(
            title: 'Ranking de Cursos',
            showBack: true,
            leadingIcon: Icons.leaderboard,
            actions: [
              HeaderAction(
                icon: Icons.refresh,
                onTap: _cargar,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          _buildFiltros(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _data == null
                        ? const SizedBox.shrink()
                        : _buildContenido(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildFechaBtn(
                label: 'Desde',
                fecha: _desde,
                onTap: () => _seleccionarFecha(true)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFechaBtn(
                label: 'Hasta',
                fecha: _hasta,
                onTap: () => _seleccionarFecha(false)),
          ),
        ],
      ),
    );
  }

  Widget _buildFechaBtn({
    required String label,
    required DateTime fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 16, color: Color(0xFF047857)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text(DateFormat('dd/MM/yyyy').format(fecha),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    final ranking = _data!.ranking;

    if (ranking.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Podio top 3
          if (ranking.length >= 3) _buildPodio(ranking),
          const SizedBox(height: 16),
          // Lista completa
          ...ranking.map((c) => _buildCursoCard(c, ranking.length)),
        ],
      ),
    );
  }

  Widget _buildPodio(List<CursoRanking> ranking) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 3',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2do lugar
                if (ranking.length > 1)
                  _buildPodioItem(ranking[1], '🥈', 70),
                // 1er lugar
                _buildPodioItem(ranking[0], '🥇', 90),
                // 3er lugar
                if (ranking.length > 2)
                  _buildPodioItem(ranking[2], '🥉', 55),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodioItem(CursoRanking curso, String emoji, double height) {
    final color = _colorPorPorcentaje(curso.porcentajeAsistencia);
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          curso.nombreCompleto,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          '${curso.porcentajeAsistencia.toStringAsFixed(1)}%',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }

  Widget _buildCursoCard(CursoRanking curso, int total) {
    final color = _colorPorPorcentaje(curso.porcentajeAsistencia);
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final medal = medals[curso.posicion];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Posición
                SizedBox(
                  width: 36,
                  child: medal != null
                      ? Text(medal,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22))
                      : Text(
                          '#${curso.posicion}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500]),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.nombreCompleto,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '${curso.totalEstudiantes} estudiantes · ${curso.totalClases} clases',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${curso.porcentajeAsistencia.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: curso.porcentajeAsistencia / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                    'Presentes', curso.presentes, const Color(0xFF059669)),
                _buildMiniStat(
                    'Ausentes', curso.ausentes, const Color(0xFFEF4444)),
                _buildMiniStat(
                    'Tardanzas', curso.tardanzas, const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int valor, Color color) {
    return Column(
      children: [
        Text(valor.toString(),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Color _colorPorPorcentaje(double p) {
    if (p >= 90) return const Color(0xFF059669);
    if (p >= 75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Sin datos de ranking',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('Ajusta el rango de fechas para ver el ranking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
