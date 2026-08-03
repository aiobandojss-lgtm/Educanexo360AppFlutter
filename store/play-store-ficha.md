# Ficha de Google Play — EducaNexo360

Textos listos para copiar y pegar en Play Console. Los límites de caracteres los
impone Google: si te pasas, el campo no deja guardar.

---

## 1. Nombre de la app (máx. 30 caracteres)

**Opción recomendada (ASO):**

```
EducaNexo360: agenda escolar
```

*28 caracteres. Incluye "agenda escolar", que es lo que la gente busca. Google
indexa el título, así que las palabras que van ahí pesan mucho en las búsquedas.*

**Opción sobria:**

```
EducaNexo360
```

*12 caracteres. Más limpio, pero solo te encuentra quien ya conoce el nombre.*

---

## 2. Descripción corta (máx. 80 caracteres)

Es lo que se ve debajo del ícono, antes de tocar "Más información".

```
La agenda escolar digital que conecta al colegio con las familias.
```

*66 caracteres.*

---

## 3. Descripción larga (máx. 4000 caracteres)

```
EducaNexo360 reemplaza la agenda física del colegio y reúne en un solo lugar todo lo que las familias necesitan saber: calificaciones, tareas, asistencia, comunicados y mensajes directos con los docentes.

Se acabaron las circulares arrugadas en el fondo del morral y los "no me avisaron".

PARA ACUDIENTES Y PADRES DE FAMILIA
• Consulta las calificaciones y el boletín de tus hijos apenas se publican
• Revisa qué tareas tienen pendientes, para cuándo son y si ya fueron calificadas
• Entérate el mismo día si hubo una ausencia o una llegada tarde
• Recibe los comunicados del colegio y confirma asistencia a los eventos
• Escríbele directamente a los docentes y a la coordinación
• Si tienes varios hijos en la institución, los ves todos desde la misma cuenta

PARA DOCENTES
• Registra la asistencia por curso y asignatura en segundos
• Crea tareas con fecha límite, prioridad y material de apoyo adjunto
• Revisa las entregas de los estudiantes y califícalas con observaciones
• Publica anuncios y programa eventos del curso
• Responde los mensajes de las familias sin tener que dar tu número personal

PARA ESTUDIANTES
• Consulta tus tareas pendientes, entregadas y calificadas
• Descarga el material que subió el docente
• Entrega tus trabajos desde el celular, sin esperar a llegar a un computador
• Revisa tus notas y tu asistencia

PARA DIRECTIVOS Y PERSONAL ADMINISTRATIVO
• Administra usuarios, cursos y asignaturas
• Publica comunicados institucionales con imágenes y archivos
• Consulta la información académica de toda la institución

NOTIFICACIONES EN EL MOMENTO
Recibe un aviso en tu celular cuando llega un mensaje nuevo, se asigna una tarea, se publica un anuncio, se programa un evento o se registra una ausencia. Sin tener que estar entrando a revisar.

TODO EN UN SOLO SITIO
Mensajería interna, calendario escolar, anuncios, tareas con archivos adjuntos, calificaciones, boletines y control de asistencia. Cada persona ve únicamente lo que le corresponde según su rol dentro de la institución.

IMPORTANTE: NECESITAS UNA CUENTA CREADA POR TU COLEGIO
EducaNexo360 no tiene registro abierto. Las cuentas las crea directamente la institución educativa y se entregan a las familias, docentes y estudiantes. Descargar la app no te da acceso a los datos de ningún colegio.

¿Tu institución todavía no usa EducaNexo360? Escríbenos a contacto@educanexo360.creativebycode.com y con gusto te mostramos cómo funciona.

PRIVACIDAD Y SEGURIDAD
La información viaja cifrada y los datos de cada institución están separados de los de las demás. Puedes solicitar la eliminación de tu cuenta desde la propia app, en la sección Perfil.

Política de privacidad: https://educanexo360.creativebycode.com/politica-de-privacidad.html
Términos y condiciones: https://educanexo360.creativebycode.com/terminos.html

Desarrollado en Cali, Colombia.
```

---

## 4. Acceso a la app (App access) — CRÍTICO

En Play Console: **Contenido de la app → Acceso a la app**. Marca
**"Todas las funciones o algunas están restringidas"** y agrega estas
instrucciones. Sin esto el revisor no puede entrar y **rechaza la app**.

**Nombre de las instrucciones:** `Cuenta de acudiente (padre de familia)`

**Usuario:**
```
demo.acudiente@educanexo360.creativebycode.com
```

**Contraseña:** está en `store/credenciales-revisor.local.txt`, que git ignora.

> Este repositorio es público: las contraseñas de las cuentas demo NO se
> versionan. Cópiala del archivo local al llenar el formulario de Play Console.

**Instrucciones:**
```
La app no tiene registro abierto: las cuentas las crea cada institución educativa.
Use las credenciales de esta cuenta de demostración, que pertenece a un colegio de
prueba con datos ficticios.

1. Abra la app y escriba el correo y la contraseña indicados.
2. Toque INICIAR SESION.

Con esa cuenta verá el panel de un acudiente con dos estudiantes asociados:
calificaciones, tareas, asistencia, mensajes, anuncios y calendario.

Si necesita revisar las funciones de un docente (crear tareas, registrar asistencia
y calificar entregas), cierre sesión y entre con:
Usuario: demo.docente@educanexo360.creativebycode.com
Contraseña: (la misma indicada arriba)

Ningún dato de esta cuenta corresponde a personas reales.
```

> Al pegar esas instrucciones en Play Console, reemplaza "(la misma indicada
> arriba)" por la contraseña real del archivo local.

---

## 5. Capturas de pantalla — LISTAS

En `store/screenshots/`, ya montadas y validadas. Súbelas en este orden:

| # | Archivo | Titular |
|---|---|---|
| 1 | `01-dashboard.png` | Todo el colegio en una pantalla |
| 2 | `02-calendario.png` | Nunca te pierdas un evento |
| 3 | `03-tareas.png` | Las tareas, siempre a la vista |
| 4 | `04-mensajeria1.png` | Habla directo con los docentes |
| 5 | `05-anuncios.png` | Comunicados que sí llegan |
| 6 | `06-asistencia.png` | Asistencia al día, sin papeleo |

**Por qué van montadas sobre un lienzo y no son la captura cruda:** Google exige
proporción 9:16 y que el lado mayor no supere el doble del menor. Las capturas
del celular son 720x1610 (2.24:1) y el validador las rechaza. Como todos los
teléfonos actuales son ~20:9, ninguna captura cruda cumple: montarlas sobre un
lienzo 1080x1920 es el procedimiento normal, no un parche.

Para cambiar los textos: edita la lista `SHOTS` en `build-screenshots.py` y
vuelve a ejecutarlo (necesita Chrome instalado y `pip install pillow`).

---

## 6. Otros campos de la ficha

| Campo | Valor |
|---|---|
| Categoría | Educación |
| Etiquetas | Educación, Productividad |
| Correo de contacto | contacto@educanexo360.creativebycode.com |
| Sitio web | https://educanexo360.creativebycode.com |
| Política de privacidad | https://educanexo360.creativebycode.com/politica-de-privacidad.html |
| Público objetivo | 13 años en adelante |
| ¿Contiene anuncios? | No |
| ¿Compras en la app? | No |
| Gráfico destacado | 1024 x 500 px (pendiente de diseñar) |
| Ícono | 512 x 512 px — usar `assets/images/logo_icono_nuevo.png` |
