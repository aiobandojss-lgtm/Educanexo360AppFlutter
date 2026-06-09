// lib/screens/calendario/calendario_screen.dart
// ✅ MIGRACIÓN A VERDE/TEAL - 10 CAMBIOS APLICADOS

import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/evento.dart';
import '../../providers/calendario_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/permission_service.dart';
import 'evento_detail_screen.dart';
import 'create_evento_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    final provider = context.read<CalendarioProvider>();
    if (provider.eventos.isEmpty) {
      provider.prepareLoading();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CalendarioProvider>().loadEventos(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer2<CalendarioProvider, AuthProvider>(
        builder: (context, calendarProvider, authProvider, child) {
          final tipoUsuario = authProvider.currentUser?.tipo.value;

          return RefreshIndicator(
            onRefresh: () => calendarProvider.refresh(),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(calendarProvider),
                  // Contenido scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Calendario
                          _buildCalendar(calendarProvider, authProvider),
                          // Título dinámico
                          _buildDynamicTitle(calendarProvider, tipoUsuario),
                          // Lista de eventos
                          if (calendarProvider.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            _buildEventsList(calendarProvider, tipoUsuario),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // FAB PARA CREAR EVENTO
      floatingActionButton: PermissionService.canAccess('calendario.crear')
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateEvento(),
              backgroundColor: const Color(0xFF059669), // ← VERDE (cambio 1/10)
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear Evento',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  // ==========================================
  // HEADER (SIN FILTROS)
  // ==========================================

  Widget _buildHeader(CalendarioProvider provider) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF047857), // ← VERDE OSCURO (cambio 2/10)
            Color(0xFF14B8A6), // ← TEAL (cambio 3/10)
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendario',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Eventos y actividades escolares',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CALENDARIO
  // ==========================================

  Widget _buildCalendar(
      CalendarioProvider provider, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // NAVEGACIÓN DE MES
          _buildMonthNavigation(provider),

          // CALENDARIO
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            locale: 'es_ES',

            // EVENTOS - Punto amarillo cuando hay eventos
            eventLoader: (day) {
              return provider.getEventosDelDia(
                  day, authProvider.currentUser?.tipo.value);
            },

            // ESTILOS
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFF059669)
                    .withOpacity(0.3), // ← VERDE (cambio 4/10)
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF059669), // ← VERDE (cambio 5/10)
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFf59e0b), // ✅ MANTENER Naranja
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              outsideDaysVisible: false,
            ),

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronVisible: false,
              rightChevronVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 0, // Ocultamos el header por defecto
              ),
            ),

            // CALLBACKS
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              final eventos = provider.getEventosDelDia(
                  selectedDay, authProvider.currentUser?.tipo.value);

              dlog(
                  '📅 Día seleccionado: ${selectedDay.day}/${selectedDay.month}');
              dlog('🔍 Eventos encontrados: ${eventos.length}');

              // Solo mostrar diálogo si NO hay eventos y puede crear
              if (eventos.isEmpty &&
                  PermissionService.canAccess('calendario.crear')) {
                _showEmptyDayDialog(context, selectedDay);
              }
            },

            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },

            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              provider.irAMes(focusedDay);
            },
          ),
        ],
      ),
    );
  }

  // NAVEGACIÓN DE MES
  Widget _buildMonthNavigation(CalendarioProvider provider) {
    final mesActual = provider.mesActual;
    final nombreMes = DateFormat.yMMMM('es_ES').format(mesActual);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.mesAnterior(),
            color: const Color(0xFF059669),
          ),
          Expanded(
            child: Text(
              nombreMes.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.mesSiguiente(),
            color: const Color(0xFF059669),
          ),
          // Toggle semana / mes
          GestureDetector(
            onTap: () => setState(() {
              _calendarFormat = _calendarFormat == CalendarFormat.week
                  ? CalendarFormat.month
                  : CalendarFormat.week;
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: Text(
                _calendarFormat == CalendarFormat.week ? 'Mes' : 'Semana',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TÍTULO DINÁMICO MEJORADO
  // ==========================================

  Widget _buildDynamicTitle(CalendarioProvider provider, String? tipoUsuario) {
    final eventosDelDia = _selectedDay != null
        ? provider.getEventosDelDia(_selectedDay!, tipoUsuario)
        : <Evento>[];

    // Determinar qué mostrar
    final bool mostrarEventosDelDia =
        _selectedDay != null && eventosDelDia.isNotEmpty;
    final String titulo = mostrarEventosDelDia
        ? 'Eventos del ${DateFormat('d \'de\' MMMM', 'es_ES').format(_selectedDay!)}'
        : _selectedDay != null
            ? 'No hay eventos este día'
            : 'Próximos Eventos';

    final IconData icono = mostrarEventosDelDia
        ? Icons.event
        : _selectedDay != null
            ? Icons.event_busy
            : Icons.event_available;

    final Color color = mostrarEventosDelDia
        ? const Color(0xFF047857)
        : _selectedDay != null
            ? Colors.orange[700]!
            : const Color(0xFF0D9488);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          // Botón para limpiar selección
          if (_selectedDay != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDay = null;
                });
              },
              icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
              label: Text(
                'Ver todos',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // LISTA DE EVENTOS MEJORADA
  // ==========================================

  Widget _buildEventsList(CalendarioProvider provider, String? tipoUsuario) {
    final List<Evento> eventosAMostrar;

    if (_selectedDay != null) {
      eventosAMostrar = provider.getEventosDelDia(_selectedDay!, tipoUsuario);
      dlog(
          '📅 Mostrando eventos del día ${_selectedDay!.day}/${_selectedDay!.month}');
      dlog('🔢 Total: ${eventosAMostrar.length}');
    } else {
      eventosAMostrar = provider.proximosEventos;
      dlog('📋 Mostrando próximos eventos');
      dlog('🔢 Total: ${eventosAMostrar.length}');
    }

    if (eventosAMostrar.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children:
            eventosAMostrar.map((evento) => _buildEventCard(evento)).toList(),
      ),
    );
  }

  // ==========================================
  // TARJETA DE EVENTO
  // ==========================================

  Widget _buildEventCard(Evento evento) {
    final color = _getEventTypeColor(evento.tipo);

    return GestureDetector(
      onTap: () => _navigateToEventDetail(evento),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // BARRA DE COLOR
            Container(
              width: 4,
              height: 100,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // CONTENIDO
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO + TIPO
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            evento.titulo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1f2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            evento.tipo.icon,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // FECHA
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM, HH:mm', 'es_ES')
                              .format(evento.fechaInicio),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (evento.lugar != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.location_on,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              evento.lugar!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),

                    // DESCRIPCIÓN (1 línea)
                    Text(
                      evento.descripcion,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // ÍCONO
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIÁLOGOS
  // ==========================================

  void _showEmptyDayDialog(BuildContext context, DateTime day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No hay eventos'),
        content: Text(
          '¿Deseas crear un evento para el ${DateFormat('d \'de\' MMMM', 'es_ES').format(day)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToCreateEvento(fechaInicial: day);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669), // ← VERDE (cambio 9/10)
            ),
            child: const Text('Crear evento'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ESTADO VACÍO
  // ==========================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedDay != null
                ? Icons.event_busy_outlined
                : Icons.event_available_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedDay != null
                ? 'No hay eventos este día'
                : 'No hay eventos próximos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDay != null
                ? 'Selecciona otro día o usa el botón para crear uno'
                : 'Los eventos que se creen aparecerán aquí',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NAVEGACIÓN
  // ==========================================

  void _navigateToCreateEvento({DateTime? fechaInicial}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventoScreen(fechaInicial: fechaInicial),
      ),
    );
  }

  void _navigateToEventDetail(Evento evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventoDetailScreen(eventoId: evento.id),
      ),
    );
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  Color _getEventTypeColor(EventType type) {
    return Color(
      int.parse(type.colorHex.substring(1), radix: 16) + 0xFF000000,
    );
  }

}
