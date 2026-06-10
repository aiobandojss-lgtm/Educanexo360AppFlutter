# Spec: Alertas Automáticas de Asistencia
**Fecha:** 2026-05-25  
**Estado:** Aprobado — pendiente implementación  
**Módulos afectados:** Backend (Node.js) + Frontend React (`InformeRiesgo`)

---

## 1. Contexto y objetivo

Cuando un estudiante supera ciertos umbrales de ausentismo, el sistema debe notificar automáticamente al rector, coordinador y docente del curso — sin intervención manual. El objetivo es cerrar el ciclo: **detectar → alertar → actuar → registrar** (el registro de intervención es una mejora posterior).

---

## 2. Reglas de negocio

### Umbrales de alerta
| Nivel | % Ausencias | % Asistencia equivalente | Significado |
|-------|-------------|--------------------------|-------------|
| `ALERTA` | ≥ 15% | ≤ 85% | Riesgo temprano |
| `CRITICO` | ≥ 25% | ≤ 75% | Riesgo alto |
| `INMINENTE` | ≥ 30% | ≤ 70% | Umbral legal reprobación Colombia |

### Cálculo de ausencias
```
porcentajeAusencias = diasAusente / totalDias × 100

diasAusente = registros con estado AUSENTE únicamente
             (TARDANZA y JUSTIFICADO NO cuentan como ausencia)
totalDias   = total de registros del estudiante en el período actual
             (todos los estados: PRESENTE, AUSENTE, TARDANZA, JUSTIFICADO)
```

### Deduplicación — una vez por umbral por período
- Cada nivel (`ALERTA`, `CRITICO`, `INMINENTE`) se notifica **una sola vez** por estudiante por período académico.
- Si el estudiante mejora y vuelve a empeorar, **no** se reenvía (el índice único de MongoDB lo garantiza).
- Un estudiante puede recibir máximo 3 alertas por período (una por nivel).
- Los tres niveles son **acumulativos**: si un estudiante llega directamente al 30%, recibe las tres alertas en el mismo trigger.

### Momento del trigger
- **Se activa en:** `POST /api/asistencia` y `PATCH /api/asistencia/:id/finalizar`
- **No se activa en:** `PUT /api/asistencia/:id` (ediciones son generalmente correcciones positivas)

### Destinatarios
Por cada alerta, se notifica a:
1. Todos los usuarios con rol `RECTOR` de la misma `escuelaId`
2. Todos los usuarios con rol `COORDINADOR` de la misma `escuelaId`
3. El docente que registró la asistencia (`docenteId` del registro)

---

## 3. Cambios en el Backend

> **Este bloque es para el chat del backend (Node.js + Express + TypeScript + MongoDB/Mongoose)**

### 3.1 Nuevo modelo — `AlertaAsistencia`

**Archivo:** `src/models/alertaAsistencia.model.ts`

```typescript
import mongoose, { Schema, Document } from 'mongoose';

export interface IAlertaAsistencia extends Document {
  estudianteId: mongoose.Types.ObjectId;
  cursoId: mongoose.Types.ObjectId;
  escuelaId: mongoose.Types.ObjectId;
  nivel: 'ALERTA' | 'CRITICO' | 'INMINENTE';
  porcentajeAusencias: number;
  periodoId: string;           // ej: "2026-1" — identificador del período académico activo
  fechaEnvio: Date;
  notificadosIds: mongoose.Types.ObjectId[];
}

const AlertaAsistenciaSchema = new Schema<IAlertaAsistencia>({
  estudianteId:        { type: Schema.Types.ObjectId, ref: 'Usuario', required: true },
  cursoId:             { type: Schema.Types.ObjectId, ref: 'Curso', required: true },
  escuelaId:           { type: Schema.Types.ObjectId, ref: 'Escuela', required: true },
  nivel:               { type: String, enum: ['ALERTA', 'CRITICO', 'INMINENTE'], required: true },
  porcentajeAusencias: { type: Number, required: true },
  periodoId:           { type: String, required: true },
  fechaEnvio:          { type: Date, default: Date.now },
  notificadosIds:      [{ type: Schema.Types.ObjectId, ref: 'Usuario' }],
}, { timestamps: true });

// Índice único compuesto: garantiza deduplicación a nivel de base de datos
AlertaAsistenciaSchema.index(
  { estudianteId: 1, nivel: 1, periodoId: 1 },
  { unique: true }
);

export default mongoose.model<IAlertaAsistencia>('AlertaAsistencia', AlertaAsistenciaSchema);
```

### 3.2 Nueva interface — `IAlertaAsistencia`

**Archivo:** `src/interfaces/IAlertaAsistencia.ts`  
(Copiar la interface del modelo, sin la extensión de Document)

### 3.3 Nuevo servicio — función `triggerAlertasAsistencia`

**Archivo:** `src/services/asistenciaService.ts` (agregar función al final, o extraer a `alertaAsistencia.service.ts`)

```typescript
/**
 * Evalúa umbrales de ausencias de un estudiante y envía alertas si corresponde.
 * Llamar después de POST /api/asistencia y después de PATCH finalizar.
 */
async function triggerAlertasAsistencia(
  estudianteId: string,
  cursoId: string,
  escuelaId: string,
  docenteId: string,
  periodoId: string   // identificador del período académico activo de la escuela
): Promise<void> {

  // 1. Calcular % ausencias del estudiante en el período
  // NOTA para el backend: el modelo Asistencia tiene un array `asistencias` donde
  // cada entrada es { estudianteId, estado }. Verificar con IAsistencia.ts.
  // Si la estructura difiere, adaptar el query y el flatMap.
  const registros = await Asistencia.find({
    cursoId,
    'asistencias.estudianteId': new mongoose.Types.ObjectId(estudianteId),
  });

  // Aplanar y filtrar los registros individuales del estudiante
  const entradas = registros.flatMap(r =>
    r.asistencias.filter(a => a.estudianteId.toString() === estudianteId)
  );

  const totalDias = entradas.length;
  if (totalDias === 0) return;

  const diasAusente = entradas.filter(a => a.estado === 'AUSENTE').length;
  const porcentajeAusencias = (diasAusente / totalDias) * 100;

  // 2. Determinar qué umbrales aplican (de mayor a menor)
  const UMBRALES: { nivel: IAlertaAsistencia['nivel']; minPct: number }[] = [
    { nivel: 'INMINENTE', minPct: 30 },
    { nivel: 'CRITICO',   minPct: 25 },
    { nivel: 'ALERTA',    minPct: 15 },
  ];

  const umbralesAplicables = UMBRALES.filter(u => porcentajeAusencias >= u.minPct);
  if (umbralesAplicables.length === 0) return;

  // 3. Buscar destinatarios: rectores + coordinadores + docente
  const [administrativos, estudiante] = await Promise.all([
    Usuario.find({
      escuelaId,
      tipo: { $in: ['RECTOR', 'COORDINADOR'] },
      activo: true,
    }).select('_id'),
    Usuario.findById(estudianteId).select('nombre apellidos'),
  ]);

  const docente = await Usuario.findById(docenteId).select('_id');
  const destinatariosIds = [
    ...administrativos.map(u => u._id),
    ...(docente ? [docente._id] : []),
  ];

  const curso = await Curso.findById(cursoId).select('nombre');
  const nombreEstudiante = `${estudiante?.nombre} ${estudiante?.apellidos}`;

  // 4. Para cada umbral aplicable, intentar insertar (falla silenciosamente si ya existe)
  for (const { nivel, minPct: _ } of umbralesAplicables) {
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

      // 5. Enviar notificaciones (canales: interno + email)
      await enviarNotificacionesAlerta({
        nivel,
        nombreEstudiante,
        nombreCurso: curso?.nombre ?? '',
        porcentajeAusencias,
        destinatariosIds,
        escuelaId,
      });

    } catch (err: any) {
      // Error 11000 = duplicate key (alerta ya enviada) — ignorar silenciosamente
      if (err.code !== 11000) throw err;
    }
  }
}
```

### 3.4 Función auxiliar — `enviarNotificacionesAlerta`

Esta función centraliza los canales de notificación. Diseñada para ser **canal-agnóstica**: cuando se integre FCM (push Flutter), solo se agrega un canal aquí sin tocar el trigger.

```typescript
async function enviarNotificacionesAlerta(params: {
  nivel: 'ALERTA' | 'CRITICO' | 'INMINENTE';
  nombreEstudiante: string;
  nombreCurso: string;
  porcentajeAusencias: number;
  destinatariosIds: mongoose.Types.ObjectId[];
  escuelaId: string;
}): Promise<void> {
  const { nivel, nombreEstudiante, nombreCurso, porcentajeAusencias, destinatariosIds } = params;

  const etiquetas: Record<string, string> = {
    ALERTA:    '⚠️ Alerta de asistencia',
    CRITICO:   '🔴 Asistencia crítica',
    INMINENTE: '🚨 Riesgo de reprobación por inasistencia',
  };

  const mensaje = `${nombreEstudiante} (${nombreCurso}) tiene ${porcentajeAusencias.toFixed(1)}% de ausencias.`;

  // Canal 1: Notificación interna (sistema existente)
  await Promise.all(destinatariosIds.map(destinatarioId =>
    Notificacion.create({
      usuarioId: destinatarioId,
      tipo: 'ALERTA_ASISTENCIA',
      titulo: etiquetas[nivel],
      mensaje,
      leida: false,
    })
  ));

  // Canal 2: Email (Nodemailer — sistema existente en src/services/email.service.ts)
  // NOTA: adaptar la firma al método real del emailService (puede ser sendEmail, send, etc.)
  const usuarios = await Usuario.find({ _id: { $in: destinatariosIds } }).select('email nombre');
  await Promise.all(usuarios.map(u =>
    emailService.sendEmail({
      to: u.email,
      subject: etiquetas[nivel],
      text: `Estimado/a ${u.nombre},\n\n${mensaje}\n\nIngrese a EducaNexo360 para más detalles.`,
    })
  ));

  // Canal 3: Push FCM — PENDIENTE cuando Flutter integre FCM
  // await fcmService.enviar({ destinatariosIds, titulo: etiquetas[nivel], cuerpo: mensaje });
}
```

### 3.5 Integrar trigger en el controller de asistencia

**Archivo:** `src/controllers/asistencia.controller.ts`

Agregar llamada al final de los handlers de creación y finalización:

```typescript
// En el handler de POST /api/asistencia (después de guardar exitosamente):
// periodoId: derivar del período académico activo de la escuela.
// La escuela tiene escuela.periodos_academicos[]. Buscar el período cuya
// fecha_inicio <= hoy <= fecha_fin. Si no hay período activo, usar 'sin-periodo'.
const escuela = await Escuela.findById(escuelaId).select('periodos_academicos');
const hoy = new Date();
const periodoActivo = escuela?.periodos_academicos?.find(
  p => new Date(p.fecha_inicio) <= hoy && hoy <= new Date(p.fecha_fin)
);
const periodoId = periodoActivo?._id?.toString() ?? 'sin-periodo';

// Iterar sobre cada estudiante del registro y disparar el trigger
for (const entrada of asistenciaGuardada.asistencias) {
  triggerAlertasAsistencia(
    entrada.estudianteId.toString(),
    asistenciaGuardada.cursoId.toString(),
    escuelaId,
    req.user._id.toString(),
    periodoActivo?.id ?? 'sin-periodo'
  ).catch(console.error); // fire-and-forget, no bloquear la respuesta al cliente
}

// En el handler de PATCH /api/asistencia/:id/finalizar (después de finalizar):
// Mismo bloque de iteración sobre asistenciaFinalizada.asistencias
```

> **Nota:** Se usa `fire-and-forget` (`.catch(console.error)`) para que el trigger no bloquee la respuesta al docente. Las alertas son asíncronas.

### 3.6 Nuevo endpoint — `GET /api/asistencia/alertas`

**Archivo:** `src/routes/asistencia.routes.ts` — agregar ruta  
**Archivo:** `src/controllers/asistencia.controller.ts` — agregar handler

```
GET /api/asistencia/alertas
  Auth: requerida
  Roles: ADMIN, RECTOR, COORDINADOR, DOCENTE

Query params:
  cursoId?      → filtrar por curso
  estudianteId? → filtrar por estudiante
  nivel?        → ALERTA | CRITICO | INMINENTE
  periodoId?    → filtrar por período

Respuesta:
{
  success: true,
  data: AlertaAsistencia[] pobladas con:
    - estudianteId: { _id, nombre, apellidos }
    - cursoId: { _id, nombre }
}
```

---

## 4. Cambios en el Frontend React

> **Este bloque es para implementar en EducaNexo360React (este proyecto)**

### 4.1 Nuevo service function

**Archivo:** `src/services/asistenciaInformesService.ts`

```typescript
export interface AlertaAsistencia {
  _id: string;
  estudianteId: { _id: string; nombre: string; apellidos: string };
  cursoId: { _id: string; nombre: string };
  nivel: 'ALERTA' | 'CRITICO' | 'INMINENTE';
  porcentajeAusencias: number;
  periodoId: string;
  fechaEnvio: string;
}

export const getAlertasAsistencia = async (params: {
  cursoId?: string;
  estudianteId?: string;
  nivel?: string;
  periodoId?: string;
}): Promise<AlertaAsistencia[]> => {
  const { data } = await api.get('/asistencia/alertas', { params });
  return data.data;
};
```

### 4.2 Nuevo hook

**Archivo:** `src/hooks/useAppQueries.ts`

```typescript
export const useAlertasAsistencia = (params: {
  cursoId?: string;
  periodoId?: string;
}) =>
  useQuery({
    queryKey: ['alertas-asistencia', params],
    queryFn: () => getAlertasAsistencia(params),
    enabled: !!(params.cursoId || params.periodoId),
  });
```

### 4.3 Columna "Alerta" en InformeRiesgo

**Archivo:** `src/components/asistencia/informes/InformeRiesgo.tsx`

Agregar columna al final de la tabla de estudiantes en riesgo:

- Chip con color según nivel: `ALERTA` → naranja, `CRITICO` → rojo, `INMINENTE` → rojo oscuro
- Si no tiene alerta enviada: chip gris "Sin alerta"
- Tooltip con la fecha de envío

```
| Estudiante | Curso | % Asistencia | Ausencias | Faltas al 70% | Alerta enviada |
|------------|-------|--------------|-----------|---------------|----------------|
| Mateo G.   | Jard. | 62%          | 17        | 3             | 🔴 CRÍTICO (May 20) |
```

---

## 5. Flujo completo de extremo a extremo

```
1. Docente registra asistencia → POST /api/asistencia
2. Controller guarda el registro → OK → responde al cliente
3. [Asíncrono] trigger evalúa cada estudiante del registro
4. Mateo tiene 26% ausencias → supera CRÍTICO (25%)
5. AlertaAsistencia.create({ nivel: 'CRITICO', ... }) → éxito (primera vez)
6. Se crean notificaciones internas para rector + coordinador + docente
7. Se envían emails a rector + coordinador + docente
8. Rector abre EducaNexo360 → ve la notificación en la campanita
9. Rector abre InformeRiesgo → ve chip 🔴 CRÍTICO en la fila de Mateo
10. [Futuro] Acudiente de Mateo recibe push en Flutter
```

---

## 6. Consideraciones de performance

- El trigger es **fire-and-forget**: no bloquea la respuesta al docente.
- La query de ausencias filtra solo el estudiante afectado, no el curso completo.
- El índice único hace la deduplicación en O(1) a nivel de BD.
- El endpoint `GET /api/asistencia/alertas` debe paginar si la escuela es grande.

---

## 7. Pendiente futuro (no en este sprint)

- **Push FCM:** cuando Flutter integre Firebase, descomentar `Canal 3` en `enviarNotificacionesAlerta`. Sin cambios en el trigger.
- **Reset por período:** al iniciar un nuevo período académico, las alertas del período anterior no se borran — quedan como historial. El `periodoId` garantiza que el nuevo período empiece limpio.
- **Umbral configurable:** los % podrían venir de la configuración de la escuela en vez de ser hardcodeados.
