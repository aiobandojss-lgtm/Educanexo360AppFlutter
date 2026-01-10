// lib/models/ultimo_mensaje.dart

/// Modelo para los últimos mensajes del dashboard
class UltimoMensaje {
  final String id;
  final RemitenteInfo remitente;
  final String asunto;
  final String preview;
  final DateTime fechaEnvio;
  final String tiempoRelativo;

  UltimoMensaje({
    required this.id,
    required this.remitente,
    required this.asunto,
    required this.preview,
    required this.fechaEnvio,
    required this.tiempoRelativo,
  });

  factory UltimoMensaje.fromJson(Map<String, dynamic> json) {
    print('🔍 DEBUG UltimoMensaje.fromJson:');
    print('   Raw JSON: $json');

    // Intentar múltiples campos de fecha
    DateTime fechaEnvio;

    if (json['fechaEnvio'] != null) {
      print('   ✅ Usando fechaEnvio: ${json['fechaEnvio']}');
      fechaEnvio = DateTime.parse(json['fechaEnvio']);
    } else if (json['createdAt'] != null) {
      print('   ✅ Usando createdAt: ${json['createdAt']}');
      fechaEnvio = DateTime.parse(json['createdAt']);
    } else if (json['updatedAt'] != null) {
      print('   ✅ Usando updatedAt: ${json['updatedAt']}');
      fechaEnvio = DateTime.parse(json['updatedAt']);
    } else {
      print('   ⚠️ No hay fecha, usando DateTime.now()');
      fechaEnvio = DateTime.now();
    }

    print('   📅 Fecha parseada: $fechaEnvio');
    print('   🕐 Ahora: ${DateTime.now()}');
    print('   ⏱️ Diferencia: ${DateTime.now().difference(fechaEnvio)}');

    // Limpiar HTML del preview
    String previewLimpio = json['preview'] ?? json['contenido'] ?? '';
    previewLimpio = _limpiarHtml(previewLimpio);

    // Calcular tiempo relativo correctamente
    String tiempoCalculado = _calcularTiempoRelativo(fechaEnvio);
    print('   ⏰ Tiempo calculado: $tiempoCalculado');

    return UltimoMensaje(
      id: json['id'] ?? json['_id'] ?? '',
      remitente: RemitenteInfo.fromJson(json['remitente'] ?? {}),
      asunto: json['asunto'] ?? 'Sin asunto',
      preview: previewLimpio,
      fechaEnvio: fechaEnvio,
      tiempoRelativo: tiempoCalculado,
    );
  }

  /// Limpia etiquetas HTML del texto
  static String _limpiarHtml(String texto) {
    // Remover etiquetas HTML
    String limpio = texto.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decodificar entidades HTML comunes
    limpio = limpio
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Limpiar espacios múltiples
    limpio = limpio.replaceAll(RegExp(r'\s+'), ' ').trim();

    return limpio;
  }

  /// Calcula el tiempo relativo desde la fecha de envío
  static String _calcularTiempoRelativo(DateTime fechaEnvio) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaEnvio);

    if (diferencia.inSeconds < 60) {
      return 'Hace un momento';
    } else if (diferencia.inMinutes < 60) {
      final minutos = diferencia.inMinutes;
      return 'Hace $minutos ${minutos == 1 ? 'minuto' : 'minutos'}';
    } else if (diferencia.inHours < 24) {
      final horas = diferencia.inHours;
      return 'Hace $horas ${horas == 1 ? 'hora' : 'horas'}';
    } else if (diferencia.inDays < 7) {
      final dias = diferencia.inDays;
      return 'Hace $dias ${dias == 1 ? 'día' : 'días'}';
    } else if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();
      return 'Hace $semanas ${semanas == 1 ? 'semana' : 'semanas'}';
    } else if (diferencia.inDays < 365) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace $meses ${meses == 1 ? 'mes' : 'meses'}';
    } else {
      final anos = (diferencia.inDays / 365).floor();
      return 'Hace $anos ${anos == 1 ? 'año' : 'años'}';
    }
  }
}

/// Información del remitente del mensaje
class RemitenteInfo {
  final String nombre;
  final String apellidos;
  final String nombreCompleto;
  final String iniciales;

  RemitenteInfo({
    required this.nombre,
    required this.apellidos,
    required this.nombreCompleto,
    required this.iniciales,
  });

  factory RemitenteInfo.fromJson(Map<String, dynamic> json) {
    final nombre = json['nombre'] ?? '';
    final apellidos = json['apellidos'] ?? '';

    // Calcular nombreCompleto si no viene del backend
    String nombreCompleto = json['nombreCompleto'] ?? '';
    if (nombreCompleto.isEmpty && (nombre.isNotEmpty || apellidos.isNotEmpty)) {
      nombreCompleto = '$nombre $apellidos'.trim();
    }

    // Calcular iniciales si no vienen del backend
    String iniciales = json['iniciales'] ?? '';
    if (iniciales.isEmpty) {
      iniciales = _calcularIniciales(nombre, apellidos);
    }

    return RemitenteInfo(
      nombre: nombre,
      apellidos: apellidos,
      nombreCompleto: nombreCompleto,
      iniciales: iniciales,
    );
  }

  /// Calcula las iniciales a partir del nombre y apellidos
  static String _calcularIniciales(String nombre, String apellidos) {
    String inicial1 = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    String inicial2 = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';

    if (inicial1.isEmpty && inicial2.isEmpty) {
      return '??';
    }

    return '$inicial1$inicial2';
  }
}
