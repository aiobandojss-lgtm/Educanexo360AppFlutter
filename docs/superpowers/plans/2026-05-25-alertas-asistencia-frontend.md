# Alertas Automáticas de Asistencia — Plan Frontend React

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar en `InformeRiesgo` una columna "Alerta enviada" que consume el nuevo endpoint `GET /api/asistencia/alertas` del backend, indicando con chips de color qué nivel de alerta fue enviado por estudiante.

**Architecture:** Modificaciones quirúrgicas en 3 archivos existentes — service, hook, y componente. Sin páginas nuevas. El componente InformeRiesgo ya tiene la tabla de estudiantes en riesgo; se agrega una columna al final.

**Tech Stack:** React 18 + TypeScript + Material UI + React Query (TanStack Query) — ya configurados en el proyecto.

**Prerequisito:** El backend debe tener el endpoint `GET /api/asistencia/alertas` funcionando antes de ejecutar este plan.

**Spec de referencia:** `docs/superpowers/specs/2026-05-25-alertas-automaticas-asistencia-design.md`

---

## Mapa de archivos

| Archivo | Acción | Responsabilidad |
|---------|--------|-----------------|
| `src/services/asistenciaInformesService.ts` | Modificar | Agregar interface `AlertaAsistencia` + función `getAlertasAsistencia` |
| `src/hooks/useAppQueries.ts` | Modificar | Agregar hook `useAlertasAsistencia` |
| `src/components/asistencia/informes/InformeRiesgo.tsx` | Modificar | Consumir hook + agregar columna "Alerta enviada" en la tabla |

---

## Task 1: Interface y función en el service

**Files:**
- Modify: `src/services/asistenciaInformesService.ts`

- [ ] **1.1 Leer el archivo actual para entender su estructura**

Abrir `src/services/asistenciaInformesService.ts` y verificar:
- Cómo se hace la instancia de axios (¿`api` de `axiosConfig`, `axios` directo, otra?)
- Dónde terminan las interfaces exportadas existentes
- El patrón de las funciones existentes

- [ ] **1.2 Agregar la interface AlertaAsistencia al final de las interfaces del archivo**

```typescript
export interface AlertaAsistencia {
  _id: string;
  estudianteId: {
    _id: string;
    nombre: string;
    apellidos: string;
  };
  cursoId: {
    _id: string;
    nombre: string;
  };
  nivel: 'ALERTA' | 'CRITICO' | 'INMINENTE';
  porcentajeAusencias: number;
  periodoId: string;
  fechaEnvio: string;
}
```

- [ ] **1.3 Agregar la función getAlertasAsistencia al final del archivo**

```typescript
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

> **Nota:** Reemplazar `api` por el nombre real del cliente axios del archivo (puede ser `axiosInstance`, `http`, etc.).

- [ ] **1.4 Verificar TypeScript**

```bash
npx tsc --noEmit
```

Debe completar sin errores relacionados al nuevo código.

- [ ] **1.5 Commit**

```bash
git add src/services/asistenciaInformesService.ts
git commit -m "feat: agregar interface AlertaAsistencia y getAlertasAsistencia al service"
```

---

## Task 2: Hook useAlertasAsistencia

**Files:**
- Modify: `src/hooks/useAppQueries.ts`

- [ ] **2.1 Leer el archivo para verificar el patrón de hooks existentes**

Abrir `src/hooks/useAppQueries.ts`. Confirmar:
- El import de `useQuery` (¿de `@tanstack/react-query` o `react-query`?)
- Cómo están definidos los hooks similares: `useInformeRiesgo`, `useInformeTendencia`, etc.

- [ ] **2.2 Agregar el import de getAlertasAsistencia**

En la sección de imports del archivo, agregar `getAlertasAsistencia` y `AlertaAsistencia` al import existente de `asistenciaInformesService`:

```typescript
// Modificar la línea existente que importa de asistenciaInformesService:
import {
  // ... imports existentes ...,
  getAlertasAsistencia,
  AlertaAsistencia,
} from '../services/asistenciaInformesService';
```

- [ ] **2.3 Agregar el hook al final del archivo**

```typescript
export const useAlertasAsistencia = (params: {
  cursoId?: string;
  periodoId?: string;
}) =>
  useQuery<AlertaAsistencia[]>({
    queryKey: ['alertas-asistencia', params],
    queryFn: () => getAlertasAsistencia(params),
    enabled: !!(params.cursoId || params.periodoId),
    staleTime: 5 * 60 * 1000, // 5 minutos — las alertas no cambian frecuentemente
  });
```

- [ ] **2.4 Verificar TypeScript**

```bash
npx tsc --noEmit
```

- [ ] **2.5 Commit**

```bash
git add src/hooks/useAppQueries.ts
git commit -m "feat: agregar hook useAlertasAsistencia"
```

---

## Task 3: Columna "Alerta enviada" en InformeRiesgo

**Files:**
- Modify: `src/components/asistencia/informes/InformeRiesgo.tsx`

- [ ] **3.1 Leer el archivo completo**

Abrir `src/components/asistencia/informes/InformeRiesgo.tsx` y entender:
- Qué filtros tiene (cursoId, umbral de riesgo)
- Cómo está construida la tabla (TableHead, TableRow, TableCell)
- Qué datos tiene disponibles por fila de estudiante (nombre, porcentaje, etc.)
- Qué imports de MUI ya están presentes

- [ ] **3.2 Agregar import del hook**

En la sección de imports del componente:

```typescript
import { useAlertasAsistencia } from '../../../hooks/useAppQueries';
```

- [ ] **3.3 Agregar imports de MUI necesarios**

Verificar que estén presentes en los imports de MUI (agregar los que falten):

```typescript
import {
  // ... imports existentes ...,
  Chip,
  Tooltip,
} from '@mui/material';
```

- [ ] **3.4 Consumir el hook en el componente**

Dentro del componente `InformeRiesgo`, después de los hooks existentes, agregar:

```typescript
// cursoId ya existe como estado/prop en el componente — usar el nombre real
const { data: alertas = [] } = useAlertasAsistencia({
  cursoId: cursoIdSeleccionado || undefined,
});

// Mapa de estudianteId → alerta de mayor nivel para lookup O(1)
const ORDEN_NIVEL: Record<string, number> = { INMINENTE: 3, CRITICO: 2, ALERTA: 1 };

const alertaPorEstudiante = useMemo(() => {
  const mapa = new Map<string, AlertaAsistencia>();
  for (const alerta of alertas) {
    const idEst = alerta.estudianteId._id;
    const existente = mapa.get(idEst);
    if (!existente || ORDEN_NIVEL[alerta.nivel] > ORDEN_NIVEL[existente.nivel]) {
      mapa.set(idEst, alerta);
    }
  }
  return mapa;
}, [alertas]);
```

> **Nota:** `cursoIdSeleccionado` — usar el nombre real del estado de selección de curso en el componente. Puede llamarse `cursoId`, `selectedCurso`, `filters.cursoId`, etc.

> **Nota:** Agregar `AlertaAsistencia` al import de `asistenciaInformesService` si el componente ya importa de ese archivo, o agregar un nuevo import.

- [ ] **3.5 Agregar columna al TableHead**

En el `<TableHead>`, al final de los `<TableCell>` de encabezado existentes, agregar:

```tsx
<TableCell align="center" sx={{ fontWeight: 'bold', whiteSpace: 'nowrap' }}>
  Alerta enviada
</TableCell>
```

- [ ] **3.6 Agregar celda de alerta a cada TableRow**

En el `<TableBody>`, dentro del map de filas de estudiantes, al final de los `<TableCell>` existentes, agregar:

```tsx
{/* Celda de alerta — al final de cada fila de estudiante */}
<TableCell align="center">
  {(() => {
    const alerta = alertaPorEstudiante.get(estudiante._id ?? estudiante.estudianteId);
    if (!alerta) {
      return (
        <Chip
          label="Sin alerta"
          size="small"
          sx={{ backgroundColor: '#e0e0e0', color: '#757575' }}
        />
      );
    }

    const config: Record<string, { label: string; color: string; bg: string }> = {
      ALERTA:    { label: 'ALERTA',    color: '#fff', bg: '#F59E0B' },
      CRITICO:   { label: 'CRÍTICO',   color: '#fff', bg: '#EF4444' },
      INMINENTE: { label: 'INMINENTE', color: '#fff', bg: '#7F1D1D' },
    };

    const { label, color, bg } = config[alerta.nivel];
    const fecha = new Date(alerta.fechaEnvio).toLocaleDateString('es-CO', {
      day: '2-digit', month: 'short',
    });

    return (
      <Tooltip title={`Enviada el ${fecha}`} arrow>
        <Chip
          label={label}
          size="small"
          sx={{ backgroundColor: bg, color, fontWeight: 'bold', cursor: 'default' }}
        />
      </Tooltip>
    );
  })()}
</TableCell>
```

> **Nota:** `estudiante._id ?? estudiante.estudianteId` — usar el nombre real del campo ID del estudiante en el objeto de cada fila. En InformeRiesgo puede ser `est.estudianteId`, `est._id`, etc. Verificar con el tipo del objeto de fila.

- [ ] **3.7 Agregar `useMemo` al import de React si no está**

```typescript
import React, { useMemo, ... } from 'react';
// o si ya está: agregar useMemo a los imports desestructurados existentes
```

- [ ] **3.8 Verificar TypeScript**

```bash
npx tsc --noEmit
```

- [ ] **3.9 Commit**

```bash
git add src/components/asistencia/informes/InformeRiesgo.tsx
git commit -m "feat: agregar columna Alerta enviada en InformeRiesgo con chips de color"
```

---

## Task 4: Verificación en el navegador

- [ ] **4.1 Levantar el servidor de desarrollo**

```bash
npm run dev
```

- [ ] **4.2 Verificar columna con datos reales**

1. Iniciar sesión como rector o coordinador
2. Ir a Asistencia → Informes → Riesgo
3. Seleccionar un curso
4. Confirmar que la columna "Alerta enviada" aparece al final de la tabla
5. Si hay alertas en BD: confirmar chips de color (naranja ALERTA, rojo CRÍTICO, rojo oscuro INMINENTE)
6. Si no hay alertas: confirmar chips grises "Sin alerta"

- [ ] **4.3 Verificar tooltip**

Hacer hover sobre un chip de alerta → debe aparecer tooltip con la fecha de envío en español (ej: "Enviada el 25 may").

- [ ] **4.4 Verificar que sin cursoId seleccionado no hay llamada al endpoint**

Con el Network tab del browser abierto, sin seleccionar curso en el informe → confirmar que no se hace `GET /api/asistencia/alertas` (el hook tiene `enabled: !!cursoId`).

- [ ] **4.5 Commit final**

```bash
git add .
git commit -m "feat: columna alertas asistencia en InformeRiesgo — verificado en navegador"
```
