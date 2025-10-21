// lib/screens/calendario/calendario_screen.dart
// ⭐ SOLO CAMBIO: padding en SliverPadding de 100 a 80 (línea 285 aprox)

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
  const CalendarioScreen({Key? key}) : super(key: key);

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarioProvider>().loadEventos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer2<CalendarioProvider, AuthProvider>(
        builder: (context, calendarProvider, authProvider, child) {
          final canEditEvents = PermissionService.canAccess('calendario.crear');
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
              backgroundColor: const Color(0xFF8b5cf6),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8b5cf6),
            const Color(0xFF7c3aed),
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
                color: const Color(0xFF8b5cf6).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF8b5cf6),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFf59e0b), // Punto amarillo
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

              print(
                  '📅 Día seleccionado: ${selectedDay.day}/${selectedDay.month}');
              print('🔍 Eventos encontrados: ${eventos.length}');

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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.mesAnterior(),
            color: const Color(0xFF8b5cf6),
          ),
          Text(
            nombreMes.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8b5cf6),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.mesSiguiente(),
            color: const Color(0xFF8b5cf6),
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
        ? Colors.purple[700]!
        : _selectedDay != null
            ? Colors.orange[700]!
            : Colors.blue[700]!;

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
      print(
          '📅 Mostrando eventos del día ${_selectedDay!.day}/${_selectedDay!.month}');
      print('📢 Total: ${eventosAMostrar.length}');
    } else {
      eventosAMostrar = provider.proximosEventos;
      print('📋 Mostrando próximos eventos');
      print('📢 Total: ${eventosAMostrar.length}');
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
    final statusColor = _getStatusColor(evento.estado);

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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO
                    Text(
                      evento.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // FECHA
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy, HH:mm', 'es_ES')
                              .format(evento.fechaInicio),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // DESCRIPCIÓN
                    Text(
                      evento.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // META INFO
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // CHIP DE TIPO
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            evento.tipo.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),

                        // CHIP DE ESTADO
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            evento.estado.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),

                        // LUGAR
                        if (evento.lugar != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on,
                                  size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 2),
                              Text(
                                evento.lugar!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
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
              backgroundColor: const Color(0xFF8b5cf6),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '📅',
            style: TextStyle(fontSize: 80, color: Colors.grey[300]),
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
                ? 'Selecciona otro día o crea un nuevo evento'
                : 'Los eventos que se creen aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedDay != null &&
              PermissionService.canAccess('calendario.crear')) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  _navigateToCreateEvento(fechaInicial: _selectedDay),
              icon: const Icon(Icons.add),
              label: const Text('Crear evento para este día'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b5cf6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
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

  Color _getStatusColor(EventStatus status) {
    return Color(
      int.parse(status.colorHex.substring(1), radix: 16) + 0xFF000000,
    );
  }
}
