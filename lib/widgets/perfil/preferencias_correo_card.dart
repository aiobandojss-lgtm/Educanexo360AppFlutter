// lib/widgets/perfil/preferencias_correo_card.dart
//
// Sección del perfil "Correos de EducaNexo": cómo quiere recibir el usuario
// los correos de mensajes. Se oculta si el backend no tiene el endpoint.

import 'package:flutter/material.dart';
import '../../services/preferencias_service.dart';

class PreferenciasCorreoCard extends StatefulWidget {
  const PreferenciasCorreoCard({super.key, this.service});

  /// Inyectable para pruebas
  final PreferenciasService? service;

  @override
  State<PreferenciasCorreoCard> createState() => _PreferenciasCorreoCardState();
}

enum _Estado { cargando, oculto, error, listo }

class _PreferenciasCorreoCardState extends State<PreferenciasCorreoCard> {
  static const _verde = Color(0xFF059669);

  late final PreferenciasService _service =
      widget.service ?? PreferenciasService();

  _Estado _estado = _Estado.cargando;
  PreferenciasCorreo? _preferencias;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _estado = _Estado.cargando);
    try {
      final preferencias = await _service.obtener();
      if (!mounted) return;
      setState(() {
        _preferencias = preferencias;
        _estado = preferencias == null ? _Estado.oculto : _Estado.listo;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _estado = _Estado.error);
    }
  }

  Future<void> _elegir(PreferenciaCorreo opcion) async {
    final anterior = _preferencias;
    if (anterior == null || _guardando || anterior.email == opcion) return;

    // Cambio inmediato en pantalla; si falla se vuelve a la anterior
    setState(() {
      _guardando = true;
      _preferencias = PreferenciasCorreo(email: opcion, porDefecto: false);
    });
    try {
      final guardada = await _service.actualizar(opcion);
      if (!mounted) return;
      setState(() => _preferencias = guardada);
    } catch (_) {
      if (!mounted) return;
      setState(() => _preferencias = anterior);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar tu preferencia. Intenta de nuevo.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estado == _Estado.oculto) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              '✉️ Correos de EducaNexo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              '¿Cómo quieres recibir por correo los mensajes del colegio?',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          ..._contenido(),
        ],
      ),
    );
  }

  List<Widget> _contenido() {
    switch (_estado) {
      case _Estado.cargando:
        return const [
          Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _verde),
              ),
            ),
          ),
        ];
      case _Estado.error:
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'No se pudo cargar tu preferencia de correo.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
                TextButton(
                  onPressed: _cargar,
                  child: const Text('Reintentar',
                      style: TextStyle(color: _verde)),
                ),
              ],
            ),
          ),
        ];
      case _Estado.oculto:
      case _Estado.listo:
        final actual = _preferencias!.email;
        return [
          _opcion(
            opcion: PreferenciaCorreo.inmediato,
            actual: actual,
            icono: Icons.mark_email_unread_outlined,
            titulo: 'Al instante',
            descripcion: 'Un correo por cada mensaje.',
          ),
          const Divider(height: 1),
          _opcion(
            opcion: PreferenciaCorreo.resumen,
            actual: actual,
            icono: Icons.schedule_outlined,
            titulo: 'Resumen diario',
            etiqueta: 'Recomendado para acudientes',
            descripcion: 'Un solo correo a las 6 p. m. con los mensajes que '
                'aún no hayas leído.',
          ),
          const Divider(height: 1),
          _opcion(
            opcion: PreferenciaCorreo.ninguno,
            actual: actual,
            icono: Icons.notifications_active_outlined,
            titulo: 'Ninguno',
            descripcion: 'Solo notificaciones en el celular.',
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF047857)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los mensajes urgentes, las alertas de asistencia y los '
                    'correos de tu cuenta (como recuperar la contraseña) '
                    'siempre te llegan.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }

  Widget _opcion({
    required PreferenciaCorreo opcion,
    required PreferenciaCorreo actual,
    required IconData icono,
    required String titulo,
    required String descripcion,
    String? etiqueta,
  }) {
    final seleccionada = opcion == actual;

    // Accesibilidad: el lector de pantalla anuncia la opción, su
    // descripción y si está seleccionada (como un botón de radio)
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: seleccionada,
      label: '$titulo. $descripcion',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('preferencia-${opcion.value}'),
        onTap: _guardando ? null : () => _elegir(opcion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icono,
                  size: 24,
                  color: seleccionada ? _verde : Colors.grey.shade500),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (etiqueta != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          etiqueta,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                seleccionada
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: seleccionada ? _verde : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
