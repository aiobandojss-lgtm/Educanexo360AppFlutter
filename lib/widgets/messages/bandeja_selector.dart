// lib/widgets/messages/bandeja_selector.dart

import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../services/permission_service.dart';

/// 📬 SELECTOR DE BANDEJAS (CON FILTRO POR PERMISOS)
/// Botones horizontales para cambiar entre bandejas de mensajes
/// ✅ CORREGIDO: Filtra bandejas según rol del usuario
class BandejaSelector extends StatelessWidget {
  final Bandeja selectedBandeja;
  final Function(Bandeja) onBandejaChanged;
  final Map<Bandeja, int> counts;

  const BandejaSelector({
    super.key,
    required this.selectedBandeja,
    required this.onBandejaChanged,
    this.counts = const {},
  });

  /// 🔐 FILTRAR BANDEJAS DISPONIBLES SEGÚN PERMISOS
  List<Bandeja> get _availableBandejas {
    final canSendMasive = PermissionService.canAccess('mensajes.enviar_masivo');

    if (canSendMasive) {
      // DOCENTE/ADMIN/COORDINADOR: Todas las 5 bandejas
      return Bandeja.values;
    } else {
      // ✅ ESTUDIANTE/ACUDIENTE: 4 bandejas pero solo mostrar 2
      // Tienen acceso a: recibidos, enviados, archivados, eliminados
      // Pero solo MOSTRAMOS: recibidos, enviados
      return [
        Bandeja.recibidos,
        Bandeja.enviados,
        Bandeja.archivados, // ← AGREGAR
        Bandeja.eliminados,
        // Ocultos pero accesibles: archivados, eliminados
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bandejas = _availableBandejas;

    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: bandejas
            .map((bandeja) => _buildBandejaButton(context, bandeja))
            .toList(),
      ),
    );
  }

  Widget _buildBandejaButton(BuildContext context, Bandeja bandeja) {
    final isSelected = selectedBandeja == bandeja;
    final count = counts[bandeja] ?? 0;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => onBandejaChanged(bandeja),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bandeja.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  bandeja.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : Colors.grey[700],
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
