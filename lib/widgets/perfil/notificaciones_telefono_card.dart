// lib/widgets/perfil/notificaciones_telefono_card.dart
//
// Acceso a los ajustes de notificaciones de la app en el teléfono. Reemplaza
// el interruptor "Notificaciones Push" del perfil, que no hacía nada: las
// notificaciones se activan o silencian desde el sistema.

import 'package:flutter/material.dart';
import '../../services/ajustes_telefono.dart';

class NotificacionesTelefonoCard extends StatelessWidget {
  const NotificacionesTelefonoCard({super.key});

  Future<void> _abrir(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final abierto = await AjustesTelefono.abrirNotificaciones();
    if (!abierto) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron abrir los ajustes. Búscalos en Ajustes > '
            'Aplicaciones > EducaNexo360 > Notificaciones.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AjustesTelefono.disponible) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              '🔔 Notificaciones del celular',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          // onTap en el Semantics: excludeSemantics descarta la acción del
          // InkWell y, sin esto, con TalkBack no se podría activar
          Semantics(
            // Nodo propio: sin esto el título de la tarjeta se fusiona con
            // el botón y TalkBack lo lee todo junto
            container: true,
            button: true,
            label: 'Abrir ajustes de notificaciones del teléfono',
            onTap: () => _abrir(context),
            excludeSemantics: true,
            child: InkWell(
              key: const ValueKey('abrir-ajustes-notificaciones'),
              onTap: () => _abrir(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: Color(0xFF0D9488), size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ajustes de notificaciones',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Activa o silencia las notificaciones de '
                            'EducaNexo en tu teléfono.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new,
                        color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
