// test/file_name_sanitize_test.dart
// Nombres de archivo que llegan del servidor (Fase 2B, ítem 2B.5)
import 'package:educanexo360_app/utils/file_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const s = FileHelper.sanitizeFileName;

  test('conserva un nombre normal', () {
    expect(s('Circular junio.pdf'), 'Circular junio.pdf');
  });

  test('no permite salir de la carpeta', () {
    expect(s('../../shared_prefs/datos.xml'), 'datos.xml');
    expect(s(r'..\..\evil.exe'), 'evil.exe');
    expect(s('..'), 'archivo');
  });

  test('quita puntos iniciales y caracteres inválidos', () {
    expect(s('.oculto'), 'oculto');
    expect(s('a<b>:c|d?.txt'), 'a_b__c_d_.txt');
  });

  test('limita la longitud conservando la extensión', () {
    final largo = '${'x' * 300}.pdf';
    final result = s(largo);
    expect(result.length, 120);
    expect(result.endsWith('.pdf'), isTrue);
  });

  test('vacío → nombre por defecto', () {
    expect(s(''), 'archivo');
    expect(s('   '), 'archivo');
  });
}
