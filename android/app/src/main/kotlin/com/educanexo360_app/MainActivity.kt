package com.educanexo360.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal para abrir los ajustes del teléfono desde el perfil
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_AJUSTES)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "abrirNotificaciones" -> result.success(abrirAjustesNotificaciones())
                    else -> result.notImplemented()
                }
            }
    }

    // Pantalla de notificaciones de la app (Android 8+). Si el teléfono no la
    // tiene, la pantalla de información de la app. Devuelve si pudo abrir alguna.
    private fun abrirAjustesNotificaciones(): Boolean {
        val notificaciones = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            null
        }
        val infoApp = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )

        for (intent in listOfNotNull(notificaciones, infoApp)) {
            try {
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // Fabricante sin esa pantalla: probar la siguiente
            }
        }
        return false
    }

    companion object {
        private const val CANAL_AJUSTES = "educanexo360/ajustes"
    }
}
