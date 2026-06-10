# Alertas Automáticas de Asistencia — Plan Backend

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cuando un estudiante supera umbrales de ausentismo (15%/25%/30%), el backend genera alertas automáticas con notificación interna + email a rector, coordinador y docente, con deduplicación por período académico.

**Architecture:** Nuevo modelo `AlertaAsistencia` con índice único compuesto `(estudianteId, nivel, periodoId)` que garantiza deduplicación en BD. Trigger asíncrono (fire-and-forget) en los handlers de creación y finalización de asistencia. Función `enviarNotificacionesAlerta` canal-agnóstica preparada para FCM futuro.

**Tech Stack:** Node.js + Express + TypeScript + MongoDB/Mongoose + Nodemailer (ya configurado)

**Spec de referencia:** `docs/superpowers/specs/2026-05-25-alertas-automaticas-asistencia-design.md` (en el proyecto React, para consulta)

---

## Paso previo: Verificar estructura del modelo Asistencia

Antes de empezar, abrir `src/interfaces/IAsistencia.ts` y `src/models/asistencia.model.ts`.

Determinar cuál de estas dos estructuras usa el proyecto:

**Estructura A** — Un documento por clase por día, con array de estudiantes:
```typescript
// asistencias: [{ estudianteId, estado }]
```

**Estructura B** — Un documento por estudiante por día:
```typescript
// { estudianteId, cursoId, fecha, estado }
```

El Task 3 usa **Estructura A**. Si el proyecto usa Estructura B, adaptar la query en el paso 3.2 según la nota incluida allí.

---

## Task 1: Interface IAlertaAsistencia

**Files:**
- Create: `src/interfaces/IAlertaAsistencia.ts`

- [ ] **1.1 Crear la interface**

```typescript
// src/interfaces/IAlertaAsistencia.ts
import mongoose from 'mongoose';

export interface IAlertaAsistencia {
  estudianteId: mongoose.Types.ObjectId;
  cursoId: mongoose.Types.ObjectId;
  escuelaId: mongoose.Types.ObjectId;
  nivel: 'ALERTA' | 'CRITICO' | 'INMINENTE';
  porcentajeAusencias: number;
  periodoId: string;
  fechaEnvio: Date;
  notificadosIds: mongoose.Types.ObjectId[];
}
```

- [ ] **1.2 Commit**

```bash
git add src/interfaces/IAlertaAsistencia.ts
git commit -m "feat: agregar interface IAlertaAsistencia"
```

---

## Task 2: Modelo AlertaAsistencia

**Files:**
- Create: `src/models/alertaAsistencia.model.ts`

- [ ] **2.1 Crear el modelo con índice único compuesto**

```typescript
// src/models/alertaAsistencia.model.ts
import mongoose, { Schema, Document } from 'mongoose';
import { IAlertaAsistencia } from '../interfaces/IAlertaAsistencia';

export interface IAlertaAsistenciaDocument extends IAlertaAsistencia, Document {}

const AlertaAsistenciaSchema = new Schema<IAlertaAsistenciaDocument>(
  {
    estudianteId:        { type: Schema.Types.ObjectId, ref: 'Usuario', required: true },
    cursoId:             { type: Schema.Types.ObjectId, ref: 'Curso', required: true },
    escuelaId:           { type: Schema.Types.ObjectId, ref: 'Escuela', required: true },
    nivel:               { type: String, enum: ['ALERTA', 'CRITICO', 'INMINENTE'], required: true },
    porcentajeAusencias: { type: Number, required: true },
    periodoId:           { type: String, required: true },
    fechaEnvio:          { type: Date, default: Date.now },
    notificadosIds:      [{ type: Schema.Types.ObjectId, ref: 'Usuario' }],
  },
  { timestamps: true }
);

// Índice único compuesto — garantiza deduplicación en BD
// Un estudiante no puede tener dos alertas del mismo nivel en el mismo período
AlertaAsistenciaSchema.index(
  { estudianteId: 1, nivel: 1, periodoId: 1 },
  { unique: true }
);

export default mongoose.model<IAlertaAsistenciaDocument>(
  'AlertaAsistencia',
  AlertaAsistenciaSchema
);
```

- [ ] **2.2 Verificar que Mongoose registra el modelo**

Abrir `src/app.ts` (o el archivo principal donde se importan los modelos). Si los modelos se importan explícitamente, agregar:

```typescript
import './models/alertaAsistencia.model';
```

Si los modelos se cargan automáticamente por directorio, no es necesario.

- [ ] **2.3 Commit**

```bash
git add src/models/alertaAsistencia.model.ts src/app.ts
git commit -m "feat: agregar modelo AlertaAsistencia con índice único compuesto"
```

---

## Task 3: Función triggerAlertasAsistencia

**Files:**
- Modify: `src/services/asistenciaService.ts` (agregar al final del archivo)

- [ ] **3.1 Agregar imports necesarios al archivo**

En `src/services/asistenciaService.ts`, verificar que estén importados (agregar los que falten):

```typescript
import mongoose from 'mongoose';
import AlertaAsistencia from '../models/alertaAsistencia.model';
import Usuario from '../models/usuario.model';
import Curso from '../models/curso.model';
import Escuela from '../models/escuela.model';
// Notificacion model — usar el import ya existente en el archivo si lo hay
import Notificacion from '../models/notificacion.model';
// emailService — usar el import ya existente en el archivo si lo hay
import { emailService } from './email.service';
```

- [ ] **3.2 Agregar la función triggerAlertasAsistencia**

```typescript
/**
 * Evalúa umbrales de ausencias de un estudiante y dispara alertas si corresponde.
 * Llamar en fire-and-forget desde los controllers de asistencia (POST y PATCH finalizar).
 */
export async function triggerAlertasAsistencia(
  estudianteId: string,
  cursoId: string,
  escuelaId: string,
  docenteId: string
): Promise<void> {
  // Obtener período académico activo de la escuela
  const escuela = await Escuela.findById(escuelaId).select('periodos_academicos');
  const hoy = new Date();
  const periodoActivo = escuela?.periodos_academicos?.find(
    (p: any) => new Date(p.fecha_inicio) <= hoy && hoy <= new Date(p.fecha_fin)
  );
  const periodoId = periodoActivo?._id?.toString() ?? 'sin-periodo';

  // ---------------------------------------------------------------
  // NOTA: El query siguiente asume Estructura A (un documento por
  // clase con array de asistencias). Si el proyecto usa Estructura B
  // (un documento por estudiante), reemplazar por:
  //
  // const entradas = await Asistencia.find({ cursoId, estudianteId });
  // const totalDias = entradas.length;
  // const diasAusente = entradas.filter(a => a.estado === 'AUSENTE').length;
  // ---------------------------------------------------------------
  const registros = await Asistencia.find({
    cursoId,
    'asistencias.estudianteId': new mongoose.Types.ObjectId(estudianteId),
  });

  const entradas = registros.flatMap((r: any) =>
    r.asistencias.filter(
      (a: any) => a.estudianteId.toString() === estudianteId
    )
  );

  const totalDias = entradas.length;
  if (totalDias === 0) return;

  const diasAusente = entradas.filter((a: any) => a.estado === 'AUSENTE').length;
  const porcentajeAusencias = (diasAusente / totalDias) * 100;

  // Evaluar umbrales de mayor a menor
  const UMBRALES: { nivel: IAlertaAsistencia['nivel']; minPct: number }[] = [
    { nivel: 'INMINENTE', minPct: 30 },
    { nivel: 'CRITICO',   minPct: 25 },
    { nivel: 'ALERTA',    minPct: 15 },
  ];

  const umbralesAplicables = UMBRALES.filter(u => porcentajeAusencias >= u.minPct);
  if (umbralesAplicables.length === 0) return;

  // Buscar destinatarios: rectores + coordinadores + docente
  const [administrativos, estudiante, docente, curso] = await Promise.all([
    Usuario.find({
      escuelaId,
      tipo: { $in: ['RECTOR', 'COORDINADOR'] },
      activo: true,
    }).select('_id'),
    Usuario.findById(estudianteId).select('nombre apellidos'),
    Usuario.findById(docenteId).select('_id'),
    Curso.findById(cursoId).select('nombre'),
  ]);

  const destinatariosIds = [
    ...administrativos.map((u: any) => u._id),
    ...(docente ? [docente._id] : []),
  ];

  if (destinatariosIds.length === 0) return;

  const nombreEstudiante = `${estudiante?.nombre ?? ''} ${estudiante?.apellidos ?? ''}`.trim();
  const nombreCurso = curso?.nombre ?? '';

  // Para cada umbral aplicable, intentar insertar y notificar
  for (const { nivel } of umbralesAplicables) {
    try {
      await AlertaAsistencia.create({
        estudianteId,
        cursoId,
        escuelaId,
        nivel,
        porcentajeAusencias,
        periodoId,
        notificadosIds: destinatariosIds,
      });

      // Solo notificar si el insert tuvo éxito (no era duplicado)
      await enviarNotificacionesAlerta({
        nivel,
        nombreEstudiante,
        nombreCurso,
        porcentajeAusencias,
        destinatariosIds,
      });
    } catch (err: any) {
      if (err.code !== 11000) throw err;
      // 11000 = duplicate key — alerta ya enviada para este nivel+período, ignorar
    }
  }
}
```

> **Nota:** El tipo `IAlertaAsistencia['nivel']` requiere importar la interface. Agregar al inicio del archivo: `import { IAlertaAsistencia } from '../interfaces/IAlertaAsistencia';`

> **Nota:** `Asistencia` — usar el import del modelo que ya existe en el archivo de servicio.

- [ ] **3.3 Commit**

```bash
git add src/services/asistenciaService.ts src/interfaces/IAlertaAsistencia.ts
git commit -m "feat: agregar triggerAlertasAsistencia con lógica de umbrales y deduplicación"
```

---

## Task 4: Función enviarNotificacionesAlerta

**Files:**
- Modify: `src/services/asistenciaService.ts` (agregar después de triggerAlertasAsistencia)

- [ ] **4.1 Agregar la función auxiliar**

```typescript
/**
 * Envía notificación interna + email a los destinatarios de una alerta.
 * Canal-agnóstica: agregar Canal 3 (FCM) aquí cuando Flutter integre Firebase.
 */
async function enviarNotificacionesAlerta(params: {
  nivel: 'ALERTA' | 'CRITICO' | 'INMINENTE';
  nombreEstudiante: string;
  nombreCurso: string;
  porcentajeAusencias: number;
  destinatariosIds: mongoose.Types.ObjectId[];
}): Promise<void> {
  const { nivel, nombreEstudiante, nombreCurso, porcentajeAusencias, destinatariosIds } = params;

  const etiquetas: Record<string, string> = {
    ALERTA:    'Alerta de asistencia',
    CRITICO:   'Asistencia crítica',
    INMINENTE: 'Riesgo de reprobación por inasistencia',
  };

  const mensaje = `${nombreEstudiante} (${nombreCurso}) tiene ${porcentajeAusencias.toFixed(1)}% de ausencias.`;
  const titulo = etiquetas[nivel];

  // Canal 1: Notificación interna
  await Promise.all(
    destinatariosIds.map(usuarioId =>
      Notificacion.create({
        usuarioId,
        tipo: 'ALERTA_ASISTENCIA',
        titulo,
        mensaje,
        leida: false,
      })
    )
  );

  // Canal 2: Email
  // NOTA: verificar la firma real de emailService en src/services/email.service.ts
  // Puede ser sendEmail, send, enviarEmail, etc. Adaptar según el archivo real.
  const usuarios = await Usuario.find({ _id: { $in: destinatariosIds } }).select('email nombre');
  await Promise.all(
    usuarios.map((u: any) =>
      emailService.sendEmail({
        to: u.email,
        subject: titulo,
        html: `
          <p>Estimado/a ${u.nombre},</p>
          <p>${mensaje}</p>
          <p>Ingrese a <strong>EducaNexo360</strong> para ver el detalle en el módulo de Asistencia → Informes → Riesgo.</p>
        `,
      })
    )
  );

  // Canal 3: Push FCM — pendiente cuando Flutter integre Firebase
  // await fcmService.enviar({ destinatariosIds, titulo, cuerpo: mensaje });
}
```

- [ ] **4.2 Verificar que el modelo Notificacion tiene el campo `tipo`**

Abrir `src/models/notificacion.model.ts` y confirmar que acepta el tipo `'ALERTA_ASISTENCIA'`. Si el campo `tipo` tiene un enum, agregar `'ALERTA_ASISTENCIA'` al array de valores permitidos.

- [ ] **4.3 Commit**

```bash
git add src/services/asistenciaService.ts src/models/notificacion.model.ts
git commit -m "feat: agregar enviarNotificacionesAlerta canal-agnóstica"
```

---

## Task 5: Integrar trigger en el controller de asistencia

**Files:**
- Modify: `src/controllers/asistencia.controller.ts`

- [ ] **5.1 Agregar import del trigger al inicio del archivo**

```typescript
import { triggerAlertasAsistencia } from '../services/asistenciaService';
```

- [ ] **5.2 Integrar en el handler POST (crear registro)**

Localizar el handler de `POST /api/asistencia`. Después de guardar exitosamente el registro, agregar el bloque de disparo asíncrono. El registro guardado tiene los estudiantes; iterar sobre ellos:

```typescript
// --- DESPUÉS del bloque de guardado exitoso, ANTES del return ---

// Fire-and-forget: no bloquear la respuesta al docente
// Adaptar 'asistenciaGuardada.asistencias' al nombre real del campo
// y 'req.user._id' al campo real del usuario autenticado
setImmediate(() => {
  const docenteId = req.user._id.toString();
  const cursoId = asistenciaGuardada.cursoId.toString();
  const escuelaId = req.user.escuelaId.toString();

  // Si Estructura A (array de estudiantes por registro):
  for (const entrada of asistenciaGuardada.asistencias ?? []) {
    triggerAlertasAsistencia(
      entrada.estudianteId.toString(),
      cursoId,
      escuelaId,
      docenteId
    ).catch((err: any) => console.error('[AlertaAsistencia]', err));
  }

  // Si Estructura B (un documento por estudiante):
  // triggerAlertasAsistencia(
  //   asistenciaGuardada.estudianteId.toString(),
  //   cursoId,
  //   escuelaId,
  //   docenteId
  // ).catch((err: any) => console.error('[AlertaAsistencia]', err));
});
```

- [ ] **5.3 Integrar en el handler PATCH /finalizar**

Localizar el handler de `PATCH /api/asistencia/:id/finalizar`. Después de finalizar exitosamente, agregar el mismo bloque:

```typescript
setImmediate(() => {
  const docenteId = req.user._id.toString();
  const cursoId = asistenciaFinalizada.cursoId.toString();
  const escuelaId = req.user.escuelaId.toString();

  for (const entrada of asistenciaFinalizada.asistencias ?? []) {
    triggerAlertasAsistencia(
      entrada.estudianteId.toString(),
      cursoId,
      escuelaId,
      docenteId
    ).catch((err: any) => console.error('[AlertaAsistencia]', err));
  }
});
```

- [ ] **5.4 Commit**

```bash
git add src/controllers/asistencia.controller.ts
git commit -m "feat: disparar triggerAlertasAsistencia en creación y finalización de registro"
```

---

## Task 6: Endpoint GET /api/asistencia/alertas

**Files:**
- Modify: `src/controllers/asistencia.controller.ts` (agregar handler)
- Modify: `src/routes/asistencia.routes.ts` (agregar ruta)

- [ ] **6.1 Agregar handler en el controller**

```typescript
/**
 * GET /api/asistencia/alertas
 * Retorna alertas de asistencia con populate de estudiante y curso.
 * Roles: ADMIN, RECTOR, COORDINADOR, DOCENTE
 */
export const getAlertasAsistencia = async (req: Request, res: Response): Promise<void> => {
  try {
    const { cursoId, estudianteId, nivel, periodoId } = req.query;
    const escuelaId = req.user.escuelaId;

    const filtro: Record<string, any> = { escuelaId };
    if (cursoId)       filtro.cursoId = cursoId;
    if (estudianteId)  filtro.estudianteId = estudianteId;
    if (nivel)         filtro.nivel = nivel;
    if (periodoId)     filtro.periodoId = periodoId;

    const alertas = await AlertaAsistencia.find(filtro)
      .populate('estudianteId', 'nombre apellidos')
      .populate('cursoId', 'nombre')
      .sort({ fechaEnvio: -1 });

    res.status(200).json({ success: true, data: alertas });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error al obtener alertas de asistencia' });
  }
};
```

> **Nota:** Agregar `import AlertaAsistencia from '../models/alertaAsistencia.model';` al inicio del controller si no está.

- [ ] **6.2 Agregar la ruta**

En `src/routes/asistencia.routes.ts`, agregar antes de las rutas con parámetros `:id` para evitar conflictos de routing:

```typescript
// Ruta de alertas — debe ir ANTES de /:id
router.get(
  '/alertas',
  authMiddleware,
  authorizeRoles('ADMIN', 'SUPER_ADMIN', 'RECTOR', 'COORDINADOR', 'ADMINISTRATIVO', 'DOCENTE'),
  getAlertasAsistencia
);
```

> **Nota:** `authMiddleware` y `authorizeRoles` — usar los nombres reales que ya usan las demás rutas del archivo.

- [ ] **6.3 Verificar que la ruta no colisiona con rutas existentes**

Ejecutar el servidor y comprobar que `GET /api/asistencia/alertas` no es capturada por otra ruta. El orden en el archivo importa en Express.

- [ ] **6.4 Commit**

```bash
git add src/controllers/asistencia.controller.ts src/routes/asistencia.routes.ts
git commit -m "feat: agregar endpoint GET /api/asistencia/alertas"
```

---

## Task 7: Prueba manual con Postman / curl

- [ ] **7.1 Levantar el servidor**

```bash
npm run dev
```

- [ ] **7.2 Crear un registro de asistencia con un estudiante con alto ausentismo**

```bash
# Ajustar el body según el modelo real de asistencia del proyecto
curl -X POST http://localhost:3000/api/asistencia \
  -H "Authorization: Bearer <token_docente>" \
  -H "Content-Type: application/json" \
  -d '{
    "cursoId": "<id_curso>",
    "asignaturaId": "<id_asignatura>",
    "fecha": "2026-05-25",
    "asistencias": [
      { "estudianteId": "<id_estudiante_con_muchas_ausencias>", "estado": "AUSENTE" }
    ]
  }'
```

- [ ] **7.3 Verificar que se creó la alerta en MongoDB**

En MongoDB Compass o mongo shell:
```javascript
db.alertaasistencias.find({ estudianteId: ObjectId("<id_estudiante>") })
// Debe retornar al menos un documento con nivel ALERTA, CRITICO o INMINENTE
```

- [ ] **7.4 Verificar que se crearon las notificaciones internas**

```javascript
db.notificaciones.find({ tipo: 'ALERTA_ASISTENCIA' }).sort({ createdAt: -1 }).limit(5)
// Debe retornar notificaciones para rector + coordinador + docente
```

- [ ] **7.5 Verificar el endpoint GET /alertas**

```bash
curl http://localhost:3000/api/asistencia/alertas \
  -H "Authorization: Bearer <token_rector>"
# Debe retornar la alerta con estudianteId y cursoId populados
```

- [ ] **7.6 Verificar deduplicación**

Crear otro registro con el mismo estudiante y confirmar que MongoDB **no** crea una segunda alerta del mismo nivel:

```bash
# Segundo POST con mismo estudianteId...
# Luego verificar:
db.alertaasistencias.find({ estudianteId: ObjectId("<id>"), nivel: "ALERTA" }).count()
# Debe ser exactamente 1
```

- [ ] **7.7 Commit final de verificación**

```bash
git commit --allow-empty -m "test: alertas asistencia verificadas manualmente — deduplicación OK"
```

---

## Notas para el backend chat

1. **`req.user`** — el middleware de auth inyecta el usuario en `req.user`. Verificar los campos reales disponibles (`_id`, `escuelaId`, `tipo`) en `src/@types/express/index.d.ts`.

2. **`emailService`** — la firma exacta del método puede diferir. Abrir `src/services/email.service.ts` y adaptar la llamada.

3. **`Asistencia` model** — verificar si es Estructura A (array `asistencias[]`) o Estructura B (un doc por estudiante) antes de implementar Task 3. El trigger funciona en ambos casos, la query es diferente.

4. **Notificacion model** — si `tipo` tiene enum, agregar `'ALERTA_ASISTENCIA'`.

5. **Fire-and-forget con `setImmediate`** — garantiza que el trigger no bloquea la respuesta HTTP. Los errores van al log del servidor (`console.error`), no al cliente.
