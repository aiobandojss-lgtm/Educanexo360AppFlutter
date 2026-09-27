// test/notificaciones_telefono_test.dart
// Acceso a los ajustes de notificaciones del teléfono desde el perfil
import 'package:educanexo360_app/services/ajustes_telefono.dart';
import 'package:educanexo360_app/widgets/perfil/notificaciones_telefono_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app() => const MaterialApp(
      home: Scaffold(body: NotificacionesTelefonoCard()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> llamadas;
  bool respuesta = true;

  setUp(() {
    llamadas = [];
    respuesta = true;
    AjustesTelefono.debugDisponible = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AjustesTelefono.canal, (call) async {
      llamadas.add(call.method);
      return respuesta;
    });
  });

  tearDown(() {
    AjustesTelefono.debugDisponible = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AjustesTelefono.canal, null);
  });

  testWidgets('tocar la opción abre los ajustes de notificaciones',
      (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('🔔 Notificaciones del celular'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('abrir-ajustes-notificaciones')));
    await tester.pumpAndSettle();

    expect(llamadas, ['abrirNotificaciones']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('si no se pueden abrir, explica dónde encontrarlos',
      (tester) async {
    respuesta = false;
    await tester.pumpWidget(_app());

    await tester.tap(find.byKey(const ValueKey('abrir-ajustes-notificaciones')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ajustes > Aplicaciones'), findsOneWidget);
  });

  testWidgets('sin el canal nativo (error de plataforma) no se rompe',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AjustesTelefono.canal, (call) async {
      throw PlatformException(code: 'error');
    });
    await tester.pumpWidget(_app());

    await tester.tap(find.byKey(const ValueKey('abrir-ajustes-notificaciones')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ajustes > Aplicaciones'), findsOneWidget);
  });

  testWidgets('fuera de Android la opción no se muestra', (tester) async {
    AjustesTelefono.debugDisponible = false;
    await tester.pumpWidget(_app());

    expect(find.text('🔔 Notificaciones del celular'), findsNothing);
  });
}
