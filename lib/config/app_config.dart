// lib/config/app_config.dart
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class AppConfig {
  // ==========================================
  // CONFIGURACIÓN BASE - SISTEMA DE ENTORNOS
  // ==========================================
  //
  // Para desarrollo local, usar:
  //   flutter run --dart-define=API_URL=http://192.168.0.17:3000/api
  //
  // Para producción (release), usar:
  //   flutter build apk --dart-define=API_URL=https://TU_DOMINIO.com/api
  //   flutter build appbundle --dart-define=API_URL=https://TU_DOMINIO.com/api
  //
  // Si no se pasa --dart-define, usa la URL de desarrollo por defecto
  // SOLO en debug/profile. En release la app se niega a arrancar
  // (ver releaseConfigError) para no publicar nunca un APK apuntando a la IP
  // de desarrollo.

  static const String _defaultDevUrl = 'http://192.168.1.7:3000/api';

  // URL inyectada en tiempo de compilación via --dart-define
  static const String _injectedUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  // URL base activa
  static String get baseUrl {
    if (_injectedUrl.isNotEmpty) return _injectedUrl;
    // En release nunca se usa la URL de desarrollo
    if (kReleaseMode) return '';
    return _defaultDevUrl;
  }

  /// En release: motivo por el que la build está mal configurada, o null si
  /// está bien. main.dart muestra este error en pantalla en lugar de la app.
  static String? get releaseConfigError {
    if (!kReleaseMode) return null;
    if (_injectedUrl.isEmpty) {
      return 'Build de release sin API_URL.\n'
          'Compila con --dart-define=API_URL=https://...';
    }
    if (!_injectedUrl.startsWith('https://')) {
      return 'API_URL debe usar https en release.\n'
          'Valor recibido: $_injectedUrl';
    }
    return null;
  }

  static bool get isProduction =>
      baseUrl.startsWith('https://') && !baseUrl.contains('192.168');

  static bool get isDevelopment => !isProduction;

  // ==========================================
  // ENLACES LEGALES (requeridos por Play Store / App Store)
  // ==========================================
  //
  // ⚠️ ACTUALIZAR con la URL real de la Política de Privacidad publicada
  // antes de enviar a las tiendas. Debe ser una URL pública y accesible.

  static const String privacyPolicyUrl =
      'https://educanexo360.creativebycode.com/politica-de-privacidad.html';
  static const String termsUrl =
      'https://educanexo360.creativebycode.com/terminos.html';

  // ==========================================
  // LÍMITES DE SUBIDA (alineados con el backend)
  // ==========================================
  //
  // mensaje.routes.ts: multer 5 MB por archivo, 5 archivos;
  // mensaje.controller.ts: 15 MB en total.
  // tarea.routes.ts: multer 10 MB por archivo, 5 archivos.

  static const int mensajeMaxArchivos = 5;
  static const int mensajeMaxArchivoMB = 5;
  static const int mensajeMaxTotalMB = 15;
  static const int tareaMaxArchivos = 5;
  static const int tareaMaxArchivoMB = 10;

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
  static const String usuariosEliminarCuenta = '/usuarios/eliminar-cuenta';
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
  static String usuarioAssociateStudent(String acudienteId) =>
      '/usuarios/$acudienteId/estudiantes-asociados';

  static String usuarioDisassociateStudent(
          String acudienteId, String estudianteId) =>
      '/usuarios/$acudienteId/estudiantes-asociados/$estudianteId';

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
  // ENDPOINTS DE PERFILES DE ROL (RBAC)
  // ==========================================

  static const String perfilesRol = '/perfiles-rol';

  static String perfilRolDetail(String id) => '/perfiles-rol/$id';
  static const String perfilesRolCatalogo = '/perfiles-rol/catalogo/permisos';
  static String perfilesRolSugeridos(String rolBase) =>
      '/perfiles-rol/catalogo/sugeridos/$rolBase';

  // ==========================================
  // ENDPOINTS DE NOTIFICACIONES
  // ==========================================

  static const String notificaciones = '/notificaciones';
  static const String notificacionesLeerTodas = '/notificaciones/leer-todas';
  static const String notificacionesFcmToken = '/notificaciones/register-token';

  // Desvincular el token FCM del usuario al cerrar sesión (backend Fase 1):
  // POST /notificaciones/unregister-token { fcmToken }, autenticado; responde
  // 200 con data.tokenRemoved. Además el logout invalida el token local
  // (deleteToken).
  static const bool fcmUnregisterEnabled = true;
  static const String notificacionesFcmUnregister =
      '/notificaciones/unregister-token';

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
  // ENDPOINTS DE TAREAS
  // ==========================================

  static const String tareas = '/tareas';
  static const String misTareas = '/tareas/especial/mis-tareas';

  static String tareaDetail(String id) => '/tareas/$id';
  static String tareaUpdate(String id) => '/tareas/$id';
  static String tareaDelete(String id) => '/tareas/$id';
  static String tareaCerrar(String id) => '/tareas/$id/cerrar';

  // 🔧 ARCHIVOS DE REFERENCIA (material del docente)
  // ✅ CORREGIDO: Es /archivos NO /archivos-referencia
  static String tareaArchivos(String id) => '/tareas/$id/archivos';
  static String tareaArchivoDelete(String tareaId, String archivoId) =>
      '/tareas/$tareaId/archivos/$archivoId';
  static String tareaArchivoDownload(String tareaId, String archivoId) =>
      '/tareas/$tareaId/archivos/$archivoId';

  // Entregas de estudiantes
  static String tareaMarcarVista(String id) => '/tareas/$id/marcar-vista';
  static String tareaEntregar(String id) => '/tareas/$id/entregar';
  static String tareaMiEntrega(String id) => '/tareas/$id/mi-entrega';
  static String tareaEntregas(String id) => '/tareas/$id/entregas';
  static String tareaCalificar(String tareaId, String entregaId) =>
      '/tareas/$tareaId/entregas/$entregaId/calificar';

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

  /// Información de debug
  static Map<String, dynamic> get debugInfo => {
        'baseUrl': baseUrl,
        'isProduction': isProduction,
        'injectedUrl': _injectedUrl.isNotEmpty ? _injectedUrl : '(no inyectada)',
      };

  /// Imprimir configuración actual
  static void printConfig() {
    dlog('\n🌐 ===== APP CONFIG =====');
    dlog('📍 Base URL: $baseUrl');
    dlog('🔧 Modo: ${isProduction ? "PRODUCCIÓN" : "DESARROLLO"}');
    dlog('========================\n');
  }
}
