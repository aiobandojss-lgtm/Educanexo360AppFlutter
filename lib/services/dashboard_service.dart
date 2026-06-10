// lib/services/dashboard_service.dart
import '../utils/logger.dart';
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

/// Modelo para el próximo evento del dashboard
class ProximoEvento {
  final String titulo;
  final DateTime fecha;
  final String? lugar;
  final String? tipo;

  ProximoEvento({
    required this.titulo,
    required this.fecha,
    this.lugar,
    this.tipo,
  });
}

/// Modelo para estadísticas del dashboard
class DashboardStats {
  final int mensajesSinLeer;
  final int eventosProximos;
  final int anunciosRecientes;
  final ProximoEvento? proximoEvento;

  DashboardStats({
    required this.mensajesSinLeer,
    required this.eventosProximos,
    required this.anunciosRecientes,
    this.proximoEvento,
  });
}

/// Servicio para obtener datos del dashboard
class DashboardService {
  /// Obtener información de la escuela
  static Future<EscuelaInfo?> getEscuelaInfo(String escuelaId) async {
    try {
      dlog('📊 DashboardService - Obteniendo info de escuela: $escuelaId');

      final response = await ApiService().get('/escuelas/$escuelaId');

      final data = response['data'] ?? response;

      if (data != null) {
        final escuela = EscuelaInfo.fromJson(data);
        dlog('✅ Escuela cargada: ${escuela.nombre}');
        return escuela;
      }

      dlog('⚠️ No se encontró la escuela');
      return null;
    } catch (e) {
      dlog('❌ Error obteniendo info de escuela: $e');
      return null;
    }
  }

  /// Helper: fetch seguro que retorna null en vez de lanzar excepción
  static Future<dynamic> _safeFetch(String path) async {
    try {
      return await ApiService().get(path);
    } catch (e) {
      dlog('❌ Error fetching $path: $e');
      return null;
    }
  }

  /// Obtener estadísticas del dashboard
  static Future<DashboardStats> getDashboardStats() async {
    try {
      dlog('📊 DashboardService - Obteniendo estadísticas (paralelo)');

      // Las 3 llamadas en paralelo en lugar de secuencial
      final responses = await Future.wait<dynamic>([
        _safeFetch('/mensajes'),
        _safeFetch('/calendario'),
        _safeFetch('/anuncios'),
      ]);

      int mensajesSinLeer = 0;
      int eventosProximos = 0;
      int anunciosRecientes = 0;
      ProximoEvento? proximoEvento;

      // ==========================================
      // 1. PROCESAR MENSAJES SIN LEER
      // ==========================================
      final mensajesResponse = responses[0];
      if (mensajesResponse != null) {
        try {
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
            dlog('📬 Total mensajes recibidos: ${mensajes.length}');
            final user = AuthService().currentUser;
            if (user != null) {
              final userId = user.id;
              mensajesSinLeer = mensajes.where((mensaje) {
                if (mensaje == null || mensaje is! Map) return false;
                if (mensaje['esDestinatario'] != true) return false;
                final lecturas = mensaje['lecturas'] as List? ?? [];
                if (lecturas.isEmpty) return true;
                return !lecturas.any((l) => l is Map && l['usuarioId'] == userId);
              }).length;
              dlog('📬 Mensajes SIN leer: $mensajesSinLeer');
            }
          }
        } catch (e) {
          dlog('❌ Error procesando mensajes: $e');
        }
      }

      // ==========================================
      // 2. PROCESAR EVENTOS PRÓXIMOS
      // ==========================================
      final eventosResponse = responses[1];
      if (eventosResponse != null) {
        try {
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

            String getFechaStr(dynamic e) =>
                (e['fecha'] ?? e['fechaInicio'] ?? e['startDate'] ?? e['date'] ?? '').toString();

            final proximos = eventos.where((e) {
              if (e == null || e is! Map) return false;
              try {
                final f = getFechaStr(e);
                if (f.isEmpty) return false;
                final fechaEvento = DateTime.parse(f);
                return fechaEvento.isAfter(ahora) && fechaEvento.isBefore(limite);
              } catch (_) {
                return false;
              }
            }).toList();

            eventosProximos = proximos.length;

            if (proximos.isNotEmpty) {
              proximos.sort((a, b) {
                try {
                  return DateTime.parse(getFechaStr(a))
                      .compareTo(DateTime.parse(getFechaStr(b)));
                } catch (_) {
                  return 0;
                }
              });
              final next = proximos.first as Map;
              try {
                proximoEvento = ProximoEvento(
                  titulo: (next['titulo'] ?? next['title'] ?? next['nombre'] ?? 'Evento').toString(),
                  fecha: DateTime.parse(getFechaStr(next)),
                  lugar: next['lugar']?.toString() ?? next['location']?.toString(),
                  tipo: next['tipo']?.toString() ?? next['type']?.toString(),
                );
              } catch (_) {}
            }

            dlog('📅 Eventos PRÓXIMOS (30 días): $eventosProximos');
          }
        } catch (e) {
          dlog('❌ Error procesando eventos: $e');
        }
      }

      // ==========================================
      // 3. PROCESAR ANUNCIOS RECIENTES
      // ==========================================
      final anunciosResponse = responses[2];
      if (anunciosResponse != null) {
        try {
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
                if (estado.toString().toUpperCase() != 'PUBLICADO') return false;
                final fechaStr = a['fechaPublicacion'] ?? a['publishedAt'] ?? a['createdAt'] ?? a['fecha'] ?? '';
                if (fechaStr.isEmpty) return true;
                return DateTime.parse(fechaStr).isAfter(limite);
              } catch (_) {
                return true;
              }
            }).length;
            dlog('📢 Anuncios RECIENTES (7 días): $anunciosRecientes');
          }
        } catch (e) {
          dlog('❌ Error procesando anuncios: $e');
        }
      }

      final stats = DashboardStats(
        mensajesSinLeer: mensajesSinLeer,
        eventosProximos: eventosProximos,
        anunciosRecientes: anunciosRecientes,
        proximoEvento: proximoEvento,
      );
      dlog('✅ Stats: mensajes=$mensajesSinLeer, eventos=$eventosProximos, anuncios=$anunciosRecientes');
      return stats;
    } catch (e) {
      dlog('❌ Error GENERAL obteniendo estadísticas: $e');
      return DashboardStats(mensajesSinLeer: 0, eventosProximos: 0, anunciosRecientes: 0, proximoEvento: null);
    }
  }

  /// Obtener últimos mensajes para mostrar en el dashboard
  static Future<List<UltimoMensaje>> getUltimosMensajes({int limit = 3}) async {
    try {
      dlog('📬 DashboardService - Obteniendo últimos $limit mensajes');

      final response = await ApiService().get('/mensajes/ultimos?limit=$limit');

      if (response['success'] == true) {
        final data = response['data'];

        if (data is List) {
          final mensajes =
              data.map((json) => UltimoMensaje.fromJson(json)).toList();

          dlog('✅ Cargados ${mensajes.length} mensajes');
          return mensajes;
        }
      }

      dlog('⚠️ No se encontraron mensajes');
      return [];
    } catch (e) {
      dlog('❌ Error obteniendo últimos mensajes: $e');
      return [];
    }
  }

  // ❌ ELIMINADO: getContadorMensajesSinLeer()
  // El contador ya viene de getDashboardStats().mensajesSinLeer
}
