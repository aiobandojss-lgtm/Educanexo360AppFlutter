// test/seleccion_archivos_test.dart
// Límites al elegir adjuntos de anuncios: 5 archivos de 10 MB (E1)
import 'package:educanexo360_app/config/app_config.dart';
import 'package:educanexo360_app/utils/seleccion_archivos.dart';
import 'package:flutter_test/flutter_test.dart';

const _mb = 1024 * 1024;

SeleccionArchivos _filtrar(
  Map<String, int> archivos, {
  int yaSeleccionados = 0,
}) =>
    filtrarArchivosElegidos(
      rutas: archivos.keys.toList(),
      yaSeleccionados: yaSeleccionados,
      maxArchivos: AppConfig.anuncioMaxArchivos,
      maxMB: AppConfig.anuncioMaxArchivoMB,
      unidad: 'archivos por anuncio',
      tamanoDe: (ruta) => archivos[ruta]!,
    );

List<String> _nombres(SeleccionArchivos s) =>
    s.aceptados.map((f) => f.path.split('/').last).toList();

void main() {
  test('los límites de anuncios coinciden con el backend (5 x 10 MB)', () {
    expect(AppConfig.anuncioMaxArchivos, 5);
    expect(AppConfig.anuncioMaxArchivoMB, 10);
  });

  test('archivos válidos se aceptan sin aviso', () {
    final s = _filtrar({'/t/circular.pdf': 2 * _mb, '/t/foto.jpg': _mb});
    expect(_nombres(s), ['circular.pdf', 'foto.jpg']);
    expect(s.aviso, isNull);
  });

  test('un archivo de 12 MB se rechaza con aviso claro', () {
    final s = _filtrar({'/t/grande.pdf': 12 * _mb, '/t/ok.pdf': _mb});
    expect(_nombres(s), ['ok.pdf']);
    expect(s.aviso, contains('"grande.pdf" pesa 12.0 MB'));
    expect(s.aviso, contains('Máximo 10 MB por archivo'));
  });

  test('con 6 archivos solo se agregan 5 y se avisa', () {
    final s = _filtrar({for (var i = 1; i <= 6; i++) '/t/doc$i.pdf': _mb});
    expect(s.aceptados, hasLength(5));
    expect(s.aviso, contains('máximo 5 archivos por anuncio'));
    expect(s.aviso, contains('Se agregaron solo 5'));
  });

  test('cuenta los ya seleccionados', () {
    final s = _filtrar({'/t/a.pdf': _mb, '/t/b.pdf': _mb}, yaSeleccionados: 4);
    expect(_nombres(s), ['a.pdf']);
    expect(s.aviso, contains('Se agregaron solo 1'));

    final lleno = _filtrar({'/t/c.pdf': _mb}, yaSeleccionados: 5);
    expect(lleno.aceptados, isEmpty);
    expect(lleno.aviso, contains('No se agregó ninguno'));
  });

  test('tipo no permitido se rechaza', () {
    final s = _filtrar({'/t/video.mp4': _mb});
    expect(s.aceptados, isEmpty);
    expect(s.aviso, contains('No se permite "video.mp4"'));
  });
}
