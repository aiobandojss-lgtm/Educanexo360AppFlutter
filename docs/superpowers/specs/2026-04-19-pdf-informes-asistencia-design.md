# Diseño — Exportación PDF de Informes de Asistencia

**Fecha:** 2026-04-19  
**Proyecto:** EducaNexo360 React  
**Estado:** Aprobado por Aymer Ivan Obando

---

## Contexto

El módulo de Informes de Asistencia ya tiene 5 pestañas funcionales (Riesgo, Tendencia, Ranking, Patrón días, Historial). Los directivos del colegio (rector, coordinador) y los docentes necesitan documentos formales en PDF para reuniones con padres, reportes a la Secretaría de Educación y comités internos.

---

## Alcance

Tres PDFs nuevos integrados en la sección de Informes de Asistencia:

| PDF | Dónde aparece | Endpoint que usa |
|-----|--------------|-----------------|
| 1. Historial de estudiante | Pestaña "Historial" — botón después de cargar datos | `GET /asistencia/informes/historial/:id` (ya en uso) |
| 2. Informe de Riesgo | Pestaña "Riesgo" — botón junto a "Consultar" | `GET /asistencia/informes/riesgo` (ya en uso) |
| 3. Cierre de Período | Pestaña nueva "Cierre de Período" (6ª pestaña) | `GET /asistencia/resumen/periodo/:periodoId` (ya existe) |

**No se requieren cambios en el backend.**

---

## Tecnología

- **jsPDF** (`jspdf`) — generación de PDFs en el navegador
- **jsPDF AutoTable** (`jspdf-autotable`) — tablas formateadas sin html2canvas
- Generación 100% en el cliente, sin pasar por el servidor
- Descarga inmediata al navegador del usuario

---

## Arquitectura

### Nuevo archivo utilitario

```
src/utils/pdfGenerators/
  ├── pdfBase.ts          — helpers compartidos: header institucional, footer, colores
  ├── pdfHistorial.ts     — genera PDF del historial de estudiante
  ├── pdfRiesgo.ts        — genera PDF del informe de riesgo
  └── pdfCierrePeriodo.ts — genera PDF de cierre de período
```

Cada función recibe los datos ya cargados en el componente — no hace llamadas API propias.

### Nuevo componente

```
src/components/asistencia/informes/InformeCierrePeriodo.tsx
```

Contiene: selector de período académico + selector de curso + botón "Generar PDF". No tiene vista previa en pantalla; su único propósito es configurar y descargar el documento.

### Modificaciones a componentes existentes

- `InformeHistorialEstudiante.tsx` — agregar botón "Descargar PDF" que aparece cuando `data` está cargada
- `InformeRiesgo.tsx` — agregar botón "Descargar PDF" que aparece cuando `data` está cargada
- `InformesAsistencia.tsx` — agregar 6ª pestaña "Cierre de Período"

---

## Encabezado institucional (compartido por los 3 PDFs)

Todos los PDFs tienen el mismo encabezado parametrizable:

```
┌────────────────────────────────────────────────────────┐
│ [LOGO]   Nombre del Colegio                            │
│          NIT: xxx.xxx.xxx-x · Ciudad, Departamento     │
│                                          TÍTULO PDF    │
│                                   Generado: DD/MM/AAAA │
└────────────────────────────────────────────────────────┘
```

**Fuente de datos del encabezado:**
- Nombre del colegio: `GET /api/escuelas/:escuelaId` (campo `nombre`)
- NIT y ciudad: misma respuesta de escuela
- Logo: URL del logo si existe en el objeto escuela; si no, espacio en blanco reservado
- Usuario que genera: `user.nombre + user.apellidos` desde Redux auth
- Fecha: `new Date()` al momento de generar

### Hook necesario

```typescript
// src/hooks/useAppQueries.ts — agregar:
export const useEscuela = (escuelaId: string) => useQuery({
  queryKey: ['escuela', escuelaId],
  queryFn: () => escuelaService.obtenerEscuela(escuelaId),
  staleTime: 1000 * 60 * 30, // 30 min — datos que cambian poco
  enabled: !!escuelaId,
});
```

---

## PDF 1 — Historial de Asistencia del Estudiante

**Nombre de archivo:** `historial-{apellidos}-{nombre}-{fecha}.pdf`

**Secciones:**
1. Encabezado institucional (verde — `#059669`)
2. Bloque de datos del estudiante: nombre completo, curso, rango de fechas consultado
3. Resumen estadístico: 5 métricas en fila — Clases, Presentes, Ausentes, Tardanzas, % Asistencia
4. Tabla detalle (una fila por registro): Fecha | Día | Asignatura | Estado | Observaciones
5. Footer: "Generado por: {nombre}" a la izquierda, número de página a la derecha

**Colores de chips en tabla:**
- PRESENTE → fondo `#d1fae5`, texto `#065f46`
- AUSENTE → fondo `#fee2e2`, texto `#991b1b`
- TARDANZA → fondo `#fef3c7`, texto `#92400e`
- JUSTIFICADO → fondo `#dbeafe`, texto `#1e40af`
- PERMISO → fondo `#f3f4f6`, texto `#374151`

**Cuándo aparece el botón:** cuando `data` del hook `useInformeHistorial` no es null (es decir, la consulta ya se ejecutó y devolvió resultados).

---

## PDF 2 — Informe de Estudiantes en Riesgo

**Nombre de archivo:** `riesgo-asistencia-{fecha}.pdf`

**Secciones:**
1. Encabezado institucional (rojo — `#ef4444`)
2. Línea de parámetros: "Umbral: X% · Período: DD/MM — DD/MM/AAAA · Curso: {nombre o 'Todos'}"
3. Resumen en 3 tarjetas: Total en riesgo | Críticos (<70%) | En alerta (<umbral%)
4. Tabla: Estudiante | Curso | Clases | Ausencias | Tardanzas | % Asistencia | Nivel
5. Footer: "Confidencial — uso interno" a la derecha

**Colores de nivel en tabla:**
- CRÍTICO → texto `#991b1b`, fondo fila `#fff5f5`
- ALERTA → texto `#92400e`, fondo fila normal

**Cuándo aparece el botón:** cuando `data?.estudiantes?.length > 0`.

---

## PDF 3 — Cierre de Período por Curso

**Nombre de archivo:** `cierre-periodo-{nombreCurso}-{periodo}.pdf`

**UI en la nueva pestaña:**
```
┌─────────────────────────────────────────────────────┐
│  Selector: Período académico  │  Selector: Curso    │
│                               │                     │
│        [Generar y descargar PDF]                    │
└─────────────────────────────────────────────────────┘
  (sin tabla previa — el PDF se genera directamente)
```

**Endpoint:** `GET /api/asistencia/resumen/periodo/:periodoId?cursoId=xxx`  
Devuelve estadísticas por estudiante ordenadas por % de asistencia descendente.

**Secciones del PDF:**
1. Encabezado institucional (teal — `#0d9488`)
2. Bloque: Nombre del curso, grado, grupo, nombre del período, docente
3. Resumen del curso: Total estudiantes | Clases dictadas | Promedio asistencia | Cantidad en riesgo
4. Tabla por estudiante: Nombre | Clases | Presentes | Ausentes | Tardanzas | Justificados | % Asistencia
5. Footer: "Documento oficial de la institución"

**Fuente de períodos:** `GET /api/escuelas/:id` — el objeto escuela contiene los períodos académicos configurados.

---

## Estados de botones PDF

- **Deshabilitado / oculto:** mientras la data no esté cargada
- **Cargando:** spinner pequeño mientras se genera el PDF (jsPDF puede tardar 1-2 segundos con tablas largas)
- **Listo:** descarga automática del archivo

---

## Roles con acceso al botón PDF

| PDF | Roles |
|-----|-------|
| Historial | ADMIN, RECTOR, COORDINADOR, DOCENTE |
| Riesgo | ADMIN, RECTOR, COORDINADOR, DOCENTE |
| Cierre de Período | ADMIN, RECTOR, COORDINADOR, DOCENTE |

Los mismos roles que pueden ver los informes ya tienen acceso al PDF.

---

## Lo que NO entra en este sprint

- Gráficas de recharts incrustadas en el PDF (jsPDF no renderiza SVG bien)
- Firma digital o certificación
- Envío del PDF por email desde la UI (eso va en el Grupo B — alertas automáticas)
- PDFs para otros módulos (calificaciones, tareas)

---

## Dependencias nuevas

```bash
npm install jspdf jspdf-autotable
```

Ambas son librerías maduras, ampliamente usadas, sin dependencias de servidor.

---

## Orden de implementación sugerido

1. Instalar dependencias
2. Crear `pdfBase.ts` con el header y footer institucional
3. PDF 1 (Historial) — el más completo, establece el patrón
4. PDF 2 (Riesgo) — reutiliza pdfBase, tabla más simple
5. Hook `useEscuela` + nuevo componente `InformeCierrePeriodo`
6. PDF 3 (Cierre de período) — pestaña nueva + generación
7. Tests manuales con los 3 roles principales (ADMIN, DOCENTE, COORDINADOR)
