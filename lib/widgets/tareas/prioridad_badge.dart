// lib/widgets/tareas/prioridad_badge.dart

import 'package:flutter/material.dart';
import '../../models/tarea.dart';

/// 🎯 BADGE DE PRIORIDAD DE TAREA
/// Widget simple para mostrar la prioridad de una tarea con color e ícono
class PrioridadBadge extends StatelessWidget {
  final PrioridadTarea prioridad;
  final bool compacto;
  final bool mostrarIcono;

  const PrioridadBadge({
    super.key,
    required this.prioridad,
    this.compacto = false,
    this.mostrarIcono = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(prioridad.color);

    return Container(
      padding: compacto
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compacto ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarIcono) ...[
            Text(
              prioridad.icon,
              style: TextStyle(fontSize: compacto ? 12 : 14),
            ),
            SizedBox(width: compacto ? 4 : 6),
          ],
          Text(
            prioridad.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: compacto ? 11 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎯 BADGE DE PRIORIDAD CON VARIANTES
/// Badge más elaborado con diferentes estilos
class PrioridadBadgeOutlined extends StatelessWidget {
  final PrioridadTarea prioridad;
  final bool compacto;

  const PrioridadBadgeOutlined({
    super.key,
    required this.prioridad,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(prioridad.color);

    return Container(
      padding: compacto
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compacto ? 8 : 12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prioridad.icon, style: TextStyle(fontSize: compacto ? 12 : 14)),
          SizedBox(width: compacto ? 4 : 6),
          Text(
            prioridad.displayName,
            style: TextStyle(
              color: color,
              fontSize: compacto ? 11 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎯 BADGE DE PRIORIDAD CON DESCRIPCIÓN
/// Badge más grande con descripción adicional
class PrioridadBadgeDetailed extends StatelessWidget {
  final PrioridadTarea prioridad;
  final String? descripcion;

  const PrioridadBadgeDetailed({
    super.key,
    required this.prioridad,
    this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(prioridad.color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              prioridad.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prioridad.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (descripcion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    descripcion!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
