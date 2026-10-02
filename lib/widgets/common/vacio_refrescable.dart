// lib/widgets/common/vacio_refrescable.dart
//
// Estado vacío de una lista que se puede refrescar arrastrando hacia abajo.
// Antes el estado vacío quedaba fuera del RefreshIndicator: tras crear el
// primer elemento no había forma de refrescar sin salir y volver (G5).

import 'package:flutter/material.dart';

class VacioRefrescable extends StatelessWidget {
  const VacioRefrescable({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          // Desplazable aunque el contenido quepa: si no, no hay gesto
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}
