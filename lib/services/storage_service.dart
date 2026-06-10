// lib/services/storage_service.dart
import '../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/usuario.dart';

class StorageService {
  // Claves de almacenamiento
  static const String _tokenKey = '@educanexo360_token';
  static const String _refreshTokenKey = '@educanexo360_refreshToken';
  static const String _userKey = '@educanexo360_user';

  // Instancia de FlutterSecureStorage
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ==========================================
  // TOKENS (usando FlutterSecureStorage)
  // ==========================================

  /// Guardar token de acceso
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      dlog('✅ Token guardado en secure storage');
    } catch (e) {
      dlog('❌ Error guardando token: $e');
      rethrow;
    }
  }

  /// Obtener token de acceso
  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        dlog('✅ Token recuperado de secure storage');
      } else {
        dlog('⚠️ No hay token almacenado');
      }
      return token;
    } catch (e) {
      dlog('❌ Error obteniendo token: $e');
      return null;
    }
  }

  /// Guardar refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      dlog('✅ Refresh token guardado');
    } catch (e) {
      dlog('❌ Error guardando refresh token: $e');
      rethrow;
    }
  }

  /// Obtener refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      dlog('❌ Error obteniendo refresh token: $e');
      return null;
    }
  }

  // ==========================================
  // USUARIO (usando SharedPreferences)
  // ==========================================

  /// Guardar datos del usuario
  static Future<void> saveUser(Usuario user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      dlog('✅ Usuario guardado: ${user.nombre} ${user.apellidos}');
    } catch (e) {
      dlog('❌ Error guardando usuario: $e');
      rethrow;
    }
  }

  /// Obtener datos del usuario
  static Future<Usuario?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null) {
        dlog('⚠️ No hay usuario almacenado');
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = Usuario.fromJson(userMap);
      dlog('✅ Usuario recuperado: ${user.nombre} ${user.apellidos}');
      return user;
    } catch (e) {
      dlog('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  // ==========================================
  // LIMPIAR DATOS
  // ==========================================

  /// Limpiar todos los datos de autenticación
  static Future<void> clearAll() async {
    try {
      dlog('🧹 Limpiando datos de autenticación...');

      // Limpiar secure storage
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);

      // Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);

      dlog('✅ Datos limpiados correctamente');
    } catch (e) {
      dlog('❌ Error limpiando datos: $e');
      rethrow;
    }
  }

  /// Limpiar solo el token (mantener usuario)
  static Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      dlog('✅ Tokens limpiados');
    } catch (e) {
      dlog('❌ Error limpiando tokens: $e');
      rethrow;
    }
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  /// Verificar si hay sesión válida (token + usuario)
  static Future<bool> hasValidSession() async {
    try {
      final token = await getToken();
      final user = await getUser();
      final hasSession = token != null && user != null;

      dlog('🔍 ¿Sesión válida? ${hasSession ? "SÍ" : "NO"}');
      return hasSession;
    } catch (e) {
      dlog('❌ Error verificando sesión: $e');
      return false;
    }
  }

  /// Debug: mostrar estado actual del storage
  static Future<void> debugState() async {
    dlog('\n📦 ===== STORAGE DEBUG =====');

    final token = await getToken();
    final refreshToken = await getRefreshToken();
    final user = await getUser();

    dlog(
        '🔑 Token: ${token != null ? "EXISTS (${token.substring(0, 20)}...)" : "NULL"}');
    dlog('🔑 Refresh Token: ${refreshToken != null ? "EXISTS" : "NULL"}');
    dlog(
        '👤 Usuario: ${user != null ? "${user.nombre} (${user.tipo})" : "NULL"}');
    dlog('===========================\n');
  }
}
