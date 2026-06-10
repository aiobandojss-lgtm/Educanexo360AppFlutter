# Spec: Mensajes masivos multi-curso + mejora selector individual

**Fecha:** 2026-05-20  
**Módulo:** Mensajería — NuevoMensaje  
**Archivos afectados:** `src/pages/mensajes/NuevoMensaje.tsx`, `src/services/mensajeService.ts`

---

## Objetivo

1. Permitir seleccionar **múltiples cursos** al enviar un mensaje masivo.
2. Agregar botón **"Todo el colegio"** para roles administrativos.
3. Mostrar **contador dinámico** de cursos y estudiantes seleccionados.
4. **Limpiar el campo de búsqueda** automáticamente al seleccionar un destinatario individual.

---

## Cambios en NuevoMensaje.tsx

### Estado formik
- `cursoId: ''` → `cursoIds: [] as string[]`
- Validación masivo: `Yup.string().required(...)` → `Yup.array().min(1, 'Debe seleccionar al menos un curso')`

### UI selector masivo
Reemplazar `<Select>` simple por `<Autocomplete multiple>` con el mismo patrón visual que el selector de destinatarios individuales:

```
[ Todo el colegio ]   ← solo para ADMIN, RECTOR, COORDINADOR, ADMINISTRATIVO

┌─────────────────────────────────────┐
│ 🔍 Buscar curso...              ▼  │
└─────────────────────────────────────┘

╔═══════════════╗  ╔═══════════════╗
║ 1°A (28 est.) ║  ║ 2°B (25 est.) ║
║             ✕ ║  ║             ✕ ║
╚═══════════════╝  ╚═══════════════╝

📊 2 cursos seleccionados · 53 estudiantes total
```

### Lógica "Todo el colegio"
- Solo visible para: `ADMIN`, `RECTOR`, `COORDINADOR`, `ADMINISTRATIVO`
- Primer clic: selecciona todos los cursos disponibles
- Segundo clic (todos ya seleccionados): deselecciona todos (toggle)

### Contador dinámico
```
totalEstudiantes = cursoIds.reduce((sum, id) => {
  const curso = cursos.find(c => c._id === id);
  return sum + (curso?.cantidadEstudiantes ?? 0);
}, 0);
```
Mostrar debajo de los chips: `"X cursos seleccionados · Y estudiantes total"`

### Mejora selector individual
Al seleccionar un destinatario en el Autocomplete individual, limpiar el campo de búsqueda automáticamente usando `inputValue` controlado en el Autocomplete. Actualmente el usuario debe borrarlo a mano.

### Casos borde
| Situación | Comportamiento |
|-----------|---------------|
| Sin cursos disponibles | Alert info: "No hay cursos disponibles" |
| Todos seleccionados → clic "Todo el colegio" | Deselecciona todos |
| DOCENTE | No ve botón "Todo el colegio", solo sus cursos asignados |
| Envío en progreso | Chips, botón "Todo el colegio" y Autocomplete deshabilitados |

---

## Cambios en mensajeService.ts

### Firma de `enviarMensajeMasivo`
```typescript
// Antes
enviarMensajeMasivo(cursoId: string, asunto, contenido, prioridad, adjuntos)

// Después
enviarMensajeMasivo(cursoIds: string[], asunto, contenido, prioridad, adjuntos)
```

### Cuerpo (sin adjuntos)
```typescript
// Antes
{ cursoIds: [cursoId], asunto, contenido, prioridad, tipo: 'GRUPAL' }

// Después
{ cursoIds, asunto, contenido, prioridad, tipo: 'GRUPAL' }
```

### Cuerpo (con adjuntos — FormData)
```typescript
// Antes
formData.append("cursoIds", cursoId);

// Después
cursoIds.forEach(id => formData.append("cursoIds", id));
```

**El backend no requiere ningún cambio** — ya recibe `cursoIds` como array.

---

## Backup
Antes de modificar, guardar copia: `NuevoMensaje.tsx.bak` en la misma carpeta.

---

## Lo que NO cambia
- Colores, tipografía y tema de la app (paleta verde/teal)
- Lógica de adjuntos
- Modo responder mensaje
- Selector de prioridad
- Editor de contenido (ReactQuill)
- Backend
