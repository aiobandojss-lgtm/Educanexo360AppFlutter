// lib/services/dashboard_service.dart
import 'api_service.dart';
import 'auth_service.dart';
import '../models/ultimo_mensaje.dart';

/// Modelo para información de la escuela
class EscuelaInfo {
  final String id;
  final String nombre;
  final String codigo;

  EscuelaInfo({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  factory EscuelaInfo.fromJson(Map<String, dynamic> json) {
    return EscuelaInfo(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? 'EducaNexo360',
      codigo: json['codigo'] ?? '',
    );
  }
}

/// Modelo para estadísticas del dashboard
class DashboardStats {
  final int mensajesSinLeer;
  final int eventosProximos;
  final int anunciosRecientes;

  DashboardStats({
    required this.mensajesSinLeer,
    required this.eventosProximos,
    required this.anunciosRecientes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      mensajesSinLeer: json['mensajesSinLeer'] ?? 0,
      eventosProximos: json['eventosProximos'] ?? 0,
      anunciosRecientes: json['anunciosRecientes'] ?? 0,
    );
  }
}

/// Servicio para obtener datos del dashboard
class DashboardService {
  /// Obtener información de la escuela
  static Future<EscuelaInfo?> getEscuelaInfo(String escuelaId) async {
    try {
      print('📊 DashboardService - Obteniendo info de escuela: $escuelaId');

      final response = await ApiService().get('/escuelas/$escuelaId');

      if (response != null) {
        final data = response['data'] ?? response;

        if (data != null) {
          final escuela = EscuelaInfo.fromJson(data);
          print('✅ Escuela cargada: ${escuela.nombre}');
          return escuela;
        }
      }

      print('⚠️ No se encontró la escuela');
      return null;
    } catch (e) {
      print('❌ Error obteniendo info de escuela: $e');
      return null;
    }
  }

  /// Obtener estadísticas del dashboard
  static Future<DashboardStats> getDashboardStats() async {
    try {
      print('📊 DashboardService - Obteniendo estadísticas del dashboard');

      int mensajesSinLeer = 0;
      int eventosProximos = 0;
      int anunciosRecientes = 0;

      // ==========================================
      // 1. OBTENER MENSAJES SIN LEER
      // ==========================================
      try {
        print('📬 Obteniendo mensajes sin leer...');

        final mensajesResponse = await ApiService().get('/mensajes');

        if (mensajesResponse != null) {
          dynamic mensajes;

          if (mensajesResponse is List) {
            mensajes = mensajesResponse;
          } else if (mensajesResponse['data'] != null) {
            mensajes = mensajesResponse['data'];
          } else if (mensajesResponse['mensajes'] != null) {
            mensajes = mensajesResponse['mensajes'];
          } else {
            mensajes = [];
          }

          if (mensajes is List) {
            print('📬 Total de mensajes recibidos: ${mensajes.length}');

            final authService = AuthService();
            final user = authService.currentUser;
            if (user == null) {
              mensajesSinLeer = 0;
            } else {
              final userId = user.id;

              final mensajesNoLeidos = mensajes.where((mensaje) {
                if (mensaje == null || mensaje is! Map) return false;

                final esDestinatario = mensaje['esDestinatario'] == true;
                if (!esDestinatario) return false;

                final lecturas = mensaje['lecturas'] as List? ?? [];

                if (lecturas.isEmpty) return true;

                final tieneLeido = lecturas.any((lectura) {
                  if (lectura == null || lectura is! Map) return false;
                  return lectura['usuarioId'] == userId;
                });

                return !tieneLeido;
              }).toList();

              mensajesSinLeer = mensajesNoLeidos.length;
              print('📬 Mensajes SIN leer: $mensajesSinLeer');
            }
          }
        }
      } catch (e) {
        print('❌ Error obteniendo mensajes: $e');
      }

      // ==========================================
      // 2. OBTENER EVENTOS PRÓXIMOS
      // ==========================================
      try {
        print('📅 Obteniendo eventos...');
        final eventosResponse = await ApiService().get('/calendario');

        if (eventosResponse != null) {
          dynamic eventos;

          if (eventosResponse is List) {
            eventos = eventosResponse;
          } else if (eventosResponse['data'] != null) {
            eventos = eventosResponse['data'];
          } else if (eventosResponse['eventos'] != null) {
            eventos = eventosResponse['eventos'];
          } else {
            eventos = [];
          }

          if (eventos is List) {
            final ahora = DateTime.now();
            final limite = ahora.add(const Duration(days: 30));

            eventosProximos = eventos.where((e) {
              if (e == null || e is! Map) return false;

              try {
                final fechaStr = e['fecha'] ??
                    e['fechaInicio'] ??
                    e['startDate'] ??
                    e['date'] ??
                    '';

                if (fechaStr.isEmpty) return false;

                final fechaEvento = DateTime.parse(fechaStr);
                return fechaEvento.isAfter(ahora) &&
                    fechaEvento.isBefore(limite);
              } catch (error) {
                return false;
              }
            }).length;

            print('📅 Eventos PRÓXIMOS (30 días): $eventosProximos');
          }
        }
      } catch (e) {
        print('❌ Error obteniendo eventos: $e');
      }

      // ==========================================
      // 3. OBTENER ANUNCIOS RECIENTES
      // ==========================================
      try {
        print('📢 Obteniendo anuncios...');
        final anunciosResponse = await ApiService().get('/anuncios');

        if (anunciosResponse != null) {
          dynamic anuncios;

          if (anunciosResponse is List) {
            anuncios = anunciosResponse;
          } else if (anunciosResponse['data'] != null) {
            anuncios = anunciosResponse['data'];
          } else if (anunciosResponse['anuncios'] != null) {
            anuncios = anunciosResponse['anuncios'];
          } else {
            anuncios = [];
          }

          if (anuncios is List) {
            final ahora = DateTime.now();
            final limite = ahora.subtract(const Duration(days: 7));

            anunciosRecientes = anuncios.where((a) {
              if (a == null || a is! Map) return false;

              try {
                final estado = a['estado'] ?? a['status'] ?? 'PUBLICADO';

                if (estado.toString().toUpperCase() != 'PUBLICADO') {
                  return false;
                }

                final fechaStr = a['fechaPublicacion'] ??
                    a['publishedAt'] ??
                    a['createdAt'] ??
                    a['fecha'] ??
                    '';

                if (fechaStr.isEmpty) return true;

                final fechaAnuncio = DateTime.parse(fechaStr);
                return fechaAnuncio.isAfter(limite);
              } catch (error) {
                return true;
              }
            }).length;

            print('📢 Anuncios RECIENTES (7 días): $anunciosRecientes');
          }
        }
      } catch (e) {
        print('❌ Error obteniendo anuncios: $e');
      }

      // ==========================================
      // RETORNAR ESTADÍSTICAS
      // ==========================================
      final stats = DashboardStats(
        mensajesSinLeer: mensajesSinLeer,
        eventosProximos: eventosProximos,
        anunciosRecientes: anunciosRecientes,
      );

      print(
          '✅ Stats: mensajes=$mensajesSinLeer, eventos=$eventosProximos, anuncios=$anunciosRecientes');

      return stats;
    } catch (e) {
      print('❌ Error GENERAL obteniendo estadísticas: $e');

      return DashboardStats(
        mensajesSinLeer: 0,
        eventosProximos: 0,
        anunciosRecientes: 0,
      );
    }
  }

  /// Obtener últimos mensajes para mostrar en el dashboard
  static Future<List<UltimoMensaje>> getUltimosMensajes({int limit = 3}) async {
    try {
      print('📬 DashboardService - Obteniendo últimos $limit mensajes');

      final response = await ApiService().get('/mensajes/ultimos?limit=$limit');

      if (response != null && response['success'] == true) {
        final data = response['data'];

        if (data is List) {
          final mensajes =
              data.map((json) => UltimoMensaje.fromJson(json)).toList();

          print('✅ Cargados ${mensajes.length} mensajes');
          return mensajes;
        }
      }

      print('⚠️ No se encontraron mensajes');
      return [];
    } catch (e) {
      print('❌ Error obteniendo últimos mensajes: $e');
      return [];
    }
  }

  // ❌ ELIMINADO: getContadorMensajesSinLeer()
  // El contador ya viene de getDashboardStats().mensajesSinLeer
}
