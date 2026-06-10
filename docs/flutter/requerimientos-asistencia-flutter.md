# Requerimientos Flutter — Módulo de Asistencia
**Fecha:** 2026-05-28  
**Proyecto:** EducaNexo360  
**Backend:** Node.js + Express + TypeScript + MongoDB (ya en producción)  
**Documento para:** Chat de desarrollo Flutter — planeación e implementación del módulo de asistencia completo

---

## 1. Contexto del sistema

EducaNexo360 es una plataforma escolar que reemplaza la agenda física. El backend REST ya está 100% construido y en producción. Flutter **no necesita construir lógica de negocio** — solo consumir los endpoints existentes y presentar la información de forma apropiada para dispositivos móviles.

**URL base del backend:** configurar según ambiente (desarrollo/producción)  
**Autenticación:** JWT Bearer token en cada request  
**Formato de respuesta estándar:**
```json
{
  "success": true,
  "data": { ... },
  "message": "...",
  "meta": { "total": 0, "pagina": 1, "limite": 20, "totalPaginas": 1 }
}
```

---

## 2. Roles relevantes para el módulo de asistencia

| Rol | Código | Qué puede hacer en asistencia |
|-----|--------|-------------------------------|
| Rector | `RECTOR` | Ver todos los registros, finalizar, ver todos los informes |
| Coordinador | `COORDINADOR` | Ver todos los registros, finalizar, ver todos los informes |
| Docente | `DOCENTE` | Crear registros de sus cursos, actualizar, finalizar, ver informes |
| Estudiante | `ESTUDIANTE` | Ver su propia asistencia (historial personal) |
| Acudiente/Padre | `ACUDIENTE` | Ver asistencia de sus hijos asociados |

El usuario autenticado llega en el JWT con campos: `_id`, `tipo`, `escuelaId`.

---

## 3. Modelos de datos

### 3.1 Registro de Asistencia (`Asistencia`)

```typescript
{
  _id: string,
  fecha: string,              // ISO 8601: "2026-05-28T00:00:00.000Z"
  cursoId: {                  // populado
    _id: string,
    nombre: string,
    grado: string,
    grupo: string,
    nivel: string
  },
  asignaturaId: {             // populado
    _id: string,
    nombre: string
  },
  docenteId: {                // populado — quien CREÓ el registro
    _id: string,
    nombre: string,
    apellidos: string
  },
  escuelaId: string,
  tipoSesion: "CLASE" | "TALLER" | "EVALUACION",
  horaInicio: string,         // "08:00"
  horaFin: string,            // "09:00"
  estudiantes: [              // array de entradas por estudiante
    {
      _id: string,
      estudianteId: {
        _id: string,
        nombre: string,
        apellidos: string
      },
      estado: "PRESENTE" | "AUSENTE" | "TARDANZA" | "JUSTIFICADO" | "PERMISO",
      justificacion: string,
      observaciones: string,
      registradoPor: string,
      fechaRegistro: string
    }
  ],
  finalizado: boolean,        // true = no se puede editar más
  createdAt: string,
  updatedAt: string
}
```

### 3.2 Alerta de Asistencia (`AlertaAsistencia`)

```typescript
{
  _id: string,
  estudianteId: {
    _id: string,
    nombre: string,
    apellidos: string
  },
  cursoId: {
    _id: string,
    nombre: string
  },
  escuelaId: string,
  nivel: "ALERTA" | "CRITICO" | "INMINENTE",
  porcentajeAusencias: number,   // ej: 35.5
  periodoId: string,             // ID del período académico activo
  notificadosIds: string[],      // IDs de usuarios notificados
  fechaEnvio: string
}
```

---

## 4. Reglas de negocio críticas

### 4.1 Estados de asistencia

| Estado | Cuenta como ausencia | Descripción |
|--------|---------------------|-------------|
| `PRESENTE` | No | Asistió |
| `AUSENTE` | **SÍ** | No asistió sin justificación |
| `TARDANZA` | No | Llegó tarde pero asistió |
| `JUSTIFICADO` | No | Ausencia justificada con excusa aprobada |
| `PERMISO` | No | Permiso anticipado autorizado |

**Solo `AUSENTE` cuenta para el cálculo de porcentaje de ausencias y para disparar alertas.**

### 4.2 Flujo de un registro de asistencia

```
1. DOCENTE crea el registro (POST /api/asistencia)
   → El backend inicializa TODOS los estudiantes del curso como PRESENTE
   
2. DOCENTE actualiza los estados individuales (PUT /api/asistencia/:id)
   → Cambia PRESENTE → AUSENTE / TARDANZA / etc. según corresponda
   
3. DOCENTE o RECTOR/COORDINADOR finaliza el registro (PATCH /api/asistencia/:id/finalizar)
   → finalizado = true → ya no se puede editar
   → TRIGGER AUTOMÁTICO: el backend evalúa si algún estudiante cruzó
     un umbral de ausencias y envía alertas automáticas
```

### 4.3 Reglas de negocio del trigger de alertas

- **ALERTA:** estudiante tiene ≥ 15% de ausencias en el período activo
- **CRÍTICO:** estudiante tiene ≥ 25% de ausencias en el período activo
- **INMINENTE:** estudiante tiene ≥ 30% de ausencias (umbral legal de reprobación en Colombia)
- **Deduplicación:** cada combinación `{estudianteId, nivel, periodoId}` se genera UNA SOLA VEZ por período — si la alerta ya existe, se omite silenciosamente
- **Destinatarios de la alerta:** rector + coordinador + docente del registro
- **Cálculo:** `porcentajeAusencias = diasAusente / totalClases × 100`
  - `diasAusente` = número de registros finalizados donde ese estudiante tiene estado `AUSENTE`
  - `totalClases` = total de registros finalizados donde ese estudiante aparece

### 4.4 Canales de notificación al dispararse una alerta

1. **Canal 1 — Notificación interna (campanita):** aparece en el ícono de notificaciones de la app
2. **Canal 2 — Mensaje en bandeja de recibidos:** un mensaje de "Sistema EducaNexo360" llega a la bandeja del rector, coordinador y docente
3. **Canal 3 — Email:** se envía un correo electrónico a cada destinatario
4. **Canal 4 — FCM Push (pendiente):** está comentado en el backend, listo para activar cuando Flutter integre Firebase Cloud Messaging

### 4.5 Períodos académicos

El backend deriva el `periodoId` automáticamente buscando el período cuya `fecha_inicio <= hoy <= fecha_fin` en `Escuela.periodos_academicos[]`. Si no hay período activo, usa `'sin-periodo'`.

---

## 5. API Endpoints — Asistencia

**Base:** `GET|POST|PUT|PATCH /api/asistencia`

### 5.1 Listar registros de asistencia
```
GET /api/asistencia

Query params (todos opcionales):
  cursoId       string   — filtrar por curso
  estudianteId  string   — filtrar por estudiante
  fecha         string   — filtrar por fecha exacta (YYYY-MM-DD)
  desde         string   — rango inicio
  hasta         string   — rango fin
  pagina        number   — default 1
  limite        number   — default 20

Respuesta:
{
  "success": true,
  "data": [ ...Asistencia[] ],   // array de registros
  "meta": { total, pagina, limite, totalPaginas }
}
```

**Permisos:**
- DOCENTE: solo ve registros de sus cursos asignados
- RECTOR/COORDINADOR: ve todos los registros de la escuela
- ESTUDIANTE: solo sus propios registros
- ACUDIENTE: registros de sus hijos asociados

### 5.2 Obtener un registro
```
GET /api/asistencia/:id

Respuesta: { "success": true, "data": Asistencia }
```

### 5.3 Crear registro de asistencia
```
POST /api/asistencia

Body (JSON):
{
  "cursoId": "string",          // requerido
  "fecha": "YYYY-MM-DD",        // requerido
  "asignaturaId": "string",     // requerido
  "tipoSesion": "CLASE"         // opcional, default CLASE
}

Respuesta: { "success": true, "data": Asistencia }
```

**Importante:** el backend automáticamente inicializa TODOS los estudiantes del curso como `PRESENTE`. El docente luego actualiza solo los que cambien de estado.

**Restricción:** solo se puede crear UN registro por `{fecha, cursoId, asignaturaId}`. Si ya existe, retorna error 400.

### 5.4 Actualizar estados de estudiantes
```
PUT /api/asistencia/:id

Body (JSON):
{
  "estudiantes": [
    {
      "estudianteId": "string",
      "estado": "AUSENTE" | "PRESENTE" | "TARDANZA" | "JUSTIFICADO" | "PERMISO",
      "justificacion": "string",    // opcional
      "observaciones": "string"     // opcional
    }
  ]
}

Respuesta: { "success": true, "data": Asistencia actualizada }
```

**Restricción:** solo funciona si `finalizado = false`.

### 5.5 Finalizar registro (dispara alertas automáticas)
```
PATCH /api/asistencia/:id/finalizar

Sin body.

Respuesta: { "success": true, "message": "Registro de asistencia finalizado exitosamente" }
```

**Importante:** este endpoint es el único que dispara el trigger de alertas automáticas. El trigger corre en background (no bloquea la respuesta).

### 5.6 Estadísticas de un estudiante
```
GET /api/asistencia/estadisticas/estudiante/:estudianteId

Query params opcionales:
  desde    string   YYYY-MM-DD
  hasta    string   YYYY-MM-DD
  cursoId  string

Respuesta:
{
  "success": true,
  "data": {
    "totalClases": number,
    "presentes": number,
    "ausentes": number,
    "tardanzas": number,
    "justificados": number,
    "permisos": number,
    "porcentajeAsistencia": number   // 0-100
  }
}
```

---

## 6. API Endpoints — Informes de Asistencia

**Base:** `GET /api/asistencia/informes/...`

### 6.1 Informe de Riesgo
```
GET /api/asistencia/informes/riesgo

Query params:
  umbral    number   — porcentaje de ausencias mínimo (default 15)
  cursoId   string   — opcional, filtra por curso
  desde     string   — YYYY-MM-DD
  hasta     string   — YYYY-MM-DD

Respuesta:
{
  "ok": true,
  "umbral": 15,
  "total": number,
  "criticos": number,
  "alertas": number,
  "estudiantes": [
    {
      "estudianteId": string,
      "nombre": string,
      "apellidos": string,
      "curso": { _id, nombre, grado, grupo },
      "clasesTotales": number,
      "ausencias": number,
      "tardanzas": number,
      "porcentajeAsistencia": number,
      "nivelRiesgo": "CRITICO" | "ALERTA"
    }
  ]
}
```

### 6.2 Historial de un estudiante
```
GET /api/asistencia/informes/historial/:estudianteId

Query params:
  desde    string   YYYY-MM-DD  (requerido)
  hasta    string   YYYY-MM-DD  (requerido)

Respuesta:
{
  "ok": true,
  "estudiante": { _id, nombre, apellidos, email },
  "resumen": {
    "clasesTotales": number,
    "presentes": number,
    "ausentes": number,
    "tardanzas": number,
    "justificados": number,
    "permisos": number,
    "porcentajeAsistencia": number
  },
  "registros": [
    {
      "fecha": string,
      "diaSemana": string,
      "curso": { _id, nombre, grado, grupo },
      "asignatura": { _id, nombre } | null,
      "estado": "PRESENTE" | "AUSENTE" | "TARDANZA" | "JUSTIFICADO" | "PERMISO",
      "justificacion": string,
      "observaciones": string,
      "registradoPor": { _id, nombre, apellidos }
    }
  ]
}
```

### 6.3 Tendencia de asistencia
```
GET /api/asistencia/informes/tendencia

Query params:
  desde        string   YYYY-MM-DD  (requerido)
  hasta        string   YYYY-MM-DD  (requerido)
  agrupacion   "semana" | "mes"     (default semana)
  cursoId      string               (opcional)

Respuesta:
{
  "ok": true,
  "agrupacion": string,
  "puntos": number,
  "tendencia": [
    {
      "periodo": string,
      "fechaInicio": string,
      "totalClases": number,
      "totalEstudiantes": number,
      "presentes": number,
      "ausentes": number,
      "tardanzas": number,
      "porcentajeAsistencia": number
    }
  ]
}
```

### 6.4 Ranking de cursos por asistencia
```
GET /api/asistencia/informes/ranking-cursos

Query params:
  desde    string   YYYY-MM-DD  (requerido)
  hasta    string   YYYY-MM-DD  (requerido)

Respuesta:
{
  "ok": true,
  "total": number,
  "ranking": [
    {
      "posicion": number,
      "cursoId": string,
      "nombre": string,
      "grado": string,
      "grupo": string,
      "totalClases": number,
      "totalEstudiantes": number,
      "presentes": number,
      "ausentes": number,
      "tardanzas": number,
      "porcentajeAsistencia": number
    }
  ]
}
```

### 6.5 Patrón de ausencias por día de la semana
```
GET /api/asistencia/informes/patron-dias

Query params:
  desde     string   YYYY-MM-DD  (requerido)
  hasta     string   YYYY-MM-DD  (requerido)
  cursoId   string               (opcional)

Respuesta:
{
  "ok": true,
  "dias": [
    {
      "diaSemana": number,        // 1=Lunes, 5=Viernes
      "nombreDia": string,
      "totalClases": number,
      "totalEstudiantes": number,
      "ausencias": number,
      "tardanzas": number,
      "porcentajeAusentismo": number
    }
  ]
}
```

### 6.6 Resumen por período (cierre)
```
GET /api/asistencia/resumen/periodo/:periodoId

Query params:
  cursoId   string   (requerido)

Respuesta:
{
  "success": true,
  "data": {
    "estudiantes": [
      {
        "estudianteId": string,
        "nombreEstudiante": string,
        "clasesTotales": number,
        "presentes": number,
        "ausentes": number,
        "tardanzas": number,
        "justificados": number,
        "permisos": number,
        "porcentajeAsistencia": number
      }
    ]
  }
}
```

---

## 7. API Endpoints — Alertas de Asistencia

```
GET /api/asistencia/alertas

Query params (todos opcionales):
  cursoId       string
  estudianteId  string
  nivel         "ALERTA" | "CRITICO" | "INMINENTE"
  periodoId     string

Respuesta:
{
  "success": true,
  "data": [
    {
      "_id": string,
      "estudianteId": { _id, nombre, apellidos },
      "cursoId": { _id, nombre },
      "escuelaId": string,
      "nivel": "ALERTA" | "CRITICO" | "INMINENTE",
      "porcentajeAusencias": number,
      "periodoId": string,
      "notificadosIds": string[],
      "fechaEnvio": string
    }
  ]
}
```

---

## 8. API Endpoints — Cursos (necesarios para asistencia)

```
GET /api/cursos
  → Lista cursos (docente ve solo sus cursos asignados)

GET /api/cursos/:id/estudiantes
  → Lista estudiantes de un curso específico
  → Respuesta: { success, data: { estudiantes: [{ _id, nombre, apellidos, email }] } }
```

---

## 9. Mensajes automáticos de alerta en la bandeja

Cuando se dispara una alerta, el sistema crea automáticamente un mensaje en la bandeja de recibidos del rector, coordinador y docente. Estos mensajes llegan al endpoint normal de mensajería.

**Estructura del mensaje de alerta:**
```
remitente.nombre:    "Sistema"
remitente.apellidos: "EducaNexo360"
remitente.email:     "sistema@educanexo360.com"
remitente.tipo:      "SUPER_ADMIN"

asunto (por nivel):
  ALERTA    → "⚠️ Alerta ALERTA — [nombre estudiante]"
  CRITICO   → "🔴 Alerta CRITICO — [nombre estudiante]"
  INMINENTE → "🚨 Alerta INMINENTE — [nombre estudiante]"

contenido: HTML string con:
  <p>El estudiante <strong>[nombre]</strong> del curso <strong>[curso]</strong> ha [descripción].</p>
  <p><strong>Porcentaje actual de ausencias:</strong> X.X%<br><strong>Umbral superado:</strong> X%</p>
  <p>Por favor revise el módulo <strong>Asistencia → Informes → Riesgo</strong> para más detalles.</p>
```

**Para Flutter:** el campo `contenido` es HTML. Usar paquete `flutter_html` o `flutter_widget_from_html` para renderizarlo. Para identificar mensajes del sistema: `remitente.email === 'sistema@educanexo360.com'`.

---

## 10. Flujos de usuario por rol — Lo que Flutter debe implementar

### 10.1 DOCENTE — Registrar asistencia desde el salón de clases

**Flujo principal:**
1. Docente abre la app en clase
2. Selecciona el curso y la asignatura del momento
3. La app crea el registro (`POST /api/asistencia`) — el backend inicializa todos como PRESENTE
4. La app muestra la lista de estudiantes del curso con estado PRESENTE por defecto
5. El docente toca a cada estudiante ausente/tardanza para cambiar su estado (UI rápida, tipo checkbox o swipe)
6. La app actualiza con `PUT /api/asistencia/:id` según el docente va marcando
7. Al terminar la clase, el docente presiona "Finalizar" (`PATCH /api/asistencia/:id/finalizar`)
8. El backend dispara las alertas automáticas en background

**Consideraciones UX:**
- La pantalla de toma de asistencia debe ser extremadamente rápida — el docente tiene todo el curso frente a él
- Un toque = AUSENTE, dos toques = TARDANZA, tres toques = vuelve a PRESENTE (ciclo)
- O botones de estado por estudiante (PRESENTE / AUSENTE / TARDANZA)
- Mostrar foto del estudiante si está disponible
- Mostrar contador: "X presentes, Y ausentes, Z tardanzas"
- Al intentar finalizar, mostrar resumen antes de confirmar
- Si ya existe un registro para ese día/curso/asignatura, mostrar el existente para editar (no crear duplicado)

**Pantallas necesarias:**
- Lista de cursos asignados al docente (para seleccionar)
- Lista de asignaturas del curso (para seleccionar)
- Pantalla de toma de asistencia (lista de estudiantes + estados)
- Confirmación de finalización
- Historial de registros anteriores del docente

### 10.2 ESTUDIANTE — Ver su propia asistencia

**Pantallas necesarias:**
- Resumen de asistencia del período actual: % de asistencia, número de ausencias, tardanzas
- Historial de registros: lista cronológica de cada clase con su estado (PRESENTE/AUSENTE/etc.)
- Indicador visual de alerta si su porcentaje supera el umbral (≥15% ausencias)

**Endpoints a usar:**
- `GET /api/asistencia/estadisticas/estudiante/:id` — resumen numérico
- `GET /api/asistencia/informes/historial/:id?desde=&hasta=` — historial detallado
- `GET /api/asistencia/alertas?estudianteId=:id` — verificar si tiene alertas activas

### 10.3 ACUDIENTE/PADRE — Ver asistencia de sus hijos

**Consideraciones:** un acudiente puede tener múltiples hijos asociados. Primero selecciona el hijo, luego ve su asistencia.

**Para obtener los hijos asociados:** `GET /api/usuarios/:id/estudiantes-asociados`

**Pantallas necesarias:**
- Selector de hijo (si tiene más de uno)
- Resumen de asistencia del hijo en el período actual
- Historial de asistencia (con colores por estado)
- Alertas activas del hijo (chips con nivel ALERTA/CRITICO/INMINENTE)
- Notificación push cuando se genera una alerta (Canal 4 FCM — pendiente de activar)

**Endpoints a usar:**
- `GET /api/usuarios/:id/estudiantes-asociados` — obtener hijos
- `GET /api/asistencia/estadisticas/estudiante/:hijoId` — resumen
- `GET /api/asistencia/informes/historial/:hijoId?desde=&hasta=` — historial
- `GET /api/asistencia/alertas?estudianteId=:hijoId` — alertas del hijo

### 10.4 RECTOR / COORDINADOR — Supervisión en la app

**Pantallas necesarias:**
- Lista de cursos con porcentaje de asistencia del día/semana
- Estudiantes en riesgo (los con ≥15% ausencias)
- Poder ver el detalle de cualquier estudiante
- Recibir mensajes automáticos de alerta en la bandeja

---

## 11. Notificaciones push — Canal 4 FCM

### Estado actual
El backend tiene el Canal 4 **comentado** y listo para activar en `src/services/alertaAsistencia.service.ts`. El modelo `Usuario` ya tiene los campos `fcmToken` y `fcmTokenUpdatedAt`.

### Lo que Flutter necesita implementar
1. **Integrar Firebase Cloud Messaging** en el proyecto Flutter
2. **Al iniciar sesión:** obtener el FCM token del dispositivo y enviarlo al backend:
   ```
   PUT /api/usuarios/:id
   Body: { "fcmToken": "<token_fcm_del_dispositivo>" }
   ```
3. **Manejar notificaciones entrantes:** mostrar la notificación en la bandeja del sistema con el asunto y el nivel de la alerta

### Lo que el backend activa (una línea de cambio)
Cuando Flutter tenga FCM funcionando, el backend solo descomenta el Canal 4 en `alertaAsistencia.service.ts`. Los datos del payload de la notificación incluirán: `nivel`, `estudianteNombre`, `porcentajeAusencias`.

---

## 12. Consideraciones técnicas para Flutter

### Autenticación
- Login: `POST /api/auth/login` → guarda `token` y `refreshToken` en almacenamiento seguro (`flutter_secure_storage`)
- Refresh: `POST /api/auth/refresh-token` → renovar cuando el access token expire (duración: 1 día)
- Logout: `POST /api/auth/logout` + limpiar storage

### Manejo de fechas
- El backend usa UTC. Convertir siempre a hora local Colombia (UTC-5) para mostrar al usuario
- Formato de envío al backend: `YYYY-MM-DD` para fechas, ISO 8601 para datetimes

### Paginación
- Todos los listados usan `?pagina=1&limite=20`
- La respuesta incluye `meta.totalPaginas` para implementar infinite scroll o paginación

### Contenido HTML
- El campo `contenido` de los mensajes de alerta es HTML
- Paquete recomendado: `flutter_html` (pub.dev)
- DOMPurify se aplica en el backend — el HTML que llega ya está sanitizado

### Permisos según rol
- Verificar `user.tipo` del token para mostrar/ocultar funciones
- DOCENTE ve solo sus cursos (`info_academica.cursos[]`)
- ACUDIENTE opera sobre `info_academica.estudiantes_asociados[]`

### Estados visuales recomendados para la asistencia

| Estado | Color sugerido | Ícono |
|--------|---------------|-------|
| PRESENTE | Verde `#10B981` | ✓ check |
| AUSENTE | Rojo `#EF4444` | ✗ close |
| TARDANZA | Naranja `#F59E0B` | ⏱ clock |
| JUSTIFICADO | Azul `#3B82F6` | 📄 document |
| PERMISO | Morado `#8B5CF6` | 📋 clipboard |

### Niveles de alerta visuales

| Nivel | Color | Descripción |
|-------|-------|-------------|
| ALERTA | Naranja `#F59E0B` | ≥ 15% ausencias |
| CRITICO | Rojo `#EF4444` | ≥ 25% ausencias |
| INMINENTE | Rojo oscuro `#7F1D1D` | ≥ 30% — riesgo de reprobación legal |

---

## 13. Lo que NO existe aún y Flutter NO debe implementar todavía

- **Excusas digitales:** el padre sube una excusa para justificar una ausencia. El backend aún no existe — se construirá en el web primero.
- **Calificaciones completas:** el modelo existe pero la UI web no está terminada — esperar a que el web lo construya.
- **Boletines:** ídem.
- **Observador del estudiante:** no existe en web ni en backend — pendiente de diseño.

---

## 14. Resumen de endpoints por pantalla Flutter

| Pantalla | Método | Endpoint |
|---------|--------|----------|
| Lista de cursos del docente | GET | `/api/cursos` |
| Estudiantes de un curso | GET | `/api/cursos/:id/estudiantes` |
| Crear registro de asistencia | POST | `/api/asistencia` |
| Actualizar estados de estudiantes | PUT | `/api/asistencia/:id` |
| Finalizar registro | PATCH | `/api/asistencia/:id/finalizar` |
| Listar registros (historial docente) | GET | `/api/asistencia?cursoId=&desde=&hasta=` |
| Ver registro específico | GET | `/api/asistencia/:id` |
| Estadísticas de un estudiante | GET | `/api/asistencia/estadisticas/estudiante/:id` |
| Historial de asistencia (estudiante/padre) | GET | `/api/asistencia/informes/historial/:id?desde=&hasta=` |
| Alertas activas de un estudiante | GET | `/api/asistencia/alertas?estudianteId=:id` |
| Estudiantes en riesgo (rector/coord) | GET | `/api/asistencia/informes/riesgo?umbral=15` |
| Hijos de un acudiente | GET | `/api/usuarios/:id/estudiantes-asociados` |
| Actualizar FCM token | PUT | `/api/usuarios/:id` (body: `{ fcmToken }`) |
