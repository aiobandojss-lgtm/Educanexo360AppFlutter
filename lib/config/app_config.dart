// lib/config/app_config.dart
class AppConfig {
  // ==========================================
  // CONFIGURACIÓN BASE
  // ==========================================

  // ⚠️ CAMBIAR ESTA IP POR LA DE TU SERVIDOR BACKEND
  static const String _localIp = '192.168.1.3';
  static const int _port = 3000;

  // URL base según el entorno
  static String get baseUrl {
    const isDevelopment = true; // Cambiar a false en producción

    if (isDevelopment) {
      return 'http://$_localIp:$_port/api';
    } else {
      return 'https://tu-servidor-produccion.com/api';
    }
  }

  // ==========================================
  // ENDPOINTS DE AUTENTICACIÓN
  // ==========================================

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefreshToken = '/auth/refresh-token';
  static const String authLogout = '/auth/logout';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authVerify = '/auth/verify';

  // ==========================================
  // ENDPOINTS DE USUARIOS
  // ==========================================

  static const String usuarios = '/usuarios';
  static const String usuariosDocentes = '/usuarios/docentes';
  static const String usuariosEstudiantes = '/usuarios/estudiantes';
  static const String usuariosPadres = '/usuarios/padres';

  static String usuarioDetail(String id) => '/usuarios/$id';
  static String usuarioUpdate(String id) => '/usuarios/$id';
  static String usuarioDelete(String id) => '/usuarios/$id';
  static String usuarioChangePassword(String id) =>
      '/usuarios/$id/cambiar-password';
  static String usuarioAssociatedStudents(String id) =>
      '/usuarios/$id/estudiantes-asociados';

  // ==========================================
  // ENDPOINTS DE MENSAJERÍA
  // ==========================================

  static const String mensajes = '/mensajes';
  static const String mensajesEnviados = '/mensajes/enviados';
  static const String mensajesBorradores = '/mensajes/borradores';

  static String mensajeDetail(String id) => '/mensajes/$id';
  static String mensajeDelete(String id) => '/mensajes/$id';
  static String mensajeMarkRead(String id) => '/mensajes/$id/leer';
  static String mensajeAdjunto(String id) => '/mensajes/adjunto/$id';
  static String mensajeResponder(String id) => '/mensajes/$id/responder';

  // ==========================================
  // ENDPOINTS DE CALENDARIO
  // ==========================================

  static const String calendario = '/calendario';

  static String calendarioDetail(String id) => '/calendario/$id';
  static String calendarioUpdate(String id) => '/calendario/$id';
  static String calendarioDelete(String id) => '/calendario/$id';
  static String calendarioConfirmar(String id) => '/calendario/$id/confirmar';
  static String calendarioAdjunto(String id) => '/calendario/$id/adjunto';

  // ==========================================
  // ENDPOINTS DE ANUNCIOS
  // ==========================================

  static const String anuncios = '/anuncios';

  static String anuncioDetail(String id) => '/anuncios/$id';
  static String anuncioUpdate(String id) => '/anuncios/$id';
  static String anuncioPublicar(String id) => '/anuncios/$id/publicar';
  static String anuncioArchivar(String id) => '/anuncios/$id/archivar';
  static String anuncioImagen(String anuncioId, String imagenId) =>
      '/anuncios/$anuncioId/imagen/$imagenId';
  static String anuncioAdjunto(String anuncioId, String adjuntoId) =>
      '/anuncios/$anuncioId/adjunto/$adjuntoId';

  // ==========================================
  // ENDPOINTS DE CALIFICACIONES
  // ==========================================

  static const String calificaciones = '/calificaciones';

  static String calificacionDetail(String id) => '/calificaciones/$id';
  static String calificacionUpdate(String id) => '/calificaciones/$id';
  static String calificacionDelete(String id) => '/calificaciones/$id';
  static String calificacionEstudiante(String estudianteId) =>
      '/calificaciones/estudiante/$estudianteId';
  static String calificacionAsignatura(String asignaturaId) =>
      '/calificaciones/asignatura/$asignaturaId';

  // ==========================================
  // ENDPOINTS DE ASISTENCIA
  // ==========================================

  static const String asistencia = '/asistencia';
  static const String asistenciaDia = '/asistencia/dia';

  static String asistenciaDetail(String id) => '/asistencia/$id';
  static String asistenciaUpdate(String id) => '/asistencia/$id';
  static String asistenciaDelete(String id) => '/asistencia/$id';
  static String asistenciaFinalizar(String id) => '/asistencia/$id/finalizar';
  static String asistenciaEstadisticasCurso(String cursoId) =>
      '/asistencia/estadisticas/curso/$cursoId';
  static String asistenciaEstadisticasEstudiante(String estudianteId) =>
      '/asistencia/estadisticas/estudiante/$estudianteId';
  static String asistenciaResumenPeriodo(String periodoId) =>
      '/asistencia/resumen/periodo/$periodoId';

  // ==========================================
  // ENDPOINTS DE CURSOS
  // ==========================================

  static const String cursos = '/cursos';

  static String cursoDetail(String id) => '/cursos/$id';
  static String cursoUpdate(String id) => '/cursos/$id';
  static String cursoDelete(String id) => '/cursos/$id';
  static String cursoEstudiantes(String id) => '/cursos/$id/estudiantes';
  static String cursoAddEstudiante(String id) => '/cursos/$id/estudiantes';
  static String cursoRemoveEstudiante(String cursoId, String estudianteId) =>
      '/cursos/$cursoId/estudiantes/$estudianteId';

  // ==========================================
  // ENDPOINTS DE ESCUELAS
  // ==========================================

  static const String escuelas = '/escuelas';

  static String escuelaDetail(String id) => '/escuelas/$id';
  static String escuelaUpdate(String id) => '/escuelas/$id';
  static String escuelaDelete(String id) => '/escuelas/$id';
  static String escuelaPeriodos(String id) => '/escuelas/$id/periodos';

  // ==========================================
  // ENDPOINTS DE NOTIFICACIONES
  // ==========================================

  static const String notificaciones = '/notificaciones';
  static const String notificacionesLeerTodas = '/notificaciones/leer-todas';

  static String notificacionMarkRead(String id) => '/notificaciones/$id/leer';
  static String notificacionDelete(String id) => '/notificaciones/$id';

  // ==========================================
  // ENDPOINTS DE BOLETINES
  // ==========================================

  static const String boletinGenerar = '/boletin/generar';

  static String boletinEstudiante(String estudianteId) =>
      '/boletin/estudiante/$estudianteId';
  static String boletinCurso(String cursoId) => '/boletin/curso/$cursoId';

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Construir URL completa con query parameters
  static String buildUrl(String endpoint, {Map<String, dynamic>? queryParams}) {
    if (queryParams == null || queryParams.isEmpty) {
      return endpoint;
    }

    final uri = Uri.parse(endpoint);
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryParams.map((key, value) => MapEntry(key, value.toString())),
    });

    return newUri.toString();
  }

  /// Verificar si es URL de desarrollo
  static bool get isDevelopment =>
      baseUrl.contains('localhost') || baseUrl.contains('192.168');

  /// Información de debug
  static Map<String, dynamic> get debugInfo => {
        'baseUrl': baseUrl,
        'isDevelopment': isDevelopment,
        'localIp': _localIp,
        'port': _port,
      };

  /// Imprimir configuración actual
  static void printConfig() {
    print('\n🌐 ===== APP CONFIG =====');
    print('📍 Base URL: $baseUrl');
    print('🔧 Modo: ${isDevelopment ? "DESARROLLO" : "PRODUCCIÓN"}');
    if (isDevelopment) {
      print('🖥️  IP Local: $_localIp:$_port');
    }
    print('========================\n');
  }
}
