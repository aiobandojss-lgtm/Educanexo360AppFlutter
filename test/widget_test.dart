// test/widget_test.dart
// Prueba de humo de UI sin Firebase: MyApp requiere Firebase.initializeApp(),
// que no está disponible en pruebas, así que se prueba un widget común.
import 'package:educanexo360_app/config/theme.dart';
import 'package:educanexo360_app/widgets/common/gradient_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GradientHeader muestra título, subtítulo y botón atrás',
      (WidgetTester tester) async {
    var backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: GradientHeader(
            title: 'Mensajes',
            subtitle: 'Bandeja de entrada',
            showBack: true,
            onBack: () => backPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Bandeja de entrada'), findsOneWidget);

    await tester.tap(find.byTooltip('Atrás'));
    expect(backPressed, isTrue);
  });
}
