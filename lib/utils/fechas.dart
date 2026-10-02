// lib/utils/fechas.dart
//
// Manejo único de fechas con el backend (convención de la web):
// - Instantes (mensajes, eventos, tareas…): el backend los guarda en UTC.
//   Al recibir → hora local del teléfono (fechaLocal). Al enviar → UTC con
//   'Z' (fechaParaEnviar). Un DateTime local de Dart con toIso8601String()
//   NO lleva zona y el servidor lo interpretaba en su propia zona.
// - Fechas sin hora (asistencia, nacimiento): llegan como medianoche UTC
//   ('2026-10-01T00:00:00.000Z'). Convertirlas a hora de Colombia las
//   correría al día anterior: se toma 'YYYY-MM-DD' tal cual (soloFecha),
//   como parseFechaLocal de la web. Al enviar → 'yyyy-MM-dd' (soloFechaParaEnviar).

/// Instante recibido del backend, en hora local. Lanza si no es una fecha.
DateTime fechaLocal(String valor) => DateTime.parse(valor).toLocal();

/// Igual que [fechaLocal] pero devuelve null si falta o no es una fecha.
DateTime? fechaLocalOpcional(String? valor) =>
    valor == null ? null : DateTime.tryParse(valor)?.toLocal();

/// Fecha sin hora: toma 'YYYY-MM-DD' sin convertir zona. Lanza si no es válida.
DateTime soloFecha(String valor) {
  final fecha = soloFechaOpcional(valor);
  if (fecha == null) throw FormatException('Fecha inválida', valor);
  return fecha;
}

/// Igual que [soloFecha] pero devuelve null si falta o no es válida.
DateTime? soloFechaOpcional(String? valor) {
  if (valor == null || valor.length < 10) return null;
  final partes = valor.substring(0, 10).split('-');
  if (partes.length != 3) return null;
  final anio = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final dia = int.tryParse(partes[2]);
  if (anio == null || mes == null || dia == null) return null;
  return DateTime(anio, mes, dia);
}

/// Instante para enviar al backend: UTC con 'Z'.
String fechaParaEnviar(DateTime fecha) => fecha.toUtc().toIso8601String();

/// Fecha sin hora para enviar: 'yyyy-MM-dd' según el día local.
String soloFechaParaEnviar(DateTime fecha) {
  final local = fecha.isUtc ? fecha.toLocal() : fecha;
  final mes = local.month.toString().padLeft(2, '0');
  final dia = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mes-$dia';
}
