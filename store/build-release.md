# Build de release — EducaNexo360 (Android)

Comandos exactos para generar la versión que se sube a Google Play o se instala a mano.
Ejecutar desde la raíz del proyecto (`educanexo360_app/`).

## 1. Antes de compilar

1. **Subir la versión** en `pubspec.yaml` → `version: X.Y.Z+N`
   - `X.Y.Z` = versionName (lo que ve el usuario).
   - `N` = versionCode. **Debe aumentar en cada subida a Play** (nunca se reutiliza).
   - Versión actual: `1.1.0+2`.
2. **Firma**: debe existir `android/key.properties` apuntando al keystore de producción
   (`storeFile` es relativo a la carpeta `android/`). Ese archivo y el `.jks` **no se versionan**.
3. `flutter pub get` y `flutter analyze` sin errores; `flutter test` en verde.

## 2. Comandos

La URL del API es **obligatoria** en release: sin `--dart-define=API_URL=https://...`
la app arranca en una pantalla roja de "Error de configuración" (a propósito, para no publicar
nunca un build apuntando a la IP de desarrollo).

**App Bundle para Google Play (.aab):**

```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define=API_URL=https://educanexo360.creativebycode.com/educanexo360/api
```

Resultado: `build/app/outputs/bundle/release/app-release.aab`

**APK para instalar directo (pruebas o distribución manual):**

```bash
flutter build apk --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define=API_URL=https://educanexo360.creativebycode.com/educanexo360/api
```

Resultado: `build/app/outputs/flutter-apk/app-release.apk`

> En PowerShell, reemplazar `\` al final de línea por `` ` `` o escribir el comando en una sola línea.

## 3. Símbolos de depuración (IMPORTANTE)

`--obfuscate` renombra clases y métodos: los errores reportados desde un teléfono llegan
ilegibles. Para traducirlos se necesitan los archivos de `build/symbols/`
(`app.android-arm64.symbols`, etc.) **de esa misma versión**.

- **Guardarlos fuera del repo** (el repo es público y `build/` se borra con `flutter clean`),
  en una carpeta por versión, por ejemplo:
  `C:\Proyectos_personales\EducaNexo360\Otros\simbolos\1.1.0+2\`
- No subirlos a git.

Traducir un stack trace ofuscado (guardado en `stack.txt`):

```bash
flutter symbolize -i stack.txt -d C:\...\simbolos\1.1.0+2\app.android-arm64.symbols
```

## 4. Verificación rápida antes de subir

- [ ] Instalar el APK en un teléfono real: arranca, inicia sesión, abre Mensajes y Tareas.
- [ ] La versión se ve correcta (`build/app/outputs/apk/release/output-metadata.json` →
      `versionCode` y `versionName`).
- [ ] Símbolos copiados a la carpeta de la versión.
- [ ] El `.aab` es el que se sube a Play Console (no el `.apk`).
