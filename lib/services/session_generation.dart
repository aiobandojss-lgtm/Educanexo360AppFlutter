// lib/services/session_generation.dart

/// Contador global de sesión.
///
/// Se incrementa cada vez que se limpia la sesión local (logout, sesión
/// expirada o inicio de un login). ApiService marca cada petición con el valor
/// vigente al iniciarla y descarta la respuesta si al llegar el valor cambió:
/// así una respuesta del usuario anterior nunca llega a los providers.
class SessionGeneration {
  SessionGeneration._();

  static int _current = 0;

  static int get current => _current;

  static void next() => _current++;
}
