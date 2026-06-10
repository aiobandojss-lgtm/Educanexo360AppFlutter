# PDF Informes de Asistencia — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar exportación PDF en tres informes de asistencia: Historial de estudiante, Riesgo, y un nuevo tab de Cierre de Período.

**Architecture:** Utilidades de generación de PDF puras en `src/utils/pdfGenerators/` — reciben datos ya cargados, generan y descargan el PDF sin llamadas a API. Los componentes existentes se modifican mínimamente para agregar el botón; el nuevo componente `InformeCierrePeriodo` hace la llamada al endpoint propio.

**Tech Stack:** jsPDF 2.x + jspdf-autotable 3.x (generación en browser), React + TypeScript + MUI, date-fns (ya instalado).

---

## Mapa de archivos

| Acción | Archivo | Responsabilidad |
|--------|---------|-----------------|
| Crear | `src/utils/pdfGenerators/pdfBase.ts` | Encabezado institucional + footer compartidos |
| Crear | `src/utils/pdfGenerators/pdfHistorial.ts` | Genera PDF del historial de asistencia de un estudiante |
| Crear | `src/utils/pdfGenerators/pdfRiesgo.ts` | Genera PDF del informe de estudiantes en riesgo |
| Crear | `src/utils/pdfGenerators/pdfCierrePeriodo.ts` | Genera PDF de cierre de período por curso |
| Crear | `src/components/asistencia/informes/InformeCierrePeriodo.tsx` | UI con selectores de período/curso + botón generar PDF |
| Modificar | `src/services/asistenciaInformesService.ts` | Agregar interfaz `EstadisticaEstudiantePeriodo` y función `getResumenPeriodo` |
| Modificar | `src/components/asistencia/informes/InformeHistorialEstudiante.tsx` | Agregar botón "Descargar PDF" cuando hay datos cargados |
| Modificar | `src/components/asistencia/informes/InformeRiesgo.tsx` | Agregar botón "Descargar PDF" cuando hay estudiantes en riesgo |
| Modificar | `src/pages/asistencia/InformesAsistencia.tsx` | Agregar 6ª pestaña "Cierre de Período" |

---

## Tarea 1 — Instalar dependencias

**Archivos:** ninguno (solo package.json)

- [ ] **Paso 1: Instalar jsPDF y jspdf-autotable**

```bash
npm install jspdf jspdf-autotable
```

Salida esperada: las dos dependencias agregadas a `node_modules/` y `package.json`. No se espera ningún error de compilación.

- [ ] **Paso 2: Verificar tipos disponibles**

```bash
npx tsc --noEmit 2>&1 | head -20
```

Salida esperada: sin errores nuevos. jsPDF y jspdf-autotable incluyen sus propios tipos (`@types` no es necesario).

- [ ] **Paso 3: Commit**

```bash
git add package.json package-lock.json
git commit -m "chore: agregar jspdf y jspdf-autotable para generación de PDF en browser"
```

---

## Tarea 2 — Agregar `getResumenPeriodo` al servicio de informes

**Archivos:**
- Modificar: `src/services/asistenciaInformesService.ts`

- [ ] **Paso 1: Agregar interfaz y función al final del archivo**

Al final de `src/services/asistenciaInformesService.ts`, después de la última función exportada, agregar:

```typescript
export interface EstadisticaEstudiantePeriodo {
  estudianteId: string;
  nombreEstudiante: string;
  clasesTotales: number;
  presentes: number;
  ausentes: number;
  tardanzas: number;
  justificados: number;
  permisos: number;
  porcentajeAsistencia: number;
}

export const getResumenPeriodo = async (
  periodoId: string,
  cursoId: string
): Promise<EstadisticaEstudiantePeriodo[]> => {
  const response = await axiosInstance.get(
    `/asistencia/resumen/periodo/${periodoId}`,
    { params: { cursoId } }
  );
  return response.data.data;
};
```

- [ ] **Paso 2: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 3: Commit**

```bash
git add src/services/asistenciaInformesService.ts
git commit -m "feat: agregar getResumenPeriodo en asistenciaInformesService"
```

---

## Tarea 3 — Crear `pdfBase.ts` — encabezado y footer institucional compartidos

**Archivos:**
- Crear: `src/utils/pdfGenerators/pdfBase.ts`

- [ ] **Paso 1: Crear la carpeta y el archivo base**

Crear `src/utils/pdfGenerators/pdfBase.ts` con el siguiente contenido completo:

```typescript
import jsPDF from 'jspdf';

export interface DatosEncabezado {
  nombreColegio: string;
  ciudad?: string;
  titulo: string;
  colorPrimario: [number, number, number];
  generadoPor: string;
}

/**
 * Dibuja la banda de color superior con nombre del colegio, ciudad, título y fecha.
 * Devuelve la coordenada Y donde termina el encabezado (punto de partida del contenido).
 */
export const agregarEncabezado = (doc: jsPDF, datos: DatosEncabezado): number => {
  const { nombreColegio, ciudad, titulo, colorPrimario, generadoPor } = datos;
  const pageWidth = doc.internal.pageSize.getWidth();

  doc.setFillColor(colorPrimario[0], colorPrimario[1], colorPrimario[2]);
  doc.rect(0, 0, pageWidth, 33, 'F');

  doc.setTextColor(255, 255, 255);
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.text(nombreColegio, 15, 13);

  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  if (ciudad) {
    doc.text(ciudad, 15, 20);
  }

  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  doc.text(titulo, pageWidth - 15, 13, { align: 'right' });

  doc.setFontSize(8);
  doc.setFont('helvetica', 'normal');
  const fecha = new Date().toLocaleDateString('es-CO', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
  doc.text(`Generado: ${fecha}`, pageWidth - 15, 20, { align: 'right' });
  doc.text(`Por: ${generadoPor}`, pageWidth - 15, 27, { align: 'right' });

  doc.setTextColor(0, 0, 0);
  return 42;
};

/**
 * Agrega línea separadora + texto de footer y número de página en TODAS las páginas.
 * Llamar siempre DESPUÉS de generar todo el contenido.
 */
export const agregarFooter = (doc: jsPDF, textoIzq: string): void => {
  const pageCount = doc.getNumberOfPages();
  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();

  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setDrawColor(200, 200, 200);
    doc.line(15, pageHeight - 16, pageWidth - 15, pageHeight - 16);
    doc.setFontSize(8);
    doc.setTextColor(150, 150, 150);
    doc.text(textoIzq, 15, pageHeight - 10);
    doc.text(`${i} / ${pageCount}`, pageWidth - 15, pageHeight - 10, { align: 'right' });
    doc.setTextColor(0, 0, 0);
  }
};
```

- [ ] **Paso 2: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 3: Commit**

```bash
git add src/utils/pdfGenerators/pdfBase.ts
git commit -m "feat: crear pdfBase con encabezado y footer institucional compartidos"
```

---

## Tarea 4 — Crear `pdfHistorial.ts`

**Archivos:**
- Crear: `src/utils/pdfGenerators/pdfHistorial.ts`

- [ ] **Paso 1: Crear el archivo**

```typescript
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import type { RespuestaHistorial } from '../../services/asistenciaInformesService';
import type { Escuela } from '../../services/escuelaService';
import type { ParamsHistorial } from '../../services/asistenciaInformesService';
import { agregarEncabezado, agregarFooter } from './pdfBase';

type EstadoKey = 'PRESENTE' | 'AUSENTE' | 'TARDANZA' | 'JUSTIFICADO' | 'PERMISO';

const ESTADO_COLORES: Record<EstadoKey, { fondo: [number, number, number]; texto: [number, number, number] }> = {
  PRESENTE:    { fondo: [209, 250, 229], texto: [6, 95, 70] },
  AUSENTE:     { fondo: [254, 226, 226], texto: [153, 27, 27] },
  TARDANZA:    { fondo: [254, 243, 199], texto: [146, 64, 14] },
  JUSTIFICADO: { fondo: [219, 234, 254], texto: [30, 64, 175] },
  PERMISO:     { fondo: [243, 244, 246], texto: [55, 65, 81] },
};

const ESTADO_LABELS: Record<EstadoKey, string> = {
  PRESENTE: 'Presente',
  AUSENTE: 'Ausente',
  TARDANZA: 'Tardanza',
  JUSTIFICADO: 'Justificado',
  PERMISO: 'Permiso',
};

const formatFecha = (iso: string): string =>
  iso.substring(0, 10).split('-').reverse().join('/');

export const generarPdfHistorial = (
  data: RespuestaHistorial,
  escuela: Escuela | null,
  generadoPor: string,
  params: ParamsHistorial
): void => {
  const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();

  let y = agregarEncabezado(doc, {
    nombreColegio: escuela?.nombre ?? 'Institución Educativa',
    ciudad: escuela?.direccion,
    titulo: 'Historial de Asistencia',
    colorPrimario: [5, 150, 105],
    generadoPor,
  });

  // Bloque datos del estudiante
  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  doc.text(`${data.estudiante.nombre} ${data.estudiante.apellidos}`, 15, y);
  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(80, 80, 80);
  doc.text(
    `Período: ${formatFecha(params.desde)} — ${formatFecha(params.hasta)}`,
    15,
    y + 6
  );
  doc.setTextColor(0, 0, 0);
  y += 16;

  // 5 tarjetas de resumen en fila
  const metricas: { label: string; valor: string }[] = [
    { label: 'Clases', valor: String(data.resumen.clasesTotales) },
    { label: 'Presentes', valor: String(data.resumen.presentes) },
    { label: 'Ausentes', valor: String(data.resumen.ausentes) },
    { label: 'Tardanzas', valor: String(data.resumen.tardanzas) },
    { label: '% Asistencia', valor: `${data.resumen.porcentajeAsistencia.toFixed(1)}%` },
  ];
  const cardW = (pageWidth - 30) / 5;
  metricas.forEach((m, i) => {
    const x = 15 + i * cardW;
    doc.setFillColor(240, 253, 244);
    doc.rect(x, y, cardW - 2, 17, 'F');
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(5, 150, 105);
    doc.text(m.valor, x + (cardW - 2) / 2, y + 8, { align: 'center' });
    doc.setFontSize(7);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100, 100, 100);
    doc.text(m.label, x + (cardW - 2) / 2, y + 14, { align: 'center' });
  });
  doc.setTextColor(0, 0, 0);
  y += 23;

  // Tabla detalle
  autoTable(doc, {
    startY: y,
    head: [['Fecha', 'Día', 'Asignatura', 'Estado', 'Observaciones']],
    body: data.registros.map((r) => [
      formatFecha(r.fecha),
      r.diaSemana,
      r.asignatura?.nombre ?? '—',
      ESTADO_LABELS[r.estado as EstadoKey] ?? r.estado,
      r.justificacion || r.observaciones || '—',
    ]),
    headStyles: { fillColor: [5, 150, 105], textColor: 255, fontStyle: 'bold', fontSize: 8 },
    bodyStyles: { fontSize: 8 },
    columnStyles: { 3: { halign: 'center' } },
    didParseCell: (hookData) => {
      if (hookData.section === 'body' && hookData.column.index === 3) {
        const estado = data.registros[hookData.row.index]?.estado as EstadoKey;
        const config = ESTADO_COLORES[estado];
        if (config) {
          hookData.cell.styles.fillColor = config.fondo;
          hookData.cell.styles.textColor = config.texto;
          hookData.cell.styles.fontStyle = 'bold';
        }
      }
    },
    margin: { left: 15, right: 15 },
  });

  agregarFooter(doc, `Generado por: ${generadoPor}`);

  const apellidos = data.estudiante.apellidos.toLowerCase().replace(/\s+/g, '-');
  const nombre = data.estudiante.nombre.toLowerCase().replace(/\s+/g, '-');
  const fechaHoy = new Date().toISOString().substring(0, 10).replace(/-/g, '');
  doc.save(`historial-${apellidos}-${nombre}-${fechaHoy}.pdf`);
};
```

- [ ] **Paso 2: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 3: Commit**

```bash
git add src/utils/pdfGenerators/pdfHistorial.ts
git commit -m "feat: crear generador PDF para historial de asistencia de estudiante"
```

---

## Tarea 5 — Agregar botón PDF a `InformeHistorialEstudiante.tsx`

**Archivos:**
- Modificar: `src/components/asistencia/informes/InformeHistorialEstudiante.tsx`

- [ ] **Paso 1: Actualizar imports**

Reemplazar el bloque de imports al inicio del archivo:

```typescript
import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  TextField,
  MenuItem,
  Button,
  CircularProgress,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Card,
  CardContent,
  Autocomplete,
} from '@mui/material';
import { Refresh as RefreshIcon, Search as SearchIcon, PictureAsPdf as PdfIcon } from '@mui/icons-material';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { format, subMonths } from 'date-fns';
import { useSelector } from 'react-redux';
import { RootState } from '../../../redux/store';
import { useInformeHistorial, useEstudiantes, useEscuela } from '../../../hooks/useAppQueries';
import type { ParamsHistorial } from '../../../services/asistenciaInformesService';
import { generarPdfHistorial } from '../../../utils/pdfGenerators/pdfHistorial';
```

- [ ] **Paso 2: Agregar estado y handlers dentro del componente**

Dentro de `InformeHistorialEstudiante`, justo después de las líneas del hook `useInformeHistorial` (línea ~65), agregar:

```typescript
  const [generandoPdf, setGenerandoPdf] = useState(false);
  const { user } = useSelector((state: RootState) => state.auth);
  const { data: escuela } = useEscuela();

  const handleDescargarPdf = () => {
    if (!data) return;
    setGenerandoPdf(true);
    try {
      generarPdfHistorial(
        data,
        escuela ?? null,
        `${user?.nombre ?? ''} ${user?.apellidos ?? ''}`.trim(),
        queryParams
      );
    } finally {
      setGenerandoPdf(false);
    }
  };
```

- [ ] **Paso 3: Agregar el botón en la sección `{data && (...)}` (línea ~169)**

Justo después de `{data && (` y antes del `<>` que abre el bloque, insertar el botón. Reemplazar el fragmento:

```tsx
      {data && (
        <>
          {/* Encabezado del estudiante */}
```

por:

```tsx
      {data && (
        <>
          {/* Botón PDF */}
          <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
            <Button
              variant="outlined"
              color="success"
              startIcon={generandoPdf ? <CircularProgress size={16} color="inherit" /> : <PdfIcon />}
              onClick={handleDescargarPdf}
              disabled={generandoPdf}
              sx={{ borderRadius: 20, textTransform: 'none' }}
            >
              {generandoPdf ? 'Generando...' : 'Descargar PDF'}
            </Button>
          </Box>

          {/* Encabezado del estudiante */}
```

- [ ] **Paso 4: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 5: Probar manualmente**

1. Correr `npm run dev`
2. Ir a Informes de Asistencia → pestaña Historial
3. Seleccionar un estudiante, elegir rango de fechas, clic en "Consultar"
4. Verificar que aparece el botón "Descargar PDF"
5. Clic en el botón — debe descargarse un archivo `historial-apellido-nombre-YYYYMMDD.pdf`
6. Abrir el PDF — debe mostrar: encabezado verde, bloque estudiante, 5 métricas, tabla con chips de colores por estado, footer con nombre del generador

- [ ] **Paso 6: Commit**

```bash
git add src/components/asistencia/informes/InformeHistorialEstudiante.tsx
git commit -m "feat: agregar botón Descargar PDF en informe historial de asistencia"
```

---

## Tarea 6 — Crear `pdfRiesgo.ts`

**Archivos:**
- Crear: `src/utils/pdfGenerators/pdfRiesgo.ts`

- [ ] **Paso 1: Crear el archivo**

```typescript
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import type { RespuestaRiesgo, ParamsRiesgo } from '../../services/asistenciaInformesService';
import type { Escuela } from '../../services/escuelaService';
import { agregarEncabezado, agregarFooter } from './pdfBase';

export const generarPdfRiesgo = (
  data: RespuestaRiesgo,
  escuela: Escuela | null,
  generadoPor: string,
  params: ParamsRiesgo,
  nombreCurso?: string
): void => {
  const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();

  let y = agregarEncabezado(doc, {
    nombreColegio: escuela?.nombre ?? 'Institución Educativa',
    ciudad: escuela?.direccion,
    titulo: 'Informe de Riesgo',
    colorPrimario: [239, 68, 68],
    generadoPor,
  });

  // Línea de parámetros de consulta
  const formatFecha = (iso?: string): string =>
    iso ? iso.substring(0, 10).split('-').reverse().join('/') : '';

  const partes: string[] = [`Umbral: ${params.umbral ?? 80}%`];
  if (params.desde && params.hasta) {
    partes.push(`Período: ${formatFecha(params.desde)} — ${formatFecha(params.hasta)}`);
  }
  partes.push(`Curso: ${nombreCurso ?? 'Todos'}`);

  doc.setFontSize(9);
  doc.setTextColor(80, 80, 80);
  doc.text(partes.join('  ·  '), 15, y);
  doc.setTextColor(0, 0, 0);
  y += 10;

  // 3 tarjetas de resumen
  const tarjetas: { label: string; valor: string; r: number; g: number; b: number }[] = [
    { label: 'Total en riesgo', valor: String(data.total), r: 239, g: 68, b: 68 },
    { label: 'Críticos (<70%)', valor: String(data.criticos), r: 153, g: 27, b: 27 },
    { label: `En alerta (<${params.umbral ?? 80}%)`, valor: String(data.alertas), r: 146, g: 64, b: 14 },
  ];
  const cardW = (pageWidth - 30) / 3;
  tarjetas.forEach((t, i) => {
    const x = 15 + i * cardW;
    doc.setFillColor(255, 245, 245);
    doc.rect(x, y, cardW - 4, 17, 'F');
    doc.setFontSize(15);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(t.r, t.g, t.b);
    doc.text(t.valor, x + (cardW - 4) / 2, y + 9, { align: 'center' });
    doc.setFontSize(7);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100, 100, 100);
    doc.text(t.label, x + (cardW - 4) / 2, y + 14, { align: 'center' });
  });
  doc.setTextColor(0, 0, 0);
  y += 23;

  // Tabla de estudiantes
  autoTable(doc, {
    startY: y,
    head: [['Estudiante', 'Curso', 'Clases', 'Ausencias', 'Tardanzas', '% Asistencia', 'Nivel']],
    body: data.estudiantes.map((e) => [
      `${e.nombre} ${e.apellidos}`,
      `${e.curso.nombre} ${e.curso.grado}-${e.curso.grupo}`,
      String(e.clasesTotales),
      String(e.ausencias),
      String(e.tardanzas),
      `${e.porcentajeAsistencia.toFixed(1)}%`,
      e.nivelRiesgo,
    ]),
    headStyles: { fillColor: [239, 68, 68], textColor: 255, fontStyle: 'bold', fontSize: 8 },
    bodyStyles: { fontSize: 8 },
    columnStyles: {
      2: { halign: 'center' },
      3: { halign: 'center' },
      4: { halign: 'center' },
      5: { halign: 'center' },
      6: { halign: 'center' },
    },
    didParseCell: (hookData) => {
      if (hookData.section === 'body' && hookData.column.index === 6) {
        const nivel = data.estudiantes[hookData.row.index]?.nivelRiesgo;
        if (nivel === 'CRITICO') {
          hookData.cell.styles.textColor = [153, 27, 27];
          hookData.cell.styles.fontStyle = 'bold';
          hookData.cell.styles.fillColor = [255, 245, 245];
        } else {
          hookData.cell.styles.textColor = [146, 64, 14];
          hookData.cell.styles.fontStyle = 'bold';
        }
      }
    },
    margin: { left: 15, right: 15 },
  });

  agregarFooter(doc, 'Confidencial — uso interno');

  const fechaHoy = new Date().toISOString().substring(0, 10).replace(/-/g, '');
  doc.save(`riesgo-asistencia-${fechaHoy}.pdf`);
};
```

- [ ] **Paso 2: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 3: Commit**

```bash
git add src/utils/pdfGenerators/pdfRiesgo.ts
git commit -m "feat: crear generador PDF para informe de estudiantes en riesgo"
```

---

## Tarea 7 — Agregar botón PDF a `InformeRiesgo.tsx`

**Archivos:**
- Modificar: `src/components/asistencia/informes/InformeRiesgo.tsx`

- [ ] **Paso 1: Actualizar imports**

Reemplazar las líneas de imports existentes por:

```typescript
import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  TextField,
  MenuItem,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  CircularProgress,
  Alert,
  Card,
  CardContent,
  Tooltip,
} from '@mui/material';
import {
  Warning as WarningIcon,
  Error as ErrorIcon,
  Refresh as RefreshIcon,
  PictureAsPdf as PdfIcon,
} from '@mui/icons-material';
import { format, subMonths } from 'date-fns';
import { useSelector } from 'react-redux';
import { RootState } from '../../../redux/store';
import { useInformeRiesgo, useCursos, useEscuela } from '../../../hooks/useAppQueries';
import type { ParamsRiesgo } from '../../../services/asistenciaInformesService';
import { generarPdfRiesgo } from '../../../utils/pdfGenerators/pdfRiesgo';
```

- [ ] **Paso 2: Agregar estado y handler dentro del componente**

Dentro de `InformeRiesgo`, justo después de la línea `const { data, isLoading, isError, refetch } = useInformeRiesgo(...)`:

```typescript
  const [generandoPdf, setGenerandoPdf] = useState(false);
  const { user } = useSelector((state: RootState) => state.auth);
  const { data: escuela } = useEscuela();

  const handleDescargarPdf = () => {
    if (!data) return;
    setGenerandoPdf(true);
    try {
      const cursoObj = cursos.find((c: any) => c._id === queryParams.cursoId);
      const nombreCurso = cursoObj
        ? `${cursoObj.nombre} ${cursoObj.grado}-${cursoObj.grupo}`
        : undefined;
      generarPdfRiesgo(
        data,
        escuela ?? null,
        `${user?.nombre ?? ''} ${user?.apellidos ?? ''}`.trim(),
        queryParams,
        nombreCurso
      );
    } finally {
      setGenerandoPdf(false);
    }
  };
```

- [ ] **Paso 3: Agregar el botón debajo del bloque de filtros**

Localizar el cierre de la sección de filtros (`</Paper>` que va después del bloque Grid del botón "Consultar", línea ~127), y justo después agregar:

```tsx
      {/* Botón PDF — visible cuando hay estudiantes en riesgo */}
      {(data?.estudiantes?.length ?? 0) > 0 && (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
          <Button
            variant="outlined"
            color="error"
            startIcon={generandoPdf ? <CircularProgress size={16} color="inherit" /> : <PdfIcon />}
            onClick={handleDescargarPdf}
            disabled={generandoPdf}
            sx={{ borderRadius: 20, textTransform: 'none' }}
          >
            {generandoPdf ? 'Generando...' : 'Descargar PDF'}
          </Button>
        </Box>
      )}
```

- [ ] **Paso 4: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 5: Probar manualmente**

1. Ir a Informes de Asistencia → pestaña Riesgo
2. Clic en "Consultar" — si hay estudiantes en riesgo, debe aparecer el botón "Descargar PDF"
3. Clic en "Descargar PDF" — descarga `riesgo-asistencia-YYYYMMDD.pdf`
4. Abrir el PDF — debe mostrar: encabezado rojo, línea de parámetros, 3 tarjetas resumen, tabla con CRÍTICO en fondo rojo claro, footer "Confidencial — uso interno"

- [ ] **Paso 6: Commit**

```bash
git add src/components/asistencia/informes/InformeRiesgo.tsx
git commit -m "feat: agregar botón Descargar PDF en informe de riesgo de asistencia"
```

---

## Tarea 8 — Crear `pdfCierrePeriodo.ts`

**Archivos:**
- Crear: `src/utils/pdfGenerators/pdfCierrePeriodo.ts`

- [ ] **Paso 1: Crear el archivo**

```typescript
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import type { EstadisticaEstudiantePeriodo } from '../../services/asistenciaInformesService';
import type { Escuela } from '../../services/escuelaService';
import { agregarEncabezado, agregarFooter } from './pdfBase';

export interface DatosCierrePeriodo {
  estadisticas: EstadisticaEstudiantePeriodo[];
  nombreCurso: string;
  grado: string;
  grupo: string;
  nombrePeriodo: string;
}

export const generarPdfCierrePeriodo = (
  datos: DatosCierrePeriodo,
  escuela: Escuela | null,
  generadoPor: string
): void => {
  const doc = new jsPDF({ orientation: 'p', unit: 'mm', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();

  let y = agregarEncabezado(doc, {
    nombreColegio: escuela?.nombre ?? 'Institución Educativa',
    ciudad: escuela?.direccion,
    titulo: 'Cierre de Período',
    colorPrimario: [13, 148, 136],
    generadoPor,
  });

  // Bloque info del curso
  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  doc.text(
    `${datos.nombreCurso}${datos.grado ? ` — Grado ${datos.grado}` : ''}${datos.grupo ? `, Grupo ${datos.grupo}` : ''}`,
    15,
    y
  );
  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(80, 80, 80);
  doc.text(`Período: ${datos.nombrePeriodo}`, 15, y + 6);
  doc.setTextColor(0, 0, 0);
  y += 16;

  // Resumen del curso (4 tarjetas)
  const total = datos.estadisticas.length;
  const clasesMax = datos.estadisticas.reduce((m, e) => Math.max(m, e.clasesTotales), 0);
  const promedio =
    total > 0
      ? datos.estadisticas.reduce((s, e) => s + e.porcentajeAsistencia, 0) / total
      : 0;
  const enRiesgo = datos.estadisticas.filter((e) => e.porcentajeAsistencia < 80).length;

  const resumen: { label: string; valor: string }[] = [
    { label: 'Total estudiantes', valor: String(total) },
    { label: 'Clases dictadas', valor: String(clasesMax) },
    { label: 'Promedio asistencia', valor: `${promedio.toFixed(1)}%` },
    { label: 'En riesgo (<80%)', valor: String(enRiesgo) },
  ];
  const cardW = (pageWidth - 30) / 4;
  resumen.forEach((r, i) => {
    const x = 15 + i * cardW;
    doc.setFillColor(240, 253, 250);
    doc.rect(x, y, cardW - 3, 17, 'F');
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(13, 148, 136);
    doc.text(r.valor, x + (cardW - 3) / 2, y + 8, { align: 'center' });
    doc.setFontSize(7);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100, 100, 100);
    doc.text(r.label, x + (cardW - 3) / 2, y + 14, { align: 'center' });
  });
  doc.setTextColor(0, 0, 0);
  y += 23;

  // Tabla por estudiante (ordenada por % asistencia desc — el backend ya la ordena)
  autoTable(doc, {
    startY: y,
    head: [['Nombre', 'Clases', 'Presentes', 'Ausentes', 'Tardanzas', 'Justificados', '% Asistencia']],
    body: datos.estadisticas.map((e) => [
      e.nombreEstudiante,
      String(e.clasesTotales),
      String(e.presentes),
      String(e.ausentes),
      String(e.tardanzas),
      String(e.justificados),
      `${e.porcentajeAsistencia.toFixed(1)}%`,
    ]),
    headStyles: { fillColor: [13, 148, 136], textColor: 255, fontStyle: 'bold', fontSize: 8 },
    bodyStyles: { fontSize: 8 },
    columnStyles: {
      1: { halign: 'center' },
      2: { halign: 'center' },
      3: { halign: 'center' },
      4: { halign: 'center' },
      5: { halign: 'center' },
      6: { halign: 'center' },
    },
    didParseCell: (hookData) => {
      if (hookData.section === 'body' && hookData.column.index === 6) {
        const pct = datos.estadisticas[hookData.row.index]?.porcentajeAsistencia ?? 100;
        if (pct < 80) {
          hookData.cell.styles.textColor = [153, 27, 27];
          hookData.cell.styles.fontStyle = 'bold';
          hookData.cell.styles.fillColor = [255, 245, 245];
        }
      }
    },
    margin: { left: 15, right: 15 },
  });

  agregarFooter(doc, 'Documento oficial de la institución');

  const cursoSlug = datos.nombreCurso.toLowerCase().replace(/\s+/g, '-');
  const periodoSlug = datos.nombrePeriodo.toLowerCase().replace(/\s+/g, '-');
  doc.save(`cierre-periodo-${cursoSlug}-${periodoSlug}.pdf`);
};
```

- [ ] **Paso 2: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 3: Commit**

```bash
git add src/utils/pdfGenerators/pdfCierrePeriodo.ts
git commit -m "feat: crear generador PDF para cierre de período por curso"
```

---

## Tarea 9 — Crear componente `InformeCierrePeriodo.tsx`

**Archivos:**
- Crear: `src/components/asistencia/informes/InformeCierrePeriodo.tsx`

- [ ] **Paso 1: Crear el archivo**

```typescript
import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  TextField,
  MenuItem,
  Button,
  CircularProgress,
  Alert,
} from '@mui/material';
import { PictureAsPdf as PdfIcon } from '@mui/icons-material';
import { useSelector } from 'react-redux';
import { RootState } from '../../../redux/store';
import { useEscuela, useCursos } from '../../../hooks/useAppQueries';
import { getResumenPeriodo } from '../../../services/asistenciaInformesService';
import { generarPdfCierrePeriodo } from '../../../utils/pdfGenerators/pdfCierrePeriodo';

const InformeCierrePeriodo: React.FC = () => {
  const [periodoId, setPeriodoId] = useState('');
  const [cursoId, setCursoId] = useState('');
  const [generando, setGenerando] = useState(false);
  const [error, setError] = useState('');

  const { user } = useSelector((state: RootState) => state.auth);
  const { data: escuela } = useEscuela();
  const { data: cursosData } = useCursos();

  const cursos: any[] =
    (cursosData as any)?.data ?? (Array.isArray(cursosData) ? cursosData : []);
  const periodos = escuela?.periodos_academicos ?? [];

  const handleGenerar = async () => {
    if (!periodoId || !cursoId) return;
    setError('');
    setGenerando(true);
    try {
      const estadisticas = await getResumenPeriodo(periodoId, cursoId);
      const curso = cursos.find((c: any) => c._id === cursoId);
      const periodo = periodos.find((p) => p._id === periodoId);
      generarPdfCierrePeriodo(
        {
          estadisticas,
          nombreCurso: curso?.nombre ?? 'Curso',
          grado: curso?.grado ?? '',
          grupo: curso?.grupo ?? '',
          nombrePeriodo: periodo?.nombre ?? 'Período',
        },
        escuela ?? null,
        `${user?.nombre ?? ''} ${user?.apellidos ?? ''}`.trim()
      );
    } catch {
      setError('Error al obtener los datos. Verifique que el período y curso tengan registros de asistencia.');
    } finally {
      setGenerando(false);
    }
  };

  return (
    <Box>
      <Paper
        elevation={0}
        sx={{
          p: 3,
          borderRadius: 3,
          boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
          maxWidth: 560,
        }}
      >
        <Typography variant="h3" sx={{ mb: 3 }}>
          Generar PDF de Cierre de Período
        </Typography>

        <Grid container spacing={2}>
          <Grid item xs={12} sm={6}>
            <TextField
              label="Período académico"
              select
              size="small"
              fullWidth
              value={periodoId}
              onChange={(e) => setPeriodoId(e.target.value)}
            >
              {periodos.length === 0 && (
                <MenuItem value="" disabled>
                  Sin períodos configurados
                </MenuItem>
              )}
              {periodos.map((p) => (
                <MenuItem key={p._id} value={p._id}>
                  {p.nombre}
                </MenuItem>
              ))}
            </TextField>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Curso"
              select
              size="small"
              fullWidth
              value={cursoId}
              onChange={(e) => setCursoId(e.target.value)}
            >
              {cursos.map((c: any) => (
                <MenuItem key={c._id} value={c._id}>
                  {c.nombre} {c.grado}-{c.grupo}
                </MenuItem>
              ))}
            </TextField>
          </Grid>

          <Grid item xs={12}>
            <Button
              variant="contained"
              color="primary"
              fullWidth
              startIcon={
                generando ? (
                  <CircularProgress size={18} color="inherit" />
                ) : (
                  <PdfIcon />
                )
              }
              onClick={handleGenerar}
              disabled={!periodoId || !cursoId || generando}
              sx={{ borderRadius: 20, py: 1.2, textTransform: 'none', fontSize: '0.95rem' }}
            >
              {generando ? 'Generando PDF...' : 'Generar y descargar PDF'}
            </Button>
          </Grid>
        </Grid>

        {error && (
          <Alert severity="error" sx={{ mt: 2, borderRadius: 2 }}>
            {error}
          </Alert>
        )}

        {periodos.length === 0 && escuela && (
          <Alert severity="warning" sx={{ mt: 2, borderRadius: 2 }}>
            La institución no tiene períodos académicos configurados. Configúrelos en Ajustes → Escuela.
          </Alert>
        )}
      </Paper>
    </Box>
  );
};

export default InformeCierrePeriodo;
```

- [ ] **Paso 2: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 3: Commit**

```bash
git add src/components/asistencia/informes/InformeCierrePeriodo.tsx
git commit -m "feat: crear componente InformeCierrePeriodo con selectores y descarga PDF"
```

---

## Tarea 10 — Agregar 6ª pestaña "Cierre de Período" en `InformesAsistencia.tsx`

**Archivos:**
- Modificar: `src/pages/asistencia/InformesAsistencia.tsx`

- [ ] **Paso 1: Agregar imports**

Reemplazar el bloque de imports al inicio del archivo:

```typescript
import React, { useState } from 'react';
import {
  Box,
  Typography,
  Tabs,
  Tab,
  Paper,
} from '@mui/material';
import {
  Warning as WarningIcon,
  TrendingUp as TrendingUpIcon,
  Leaderboard as LeaderboardIcon,
  CalendarMonth as CalendarIcon,
  Person as PersonIcon,
  Assessment as AssessmentIcon,
} from '@mui/icons-material';
import InformeRiesgo from '../../components/asistencia/informes/InformeRiesgo';
import InformeTendencia from '../../components/asistencia/informes/InformeTendencia';
import InformeRankingCursos from '../../components/asistencia/informes/InformeRankingCursos';
import InformePatronDias from '../../components/asistencia/informes/InformePatronDias';
import InformeHistorialEstudiante from '../../components/asistencia/informes/InformeHistorialEstudiante';
import InformeCierrePeriodo from '../../components/asistencia/informes/InformeCierrePeriodo';
```

- [ ] **Paso 2: Agregar la 6ª pestaña al array TABS**

Reemplazar:

```typescript
const TABS = [
  { label: 'Riesgo', icon: <WarningIcon fontSize="small" /> },
  { label: 'Tendencia', icon: <TrendingUpIcon fontSize="small" /> },
  { label: 'Ranking', icon: <LeaderboardIcon fontSize="small" /> },
  { label: 'Patrón días', icon: <CalendarIcon fontSize="small" /> },
  { label: 'Historial', icon: <PersonIcon fontSize="small" /> },
];
```

por:

```typescript
const TABS = [
  { label: 'Riesgo', icon: <WarningIcon fontSize="small" /> },
  { label: 'Tendencia', icon: <TrendingUpIcon fontSize="small" /> },
  { label: 'Ranking', icon: <LeaderboardIcon fontSize="small" /> },
  { label: 'Patrón días', icon: <CalendarIcon fontSize="small" /> },
  { label: 'Historial', icon: <PersonIcon fontSize="small" /> },
  { label: 'Cierre de Período', icon: <AssessmentIcon fontSize="small" /> },
];
```

- [ ] **Paso 3: Agregar el TabPanel del nuevo componente**

Localizar el último `</TabPanel>` (el de InformeHistorialEstudiante, index 4) y agregar inmediatamente después:

```tsx
          <TabPanel value={tabActivo} index={5}>
            <InformeCierrePeriodo />
          </TabPanel>
```

- [ ] **Paso 4: Verificar TypeScript**

```bash
npx tsc --noEmit
```

Salida esperada: sin errores.

- [ ] **Paso 5: Probar manualmente**

1. Ir a Informes de Asistencia — debe aparecer la 6ª pestaña "Cierre de Período"
2. Clic en la pestaña — debe mostrar los dos selectores (Período y Curso) y el botón deshabilitado
3. Si la institución tiene períodos configurados, seleccionar uno + un curso y clic en "Generar y descargar PDF"
4. Verificar que se descarga `cierre-periodo-{curso}-{periodo}.pdf`
5. Abrir el PDF — encabezado teal, nombre del curso, 4 tarjetas resumen, tabla de estudiantes con % en rojo para los que están bajo 80%

- [ ] **Paso 6: Commit final**

```bash
git add src/pages/asistencia/InformesAsistencia.tsx
git commit -m "feat: agregar pestaña Cierre de Período en Informes de Asistencia"
```

---

## Verificación final

- [ ] **Typecheck completo**

```bash
npx tsc --noEmit
```

Salida esperada: 0 errores.

- [ ] **Build de producción**

```bash
npm run build
```

Salida esperada: build exitoso sin errores. Verificar que jsPDF no genere warnings de tamaño excesivo (ambas librerías suman ~300KB gzip — aceptable).

- [ ] **Smoke test de los 3 PDFs**

| PDF | Verificar |
|-----|-----------|
| Historial | Encabezado verde, chips de color por estado, footer con nombre del generador |
| Riesgo | Encabezado rojo, 3 tarjetas, fila CRÍTICO en fondo rojo claro, footer "Confidencial" |
| Cierre de Período | Encabezado teal, 4 tarjetas resumen del curso, estudiantes bajo 80% en rojo |
