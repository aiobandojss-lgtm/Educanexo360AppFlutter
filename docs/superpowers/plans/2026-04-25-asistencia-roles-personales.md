# Asistencia para Roles Personales (ESTUDIANTE / ACUDIENTE) — Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que ESTUDIANTE y ACUDIENTE accedan al módulo de Asistencia y vean únicamente su propia información, con una vista adaptada a esa perspectiva personal.

**Architecture:** Cuatro cambios quirúrgicos en el frontend: (1) agregar roles en rutas, (2) agregar ítems de menú, (3) desactivar hook de cursos para roles personales, (4) adaptar columnas de tabla según rol. Sin cambios en el backend.

**Tech Stack:** React + TypeScript, React Router v6, MUI, @tanstack/react-query, Redux (auth state)

---

## Contexto del sistema

- **Roles personales:** `ESTUDIANTE` y `ACUDIENTE` (el acudiente puede tener >1 hijo asociado en `user.info_academica.estudiantes_asociados`)
- **Roles grupales:** `ADMIN`, `DOCENTE`, `COORDINADOR`, `RECTOR`, `ADMINISTRATIVO`
- **Backend:** `GET /api/asistencia/resumen?estudianteId=&fechaInicio=&fechaFin=` ya acepta `estudianteId` y filtra para ese estudiante
- **`ListaAsistencia.tsx`** ya tiene la lógica de `esRolPersonal`, selector de hijos para ACUDIENTE, y auto-asignación del estudianteId para ESTUDIANTE — pero los roles nunca llegan a ver esa página por los bloqueos en rutas y menú

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `src/routes/AppRoutes.tsx` | Agregar ESTUDIANTE y ACUDIENTE a la ruta `/asistencia` |
| `src/components/layout/NavigationMenu.tsx` | Agregar ítem "Mi Asistencia" para ESTUDIANTE y ACUDIENTE |
| `src/hooks/useAppQueries.ts` | Desactivar `useAsistenciaCursos` para roles personales |
| `src/pages/asistencia/ListaAsistencia.tsx` | Suprimir error de cursos para roles personales; adaptar columnas de tabla |

---

## Task 1: Habilitar la ruta `/asistencia` para roles personales

**Files:**
- Modify: `src/routes/AppRoutes.tsx:474-481`

### Por qué
`ProtectedRoute` redirige a `/` cuando el usuario no está en `allowedRoles`. ESTUDIANTE y ACUDIENTE no están incluidos, por lo que son redirigidos silenciosamente al dashboard cuando intentan navegar a `/asistencia`. Las rutas de edición (`/asistencia/registro`, `/asistencia/editar/:id`) se mantienen restringidas — los roles personales no pueden crear ni editar registros.

- [ ] **Modificar la ruta `/asistencia`** en `src/routes/AppRoutes.tsx`:

```tsx
// ANTES (línea ~477):
<Route
  path="asistencia"
  element={
    <ProtectedRoute allowedRoles={["ADMIN", "DOCENTE", "COORDINADOR", "RECTOR", "ADMINISTRATIVO"]}>
      <ListaAsistencia />
    </ProtectedRoute>
  }
/>

// DESPUÉS:
<Route
  path="asistencia"
  element={
    <ProtectedRoute allowedRoles={["ADMIN", "DOCENTE", "COORDINADOR", "RECTOR", "ADMINISTRATIVO", "ESTUDIANTE", "ACUDIENTE"]}>
      <ListaAsistencia />
    </ProtectedRoute>
  }
/>
```

- [ ] **Modificar la ruta `/asistencia/:id`** para que ESTUDIANTE y ACUDIENTE puedan ver el detalle de un registro:

```tsx
// ANTES (línea ~491):
<Route
  path="asistencia/:id"
  element={
    <ProtectedRoute allowedRoles={["ADMIN", "DOCENTE", "COORDINADOR", "RECTOR", "ADMINISTRATIVO"]}>
      <DetalleAsistencia />
    </ProtectedRoute>
  }
/>

// DESPUÉS:
<Route
  path="asistencia/:id"
  element={
    <ProtectedRoute allowedRoles={["ADMIN", "DOCENTE", "COORDINADOR", "RECTOR", "ADMINISTRATIVO", "ESTUDIANTE", "ACUDIENTE"]}>
      <DetalleAsistencia />
    </ProtectedRoute>
  }
/>
```

- [ ] **Verificar** que las rutas de edición y creación NO incluyen estos roles (deben quedar intactas):
  - `/asistencia/registro` → solo `["ADMIN", "DOCENTE", "COORDINADOR", "RECTOR", "ADMINISTRATIVO"]` ✅
  - `/asistencia/editar/:id` → solo `["ADMIN", "DOCENTE", "COORDINADOR", "RECTOR", "ADMINISTRATIVO"]` ✅
  - `/asistencia/informes` → solo `["ADMIN", "DOCENTE", "COORDINADOR", "RECTOR", "ADMINISTRATIVO"]` ✅

- [ ] **Commit:**
```bash
git add src/routes/AppRoutes.tsx
git commit -m "feat: habilitar ruta /asistencia para ESTUDIANTE y ACUDIENTE"
```

---

## Task 2: Agregar ítem de navegación para roles personales

**Files:**
- Modify: `src/components/layout/NavigationMenu.tsx:252-302`

### Por qué
El menú lateral filtra ítems por `allowedRoles`. El ítem actual de "Asistencia" (con sub-ítems "Lista de Registros", "Nuevo Registro", "Informes") no incluye ESTUDIANTE ni ACUDIENTE. Para roles personales se debe mostrar un ítem diferente: "Mi Asistencia" que apunta a `/asistencia`, sin los sub-ítems de gestión.

- [ ] **Modificar el bloque de Asistencia** en `src/components/layout/NavigationMenu.tsx`.

Agregar un nuevo ítem raíz **después** del bloque de Asistencia existente (alrededor de la línea 302, después de la `}`que cierra el ítem de Asistencia actual):

```tsx
// Ítem de menú para ESTUDIANTE y ACUDIENTE — vista personal de asistencia
{
  title: "Mi Asistencia",
  icon: <ClipboardCheck {...iconProps} />,
  path: "/asistencia",
  allowedRoles: ["ESTUDIANTE", "ACUDIENTE"],
},
```

> **Importante:** Este ítem NO tiene `children`. Apunta directamente a `/asistencia`.
> El ítem existente de "Asistencia" (con sus children) conserva sus `allowedRoles` sin ESTUDIANTE/ACUDIENTE — queda intacto.

- [ ] **Commit:**
```bash
git add src/components/layout/NavigationMenu.tsx
git commit -m "feat: agregar ítem Mi Asistencia en nav para ESTUDIANTE y ACUDIENTE"
```

---

## Task 3: Desactivar el hook de cursos para roles personales

**Files:**
- Modify: `src/hooks/useAppQueries.ts` (función `useAsistenciaCursos`, línea ~358)

### Por qué
`useAsistenciaCursos` llama a `GET /api/cursos` que el backend niega con 403 a ESTUDIANTE y ACUDIENTE. Aunque el selector de cursos está oculto para `esRolPersonal`, el hook sigue ejecutándose, produciendo un error que `ListaAsistencia.tsx` muestra como alerta roja, bloqueando la vista de asistencia personal.

- [ ] **Modificar `useAsistenciaCursos`** en `src/hooks/useAppQueries.ts`:

```ts
// ANTES:
export const useAsistenciaCursos = () => {
  const { user } = useSelector((state: RootState) => state.auth);
  return useQuery({
    queryKey: QUERY_KEYS.ASISTENCIA_CURSOS,
    queryFn: () => asistenciaService.obtenerCursosDisponibles(),
    staleTime: 1000 * 60 * 10,
    enabled: !!user,
  });
};

// DESPUÉS:
export const useAsistenciaCursos = () => {
  const { user } = useSelector((state: RootState) => state.auth);
  const esRolPersonal = user?.tipo === "ESTUDIANTE" || user?.tipo === "ACUDIENTE";
  return useQuery({
    queryKey: QUERY_KEYS.ASISTENCIA_CURSOS,
    queryFn: () => asistenciaService.obtenerCursosDisponibles(),
    staleTime: 1000 * 60 * 10,
    enabled: !!user && !esRolPersonal,
  });
};
```

- [ ] **Commit:**
```bash
git add src/hooks/useAppQueries.ts
git commit -m "fix: deshabilitar useAsistenciaCursos para ESTUDIANTE y ACUDIENTE"
```

---

## Task 4: Adaptar la vista de la tabla para roles personales

**Files:**
- Modify: `src/pages/asistencia/ListaAsistencia.tsx`

### Por qué
La tabla actual muestra columnas de perspectiva grupal: "Total Estudiantes", "Presentes", "Ausentes", "Registrado Por". Para ESTUDIANTE/ACUDIENTE estas columnas no tienen sentido. Además, `errorCursos` se muestra aunque para roles personales el error de cursos es esperado (no tienen permiso), lo cual genera confusión.

Hay dos sub-cambios:

### Sub-cambio A: Suprimir error de cursos para roles personales

- [ ] **Modificar la variable `error`** en `ListaAsistencia.tsx` (alrededor de línea 127):

```tsx
// ANTES:
const error = errorCursos
  ? "No se pudieron cargar los cursos: " + ((errorCursos as any)?.response?.data?.message || "Error del servidor")
  : errorAsistencias
  ? "No se pudieron cargar las asistencias: " + ((errorAsistencias as any)?.response?.data?.message || "Error del servidor")
  : null;

// DESPUÉS:
const error = (!esRolPersonal && errorCursos)
  ? "No se pudieron cargar los cursos: " + ((errorCursos as any)?.response?.data?.message || "Error del servidor")
  : errorAsistencias
  ? "No se pudieron cargar las asistencias: " + ((errorAsistencias as any)?.response?.data?.message || "Error del servidor")
  : null;
```

### Sub-cambio B: Adaptar columnas de la tabla

Para roles personales, ocultar las columnas que no aplican y mostrar el mensaje correcto.

- [ ] **Modificar el `<TableHead>`** en `ListaAsistencia.tsx` (alrededor de línea 520):

```tsx
// ANTES:
<TableRow>
  <TableCell>Fecha</TableCell>
  <TableCell>Curso</TableCell>
  <TableCell align="center">Total Estudiantes</TableCell>
  <TableCell align="center">Presentes</TableCell>
  <TableCell align="center">Ausentes</TableCell>
  <TableCell align="center">% Asistencia</TableCell>
  <TableCell>Registrado Por</TableCell>
  <TableCell align="center">Estado</TableCell>
  <TableCell align="center">Acciones</TableCell>
</TableRow>

// DESPUÉS:
<TableRow>
  <TableCell>Fecha</TableCell>
  <TableCell>Curso</TableCell>
  {!esRolPersonal && <TableCell align="center">Total Estudiantes</TableCell>}
  {!esRolPersonal && <TableCell align="center">Presentes</TableCell>}
  {!esRolPersonal && <TableCell align="center">Ausentes</TableCell>}
  <TableCell align="center">% Asistencia</TableCell>
  {!esRolPersonal && <TableCell>Registrado Por</TableCell>}
  <TableCell align="center">Estado</TableCell>
  <TableCell align="center">Acciones</TableCell>
</TableRow>
```

- [ ] **Modificar las celdas del `<TableBody>`** para las mismas columnas condicionales:

```tsx
// En el map de asistencias, ajustar las celdas correspondientes:
<TableRow key={asistencia._id} hover ...>
  <TableCell>{format(new Date(asistencia.fecha), "dd/MM/yyyy")}</TableCell>
  <TableCell>
    <strong>{asistencia.curso.grado} {asistencia.curso.grupo}</strong>
  </TableCell>
  {!esRolPersonal && (
    <TableCell align="center">{asistencia.totalEstudiantes}</TableCell>
  )}
  {!esRolPersonal && (
    <TableCell align="center">
      {asistencia.presentes}
      <Typography variant="caption" color="text.secondary" sx={{ ml: 1 }}>
        ({Math.round((asistencia.presentes / asistencia.totalEstudiantes) * 100)}%)
      </Typography>
    </TableCell>
  )}
  {!esRolPersonal && (
    <TableCell align="center">
      {asistencia.ausentes}
      <Typography variant="caption" color="text.secondary" sx={{ ml: 1 }}>
        ({Math.round((asistencia.ausentes / asistencia.totalEstudiantes) * 100)}%)
      </Typography>
    </TableCell>
  )}
  <TableCell align="center">
    <Chip
      label={`${asistencia.porcentajeAsistencia}%`}
      color={
        asistencia.porcentajeAsistencia >= 90 ? "success"
        : asistencia.porcentajeAsistencia >= 75 ? "warning"
        : "error"
      }
      size="small"
      sx={{ borderRadius: 8 }}
    />
  </TableCell>
  {!esRolPersonal && (
    <TableCell>
      {asistencia.registradoPor?.nombre || "Usuario"}{" "}
      {asistencia.registradoPor?.apellidos || ""}
    </TableCell>
  )}
  <TableCell align="center">
    <Chip
      label={asistencia.finalizado ? "Finalizado" : "En proceso"}
      color={asistencia.finalizado ? "success" : "warning"}
      size="small"
      sx={{ borderRadius: 8 }}
    />
  </TableCell>
  <TableCell align="center">
    <Box sx={{ display: "flex", justifyContent: "center", gap: 1 }}>
      <Tooltip title="Ver detalles del registro">
        <IconButton
          size="small"
          color="info"
          onClick={() => verDetalle(asistencia._id)}
          sx={{ bgcolor: "rgba(93, 169, 233, 0.1)", "&:hover": { bgcolor: "rgba(93, 169, 233, 0.2)" } }}
        >
          <VisibilityIcon fontSize="small" />
        </IconButton>
      </Tooltip>
      {puedeEditar && !asistencia.finalizado && (
        <Tooltip title="Editar registro de asistencia">
          <IconButton
            size="small"
            color="primary"
            onClick={() => editarAsistencia(asistencia._id)}
            sx={{ bgcolor: "rgba(0, 63, 145, 0.1)", "&:hover": { bgcolor: "rgba(0, 63, 145, 0.2)" } }}
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}
    </Box>
  </TableCell>
</TableRow>
```

- [ ] **Ajustar `colSpan`** en las filas de estado vacío/cargando (cambia de 9 a 6 para roles personales):

```tsx
// ANTES (dos TableCell con colSpan={9}):
<TableCell colSpan={9} align="center" sx={{ py: 3 }}>

// DESPUÉS:
<TableCell colSpan={esRolPersonal ? 6 : 9} align="center" sx={{ py: 3 }}>
```

- [ ] **Commit:**
```bash
git add src/pages/asistencia/ListaAsistencia.tsx
git commit -m "fix: adaptar ListaAsistencia para vista personal de ESTUDIANTE y ACUDIENTE"
```

---

## Task 5: Verificación manual

- [ ] Iniciar el servidor: `npm run dev`
- [ ] **Login como ESTUDIANTE:**
  - Verificar que el menú lateral muestra "Mi Asistencia" (no el bloque de "Asistencia" con sub-ítems)
  - Navegar a `/asistencia` → debe cargar sin error y mostrar registros del período actual
  - Verificar que NO aparece el botón "Nuevo Registro"
  - Verificar que la tabla tiene 6 columnas (Fecha, Curso, % Asistencia, Estado, Acciones) sin columnas grupales
  - Verificar que hay un `Alert` de "Viendo tu propia asistencia"
- [ ] **Login como ACUDIENTE con 1 hijo:**
  - Verificar que el menú muestra "Mi Asistencia"
  - Navegar a `/asistencia` → debe mostrar registros del hijo
  - Verificar `Alert` con nombre del hijo
- [ ] **Login como ACUDIENTE con >1 hijos:**
  - Verificar que aparece el selector de hijos
  - Cambiar selección → tabla actualiza con el otro hijo
- [ ] **Login como ADMIN/DOCENTE:**
  - Verificar que el menú sigue mostrando "Asistencia" con todos sus sub-ítems
  - Verificar que la tabla tiene las 9 columnas originales
  - Verificar que funciona el selector de curso

---

## Alcance / Fuera de alcance

| ✅ Incluido | ❌ Fuera de alcance |
|------------|-------------------|
| Acceso a `/asistencia` y `/asistencia/:id` | Crear o editar registros de asistencia |
| Vista personal con columnas adaptadas | Acceso a `/asistencia/informes` |
| Selector de hijos para ACUDIENTE | Ver el estado PRESENTE/AUSENTE individual del estudiante (requiere cambio de endpoint en el backend) |
| Menú lateral "Mi Asistencia" | |
| Sin error falso de cursos | |
