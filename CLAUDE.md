# CLAUDE.md - Contexto Completo EducaNexo360

## 📋 DESCRIPCIÓN DEL PROYECTO

**EducaNexo360** es una plataforma integral de comunicación escolar que reemplaza las agendas físicas tradicionales en instituciones educativas. Facilita la comunicación bidireccional entre colegios y familias, conectando administradores, profesores, estudiantes y padres en un ecosistema unificado.

**Desarrollador:** Aymer Ivan Obando  
**Ubicación:** Cali, Valle del Cauca, Colombia  
**Estado:** En producción con ~130 usuarios activos, 1 colegio cliente  
**Meta:** 13 colegios, ~10,000 usuarios, 5M COP/mes  

---

## 🏗️ ARQUITECTURA DEL SISTEMA

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Frontend Web  │     │   Backend API    │     │    MongoDB       │
│   React + TS    │◄───►│ Node.js+Express  │◄───►│  (Digital Ocean) │
│   (Vercel)      │     │ TypeScript       │     │  $15/mes         │
└─────────────────┘     │ (cPanel $50/año) │     └──────────────────┘
                        └──────────────────┘
┌─────────────────┐            ▲
│   App Móvil     │            │
│   Flutter/Dart  │◄───────────┘
│   (APK)         │
└─────────────────┘
```

### Hosting y Despliegue
- **Backend:** cPanel (elegido por integración de email) - $50/año
- **Frontend Web:** Vercel (free tier)
- **Base de Datos:** MongoDB en Digital Ocean (managed) - $15/mes
- **App Móvil:** APK distribuido directamente

---

## 👥 ROLES DEL SISTEMA (8 roles)

| Rol | Código | Permisos principales |
|-----|--------|---------------------|
| Super Admin | `SUPER_ADMIN` | Gestión global del sistema, múltiples escuelas |
| Administrador | `ADMIN` | Gestión completa de una escuela |
| Rector | `RECTOR` | Gestión académica y administrativa |
| Coordinador | `COORDINADOR` | Coordinación académica |
| Administrativo | `ADMINISTRATIVO` | Funciones administrativas |
| Docente | `DOCENTE` | Gestión de cursos, tareas, calificaciones, asistencia |
| Estudiante | `ESTUDIANTE` | Ver tareas, entregar trabajos, ver calificaciones |
| Acudiente/Padre | `ACUDIENTE` | Ver información de hijos asociados |

---

## 📦 MÓDULOS DEL SISTEMA

### 1. Autenticación (`/api/auth`)
- Login con JWT (token + refreshToken)
- Refresh token
- Recuperación de contraseña por email
- Verificación de token

### 2. Dashboard/Home
- Panel personalizado según rol del usuario
- Resumen de actividad reciente
- Accesos rápidos a módulos frecuentes

### 3. Mensajería (`/api/mensajes`)
- Mensajes privados bidireccionales entre usuarios
- Adjuntar archivos (multipart/form-data, almacenados en GridFS)
- Bandejas: recibidos, enviados, borradores, archivados
- Notificaciones por email al recibir nuevos mensajes
- Responder mensajes
- Marcar como leído
- Destinatarios disponibles filtrados por permisos

### 4. Calendario/Eventos (`/api/calendario`)
- Creación de eventos: académicos, culturales, deportivos, institucionales
- Fechas de inicio y fin, lugar
- Adjuntos para información adicional
- Confirmación de asistencia a eventos
- Filtrado por tipo y rango de fechas

### 5. Anuncios (`/api/anuncios`)
- Comunicados institucionales con contenido HTML enriquecido
- Tipos: GENERAL, CURSO, DOCENTES, PADRES
- Imagen de portada y adjuntos
- Publicar/Archivar anuncios
- Anuncios destacados

### 6. Asistencia (`/api/asistencia`)
- Registro diario de asistencia por curso y asignatura
- Estados: PRESENTE, AUSENTE, TARDANZA, JUSTIFICADO
- Justificación de ausencias
- Estadísticas por estudiante
- Finalización de registros

### 7. Calificaciones (`/api/calificaciones`)
- Registro de calificaciones por asignatura, período y estudiante
- Calificación máxima: 5.0
- Observaciones por calificación
- Filtrado por estudiante, período, asignatura

### 8. Boletines (`/api/boletin`)
- Generación de boletines académicos
- Por estudiante o por curso completo
- Promedio y puesto del estudiante

### 9. Tareas (`/api/tareas`)
- **Docente:** Crear tareas con título, descripción, fecha límite, prioridad (ALTA/MEDIA/BAJA)
- **Docente:** Subir material de referencia (PDFs, Word, Excel - hasta 5 archivos)
- **Docente:** Ver entregas de estudiantes, calificar con nota y comentarios
- **Docente:** Cerrar tareas (impide más entregas)
- **Estudiante:** Ver tareas asignadas (Pendientes/Entregadas/Calificadas)
- **Estudiante:** Descargar material de referencia, entregar subiendo archivos
- **Acudiente:** Ver tareas y calificaciones de hijos asociados
- **Estados de tarea:** ACTIVA, CERRADA, VENCIDA
- **Estados de entrega:** PENDIENTE, ENTREGADA, ENTREGADA_TARDE, CALIFICADA, NO_ENTREGADA
- Tipo: INDIVIDUAL o GRUPAL
- Asignación automática a todos los estudiantes del curso al crear

### 10. Usuarios (`/api/usuarios`)
- CRUD completo de usuarios
- Filtrado por tipo: docentes, estudiantes, padres
- Cambio de contraseña
- Estudiantes asociados a acudientes
- Perfiles con datos de contacto

### 11. Cursos (`/api/cursos`)
- CRUD de cursos
- Asignación de estudiantes a cursos
- Listado de estudiantes por curso

### 12. Asignaturas (`/api/asignaturas`)
- CRUD de asignaturas
- Asociación con cursos y docentes

### 13. Escuelas (`/api/escuelas`)
- CRUD de escuelas (multi-tenant)
- Períodos académicos configurables

### 14. Notificaciones (`/api/notificaciones`)
- Notificaciones en tiempo real
- Marcar como leída (individual y todas)
- Eliminar notificaciones

### 15. Logros (`/api/logros`)
- Registro de logros académicos

---

## 🗄️ ESTRUCTURA DEL BACKEND (Node.js + Express + TypeScript)

```
EducaNexo360/
├── package.json
├── tsconfig.json
└── src/
    ├── app.ts                          # Punto de entrada
    ├── @types/express/index.d.ts       # Tipos personalizados
    ├── config/
    │   ├── config.ts                   # Variables de entorno
    │   ├── gridfs.ts                   # Almacenamiento de archivos (GridFS)
    │   ├── jwt.config.ts               # Configuración JWT
    │   └── swagger.ts                  # Documentación API
    ├── controllers/
    │   ├── academic.controller.ts
    │   ├── anuncio.controller.ts
    │   ├── asignatura.controller.ts
    │   ├── asistencia.controller.ts
    │   ├── auth.controller.ts
    │   ├── boletin.controller.ts
    │   ├── calendario.controller.ts
    │   ├── calificacion.controller.ts
    │   ├── curso.controller.ts
    │   ├── escuela.controller.ts
    │   ├── logro.controller.ts
    │   ├── mensaje.controller.ts
    │   ├── notificacion.controller.ts
    │   ├── system.controller.ts
    │   └── usuario.controller.ts
    ├── interfaces/
    │   ├── academic.interfaces.ts
    │   ├── IAnuncio.ts
    │   ├── IAsignatura.ts
    │   ├── IAsistencia.ts
    │   ├── ICalendario.ts
    │   ├── ICalificacion.ts
    │   ├── ICurso.ts
    │   ├── IEscuela.ts
    │   ├── IEvento.ts
    │   ├── ILogro.ts
    │   ├── IMensaje.ts
    │   ├── INotificacion.ts
    │   └── IUsuario.ts
    ├── middleware/
    │   ├── auth.middleware.ts           # Autenticación JWT
    │   ├── error.middleware.ts          # Manejo de errores
    │   ├── performance.middleware.ts    # Optimización
    │   ├── security.middleware.ts       # Seguridad
    │   └── validate.middleware.ts       # Validación de datos
    ├── models/
    │   ├── anuncio.model.ts
    │   ├── asignatura.model.ts
    │   ├── asistencia.model.ts
    │   ├── calendario.model.ts
    │   ├── calificacion.model.ts
    │   ├── curso.model.ts
    │   ├── escuela.model.ts
    │   ├── evento.model.ts
    │   ├── logro.model.ts
    │   ├── mensaje.model.ts
    │   ├── notificacion.model.ts
    │   └── usuario.model.ts
    ├── routes/
    │   ├── academic.routes.ts
    │   ├── anuncio.routes.ts
    │   ├── asignatura.routes.ts
    │   ├── asistencia.routes.ts
    │   ├── auth.routes.ts
    │   ├── boletin.routes.ts
    │   ├── calendario.routes.ts
    │   ├── calificacion.routes.ts
    │   ├── curso.routes.ts
    │   ├── escuela.routes.ts
    │   ├── evento.routes.ts
    │   ├── logro.routes.ts
    │   ├── mensaje.routes.ts
    │   ├── notificacion.routes.ts
    │   ├── system.routes.ts
    │   └── usuario.routes.ts
    ├── services/
    │   ├── auth/auth.service.ts
    │   ├── academic.service.ts
    │   ├── asistenciaService.ts
    │   ├── email.service.ts            # Nodemailer para notificaciones
    │   ├── mensaje.service.ts
    │   └── notificacion.service.ts
    ├── templates/emails/
    │   ├── nuevoMensaje.html
    │   └── nuevoMensaje.pug
    ├── utils/
    │   ├── ApiError.ts
    │   ├── apiFeatures.ts
    │   ├── memoryCache.ts
    │   ├── queryOptimizer.ts
    │   └── queryUtils.ts
    └── validations/
        ├── anuncio.validation.ts
        ├── asignatura.validation.ts
        ├── asistencia.validation.ts
        ├── auth.validation.ts
        ├── calificacion.validation.ts
        ├── calendario.validation.ts
        ├── curso.validation.ts
        ├── escuela.validation.ts
        ├── logro.validation.ts
        ├── mensaje.validation.ts
        ├── system.validation.ts
        └── usuario.validation.ts
```

---

## 🌐 API ENDPOINTS COMPLETOS

### Autenticación
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| POST | `/api/auth/login` | Iniciar sesión | No | Todos |
| POST | `/api/auth/register` | Registro | No | Todos |
| POST | `/api/auth/refresh-token` | Renovar token | Sí | Todos |
| POST | `/api/auth/logout` | Cerrar sesión | Sí | Todos |
| POST | `/api/auth/forgot-password` | Recuperar contraseña | No | Todos |
| POST | `/api/auth/reset-password` | Restablecer contraseña | No | Todos |
| GET | `/api/auth/verify-token` | Verificar token | Sí | Todos |

### Usuarios
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/usuarios` | Listar usuarios | Sí | ADMIN |
| GET | `/api/usuarios/:id` | Obtener usuario | Sí | ADMIN, DOCENTE, Propio |
| POST | `/api/usuarios` | Crear usuario | Sí | ADMIN |
| PUT | `/api/usuarios/:id` | Actualizar usuario | Sí | ADMIN, Propio |
| DELETE | `/api/usuarios/:id` | Eliminar usuario | Sí | ADMIN |
| GET | `/api/usuarios/docentes` | Listar docentes | Sí | ADMIN, DOCENTE |
| GET | `/api/usuarios/estudiantes` | Listar estudiantes | Sí | ADMIN, DOCENTE |
| GET | `/api/usuarios/padres` | Listar padres | Sí | ADMIN, DOCENTE |
| POST | `/api/usuarios/:id/cambiar-password` | Cambiar contraseña | Sí | Propio |
| GET | `/api/usuarios/:id/estudiantes-asociados` | Hijos de un acudiente | Sí | ADMIN, ACUDIENTE |

### Escuelas
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/escuelas` | Listar escuelas | Sí | ADMIN |
| GET | `/api/escuelas/:id` | Obtener escuela | Sí | ADMIN |
| POST | `/api/escuelas` | Crear escuela | Sí | ADMIN |
| PUT | `/api/escuelas/:id` | Actualizar escuela | Sí | ADMIN |
| DELETE | `/api/escuelas/:id` | Eliminar escuela | Sí | ADMIN |
| PUT | `/api/escuelas/:id/periodos` | Actualizar períodos | Sí | ADMIN |

### Cursos
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/cursos` | Listar cursos | Sí | ADMIN, DOCENTE |
| GET | `/api/cursos/:id` | Obtener curso | Sí | ADMIN, DOCENTE |
| POST | `/api/cursos` | Crear curso | Sí | ADMIN |
| PUT | `/api/cursos/:id` | Actualizar curso | Sí | ADMIN |
| DELETE | `/api/cursos/:id` | Eliminar curso | Sí | ADMIN |
| GET | `/api/cursos/:id/estudiantes` | Estudiantes del curso | Sí | ADMIN, DOCENTE |
| POST | `/api/cursos/:id/estudiantes` | Añadir estudiantes | Sí | ADMIN |
| DELETE | `/api/cursos/:id/estudiantes/:estudianteId` | Quitar estudiante | Sí | ADMIN |

### Mensajería
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/mensajes` | Listar mensajes (query: bandeja) | Sí | Todos |
| GET | `/api/mensajes/enviados` | Mensajes enviados | Sí | Todos |
| GET | `/api/mensajes/:id` | Detalle de mensaje | Sí | Todos |
| POST | `/api/mensajes` | Enviar mensaje (multipart) | Sí | Todos |
| POST | `/api/mensajes/:id/responder` | Responder mensaje | Sí | Todos |
| DELETE | `/api/mensajes/:id` | Eliminar mensaje | Sí | Todos |
| PUT | `/api/mensajes/:id/leer` | Marcar como leído | Sí | Todos |
| PUT | `/api/mensajes/:id/archivar` | Archivar mensaje | Sí | Todos |
| GET | `/api/mensajes/destinatarios-disponibles` | Usuarios disponibles | Sí | Todos |
| GET | `/api/mensajes/:mensajeId/adjuntos/:adjuntoId` | Descargar adjunto | Sí | Todos |

### Calendario
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/calendario` | Listar eventos (query: desde, hasta, tipo) | Sí | Todos |
| GET | `/api/calendario/:id` | Detalle de evento | Sí | Todos |
| POST | `/api/calendario` | Crear evento (multipart) | Sí | ADMIN, DOCENTE |
| PUT | `/api/calendario/:id` | Actualizar evento | Sí | ADMIN, DOCENTE |
| DELETE | `/api/calendario/:id` | Cancelar evento | Sí | ADMIN, DOCENTE |
| POST | `/api/calendario/:id/confirmar` | Confirmar asistencia | Sí | Todos |
| GET | `/api/calendario/:id/adjunto` | Descargar adjunto | Sí | Todos |

### Anuncios
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/anuncios` | Listar anuncios | Sí | Todos |
| GET | `/api/anuncios/:id` | Detalle de anuncio | Sí | Todos |
| POST | `/api/anuncios` | Crear anuncio (multipart) | Sí | ADMIN, DOCENTE |
| PUT | `/api/anuncios/:id` | Actualizar anuncio | Sí | ADMIN, DOCENTE |
| PATCH | `/api/anuncios/:id/publicar` | Publicar anuncio | Sí | ADMIN, DOCENTE |
| PATCH | `/api/anuncios/:id/archivar` | Archivar anuncio | Sí | ADMIN, DOCENTE |
| GET | `/api/anuncios/:id/imagen/:imagenId` | Obtener imagen | Sí | Todos |
| GET | `/api/anuncios/:id/adjunto/:adjuntoId` | Descargar adjunto | Sí | Todos |

### Asistencia
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/asistencia` | Listar registros (query: cursoId, estudianteId, fecha) | Sí | Todos |
| GET | `/api/asistencia/:id` | Registro específico | Sí | Todos |
| POST | `/api/asistencia` | Crear registro | Sí | ADMIN, DOCENTE |
| PUT | `/api/asistencia/:id` | Actualizar registro | Sí | ADMIN, DOCENTE |
| PATCH | `/api/asistencia/:id/finalizar` | Finalizar registro | Sí | ADMIN, DOCENTE |
| GET | `/api/asistencia/estadisticas/estudiante/:estudianteId` | Estadísticas | Sí | Todos |

### Calificaciones
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/calificaciones` | Listar calificaciones | Sí | Todos |
| GET | `/api/calificaciones/:id` | Obtener calificación | Sí | Todos |
| POST | `/api/calificaciones` | Crear calificación | Sí | ADMIN, DOCENTE |
| PUT | `/api/calificaciones/:id` | Actualizar calificación | Sí | ADMIN, DOCENTE |
| DELETE | `/api/calificaciones/:id` | Eliminar calificación | Sí | ADMIN, DOCENTE |
| GET | `/api/calificaciones/estudiante/:estudianteId` | Por estudiante | Sí | Todos |
| GET | `/api/calificaciones/asignatura/:asignaturaId` | Por asignatura | Sí | ADMIN, DOCENTE |

### Boletines
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/boletin/estudiante/:estudianteId` | Boletín de estudiante | Sí | Todos |
| GET | `/api/boletin/curso/:cursoId` | Boletines del curso | Sí | ADMIN, DOCENTE |
| POST | `/api/boletin/generar` | Generar boletines | Sí | ADMIN, DOCENTE |

### Tareas
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/tareas` | Listar tareas (paginación, filtros) | Sí | ADMIN, DOCENTE, RECTOR, COORDINADOR |
| GET | `/api/tareas/:id` | Detalle de tarea | Sí | Todos (filtrado por permisos) |
| POST | `/api/tareas` | Crear tarea (multipart, hasta 5 archivos) | Sí | ADMIN, DOCENTE |
| PUT | `/api/tareas/:id` | Actualizar tarea | Sí | ADMIN, DOCENTE (creador) |
| DELETE | `/api/tareas/:id` | Eliminar tarea | Sí | ADMIN, DOCENTE (creador) |
| PATCH | `/api/tareas/:id/cerrar` | Cerrar tarea | Sí | ADMIN, DOCENTE (creador) |
| GET | `/api/tareas/mis-tareas` | Tareas del estudiante | Sí | ESTUDIANTE |
| POST | `/api/tareas/:id/entregar` | Entregar tarea (multipart) | Sí | ESTUDIANTE |
| PUT | `/api/tareas/:id/entregas/:entregaId/calificar` | Calificar entrega | Sí | DOCENTE |
| GET | `/api/tareas/:id/archivos/:archivoId` | Descargar archivo de referencia | Sí | Todos |
| GET | `/api/tareas/:id/entregas/:entregaId/archivos/:archivoId` | Descargar archivo de entrega | Sí | DOCENTE, ESTUDIANTE (propio) |

### Notificaciones
| Método | Ruta | Descripción | Auth | Roles |
|--------|------|-------------|------|-------|
| GET | `/api/notificaciones` | Listar notificaciones | Sí | Todos |
| PUT | `/api/notificaciones/:id/leer` | Marcar como leída | Sí | Todos |
| DELETE | `/api/notificaciones/:id` | Eliminar | Sí | Todos |
| PUT | `/api/notificaciones/leer-todas` | Marcar todas leídas | Sí | Todos |

---

## 🎨 FRONTEND WEB (React)

### Stack Tecnológico
- **React** con TypeScript
- **Material-UI (MUI)** como librería de componentes
- **Axios** para peticiones HTTP
- **date-fns** para manejo de fechas
- **React Router** para navegación
- Desplegado en **Vercel**

### Esquema de Colores (Paleta Verde/Teal)
| Uso | Color | Hex |
|-----|-------|-----|
| Primario Verde | Emerald-600 | `#059669` |
| Primario Teal | Teal-600 | `#0D9488` |
| Gradiente Oscuro | Emerald-700 | `#047857` |
| Gradiente Claro | Teal-500 | `#14B8A6` |
| Acento Naranja | Amber | `#F59E0B` |
| Acento Verde | Emerald-500 | `#10B981` |
| Error | Rojo | `#EF4444` |

> **NOTA:** Se migró de púrpura (#6366F1, #8B5CF6, #9333EA) a verde/teal. NO debe quedar ningún color púrpura.

### Módulos del Frontend Web
La aplicación web React replica todos los módulos del backend con interfaces adaptadas según el rol del usuario:

1. **Login/Auth** - Pantalla de inicio de sesión con JWT
2. **Dashboard** - Panel principal personalizado por rol
3. **Mensajería** - Bandeja de entrada/enviados/borradores con adjuntos
4. **Calendario** - Vista de eventos con filtros
5. **Anuncios** - Lista y detalle de comunicados
6. **Asistencia** - Registro y consulta de asistencia
7. **Calificaciones** - Ingreso y consulta de notas
8. **Tareas** - Gestión completa (crear/entregar/calificar)
9. **Usuarios** - Administración de usuarios (CRUD)
10. **Cursos** - Gestión de cursos y estudiantes
11. **Perfil** - Edición de datos personales

---

## 📱 APP MÓVIL (Flutter) - DOCUMENTACIÓN COMPLETA

### Origen
La app fue migrada de React Native a Flutter por problemas técnicos con la generación de APK en React Native. NO fue desarrollo desde cero: se tradujo pantalla por pantalla la app React Native que ya estaba 90% funcional con UX validada por usuarios reales.

### Stack Tecnológico
- **Flutter** + Dart
- **Provider/Riverpod** para gestión de estado
- **Dio** para peticiones HTTP
- **file_picker** para selección de archivos
- **shared_preferences** para almacenamiento local
- **cached_network_image** para cache de imágenes
- **intl** para formateo de fechas
- **path_provider** para rutas del sistema de archivos
- **permission_handler** para permisos del dispositivo

### Dependencias del pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  dio: ^5.0.0
  file_picker: ^5.0.0
  path_provider: ^2.0.0
  intl: ^0.18.0
  shared_preferences: ^2.0.0
  cached_network_image: ^3.0.0
  permission_handler: ^10.0.0
```

### Estructura Completa de la App Flutter
```
lib/
├── main.dart                              # Entry point
├── config/
│   ├── app_config.dart                   # URLs, constantes de la API
│   ├── theme.dart                        # Tema Material (paleta verde/teal)
│   └── routes.dart                       # Definición de rutas/navegación
│
├── models/
│   ├── usuario.dart                      # Modelo usuario con fromJson/toJson
│   ├── mensaje.dart                      # Modelo mensaje
│   ├── calificacion.dart                 # Modelo calificación
│   ├── evento.dart                       # Modelo evento calendario
│   ├── anuncio.dart                      # Modelo anuncio
│   ├── asistencia.dart                   # Modelo asistencia
│   ├── tarea.dart                        # Modelo tarea
│   ├── entrega_tarea.dart                # Modelo entrega de tarea
│   └── archivo_tarea.dart                # Modelo archivo adjunto
│
├── services/
│   ├── api_service.dart                  # Cliente HTTP base (Dio + interceptors + JWT)
│   ├── auth_service.dart                 # Login, logout, refresh token, estado del usuario
│   ├── permission_service.dart           # ⭐ CRÍTICO: Abstracción de permisos por rol
│   ├── mensaje_service.dart              # CRUD mensajería + adjuntos
│   ├── calificacion_service.dart         # CRUD calificaciones + boletines
│   ├── calendario_service.dart           # CRUD eventos + confirmación asistencia
│   ├── usuario_service.dart              # CRUD usuarios + filtros por tipo
│   ├── tarea_service.dart                # CRUD tareas + entregas + calificación
│   ├── anuncio_service.dart              # CRUD anuncios
│   ├── asistencia_service.dart           # CRUD asistencia + estadísticas
│   ├── curso_service.dart                # CRUD cursos + estudiantes
│   └── storage_service.dart              # Persistencia local (SharedPreferences)
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart             # Pantalla de login
│   │   ├── forgot_password_screen.dart   # Recuperar contraseña
│   │   └── change_password_screen.dart   # Cambiar contraseña
│   │
│   ├── home/
│   │   ├── home_screen.dart              # Dashboard principal por rol
│   │   └── dashboard_widgets.dart        # Cards resumen (mensajes, eventos, etc.)
│   │
│   ├── mensajes/
│   │   ├── lista_mensajes_screen.dart    # Bandeja: recibidos/enviados/borradores
│   │   ├── detalle_mensaje_screen.dart   # Vista de un mensaje con adjuntos
│   │   ├── crear_mensaje_screen.dart     # Nuevo mensaje con adjuntos
│   │   └── responder_mensaje_screen.dart # Responder un mensaje
│   │
│   ├── calificaciones/
│   │   ├── lista_calificaciones_screen.dart  # Lista de calificaciones
│   │   ├── detalle_calificacion_screen.dart  # Detalle con observaciones
│   │   ├── crear_calificacion_screen.dart    # Ingresar notas (docente)
│   │   └── boletin_screen.dart               # Boletín académico completo
│   │
│   ├── calendario/
│   │   ├── calendario_screen.dart        # Vista calendario con eventos
│   │   ├── detalle_evento_screen.dart    # Detalle de evento
│   │   └── crear_evento_screen.dart      # Crear/editar evento
│   │
│   ├── tareas/
│   │   ├── tareas_wrapper.dart           # Router: muestra vista según rol
│   │   ├── mis_tareas_screen.dart        # Vista estudiante (3 tabs: Pendientes/Entregadas/Calificadas)
│   │   ├── lista_tareas_screen.dart      # Vista docente (lista con filtros)
│   │   ├── detalle_tarea_screen.dart     # Detalle de tarea (diferente por rol)
│   │   ├── crear_tarea_screen.dart       # Crear/editar tarea (docente)
│   │   ├── entregar_tarea_screen.dart    # Entregar tarea (estudiante, con file_picker)
│   │   ├── lista_entregas_screen.dart    # Ver entregas de estudiantes (docente)
│   │   └── calificar_entrega_screen.dart # Calificar entrega (docente)
│   │
│   ├── anuncios/
│   │   ├── lista_anuncios_screen.dart    # Lista de anuncios
│   │   ├── detalle_anuncio_screen.dart   # Detalle con imagen de portada
│   │   └── crear_anuncio_screen.dart     # Crear anuncio (admin/docente)
│   │
│   ├── asistencia/
│   │   ├── lista_asistencia_screen.dart      # Registros de asistencia
│   │   ├── registrar_asistencia_screen.dart  # Tomar asistencia (docente)
│   │   └── detalle_asistencia_screen.dart    # Detalle por estudiante
│   │
│   ├── usuarios/
│   │   ├── usuarios_screen.dart          # Lista de usuarios (admin)
│   │   ├── crear_usuario_screen.dart     # Crear/editar usuario
│   │   └── detalle_usuario_screen.dart   # Perfil de un usuario
│   │
│   ├── cursos/
│   │   ├── cursos_screen.dart            # Lista de cursos
│   │   ├── crear_curso_screen.dart       # Crear/editar curso
│   │   └── detalle_curso_screen.dart     # Detalle con estudiantes
│   │
│   └── perfil/
│       ├── perfil_screen.dart            # Mi perfil
│       ├── editar_perfil_screen.dart     # Editar datos personales
│       └── estudiantes_asociados_screen.dart # Hijos del acudiente
│
├── widgets/
│   ├── common/
│   │   ├── custom_app_bar.dart           # AppBar personalizada
│   │   ├── main_bottom_navigation.dart   # Barra de navegación inferior + Drawer
│   │   ├── loading_widget.dart           # Indicador de carga
│   │   └── error_widget.dart             # Widget de error
│   │
│   └── tareas/
│       ├── tarea_card.dart               # Card de tarea en lista
│       ├── entrega_card.dart             # Card de entrega
│       ├── estado_badge.dart             # Badge de estado (Pendiente/Entregada/etc.)
│       ├── prioridad_badge.dart          # Badge de prioridad (Alta/Media/Baja)
│       └── file_uploader.dart            # Widget para subir archivos
│
├── providers/
│   └── tarea_provider.dart               # Estado de tareas
│
└── utils/
    ├── validators.dart                   # Validaciones de formularios
    ├── formatters.dart                   # Formateo de fechas, números
    └── helpers.dart                      # Funciones auxiliares
```

### PermissionService (PATRÓN CRÍTICO)
La app usa un sistema de permisos abstraído que NO verifica roles directamente en la UI. Esto permite migrar el backend de permisos sin tocar la UI.

```dart
// ✅ CORRECTO - Cómo se verifica permisos en la app
if (PermissionService.canAccess('calificaciones.crear')) {
  mostrarBoton();
}

// ❌ INCORRECTO - NUNCA se hace esto en la UI
if (user.tipo == 'DOCENTE') {
  mostrarBoton();
}
```

El PermissionService internamente mapea `rol → permisos[]` y expone métodos como:
- `canAccess('modulo.accion')` → bool
- `canAccessAny(['perm1', 'perm2'])` → bool

### Bottom Navigation (5 tabs)
| Tab | Icono | Color | Módulo |
|-----|-------|-------|--------|
| Inicio | Home | `#059669` Verde | Dashboard |
| Mensajes | Mail | `#0D9488` Teal | Mensajería |
| Calendario | Calendar | `#F59E0B` Naranja | Calendario |
| Anuncios | Megaphone | `#10B981` Verde | Anuncios |
| Tareas | Assignment | `#047857` Verde oscuro | Tareas |

Además tiene un **Drawer** lateral con acceso a todos los módulos según permisos del rol.

### Estado de la Migración de Colores UI
**Migración:** Púrpura (#6366F1, #8B5CF6, #9333EA) → Verde/Teal (#059669, #0D9488, #047857)  
**Progreso:** 33% completado (4 de 12 módulos)

| # | Módulo | Estado | Archivo Generado |
|---|--------|--------|------------------|
| 1 | Config (theme.dart) | ✅ Completado | theme_verde.dart |
| 2 | Auth (login_screen.dart) | ✅ Completado | login_screen_correcto.dart |
| 3 | Home (dashboard_screen.dart) | ✅ Completado | dashboard_screen_verde.dart |
| 4 | Nav (main_bottom_navigation.dart) | ✅ Completado | main_bottom_navigation_verde.dart |
| 5 | Calendario | ⏳ Pendiente | - |
| 6 | Tareas (6-7 archivos) | ⏳ Pendiente | - |
| 7 | Mensajería | ⏳ Pendiente | - |
| 8 | Anuncios | ⏳ Pendiente | - |
| 9 | Usuarios | ⏳ Pendiente | - |
| 10 | Cursos | ⏳ Pendiente | - |
| 11 | Asistencia | ⏳ Pendiente | - |
| 12 | Perfil | ⏳ Pendiente | - |

### Paleta de Colores Oficial de la App
```
PRIMARIOS:
#059669  Verde Emerald-600    (color principal)
#0D9488  Teal-600             (color secundario)

GRADIENTES:
#047857  Verde Emerald-700    (oscuro para gradientes)
#14B8A6  Teal-500             (claro para gradientes)

ACENTOS:
#F59E0B  Naranja/Amber        (eventos, calendario)
#10B981  Verde Emerald-500    (anuncios, éxito)
#EF4444  Rojo                 (errores, ausencias)

PROHIBIDOS (NO deben existir):
#6366F1  Púrpura antiguo
#8B5CF6  Violeta antiguo
#9333EA  Púrpura oscuro antiguo
```

### Modelo de Usuario en Flutter
```dart
class Usuario {
  final String id;
  final String nombre;
  final String apellidos;
  final String email;
  final String tipo;          // SUPER_ADMIN, ADMIN, RECTOR, COORDINADOR, ADMINISTRATIVO, DOCENTE, ESTUDIANTE, ACUDIENTE
  final String? escuelaId;
  final String? rolBase;
  final String? perfilRolId;
  final List<String>? permisos;
  final String? telefono;
  final String? direccion;
  final String? foto;
  final List<String>? estudiantesAsociados;
}
```

### Convenciones de Código Flutter
- **Screens:** `nombre_screen.dart` (snake_case)
- **Widgets:** `nombre_widget.dart`
- **Services:** `nombre_service.dart`
- **Models:** `nombre.dart`
- **StatefulWidget** para pantallas con estado
- **Scaffold** como base de cada pantalla
- **PermissionService.canAccess()** para verificar permisos (NUNCA `user.tipo == 'ROL'`)

### Meta Inmediata de la App
**Objetivo:** Publicar en Play Store y App Store de iOS en 1 mes  
**Requisitos pendientes:**
- Completar migración de colores (67% restante)
- Auditoría completa de funcionamiento, rendimiento, seguridad y UI/UX
- Cumplir requisitos de publicación de ambas tiendas

---

## 🔍 AUDITORÍA REQUERIDA PARA CLAUDE CODE - APP FLUTTER

### INSTRUCCIONES PARA CLAUDE CODE:
Cuando Aymer te pida revisar la app Flutter, debes hacer una auditoría completa cubriendo estas 5 áreas:

### 1. FUNCIONAMIENTO
- Verificar que todos los services se conectan correctamente al backend
- Revisar manejo de errores en todas las llamadas API
- Verificar estados de carga (loading states) en cada pantalla
- Revisar navegación entre pantallas (rutas)
- Comprobar flujos completos: login → dashboard → cada módulo
- Verificar refresh token y expiración de sesión
- Revisar manejo de archivos adjuntos (upload/download)
- Verificar que el PermissionService filtra correctamente por rol

### 2. RENDIMIENTO
- Verificar uso de `ListView.builder` (no `ListView`) para listas largas
- Revisar que no hay `setState()` innecesarios que causen rebuilds
- Verificar caché de imágenes con cached_network_image
- Revisar que las peticiones API tienen paginación
- Verificar que no hay memory leaks (dispose de controllers)
- Revisar tamaño del APK y optimizar assets
- Verificar lazy loading de módulos si aplica

### 3. SEGURIDAD
- Verificar que el token JWT se almacena de forma segura (no en texto plano)
- Revisar que las peticiones siempre incluyen Authorization header
- Verificar que no hay datos sensibles en logs
- Revisar validación de inputs en formularios
- Verificar manejo seguro de archivos descargados
- Revisar configuración de ProGuard/R8 para release
- Verificar permisos de Android/iOS (solo los necesarios)
- Revisar que no hay API keys o secretos hardcodeados

### 4. INTERFAZ GRÁFICA (UI/UX) - PRIORIDAD ALTA
- **Colores:** Verificar que NO queden colores púrpuras (#6366F1, #8B5CF6, #9333EA)
- **Consistencia:** Todos los módulos deben usar la misma paleta verde/teal
- **Tipografía:** Revisar fonts, tamaños, pesos - proponer mejoras si las hay
- **Espaciado:** Verificar padding/margin consistente en toda la app
- **Responsividad:** Verificar que se ve bien en diferentes tamaños de pantalla
- **Dark mode:** Evaluar si conviene implementarlo
- **Animaciones:** Evaluar transiciones entre pantallas
- **Iconografía:** Verificar consistencia de iconos
- **Estados vacíos:** Verificar que hay diseños para cuando no hay datos
- **Proponer mejoras de diseño** que hagan la app más profesional y moderna para Play Store

### 5. REQUISITOS PARA TIENDAS
- Verificar que el package name es correcto para producción
- Revisar versionCode y versionName
- Verificar que el app signing está configurado
- Revisar que hay splash screen y app icon correctos
- Verificar que los permisos del manifiesto son los mínimos necesarios
- Preparar screenshots para las tiendas
- Verificar política de privacidad
- Revisar targetSdkVersion para cumplir requisitos de Google Play

---

## ⚙️ TECNOLOGÍAS CLAVE

| Componente | Tecnología | Notas |
|-----------|------------|-------|
| Backend Runtime | Node.js | TypeScript |
| Framework API | Express.js | REST API |
| Base de datos | MongoDB | Mongoose ODM |
| Archivos | GridFS | Almacenamiento en MongoDB |
| Autenticación | JWT | Token + RefreshToken |
| Email | Nodemailer | Notificaciones de mensajes |
| Validación | Express Validator | En middleware |
| Documentación | Swagger/OpenAPI | Auto-generada |
| Frontend Web | React + TypeScript | Material-UI |
| App Móvil | Flutter + Dart | Migrado de React Native |

---

## 🔑 REGLAS DE DESARROLLO (CRÍTICAS)

### Lo que SÍ hacer:
1. ✅ Modificaciones quirúrgicas y dirigidas (NO reescrituras completas)
2. ✅ Preservar 100% la funcionalidad existente
3. ✅ Entregar código completo y funcional (NO fragmentos parciales)
4. ✅ Trabajar desde los archivos originales del proyecto
5. ✅ Mantener compatibilidad con el backend existente
6. ✅ Respetar la estructura de carpetas y patrones establecidos
7. ✅ Probar que no se rompe nada antes de entregar
8. ✅ Documentar los cambios realizados

### Lo que NO hacer:
1. ❌ Crear archivos desde cero cuando existen originales
2. ❌ Cambiar estructura o arquitectura sin autorización
3. ❌ "Mejorar" código sin que se solicite
4. ❌ Modificar imports o dependencias innecesariamente
5. ❌ Cambiar lógica de negocio sin consultar
6. ❌ Requerir cambios en el servidor/backend para mejoras del frontend
7. ❌ Entregar código parcial o con comentarios tipo "// resto del código..."

### Principios de Aymer:
- **Estabilidad sobre innovación:** No romper lo que funciona
- **Visual profesional:** La app debe ser "hermosa, moderna, atractiva"
- **Soluciones completas:** Archivos enteros, no fragmentos
- **Backward compatible:** Todo debe funcionar con el backend actual
- **Paso a paso:** Un módulo a la vez, verificar antes de avanzar

---

## 📊 MODELO DE NEGOCIO

- **Público:** Colegios de primaria y secundaria
- **Precio:** 20,000 - 30,000 COP por estudiante/año
- **Comisión vendedores:** 20%
- **Meta:** 13 colegios, ~300 estudiantes c/u
- **Ingreso objetivo:** 5M COP/mes
- **Diferenciador:** Comunicación bidireccional completa, reemplazo total de agenda física

---

## 🔄 FLUJO DE AUTENTICACIÓN

```
1. POST /api/auth/login → { token, refreshToken, user }
2. Guardar token en localStorage/SecureStorage
3. Incluir en headers: Authorization: Bearer {token}
4. Si token expira → POST /api/auth/refresh-token
5. Si refreshToken expira → Redirigir a login
```

### Estructura del usuario autenticado:
```json
{
  "_id": "507f...",
  "nombre": "Juan",
  "apellidos": "Pérez",
  "email": "juan@ejemplo.com",
  "tipo": "DOCENTE",
  "escuelaId": "507f...",
  "info_academica": {
    "cursos": ["507f..."],
    "estudiantes_asociados": []
  }
}
```

---

## 📝 NOTAS ADICIONALES

- El backend está 100% funcional en producción - NO necesita modificaciones para mejoras del frontend
- Los archivos se almacenan en GridFS (MongoDB) - NO en el sistema de archivos
- Las notificaciones por email se envían automáticamente al recibir mensajes
- El sistema es multi-tenant (soporta múltiples escuelas)
- Cada usuario pertenece a una escuela (`escuelaId`)
- Los endpoints de archivos devuelven datos binarios directamente
- La paginación usa `pagina` y `limite` como query params
- Las respuestas siguen el formato: `{ success: boolean, data: any, message?: string, meta?: { total, pagina, limite, paginas } }`

---

## 🛠️ SKILLS INSTALADOS (Claude Code)

Tienes 3 skills globales instalados en `~/.claude/skills/` que DEBES usar activamente:

### 1. frontend-design
**Cuándo usarlo:** Al diseñar o rediseñar cualquier interfaz visual.
- Genera diseños profesionales, distintivos y de nivel producción
- Evita estéticas genéricas de AI ("AI slop")
- Enfocado en: tipografía única, paletas de color con personalidad, animaciones, composición espacial, texturas y fondos creativos
- NUNCA usar fuentes genéricas (Inter, Roboto, Arial) ni esquemas de color cliché

### 2. flutter-design
**Cuándo usarlo:** Al trabajar con ThemeData, colores, tipografía, espaciado o estilos en Flutter.
- Prioridad: tema del proyecto → Theme.of(context) → valores hardcodeados (último recurso)
- SIEMPRE revisar primero `lib/config/theme.dart` antes de crear estilos nuevos
- Material 3 con ColorScheme
- Sistema de espaciado 4dp (4, 8, 12, 16, 20, 24, 32, 40, 48)
- Soporte dark mode usando ColorScheme
- BoxDecoration consistente: borderRadius 12-16 para cards, 8-12 para inputs

### 3. flutter-development
**Cuándo usarlo:** Al desarrollar funcionalidad, optimizar rendimiento o revisar arquitectura Flutter.
- Arquitectura feature-first (screens, services, models, widgets, utils)
- Estado con Provider/Riverpod, StatefulWidget solo para UI local
- API con Dio + interceptors para JWT + refresh automático en 401
- Rendimiento: ListView.builder obligatorio, const constructors, dispose controllers, cache de imágenes, paginación
- Seguridad: JWT en almacenamiento seguro, no logs de datos sensibles, ProGuard/R8 en release
- Archivos: file_picker + Dio FormData para uploads multipart

### Cómo usar los skills:
- Para auditoría visual → Aplica **frontend-design** + **flutter-design** juntos
- Para auditoría de rendimiento/seguridad → Aplica **flutter-development**
- Para rediseño completo de pantallas → Aplica los 3 en conjunto
- SIEMPRE respetar la paleta verde/teal definida en este documento al aplicar los skills de diseño
