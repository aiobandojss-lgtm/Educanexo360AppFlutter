// lib/widgets/tareas/estado_badge.dart

import 'package:flutter/material.dart';
import '../../models/tarea.dart';

/// 📊 BADGE DE ESTADO DE ENTREGA
/// Widget simple para mostrar el estado de una entrega con color e ícono
class EstadoBadge extends StatelessWidget {
  final EstadoEntrega estado;
  final bool compacto;
  final bool mostrarIcono;

  const EstadoBadge({
    super.key,
    required this.estado,
    this.compacto = false,
    this.mostrarIcono = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(estado.color);

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
            Icon(
              _estadoIconData(estado),
              size: compacto ? 12 : 14,
              color: Colors.white,
            ),
            SizedBox(width: compacto ? 4 : 6),
          ],
          Text(
            estado.displayName,
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

/// 📊 BADGE DE ESTADO CON VARIANTES
/// Badge más elaborado con diferentes estilos
class EstadoBadgeOutlined extends StatelessWidget {
  final EstadoEntrega estado;
  final bool compacto;

  const EstadoBadgeOutlined({
    super.key,
    required this.estado,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(estado.color);

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
          Icon(_estadoIconData(estado), size: compacto ? 12 : 14, color: color),
          SizedBox(width: compacto ? 4 : 6),
          Text(
            estado.displayName,
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

/// 📊 BADGE DE ESTADO CON DESCRIPCIÓN
/// Badge más grande con descripción adicional
class EstadoBadgeDetailed extends StatelessWidget {
  final EstadoEntrega estado;
  final String? descripcion;

  const EstadoBadgeDetailed({
    super.key,
    required this.estado,
    this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(estado.color);

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
            child: Icon(_estadoIconData(estado), size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estado.displayName,
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

IconData _estadoIconData(EstadoEntrega estado) {
  switch (estado) {
    case EstadoEntrega.pendiente:
      return Icons.hourglass_empty;
    case EstadoEntrega.vista:
      return Icons.visibility;
    case EstadoEntrega.entregada:
      return Icons.check_circle_outline;
    case EstadoEntrega.atrasada:
      return Icons.warning_amber_rounded;
    case EstadoEntrega.calificada:
      return Icons.star;
  }
}
