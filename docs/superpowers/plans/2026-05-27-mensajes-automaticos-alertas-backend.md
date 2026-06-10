# Mensajes Automáticos en Bandeja — Alertas de Asistencia (Backend)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar Canal 2 en `enviarNotificacionesAlerta`: cada alerta de asistencia crea un Mensaje persistente en la bandeja de recibidos de cada destinatario, usando un usuario global "Sistema EducaNexo360" como remitente.

**Architecture:** Se agrega un helper `obtenerOCrearUsuarioSistema()` (patrón findOrCreate, idempotente) y un helper `generarCuerpoMensaje()`. Ambos se usan dentro de `enviarNotificacionesAlerta` en el orden: Canal 1 (campanita) → Canal 2 (mensaje bandeja, NUEVO) → Canal 3 (email). Un solo archivo modificado: `src/services/alertaAsistencia.service.ts`.

**Tech Stack:** Node.js, Express, TypeScript, MongoDB/Mongoose, bcrypt, crypto (built-in Node.js)

---

## Archivos involucrados

| Archivo | Acción |
|---------|--------|
| `src/services/alertaAsistencia.service.ts` | **Modificar** — agregar helpers + Canal 2 |
| `src/models/mensaje.model.ts` | **Solo lectura** — verificar nombres de campos |
| `src/interfaces/IMensaje.ts` | **Solo lectura** — verificar tipos |

---

## Task 1: Verificar estructura del modelo Mensaje

**Files:**
- Read: `src/models/mensaje.model.ts`
- Read: `src/interfaces/IMensaje.ts`

- [ ] **Step 1: Leer el modelo Mensaje**

```bash
cat src/models/mensaje.model.ts
```

Registrar los nombres exactos de estos campos en el schema (pueden diferir del nombre esperado):
- **Remitente:** probablemente `remitenteId`
- **Destinatario:** probablemente `destinatarioId` (campo singular, no array)
- **Asunto:** probablemente `asunto`
- **Cuerpo/contenido:** probablemente `cuerpo` o `contenido`
- **Estado leído:** probablemente `leido` (Boolean)
- **escuelaId:** verificar si es requerido o tiene default

- [ ] **Step 2: Leer la interfaz IMensaje**

```bash
cat src/interfaces/IMensaje.ts
```

Confirmar que los tipos coinciden con lo que se va a usar en `Mensaje.create({...})`.

- [ ] **Step 3: Anotar los nombres reales**

Guardar mentalmente (o en comentario temporal) los nombres exactos de campos. Estos se usan en Task 3.

---

## Task 2: Agregar imports en alertaAsistencia.service.ts

**Files:**
- Modify: `src/services/alertaAsistencia.service.ts`

- [ ] **Step 1: Revisar imports actuales del archivo**

```bash
head -30 src/services/alertaAsistencia.service.ts
```

Verificar qué ya está importado:
- `bcrypt` — si no está, hay que agregarlo
- El modelo `Mensaje` — hay que agregarlo
- `Usuario` — ya debería estar importado
- `IUsuarioDocument` o el tipo del documento Usuario

- [ ] **Step 2: Agregar import de Mensaje al inicio del archivo**

Agregar junto a los otros imports de modelos (verificar el path y si el export es default o named):

```typescript
import Mensaje from '../models/mensaje.model';
```

> Si el modelo exporta como named export (`export { Mensaje }`), usar:
> ```typescript
> import { Mensaje } from '../models/mensaje.model';
> ```
> Adaptar según lo que muestre Task 1 Step 1.

- [ ] **Step 3: Agregar import de bcrypt si no existe**

Buscar si `bcrypt` ya está importado:

```bash
grep -n "bcrypt" src/services/alertaAsistencia.service.ts
```

Si no aparece, agregar al inicio del archivo junto a los otros imports:

```typescript
import bcrypt from 'bcrypt';
```

- [ ] **Step 4: Verificar typecheck pasa**

```bash
npx tsc --noEmit
```

Expected: sin errores. Si hay error de tipos por `Mensaje`, verificar el path del import.

---

## Task 3: Agregar helpers obtenerOCrearUsuarioSistema y generarCuerpoMensaje

**Files:**
- Modify: `src/services/alertaAsistencia.service.ts`

- [ ] **Step 1: Agregar helper generarCuerpoMensaje**

Agregar esta función en `alertaAsistencia.service.ts`, antes de `enviarNotificacionesAlerta` (o al final del archivo, antes del export si aplica):

```typescript
function generarCuerpoMensaje(
  nivel: 'ALERTA' | 'CRITICO' | 'INMINENTE',
  nombreEstudiante: string,
  nombreCurso: string,
  porcentajeAusencias: number
): string {
  const umbralPorNivel: Record<string, string> = {
    ALERTA: '15%',
    CRITICO: '25%',
    INMINENTE: '30%',
  };
  return (
    `Estudiante: ${nombreEstudiante}\n` +
    `Curso: ${nombreCurso}\n` +
    `Porcentaje de ausencias: ${porcentajeAusencias.toFixed(1)}%\n` +
    `Umbral superado: ${umbralPorNivel[nivel]}\n\n` +
    `Revise el detalle en: Asistencia → Informes → Riesgo.`
  );
}
```

- [ ] **Step 2: Agregar helper obtenerOCrearUsuarioSistema**

Agregar esta función en el mismo archivo, después de `generarCuerpoMensaje`:

```typescript
async function obtenerOCrearUsuarioSistema(): Promise<IUsuarioDocument> {
  const EMAIL_SISTEMA = 'sistema@educanexo360.com';
  let sistema = await Usuario.findOne({ email: EMAIL_SISTEMA });
  if (!sistema) {
    sistema = await Usuario.create({
      nombre: 'Sistema',
      apellidos: 'EducaNexo360',
      email: EMAIL_SISTEMA,
      password: await bcrypt.hash(crypto.randomUUID(), 10),
      tipo: 'ADMIN',
      estado: 'ACTIVO',
      escuelaId: null,
    });
  }
  return sistema;
}
```

> `crypto.randomUUID()` está disponible nativamente en Node.js 14.17+. No requiere import adicional.
> `IUsuarioDocument` es el tipo del documento devuelto por el modelo Usuario — verificar el nombre exacto en `src/interfaces/IUsuario.ts` si TypeScript se queja; puede ser `IUsuario & Document` o similar.

- [ ] **Step 3: Verificar typecheck pasa**

```bash
npx tsc --noEmit
```

Expected: sin errores nuevos. Si hay error en `IUsuarioDocument`, ajustar el tipo de retorno a lo que exporte `src/interfaces/IUsuario.ts`.

- [ ] **Step 4: Commit intermedio**

```bash
git add src/services/alertaAsistencia.service.ts
git commit -m "feat: agregar helpers Sistema y generarCuerpoMensaje para mensajes automáticos de alertas"
```

---

## Task 4: Agregar Canal 2 en enviarNotificacionesAlerta

**Files:**
- Modify: `src/services/alertaAsistencia.service.ts`

- [ ] **Step 1: Localizar la función enviarNotificacionesAlerta**

```bash
grep -n "enviarNotificacionesAlerta\|Canal 1\|Canal 3\|Notificacion.create\|Canal 2" src/services/alertaAsistencia.service.ts
```

Identificar:
- Línea donde termina el bloque de Canal 1 (Notificacion.create)
- Línea donde comienza el bloque de Canal 3 (email)
- Los nombres de las variables disponibles: `estudiante`, `curso`, `nivel`, `porcentajeAusencias`, `destinatariosIds`

- [ ] **Step 2: Agregar Canal 2 entre Canal 1 y Canal 3**

El bloque de Canal 2 va **después** del cierre de Canal 1 y **antes** del comienzo de Canal 3. Insertar exactamente:

```typescript
    // Canal 2: Mensaje en bandeja (sistema de mensajería existente)
    try {
      const prefijo: Record<string, string> = {
        ALERTA: '⚠️',
        CRITICO: '🔴',
        INMINENTE: '🚨',
      };
      const sistemaUser = await obtenerOCrearUsuarioSistema();
      const nombreEstudiante = `${estudiante.nombre} ${estudiante.apellidos}`;
      const nombreCurso = curso.nombre;

      await Promise.all(
        destinatariosIds.map((destinatarioId) =>
          Mensaje.create({
            remitenteId: sistemaUser._id,
            destinatarioId,                    // ← ajustar si el campo tiene otro nombre (ver Task 1)
            asunto: `${prefijo[nivel]} Alerta ${nivel} — ${nombreEstudiante}`,
            cuerpo: generarCuerpoMensaje(nivel, nombreEstudiante, nombreCurso, porcentajeAusencias),
            leido: false,
          })
        )
      );
    } catch (errCanal2) {
      console.error('[AlertaAsistencia] Error en Canal 2 (mensaje bandeja):', errCanal2);
    }
```

> **Campos del Mensaje.create:** Si en Task 1 verificaste que el campo se llama diferente (ej: `contenido` en vez de `cuerpo`, o `receptorId` en vez de `destinatarioId`), usar el nombre real del campo.

> **Si el modelo Mensaje requiere `escuelaId`:** Agregar `escuelaId: estudiante.escuelaId` (o la variable que contenga el ID de escuela en el scope) dentro del `Mensaje.create({...})`.

- [ ] **Step 3: Verificar typecheck pasa**

```bash
npx tsc --noEmit
```

Expected: sin errores. Si hay error de tipos en `Mensaje.create`, verificar que los campos coincidan con la interfaz IMensaje verificada en Task 1.

---

## Task 5: Prueba manual end-to-end

**Files:** ninguno — solo prueba con API

- [ ] **Step 1: Asegurarse de que el backend está corriendo**

```bash
npm run dev
```

Expected: servidor escuchando (ej: `Server running on port 3000`).

- [ ] **Step 2: Obtener token de acceso**

```bash
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"rector.cdrc@demo.com","password":"Demo2026*"}' | jq .
```

Expected: respuesta con campo `token`. Guardar el token en variable:

```bash
TOKEN="<pegar el token aquí>"
```

- [ ] **Step 3: Crear un registro de asistencia con ausencias suficientes**

Usar un curso con estudiante que tenga ≥ 15% de ausencias en el período. Si ya hay alertas previas para ese estudiante y nivel, el índice único las rechazará silenciosamente — usar un estudiante diferente o un nivel diferente.

```bash
# Reemplazar cursoId, estudianteId, asignaturaId con valores reales del seed
curl -s -X POST http://localhost:3000/api/asistencia \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "cursoId": "<cursoId>",
    "fecha": "2026-05-27",
    "asignaturaId": "<asignaturaId>",
    "registros": [
      {"estudianteId": "<estudianteId>", "estado": "AUSENTE"}
    ]
  }' | jq .asistenciaId
```

Guardar el `asistenciaId` devuelto.

- [ ] **Step 4: Finalizar el registro (trigger de alertas)**

```bash
ASISTENCIA_ID="<pegar el id devuelto en Step 3>"

curl -s -X PATCH http://localhost:3000/api/asistencia/$ASISTENCIA_ID/finalizar \
  -H "Authorization: Bearer $TOKEN" | jq .
```

Expected: respuesta `{ ok: true, ... }`. El trigger de alertas corre en background (setImmediate).

- [ ] **Step 5: Verificar que el Mensaje fue creado en la bandeja**

Esperar 2-3 segundos y luego consultar la bandeja del rector:

```bash
curl -s "http://localhost:3000/api/mensajes?bandeja=recibidos" \
  -H "Authorization: Bearer $TOKEN" | jq '.data.mensajes[0]'
```

Expected: el primer mensaje debe tener:
- `asunto` con el emoji y el nivel de alerta
- `remitenteId` o campo remitente apuntando al usuario "Sistema EducaNexo360"
- `leido: false`

- [ ] **Step 6: Verificar que el usuario Sistema existe en la BD**

```bash
curl -s "http://localhost:3000/api/usuarios?email=sistema@educanexo360.com" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

O verificar directamente en MongoDB Compass buscando `{ email: 'sistema@educanexo360.com' }` en la colección `usuarios`.

Expected: un usuario con `nombre: 'Sistema'`, `apellidos: 'EducaNexo360'`, `escuelaId: null`.

---

## Task 6: Limpieza y commit final

**Files:**
- Modify: `src/services/alertaAsistencia.service.ts`

- [ ] **Step 1: Eliminar logs de debug si aún existen**

Buscar y eliminar cualquier línea con `[AlertaAsistencia DEBUG]` que se haya agregado durante el debugging previo:

```bash
grep -n "AlertaAsistencia DEBUG" src/services/alertaAsistencia.service.ts
```

Si aparece alguna línea, eliminarla.

- [ ] **Step 2: Typecheck final**

```bash
npx tsc --noEmit
```

Expected: cero errores.

- [ ] **Step 3: Commit final**

```bash
git add src/services/alertaAsistencia.service.ts
git commit -m "feat: agregar Canal 2 en alertas de asistencia — mensaje automático en bandeja de recibidos vía usuario Sistema EducaNexo360"
```

---

## Notas importantes

**Deduplicación:** El Canal 2 no tiene deduplicación propia. Si el mismo trigger se dispara múltiples veces (poco probable dado el índice único en `AlertaAsistencia`), se crearían mensajes duplicados. Esto es aceptable — el índice único en la colección `alertaAsistencia` garantiza que el trigger solo corre una vez por nivel/período/estudiante.

**Usuario Sistema y filtros:** El usuario `sistema@educanexo360.com` tiene `escuelaId: null`. El endpoint `GET /api/usuarios` NO debe devolver este usuario. Verificar que el query de ese endpoint filtra por `escuelaId: { $ne: null }` o por email diferente a `'sistema@educanexo360.com'`. Si no está filtrado, revisar `src/controllers/usuario.controller.ts` y agregar el filtro (tarea separada, solo si se confirma que aparece en listados).

**Orden de canales (final):**
```
Canal 1: Notificación interna (campanita)   ← ya existe, sin cambios
Canal 2: Mensaje en bandeja                  ← NUEVO (esta tarea)
Canal 3: Email (Nodemailer)                  ← ya existe, sin cambios
Canal 4: Push FCM                            ← comentado, futuro
```
