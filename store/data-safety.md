# Seguridad de los datos — Google Play Console

Borrador para copiar campo por campo en Play Console.
Cada respuesta está verificada contra el código de la app (ver "Evidencia" al final).

> **Regla de oro:** lo que declares aquí debe coincidir con lo que hace el código.
> Declarar de menos es una infracción de política y Google puede retirar la app.
> Declarar de más no infringe nada, pero ensucia la tarjeta pública que ven los papás.

Play Console tiene **tres formularios distintos** que la gente suele confundir:

| Formulario | Dónde está | Qué pregunta |
|---|---|---|
| 1. Seguridad de los datos | Política > Contenido de la app | Qué datos recoges y para qué |
| 2. Público objetivo y contenido | Política > Contenido de la app | A qué edades va dirigida |
| 3. Clasificación de contenido | Política > Contenido de la app | Cuestionario IARC para la edad recomendada |

---

## FORMULARIO 1 — Seguridad de los datos

### Paso 1: Descripción general

| Pregunta | Respuesta |
|---|---|
| ¿Tu app recopila o comparte alguno de los tipos de datos de usuario obligatorios? | **Sí** |
| ¿Se cifran todos los datos de usuario en tránsito? | **Sí** |
| ¿Proporcionas una forma para que los usuarios soliciten que se borren sus datos? | **Sí** ⚠️ ver nota abajo |

**Sobre el cifrado en tránsito — por qué puedes decir Sí sin riesgo:**
el `AndroidManifest.xml` de release no tiene `usesCleartextTraffic` (solo lo tienen
`src/debug` y `src/profile`, que nunca se publican), y el `.aab` se compila con
`--dart-define=API_URL=https://…`. En iOS, ATS está activo por defecto sin excepciones
en `Info.plist`. O sea: en producción es 100% HTTPS y es verificable.

**Sobre el borrado de datos — página ya redactada, falta subirla:**
Google pide **una URL pública** donde el usuario pueda pedir la eliminación, accesible
**sin instalar la app**. El borrado ya existía dentro de la app
(Perfil > Zona de peligro > Eliminar mi cuenta), pero faltaba la página web.

Ya está escrita en [legal/eliminar-cuenta.html](legal/eliminar-cuenta.html), con el mismo
estilo de los otros dos legales y enlazada desde ambos. Explica las dos vías (app y
correo), qué se borra, qué se conserva y por qué.

**⏳ Acción manual pendiente:** subirla por cPanel a la carpeta
`educanexo360.creativebycode.com` (la misma donde ya están
`politica-de-privacidad.html` y `terminos.html` — **no** es `public_html`).

URL a declarar en el formulario:
`https://educanexo360.creativebycode.com/eliminar-cuenta.html`

---

### Paso 2: Tipos de datos — qué marcar y qué NO

| Categoría | Subtipo | ¿Marcar? | Motivo |
|---|---|:--:|---|
| **Ubicación** | Aproximada / Precisa | ❌ | No hay permisos ni plugins de ubicación |
| **Información personal** | Nombre | ✅ | Login y perfil |
| | Dirección de correo electrónico | ✅ | Es el identificador de login |
| | ID de usuario | ✅ | `_id` de Mongo en cada petición |
| | Número de teléfono | ✅ | Campo editable en Perfil |
| | Domicilio | ❌ | Se *muestra*, nunca se captura desde la app |
| | Otra información | ✅ | Datos académicos: notas, asistencia, observaciones |
| **Información financiera** | — | ❌ | No hay pagos ni compras |
| **Salud y actividad física** | — | ❌ | — |
| **Mensajes** | Otros mensajes en la app | ✅ | Módulo de mensajería |
| | Correos / SMS | ❌ | No se lee el correo ni los SMS del dispositivo |
| **Fotos y videos** | Fotos | ✅ | Adjuntos jpg/png/gif/webp en mensajes |
| | Videos | ⚠️ | Ver "acción recomendada" abajo |
| **Archivos de audio** | — | ❌ | Sin micrófono ni grabación |
| **Archivos y documentos** | — | ✅ | Entregas de tareas, material, adjuntos |
| **Calendario** | Eventos del calendario | ❌ | El calendario es interno de la app, **no** el del dispositivo |
| **Contactos** | — | ❌ | No se lee la agenda |
| **Actividad en apps** | Todas | ❌ | Sin analítica de comportamiento |
| **Navegación web** | — | ❌ | — |
| **Rendimiento de la app** | Fallas / Diagnóstico | ❌ | No hay Crashlytics ni Performance Monitoring |
| **Dispositivo u otros IDs** | — | ✅ | Token FCM + Firebase Installation ID |

**✅ Sobre "Videos" — RESUELTO el 2026-08-13, NO marcar:**
el selector de archivos de **anuncios** y **eventos** usaba `FileType.any`, así que un
docente podía adjuntar un video. Ya se restringió a la misma lista blanca de mensajes
(`pdf, doc, docx, xls, xlsx, txt, jpg, jpeg, png, gif, webp`) en
[create_anuncio_screen.dart](lib/screens/anuncios/create_anuncio_screen.dart) y
[create_evento_screen.dart](lib/screens/calendario/create_evento_screen.dart). Con eso
los tres selectores de la app aceptan lo mismo, la declaración es exacta y de paso nadie
sube un archivo de 200 MB a GridFS.

---

### Paso 3: Detalle de cada tipo marcado

Para cada uno Play pregunta lo mismo: si se **recopila**, si se **comparte**, si es
**obligatorio u opcional**, y **para qué**.

> **Los cuatro se responden "Compartidos: NO".** Google define "compartir" como
> transferir a un tercero, y **excluye** explícitamente a los proveedores de servicios
> que procesan datos en tu nombre. Firebase/FCM entra ahí: es un proveedor, no un
> tercero. Por eso el token FCM se declara *recopilado* pero **no** *compartido*.

| Dato | Recopilado | Compartido | Obligatorio/Opcional | Finalidades |
|---|:--:|:--:|---|---|
| Nombre | Sí | No | Obligatorio | Funciones de la app · Administración de cuentas |
| Correo electrónico | Sí | No | Obligatorio | Funciones de la app · Administración de cuentas |
| ID de usuario | Sí | No | Obligatorio | Funciones de la app · Administración de cuentas |
| Número de teléfono | Sí | No | **Opcional** | Funciones de la app |
| Otra información (académicos) | Sí | No | Obligatorio | Funciones de la app |
| Otros mensajes en la app | Sí | No | **Opcional** | Funciones de la app |
| Fotos | Sí | No | **Opcional** | Funciones de la app |
| Archivos y documentos | Sí | No | **Opcional** | Funciones de la app |
| Dispositivo u otros IDs | Sí | No | Obligatorio | Funciones de la app |

**En NINGUNO marques:** Publicidad o marketing · Estadísticas · Personalización ·
Prevención de fraudes. Es cierto y además mantiene la tarjeta pública limpia, que es
justo lo que tranquiliza a un papá antes de instalar.

**Notas de criterio, por si un revisor pregunta:**

- *Teléfono como opcional:* el campo se puede dejar vacío en Editar perfil.
- *Mensajes/fotos/archivos como opcionales:* la app funciona sin enviar un solo adjunto.
- *"Otra información" para lo académico:* Play no tiene categoría de expediente escolar.
  Notas y asistencia son datos personales de un estudiante identificado, así que van en
  Información personal > Otra información. La alternativa sería Actividad en apps >
  Otro contenido generado por el usuario, pero encaja peor.

---

## FORMULARIO 2 — Público objetivo y contenido

| Pregunta | Respuesta |
|---|---|
| Grupos de edad objetivo | **13-15, 16-17, 18 y más** (nada por debajo de 13) |
| ¿La app atrae a niños menores de 13? | **No** |
| ¿Muestra anuncios? | **No** |

Marcar 13+ mantiene la app **fuera de la Política de Familias** de Google, que trae
requisitos bastante pesados (revisión de contenido, restricciones de SDK, sin publicidad
personalizada). Ya lo habías decidido así y es la decisión correcta.

**⚠️ El riesgo honesto de esta declaración:** EducaNexo360 se vende a colegios de
**primaria y secundaria**. Si el colegio cliente le crea cuenta de ESTUDIANTE a un niño
de 8 años, hay una contradicción entre lo declarado y la realidad, y eso es exactamente
el tipo de cosa por la que Google retira apps.

Cómo lo defiendes, que es sólido:

1. Las cuentas las crea el colegio, no hay registro abierto.
2. Los destinatarios reales de la app son **acudientes y docentes** (adultos).
3. En primaria quien usa la app es el papá, no el niño.

**Recomendación concreta:** deja constancia de esto por contrato con el colegio —
que las cuentas de estudiante sean para mayores de 13 y que en primaria use la app el
acudiente. Es una línea en el contrato y te cubre.

---

## FORMULARIO 3 — Clasificación de contenido (IARC)

Cuestionario. Las respuestas relevantes:

| Pregunta | Respuesta |
|---|---|
| Categoría | **Educación / Referencia** |
| ¿Violencia, sexo, lenguaje ofensivo, drogas, apuestas? | **No** a todo |
| ¿Los usuarios pueden interactuar o intercambiar contenido? | **Sí** ⚠️ |
| ¿Comparte la ubicación del usuario con otros? | **No** |
| ¿Permite compras digitales? | **No** |
| ¿Contenido generado por usuarios sin moderar? | Ver abajo |

**⚠️ Hallazgo — esto lo revisé y no está en la app:**
decir "Sí" en interacción entre usuarios activa la **política de contenido generado por
el usuario (UGC)** de Google, que exige un sistema para **denunciar** contenido o
usuarios ofensivos y para **bloquear** a un usuario. Busqué en
[lib/screens/mensajes/](lib/screens/mensajes/) y **no existe ninguna de las dos cosas**.

Lo que juega a tu favor: es una red **cerrada**: solo se comunican miembros del mismo
colegio, con cuentas creadas por el administrador, y el admin puede desactivar a
cualquiera desde la web. Eso es moderación real y suele bastar.

Tres opciones, de menor a mayor esfuerzo:

- **(A)** Enviar así y explicar la red cerrada en las notas del revisor. Puede pasar.
  Es apuesta, no certeza.
- **(B) Recomendado —** añadir un botón "Reportar mensaje" en el detalle del mensaje que
  cree una notificación al ADMIN del colegio. Es una pantalla y un endpoint; cierra el
  tema sin discusión.
- **(C)** Reportar + bloquear usuario. Más trabajo y no creo que lo necesites.

---

## Evidencia en el código

Para sostener cada respuesta si un revisor pregunta:

| Afirmación | Dónde se verifica |
|---|---|
| Sin ubicación, cámara ni almacenamiento | [AndroidManifest.xml:4-9](android/app/src/main/AndroidManifest.xml#L4-L9) — solo INTERNET, ACCESS_NETWORK_STATE y POST_NOTIFICATIONS |
| Sin analítica ni crash reporting | [pubspec.yaml:41-43](pubspec.yaml#L41-L43) — solo `firebase_core` y `firebase_messaging` |
| Datos personales recogidos | [usuario.dart:139-164](lib/models/usuario.dart#L139-L164) |
| Campos editables por el usuario | [editar_perfil_screen.dart:262-329](lib/screens/perfil/editar_perfil_screen.dart#L262-L329) — nombre, apellidos, teléfono, email |
| Token FCM + versión del SO al backend | [fcm_service.dart:123-147](lib/services/fcm_service.dart#L123-L147) |
| Token JWT cifrado en el dispositivo | [storage_service.dart:15-19](lib/services/storage_service.dart#L15-L19) — `encryptedSharedPreferences: true` |
| Fotos como adjunto de mensaje | [create_message_screen.dart:127-131](lib/screens/mensajes/create_message_screen.dart#L127-L131) |
| Descargas al directorio privado de la app | [message_service.dart:566-570](lib/services/message_service.dart#L566-L570) |
| Borrado de cuenta desde la app | [perfil_screen.dart:435](lib/screens/perfil/perfil_screen.dart#L435) → `POST /usuarios/eliminar-cuenta` |
| Enlaces legales en Perfil | [app_config.dart:44-47](lib/config/app_config.dart#L44-L47) |

---

## Acciones antes de enviar

| # | Acción | Estado | Bloquea envío |
|:-:|---|:--:|:--:|
| 1 | Redactar la página de eliminación de cuenta | ✅ hecho | — |
| 2 | **Subir `eliminar-cuenta.html` a cPanel** | ⏳ manual | Sí |
| 3 | Quitar `image_picker` del `pubspec.yaml` — ver abajo | ✅ hecho | — |
| 4 | Restringir `FileType.any` en anuncios y eventos | ✅ hecho | — |
| 5 | **Regenerar el `.aab`** (el actual trae `image_picker`) | ⏳ | Sí |
| 6 | Botón "Reportar mensaje" (opción B del formulario 3) | ⏳ decisión | No |
| 7 | Dejar por contrato que las cuentas de estudiante son 13+ | ⏳ | No |

**Sobre el punto 3 —** `image_picker: ^1.0.0` estaba en el `pubspec.yaml` pero **no se
importaba en ningún archivo de `lib/`**. Exactamente el mismo caso de
`permission_handler`, que ya habíamos quitado. Por qué importaba:

- En **iOS** era un problema real: el plugin enlaza las APIs de fototeca y cámara, y el
  `Info.plist` **no** tiene `NSPhotoLibraryUsageDescription` ni `NSCameraUsageDescription`.
  Apple rechaza automáticamente por "accede a datos sensibles sin descripción de uso".
- En **Android** no rompía nada, pero era peso muerto en el `.aab` y una incoherencia con
  la declaración de Data Safety (un plugin de fotos en una app que declara no recopilar
  fotos de la galería).

Verificado tras quitarlo: `flutter pub get` OK y `flutter analyze` con **0 errores** y
cero referencias a `image_picker`.

**⚠️ Sobre el punto 5 —** el `.aab` que ya está construido y verificado se generó
*antes* de estos cambios, así que todavía incluye `image_picker`. Hay que regenerarlo
antes de subirlo:

```
flutter build appbundle --release --dart-define=API_URL=https://educanexo360.creativebycode.com/educanexo360/api
```

Y volver a comprobar la firma antes de subir — es la trampa que ya nos mordió una vez:

```
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```

Debe decir `CN=Aymer Ivan Obando Valois, O=Creativebycode SAS`. Si dice
`CN=Android Debug`, **no subir**.
