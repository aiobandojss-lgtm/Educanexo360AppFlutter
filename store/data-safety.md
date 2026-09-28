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
| **Fotos y videos** | Fotos | ✅ | Adjuntos jpg/png/gif/webp/heic en mensajes, tareas, anuncios y eventos |
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
[create_evento_screen.dart](lib/screens/calendario/create_evento_screen.dart).

**Actualización 2026-09-28 (Fase 5):** el selector de **tareas**
([file_uploader_widget.dart](lib/widgets/tareas/file_uploader_widget.dart)) seguía con
`FileType.any` (un estudiante podía adjuntar un video). Ahora los **cuatro** selectores
(tareas, mensajes, anuncios y eventos) usan una sola lista,
`AppConfig.extensionesPermitidas`, igual a la que valida el backend por extensión y
contenido: `pdf, doc, docx, xls, xlsx, ppt, pptx, txt, csv, jpg, jpeg, png, gif, webp,
heic, heif, zip`. Sin video ni audio: la declaración es exacta.

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

**✅ RESUELTO el 2026-08-13 — la app ya tiene sistema de denuncia:**
decir "Sí" en interacción entre usuarios activa la **política de contenido generado por
el usuario (UGC)** de Google, que exige un mecanismo para **denunciar** contenido
ofensivo. No existía; ahora sí.

**Cómo funciona:** en el detalle de cualquier mensaje recibido aparece un icono de
bandera. Abre un diálogo con seis motivos y un comentario opcional, y envía el reporte
—con copia del mensaje denunciado, su remitente, fecha e ID interno— al personal
administrativo del colegio (ADMIN, RECTOR, COORDINADOR, ADMINISTRATIVO) como mensaje de
**prioridad ALTA**.

**No necesitó endpoint nuevo.** El reporte viaja por la mensajería que ya existe, así que
los moderadores lo reciben en su bandeja **con notificación push y correo**, igual que
cualquier otro mensaje. Ver `reportMessage()` en
[message_service.dart](lib/services/message_service.dart) y `_ReportarMensajeDialog` en
[message_detail_screen.dart](lib/screens/mensajes/message_detail_screen.dart).

**Qué responder si el revisor pregunta por moderación:** es una red **cerrada** —solo se
comunican miembros del mismo colegio, con cuentas creadas por el administrador—, hay
denuncia dentro de la app que llega a un moderador humano, y ese moderador puede
desactivar la cuenta del infractor desde el panel web.

*No se implementó "bloquear usuario"*, y es una decisión deliberada: en una red escolar
cerrada, dejar que un estudiante bloquee a su docente rompería la comunicación oficial
que es justamente el propósito de la plataforma. La moderación la ejerce el colegio.

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
| 4 | Restringir `FileType.any` en anuncios, eventos y tareas | ✅ hecho | — |
| 5 | Botón "Reportar mensaje" (política UGC) | ✅ hecho | — |
| 6 | Regenerar el `.aab` y verificar firma | ✅ hecho | — |
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

---

## El `.aab` de producción — regenerado el 2026-08-13

```
flutter build appbundle --release --dart-define=API_URL=https://educanexo360.creativebycode.com/educanexo360/api
```

Resultado: `build/app/outputs/bundle/release/app-release.aab`, 46.7 MB.

**Verificaciones hechas sobre este `.aab`** (repetirlas siempre antes de subir, la
trampa de la firma ya nos mordió una vez):

| Verificación | Resultado |
|---|---|
| Firma (`keytool -printcert -jarfile`) | `CN=Aymer Ivan Obando Valois, O=Creativebycode SAS` |
| SHA1 | `AB:AB:72:19:52:D7:81:1F:61:BB:66:04:83:D0:84:58:E7:B1:04:0D` |
| URL de producción en `libapp.so` | Presente en las 3 arquitecturas |
| Rastros de `image_picker` | Ninguno, ni en entradas ni en el binario |
| URL de desarrollo | Ninguna: `http://`, `192.168.1.7` y `:3000` ausentes |

```
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```

Si alguna vez dice `CN=Android Debug`, **no subir**.

> **Falso positivo conocido:** buscar la cadena `192.168` en el binario **sí da
> resultado**, una vez por arquitectura. No es una URL: es el literal del guardia
> `baseUrl.contains('192.168')` de `AppConfig.isProduction`. La URL de desarrollo
> completa sí fue eliminada por el compilador. Busca `http://192.168` o `:3000`, no
> `192.168` a secas.
