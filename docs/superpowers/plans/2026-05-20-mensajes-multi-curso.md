# Mensajes Masivos Multi-Curso Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir seleccionar múltiples cursos en el envío masivo de mensajes, agregar botón "Todo el colegio" para admins, mostrar contador dinámico de destinatarios y limpiar el campo de búsqueda al seleccionar un destinatario individual.

**Architecture:** Cambios solo en frontend. El backend ya recibe `cursoIds` como array. Se modifica `mensajeService.ts` para aceptar array de IDs, y `NuevoMensaje.tsx` para reemplazar el `Select` simple por un `Autocomplete` múltiple con chips, igual al patrón del selector individual ya existente.

**Tech Stack:** React 18, TypeScript, MUI Autocomplete, Formik, Yup, mensajeService existente.

---

## Archivos a modificar

| Archivo | Acción | Responsabilidad |
|---------|--------|-----------------|
| `src/pages/mensajes/NuevoMensaje.tsx` | Modificar | UI multi-curso, lógica "Todo el colegio", fix selector individual |
| `src/pages/mensajes/NuevoMensaje.tsx.bak` | Crear (backup) | Copia de seguridad antes de tocar el archivo |
| `src/services/mensajeService.ts` | Modificar | Firma `enviarMensajeMasivo` acepta `string[]` |

---

## Task 1: Backup del archivo original

**Files:**
- Create: `src/pages/mensajes/NuevoMensaje.tsx.bak`

- [ ] **Step 1: Copiar el archivo actual como backup**

```bash
cp src/pages/mensajes/NuevoMensaje.tsx src/pages/mensajes/NuevoMensaje.tsx.bak
```

- [ ] **Step 2: Verificar que el backup existe**

```bash
ls src/pages/mensajes/NuevoMensaje.tsx.bak
```
Resultado esperado: el archivo existe con el mismo tamaño que el original.

- [ ] **Step 3: Commit del backup**

```bash
git add src/pages/mensajes/NuevoMensaje.tsx.bak
git commit -m "chore: backup NuevoMensaje antes de refactor multi-curso"
```

---

## Task 2: Actualizar firma de `enviarMensajeMasivo` en el servicio

**Files:**
- Modify: `src/services/mensajeService.ts`

- [ ] **Step 1: Localizar la función `enviarMensajeMasivo`**

Está en `src/services/mensajeService.ts` línea ~226. Firma actual:
```typescript
const enviarMensajeMasivo = async (
  cursoId: string,
  asunto: string,
  contenido: string,
  prioridad: string,
  adjuntos: File[] = []
)
```

- [ ] **Step 2: Cambiar la firma y el cuerpo para aceptar array**

Reemplazar la función completa:

```typescript
const enviarMensajeMasivo = async (
  cursoIds: string[],
  asunto: string,
  contenido: string,
  prioridad: string,
  adjuntos: File[] = []
) => {
  try {
    console.log("Preparando mensaje masivo para los cursos:", cursoIds);

    if (adjuntos.length === 0) {
      const response = await axiosInstance.post("/mensajes", {
        cursoIds,
        asunto,
        contenido,
        prioridad,
        tipo: TipoMensaje.GRUPAL,
      });
      return response.data;
    }

    const formData = new FormData();
    cursoIds.forEach(id => formData.append("cursoIds", id));
    formData.append("asunto", asunto);
    formData.append("contenido", contenido);
    formData.append("tipo", TipoMensaje.GRUPAL);
    formData.append("prioridad", prioridad);
    adjuntos.forEach((file) => {
      formData.append("adjuntos", file);
    });

    const response = await axiosFileInstance.post("/mensajes", formData);
    return response.data;
  } catch (error: any) {
    console.error("[Frontend] Error enviando mensaje masivo:", error);

    if (error.response?.status === 404) {
      throw new Error("Ruta no encontrada");
    } else if (error.response?.status === 400) {
      if (error.response.data?.message) {
        throw new Error(error.response.data.message);
      } else {
        throw new Error("El servidor rechazó la solicitud. Verifique los datos.");
      }
    } else if (error.response?.status === 403) {
      throw new Error("No tiene permisos para enviar mensajes masivos.");
    } else if (error.response?.status === 500) {
      const errorText =
        error.response.data?.message ||
        (typeof error.response.data === "string" ? error.response.data : null);
      if (errorText && errorText.includes("not a valid enum value")) {
        throw new Error(`Error de validación: El tipo de mensaje no es válido. ${errorText}`);
      } else {
        throw new Error("Error interno del servidor. Por favor contacte al administrador.");
      }
    } else {
      throw error;
    }
  }
};
```

- [ ] **Step 3: Verificar TypeScript sin errores**

```bash
npx tsc --noEmit
```
Resultado esperado: sin output (sin errores).

- [ ] **Step 4: Commit**

```bash
git add src/services/mensajeService.ts
git commit -m "feat: enviarMensajeMasivo acepta array de cursoIds"
```

---

## Task 3: Actualizar estado Formik y validación en NuevoMensaje.tsx

**Files:**
- Modify: `src/pages/mensajes/NuevoMensaje.tsx`

- [ ] **Step 1: Agregar estado local para cursos seleccionados**

Después de la línea `const [cursos, setCursos] = useState<Curso[]>([]);` agregar:

```typescript
const [cursosSeleccionados, setCursosSeleccionados] = useState<Curso[]>([]);
```

- [ ] **Step 2: Actualizar `validationSchema`**

Reemplazar el bloque de validación del masivo:
```typescript
// Antes
...(tipoMensaje === TIPOS_MENSAJE.INDIVIDUAL ? {
  destinatarios: Yup.array().min(1, 'Debe seleccionar al menos un destinatario')
} : {
  cursoId: Yup.string().required('Debe seleccionar un curso')
}),

// Después
...(tipoMensaje === TIPOS_MENSAJE.INDIVIDUAL ? {
  destinatarios: Yup.array().min(1, 'Debe seleccionar al menos un destinatario')
} : {
  cursoIds: Yup.array().min(1, 'Debe seleccionar al menos un curso')
}),
```

- [ ] **Step 3: Actualizar `initialValues` en formik**

```typescript
// Antes
initialValues: {
  destinatarios: [] as string[],
  asunto: '',
  contenido: '',
  cursoId: '',
  prioridad: 'NORMAL' as 'ALTA' | 'NORMAL' | 'BAJA'
},

// Después
initialValues: {
  destinatarios: [] as string[],
  asunto: '',
  contenido: '',
  cursoIds: [] as string[],
  prioridad: 'NORMAL' as 'ALTA' | 'NORMAL' | 'BAJA'
},
```

- [ ] **Step 4: Actualizar `onSubmit` para pasar `cursoIds`**

```typescript
// Antes
await mensajeService.enviarMensajeMasivo(
  values.cursoId,
  values.asunto,
  values.contenido,
  values.prioridad,
  adjuntos
);

// Después
await mensajeService.enviarMensajeMasivo(
  values.cursoIds,
  values.asunto,
  values.contenido,
  values.prioridad,
  adjuntos
);
```

- [ ] **Step 5: Limpiar `cursoIds` al cambiar a modo individual en `handleChangeTipoMensaje`**

```typescript
// Antes
if (nuevoTipo === TIPOS_MENSAJE.INDIVIDUAL) {
  formik.setFieldValue('cursoId', '');
} else {

// Después
if (nuevoTipo === TIPOS_MENSAJE.INDIVIDUAL) {
  formik.setFieldValue('cursoIds', []);
  setCursosSeleccionados([]);
} else {
```

- [ ] **Step 6: Verificar TypeScript sin errores**

```bash
npx tsc --noEmit
```
Resultado esperado: sin output.

- [ ] **Step 7: Commit**

```bash
git add src/pages/mensajes/NuevoMensaje.tsx
git commit -m "feat: formik cursoId → cursoIds array en NuevoMensaje"
```

---

## Task 4: Reemplazar Select por Autocomplete múltiple con chips

**Files:**
- Modify: `src/pages/mensajes/NuevoMensaje.tsx`

- [ ] **Step 1: Agregar variable `totalEstudiantes`**

Antes del `return (` agregar:

```typescript
const totalEstudiantes = cursosSeleccionados.reduce(
  (sum, c) => sum + (c.cantidadEstudiantes ?? 0), 0
);
```

- [ ] **Step 2: Reemplazar el bloque JSX del selector de curso**

Localizar el bloque que empieza con:
```typescript
) : (
  <Grid item xs={12}>
    <FormControl 
      fullWidth 
      error={formik.touched.cursoId && Boolean(formik.errors.cursoId)}
    >
```
...y termina con:
```typescript
    </FormControl>
  </Grid>
)}
```

Reemplazarlo completamente por:

```tsx
) : (
  <Grid item xs={12}>
    <Box sx={{ mb: 1 }}>
      <Typography variant="subtitle1" gutterBottom>
        Cursos destinatarios
      </Typography>

      <Autocomplete
        multiple
        id="cursos-autocomplete"
        options={cursos.filter(c => !formik.values.cursoIds.includes(c._id))}
        getOptionLabel={(option) =>
          `${option.nombre} (${option.cantidadEstudiantes} estudiantes)`
        }
        value={cursosSeleccionados}
        onChange={(_event, newValue) => {
          setCursosSeleccionados(newValue);
          formik.setFieldValue('cursoIds', newValue.map(c => c._id));
        }}
        disabled={loading}
        noOptionsText="No hay más cursos disponibles"
        renderTags={(value, getTagProps) =>
          value.map((curso, index) => (
            <Chip
              key={curso._id}
              label={`${curso.nombre} (${curso.cantidadEstudiantes} est.)`}
              color="primary"
              variant="outlined"
              {...getTagProps({ index })}
            />
          ))
        }
        renderOption={(props, option) => (
          <li {...props} key={option._id}>
            <Box>
              <Typography variant="body1">{option.nombre}</Typography>
              <Typography variant="caption" color="text.secondary">
                {option.cantidadEstudiantes} estudiantes
                {option.infoAdicional ? ` · ${option.infoAdicional}` : ''}
              </Typography>
            </Box>
          </li>
        )}
        renderInput={(params) => (
          <TextField
            {...params}
            label="Buscar curso"
            placeholder={cursosSeleccionados.length === 0 ? "Buscar y seleccionar cursos..." : ""}
            error={formik.touched.cursoIds && Boolean(formik.errors.cursoIds)}
            helperText={
              formik.touched.cursoIds && formik.errors.cursoIds
                ? (formik.errors.cursoIds as string)
                : undefined
            }
          />
        )}
        sx={{ mb: 1 }}
      />

      {cursosSeleccionados.length > 0 && (
        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
          📊 {cursosSeleccionados.length} curso{cursosSeleccionados.length !== 1 ? 's' : ''} seleccionado{cursosSeleccionados.length !== 1 ? 's' : ''} · {totalEstudiantes} estudiantes en total
        </Typography>
      )}
    </Box>
  </Grid>
)}
```

- [ ] **Step 3: Verificar TypeScript sin errores**

```bash
npx tsc --noEmit
```
Resultado esperado: sin output.

- [ ] **Step 4: Commit**

```bash
git add src/pages/mensajes/NuevoMensaje.tsx
git commit -m "feat: selector masivo multi-curso con Autocomplete y chips"
```

---

## Task 5: Agregar botón "Todo el colegio" para roles administrativos

**Files:**
- Modify: `src/pages/mensajes/NuevoMensaje.tsx`

- [ ] **Step 1: Definir variable de roles con acceso al botón**

Después de la línea donde se define `puedeEnviarMasivo` agregar:

```typescript
const puedeSeleccionarTodo = user?.tipo === USER_ROLES.ADMIN ||
                             user?.tipo === USER_ROLES.RECTOR ||
                             user?.tipo === USER_ROLES.COORDINADOR ||
                             user?.tipo === USER_ROLES.ADMINISTRATIVO;
```

- [ ] **Step 2: Agregar handler `handleSeleccionarTodos`**

Después del handler `handleRetry` agregar:

```typescript
const handleSeleccionarTodos = () => {
  if (cursosSeleccionados.length === cursos.length) {
    // Toggle: si ya están todos, deseleccionar
    setCursosSeleccionados([]);
    formik.setFieldValue('cursoIds', []);
  } else {
    // Seleccionar todos
    setCursosSeleccionados(cursos);
    formik.setFieldValue('cursoIds', cursos.map(c => c._id));
  }
};
```

- [ ] **Step 3: Insertar el botón en el JSX, encima del Autocomplete de cursos**

Dentro del bloque del modo masivo, justo antes del `<Autocomplete multiple ...`:

```tsx
{puedeSeleccionarTodo && cursos.length > 0 && (
  <Box sx={{ mb: 2 }}>
    <Button
      variant={cursosSeleccionados.length === cursos.length ? 'contained' : 'outlined'}
      color="primary"
      size="small"
      startIcon={<SchoolIcon />}
      onClick={handleSeleccionarTodos}
      disabled={loading}
      sx={{ borderRadius: '20px' }}
    >
      {cursosSeleccionados.length === cursos.length
        ? 'Deseleccionar todo el colegio'
        : 'Todo el colegio'}
    </Button>
  </Box>
)}
```

- [ ] **Step 4: Verificar TypeScript sin errores**

```bash
npx tsc --noEmit
```
Resultado esperado: sin output.

- [ ] **Step 5: Commit**

```bash
git add src/pages/mensajes/NuevoMensaje.tsx
git commit -m "feat: botón Todo el colegio para roles administrativos"
```

---

## Task 6: Fix selector individual — limpiar campo tras selección

**Files:**
- Modify: `src/pages/mensajes/NuevoMensaje.tsx`

- [ ] **Step 1: Agregar estado `inputValueDestinatario`**

Después de la línea `const [query, setQuery] = useState<string>('');` agregar:

```typescript
const [inputValueDestinatario, setInputValueDestinatario] = useState<string>('');
```

- [ ] **Step 2: Actualizar `handleDestinatarioSeleccionado` para limpiar el input**

```typescript
// Antes
const handleDestinatarioSeleccionado = (_: any, value: Usuario | null) => {
  if (value && !destinatariosSeleccionados.find(d => d._id === value._id)) {
    setDestinatariosSeleccionados([...destinatariosSeleccionados, value]);
    formik.setFieldValue('destinatarios', [
      ...formik.values.destinatarios,
      value._id
    ]);
  }
  if (!isAcudiente) {
    setQuery('');
  }
};

// Después
const handleDestinatarioSeleccionado = (_: any, value: Usuario | null) => {
  if (value && !destinatariosSeleccionados.find(d => d._id === value._id)) {
    setDestinatariosSeleccionados([...destinatariosSeleccionados, value]);
    formik.setFieldValue('destinatarios', [
      ...formik.values.destinatarios,
      value._id
    ]);
  }
  setInputValueDestinatario('');
  if (!isAcudiente) {
    setQuery('');
  }
};
```

- [ ] **Step 3: Conectar `inputValue` controlado en el Autocomplete individual**

Localizar el `<Autocomplete id="destinatarios-autocomplete" ...>` y agregar las props `inputValue` y `onInputChange`:

```tsx
<Autocomplete
  id="destinatarios-autocomplete"
  options={destinatarios}
  getOptionLabel={(option) => getDestinatarioLabel(option)}
  loading={buscando}
  onChange={handleDestinatarioSeleccionado}
  inputValue={inputValueDestinatario}
  onInputChange={(_, value, reason) => {
    setInputValueDestinatario(value);
    if (!isAcudiente && reason !== 'reset') setQuery(value);
  }}
  noOptionsText={...}
  // ... resto de props sin cambios
```

- [ ] **Step 4: Verificar TypeScript sin errores**

```bash
npx tsc --noEmit
```
Resultado esperado: sin output.

- [ ] **Step 5: Commit**

```bash
git add src/pages/mensajes/NuevoMensaje.tsx
git commit -m "fix: limpiar campo de búsqueda al seleccionar destinatario individual"
```

---

## Task 7: Verificación final

- [ ] **Step 1: Build de producción sin errores**

```bash
npm run build
```
Resultado esperado: `✓ built in Xs` sin errores.

- [ ] **Step 2: Verificar flujo masivo — múltiples cursos**
  - Ingresar como DOCENTE → modo masivo → verificar que NO aparece botón "Todo el colegio"
  - Ingresar como ADMIN/RECTOR → modo masivo → verificar que SÍ aparece botón "Todo el colegio"
  - Seleccionar 2-3 cursos → verificar chips y contador `📊 X cursos · Y estudiantes`
  - Clic "Todo el colegio" → todos los cursos seleccionados como chips
  - Clic de nuevo → se deseleccionan todos
  - Enviar mensaje con 2 cursos → verificar en MongoDB Compass que el mensaje tiene `cursoIds` con 2 IDs

- [ ] **Step 3: Verificar flujo individual — campo se limpia**
  - Buscar un destinatario → seleccionarlo → campo de búsqueda debe quedar vacío
  - Buscar otro destinatario sin tener que borrar manualmente → funciona

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "feat: mensajes masivos multi-curso completo — Autocomplete, Todo el colegio, fix selector individual"
```
