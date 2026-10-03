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

  // J2: con cambios sin guardar la flecha debe pasar por el PopScope
  // (create_message), no descartar en silencio
  testWidgets('respeta el PopScope: con cambios sin guardar no sale',
      (tester) async {
    var avisos = 0;
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Inicio'))),
      GoRoute(
        path: '/form',
        builder: (_, __) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) avisos++; // aquí la pantalla pregunta "¿descartar?"
          },
          child: const Scaffold(
            body: GradientHeader(title: 'Nuevo mensaje', showBack: true),
          ),
        ),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/form');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo mensaje'), findsOneWidget);
    expect(avisos, 1);
  });

  // editar_perfil y cambiar_password usan WillPopScope
  testWidgets('respeta el WillPopScope: si responde false no sale',
      (tester) async {
    var preguntas = 0;
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Inicio'))),
      GoRoute(
        path: '/perfil',
        // ignore: deprecated_member_use
        builder: (_, __) => WillPopScope(
          onWillPop: () async {
            preguntas++;
            return false;
          },
          child: const Scaffold(
            body: GradientHeader(title: 'Editar perfil', showBack: true),
          ),
        ),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/perfil');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();

    expect(find.text('Editar perfil'), findsOneWidget);
    expect(preguntas, 1);
  });
}
