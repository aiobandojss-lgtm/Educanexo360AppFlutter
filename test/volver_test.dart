// test/volver_test.dart
// G4: el botón de volver del encabezado nunca queda sin efecto
import 'package:educanexo360_app/widgets/common/gradient_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() => GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Inicio')),
      ),
      GoRoute(
        path: '/lista',
        builder: (_, __) => const Scaffold(body: Text('Lista')),
      ),
      GoRoute(
        path: '/detalle',
        builder: (_, __) => const Scaffold(
          body: GradientHeader(title: 'Detalle', showBack: true),
        ),
      ),
    ]);

void main() {
  testWidgets('abierta con push: vuelve a la pantalla anterior',
      (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/lista');
    await tester.pumpAndSettle();
    router.push('/detalle');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();

    expect(find.text('Lista'), findsOneWidget);
  });

  testWidgets(
      'abierta con go (sin pantalla anterior): va al inicio en vez de no '
      'hacer nada', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/detalle');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
  });
}
