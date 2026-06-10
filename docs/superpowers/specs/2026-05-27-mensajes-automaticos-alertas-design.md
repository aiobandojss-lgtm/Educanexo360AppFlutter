# Spec: Mensajes Internos en Alertas de Asistencia
**Fecha:** 2026-05-27  
**Estado:** Aprobado — pendiente implementación  
**Módulo afectado:** Backend únicamente (Node.js)  
**Depende de:** `docs/superpowers/specs/2026-05-25-alertas-automaticas-asistencia-design.md`

---

## 1. Contexto y objetivo

Las alertas automáticas de asistencia ya envían notificación interna (campanita) y email. Se agrega un tercer canal: **mensaje en la bandeja de recibidos** via el modelo `Mensaje` existente.

Esto hace que rector, coordinador y docente reciban la alerta como un mensaje persistente en su bandeja — pueden verlo, leerlo, y en el futuro responderlo. A medida que la plataforma reemplace al email, este canal se convierte en el principal para usuarios web.

---

## 2. Usuario "Sistema EducaNexo360"

Un usuario especial global en la BD que actúa como remitente de todos los mensajes automáticos de la plataforma.

```
nombre:    "Sistema"
apellidos: "EducaNexo360"
email:     "sistema@educanexo360.com"
tipo:      "ADMIN"
estado:    "ACTIVO"
escuelaId: null   ← usuario global, no pertenece a ninguna escuela
password:  hash de un UUID aleatorio (nunca se usa para login)
```

**Creación:** el backend busca este usuario por `email: 'sistema@educanexo360.com'` al momento de enviar el primer mensaje. Si no existe, lo crea. Patrón `findOrCreate` — idempotente, sin migraciones manuales.

**Restricción:** este usuario NO puede hacer login (password inutilizable). NO aparece en listados de usuarios (`GET /api/usuarios` debe filtrarlo si devuelve todos los usuarios, o ignorar ya que tiene `escuelaId: null`).

---

## 3. Contenido del mensaje

Un mensaje por nivel de alerta, enviado a cada destinatario individualmente.

```
asunto:  "⚠️ Alerta ALERTA — [nombre] [apellidos]"
         "🔴 Alerta CRÍTICO — [nombre] [apellidos]"
         "🚨 Alerta INMINENTE — [nombre] [apellidos]"

cuerpo:
  Estudiante: [nombre completo]
  Curso: [nombre del curso]
  Porcentaje de ausencias: [X.X%]
  Umbral superado: [15% / 25% / 30%]
  
  Revise el detalle en: Asistencia → Informes → Riesgo.
```

---

## 4. Canal de mensajería en enviarNotificacionesAlerta

```typescript
// Después de Canal 1 (notificación interna) y antes de Canal 3 (email):

// Canal 2: Mensaje en bandeja (sistema existente)
const sistemaUser = await obtenerOCrearUsuarioSistema();

await Promise.all(
  destinatariosIds.map(destinatarioId =>
    Mensaje.create({
      remitenteId: sistemaUser._id,
      destinatarioId,              // verificar nombre real del campo en IMensaje
      asunto: `${prefijo[nivel]} Alerta ${nivel} — ${nombreEstudiante}`,
      cuerpo: generarCuerpoMensaje(nivel, nombreEstudiante, nombreCurso, porcentajeAusencias),
      leido: false,
    })
  )
);
```

> **Nota para el backend:** verificar la estructura exacta del modelo `Mensaje` en `src/models/mensaje.model.ts` y adaptar los campos (`remitenteId`, `destinatarioId`, `asunto`, `cuerpo`, o equivalentes).

---

## 5. Helper obtenerOCrearUsuarioSistema

```typescript
async function obtenerOCrearUsuarioSistema(): Promise<IUsuarioDocument> {
  const EMAIL_SISTEMA = 'sistema@educanexo360.com';
  
  let sistema = await Usuario.findOne({ email: EMAIL_SISTEMA });
  
  if (!sistema) {
    const { v4: uuidv4 } = require('uuid');  // o crypto.randomUUID()
    const bcrypt = require('bcrypt');
    sistema = await Usuario.create({
      nombre: 'Sistema',
      apellidos: 'EducaNexo360',
      email: EMAIL_SISTEMA,
      password: await bcrypt.hash(uuidv4(), 10),
      tipo: 'ADMIN',
      estado: 'ACTIVO',
      escuelaId: null,
    });
  }
  
  return sistema;
}
```

---

## 6. Orden de canales en enviarNotificacionesAlerta (final)

```
Canal 1: Notificación interna (campanita)   ← ya existe, sin cambios
Canal 2: Mensaje en bandeja                  ← NUEVO
Canal 3: Email (Nodemailer)                  ← ya existe, sin cambios
Canal 4: Push FCM                            ← futuro, comentado
```

---

## 7. Cambios requeridos

| Archivo | Acción |
|---------|--------|
| `src/services/alertaAsistencia.service.ts` | Agregar `obtenerOCrearUsuarioSistema()` + Canal 2 en `enviarNotificacionesAlerta` |
| `src/models/mensaje.model.ts` | Solo lectura — verificar estructura del modelo |
| `src/interfaces/IMensaje.ts` | Solo lectura — verificar tipos |

**Frontend:** ningún cambio. Los mensajes aparecen automáticamente en la bandeja existente.

---

## 8. Sin cambios en el frontend

La bandeja de mensajes ya existe y funciona. El mensaje del "Sistema EducaNexo360" aparecerá como cualquier otro mensaje recibido. No se requieren nuevas rutas, componentes, ni hooks.
