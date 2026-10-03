// lib/widgets/common/gradient_header.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// Vuelve a la pantalla anterior; si no hay (pantalla abierta con go() o
/// desde una notificación), va al inicio en vez de no hacer nada (G4).
/// maybePop respeta el PopScope de la pantalla (confirmar cambios sin
/// guardar, J2); pop() lo ignoraba.
void volverOInicio(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.maybePop();
    return;
  }
  GoRouter.maybeOf(context)?.go('/');
}

/// Encabezado unificado de la aplicación (Patrón A).
///
/// Bloque ÚNICO con gradiente verde diagonal que reemplaza el antiguo
/// doble header (AppBar sólido + Container con gradiente), el cual
/// generaba la "banda" de dos verdes apilados.
///
/// Maneja por sí mismo el área segura superior (status bar), por lo que
/// las pantallas NO deben envolverlo en un `SafeArea` adicional.
///
/// Casos cubiertos:
/// - Pantallas principales (sin botón atrás): solo `title` + `subtitle`.
/// - Pantallas de detalle/gestión: `showBack` + `leadingIcon`.
/// - Acciones a la derecha (filtros, cambio de vista): `actions`.
/// - Contenido extra debajo (chips de estadísticas, TabBar): `bottom`.
///
/// Ver también [volverOInicio], la acción por defecto del botón atrás.
class GradientHeader extends StatelessWidget {
  /// Título principal del encabezado.
  final String title;

  /// Subtítulo opcional (ej. "23 usuarios registrados").
  final String? subtitle;

  /// Muestra el botón de retroceso a la izquierda del título.
  final bool showBack;

  /// Acción personalizada para el botón atrás. Por defecto: `maybePop()`.
  final VoidCallback? onBack;

  /// Ícono opcional a la izquierda del título (ej. Icons.people).
  final IconData? leadingIcon;

  /// Widgets de acción a la derecha del título (ej. botón de filtros).
  final List<Widget> actions;

  /// Contenido adicional debajo del subtítulo (ej. chips de estadísticas,
  /// una fila de TabBar, etc.).
  final Widget? bottom;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.leadingIcon,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emerald700, // #047857
            AppColors.teal500, // #14B8A6
          ],
        ),
      ),
      // SafeArea propio: el gradiente pinta hasta el borde superior y el
      // contenido queda debajo del status bar.
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: atrás + ícono + título + acciones
              Row(
                children: [
                  if (showBack)
                    _HeaderIconButton(
                      icon: Icons.arrow_back,
                      onTap: onBack ?? () => volverOInicio(context),
                      tooltip: 'Atrás',
                    ),
                  if (leadingIcon != null) ...[
                    Padding(
                      padding: EdgeInsets.only(left: showBack ? 0 : 4),
                      child: Icon(leadingIcon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 8),
                  ] else if (!showBack)
                    const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.15,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (bottom != null) ...[
                const SizedBox(height: 16),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de ícono compacto y blanco para usar dentro del [GradientHeader].
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// Botón de acción listo para usar en [GradientHeader.actions].
///
/// Soporta un badge numérico (ej. cantidad de filtros activos).
class HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badgeCount;

  const HeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onTap,
          tooltip: tooltip,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
