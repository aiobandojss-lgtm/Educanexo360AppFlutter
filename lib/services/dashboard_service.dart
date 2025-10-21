// lib/services/dashboard_service.dart
import 'api_service.dart';
import 'auth_service.dart';

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
        // El backend puede devolver la data directamente o dentro de un objeto 'data'
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
  /// Como el backend NO tiene un endpoint /dashboard/stats,
  /// obtenemos los datos de los endpoints individuales
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

        // Obtener TODOS los mensajes (el backend NO filtra correctamente con ?leido=false)
        final mensajesResponse = await ApiService().get('/mensajes');

        print('📬 Response completo: $mensajesResponse');

        if (mensajesResponse != null) {
          // Extraer la lista de mensajes
          dynamic mensajes;

          if (mensajesResponse is List) {
            mensajes = mensajesResponse;
            print('📬 Formato: Array directo');
          } else if (mensajesResponse['data'] != null) {
            mensajes = mensajesResponse['data'];
            print('📬 Formato: response.data');
          } else if (mensajesResponse['mensajes'] != null) {
            mensajes = mensajesResponse['mensajes'];
            print('📬 Formato: response.mensajes');
          } else {
            print('⚠️ Formato de respuesta no reconocido');
            mensajes = [];
          }

          if (mensajes is List) {
            print('📬 Total de mensajes recibidos: ${mensajes.length}');

            // ⭐ FILTRAR MANUALMENTE los mensajes NO leídos
            // Obtener el ID del usuario actual
            final authService = AuthService();
            final user = authService.currentUser;
            if (user == null) {
              print('⚠️ No hay usuario autenticado');
              mensajesSinLeer = 0;
            } else {
              final userId = user.id;
              print('👤 ID del usuario actual: $userId');

              // Filtrar mensajes donde el usuario es destinatario Y NO tiene lectura
              final mensajesNoLeidos = mensajes.where((mensaje) {
                if (mensaje == null || mensaje is! Map) return false;

                // Verificar si es destinatario
                final esDestinatario = mensaje['esDestinatario'] == true;
                if (!esDestinatario) return false;

                // Verificar el array de lecturas
                final lecturas = mensaje['lecturas'] as List? ?? [];

                // Si el array está vacío = NO leído
                if (lecturas.isEmpty) return true;

                // Si el array tiene elementos, verificar si el usuario actual está en las lecturas
                final tieneLeido = lecturas.any((lectura) {
                  if (lectura == null || lectura is! Map) return false;
                  return lectura['usuarioId'] == userId;
                });

                // Si NO tiene lectura del usuario = NO leído
                return !tieneLeido;
              }).toList();

              mensajesSinLeer = mensajesNoLeidos.length;
              print(
                  '📬 Mensajes SIN leer (filtrados manualmente): $mensajesSinLeer');
            }
          } else {
            print('⚠️ Mensajes no es una lista válida');
          }
        } else {
          print('⚠️ Response de mensajes es null');
        }
      } catch (e, stackTrace) {
        print('❌ Error obteniendo mensajes: $e');
        print('Stack trace: $stackTrace');
      }

      // ==========================================
      // 2. OBTENER EVENTOS PRÓXIMOS
      // ==========================================
      try {
        print('📅 Obteniendo eventos...');
        final eventosResponse = await ApiService().get('/calendario');

        print('📅 Response completo: $eventosResponse');

        if (eventosResponse != null) {
          dynamic eventos;

          if (eventosResponse is List) {
            eventos = eventosResponse;
            print('📅 Formato: Array directo');
          } else if (eventosResponse['data'] != null) {
            eventos = eventosResponse['data'];
            print('📅 Formato: response.data');
          } else if (eventosResponse['eventos'] != null) {
            eventos = eventosResponse['eventos'];
            print('📅 Formato: response.eventos');
          } else {
            print('⚠️ Formato de respuesta no reconocido');
            eventos = [];
          }

          if (eventos is List) {
            print('📅 Total eventos recibidos: ${eventos.length}');

            // Contar eventos futuros (próximos 30 días)
            final ahora = DateTime.now();
            final limite = ahora.add(const Duration(days: 30));

            print('📅 Buscando eventos entre $ahora y $limite');

            eventosProximos = eventos.where((e) {
              if (e == null || e is! Map) return false;

              try {
                // Probar diferentes nombres de campo para la fecha
                final fechaStr = e['fecha'] ??
                    e['fechaInicio'] ??
                    e['startDate'] ??
                    e['date'] ??
                    '';

                if (fechaStr.isEmpty) {
                  print('⚠️ Evento sin fecha: $e');
                  return false;
                }

                final fechaEvento = DateTime.parse(fechaStr);
                final esProximo =
                    fechaEvento.isAfter(ahora) && fechaEvento.isBefore(limite);

                if (esProximo) {
                  print(
                      '✅ Evento próximo encontrado: ${e['titulo'] ?? e['title']} - $fechaEvento');
                }

                return esProximo;
              } catch (error) {
                print('⚠️ Error parseando fecha de evento: $error');
                return false;
              }
            }).length;

            print('📅 Eventos PRÓXIMOS (30 días): $eventosProximos');
          } else {
            print('⚠️ Eventos no es una lista válida');
          }
        } else {
          print('⚠️ Response de eventos es null');
        }
      } catch (e, stackTrace) {
        print('❌ Error obteniendo eventos: $e');
        print('Stack trace: $stackTrace');
      }

      // ==========================================
      // 3. OBTENER ANUNCIOS RECIENTES
      // ==========================================
      try {
        print('📢 Obteniendo anuncios...');
        final anunciosResponse = await ApiService().get('/anuncios');

        print('📢 Response completo: $anunciosResponse');

        if (anunciosResponse != null) {
          dynamic anuncios;

          if (anunciosResponse is List) {
            anuncios = anunciosResponse;
            print('📢 Formato: Array directo');
          } else if (anunciosResponse['data'] != null) {
            anuncios = anunciosResponse['data'];
            print('📢 Formato: response.data');
          } else if (anunciosResponse['anuncios'] != null) {
            anuncios = anunciosResponse['anuncios'];
            print('📢 Formato: response.anuncios');
          } else {
            print('⚠️ Formato de respuesta no reconocido');
            anuncios = [];
          }

          if (anuncios is List) {
            print('📢 Total anuncios recibidos: ${anuncios.length}');

            // Contar anuncios de los últimos 7 días
            final ahora = DateTime.now();
            final limite = ahora.subtract(const Duration(days: 7));

            print('📢 Buscando anuncios desde $limite hasta $ahora');

            anunciosRecientes = anuncios.where((a) {
              if (a == null || a is! Map) return false;

              try {
                // Verificar si el anuncio está activo/publicado
                final estado =
                    a['estado'] ?? a['status'] ?? a['state'] ?? 'PUBLICADO';

                if (estado.toString().toUpperCase() != 'PUBLICADO') {
                  return false;
                }

                // Verificar fecha de creación o publicación
                final fechaStr = a['fechaPublicacion'] ??
                    a['publishedAt'] ??
                    a['createdAt'] ??
                    a['fecha'] ??
                    a['date'] ??
                    '';

                if (fechaStr.isEmpty) {
                  print(
                      '⚠️ Anuncio sin fecha, se considera reciente: ${a['titulo'] ?? a['title']}');
                  return true; // Si no hay fecha, considerarlo reciente
                }

                final fechaAnuncio = DateTime.parse(fechaStr);
                final esReciente = fechaAnuncio.isAfter(limite);

                if (esReciente) {
                  print(
                      '✅ Anuncio reciente encontrado: ${a['titulo'] ?? a['title']} - $fechaAnuncio');
                }

                return esReciente;
              } catch (error) {
                print('⚠️ Error parseando anuncio: $error');
                // Si hay error parseando fecha, considerarlo reciente
                return true;
              }
            }).length;

            print('📢 Anuncios RECIENTES (7 días): $anunciosRecientes');
          } else {
            print('⚠️ Anuncios no es una lista válida');
          }
        } else {
          print('⚠️ Response de anuncios es null');
        }
      } catch (e, stackTrace) {
        print('❌ Error obteniendo anuncios: $e');
        print('Stack trace: $stackTrace');
      }

      // ==========================================
      // RETORNAR ESTADÍSTICAS
      // ==========================================
      final stats = DashboardStats(
        mensajesSinLeer: mensajesSinLeer,
        eventosProximos: eventosProximos,
        anunciosRecientes: anunciosRecientes,
      );

      print('');
      print('✅ ===== ESTADÍSTICAS FINALES =====');
      print('   📬 Mensajes sin leer: $mensajesSinLeer');
      print('   📅 Eventos próximos: $eventosProximos');
      print('   📢 Anuncios recientes: $anunciosRecientes');
      print('====================================');
      print('');

      return stats;
    } catch (e, stackTrace) {
      print('❌ Error GENERAL obteniendo estadísticas: $e');
      print('Stack trace: $stackTrace');

      // Valores por defecto si falla todo
      return DashboardStats(
        mensajesSinLeer: 0,
        eventosProximos: 0,
        anunciosRecientes: 0,
      );
    }
  }
}
