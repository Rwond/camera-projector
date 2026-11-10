package com.swvertex.swvertex_camera_projector

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.NetworkInterface

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.swvertex.camera_projector/projection_test"
        const val REQUEST_MEDIA_PROJECTION = 0x5357
    }

    private val projectionManager: MediaProjectionManager by lazy {
        getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    }
    private var pendingStartResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(statusMap())
                "start" -> startProjection(result)
                "stop" -> {
                    val stopIntent = Intent(this, ScreenStreamService::class.java).apply {
                        action = ScreenStreamService.ACTION_STOP
                    }
                    startService(stopIntent)
                    result.success(statusMap())
                }
                "isAccessibilityServiceEnabled" -> result.success(isRemoteControlAccessibilityEnabled())
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "setRemoteControlEnabled" -> {
                    ScreenStreamService.remoteControlEnabled = call.argument<Boolean>("enabled") == true
                    result.success(ScreenStreamService.remoteControlEnabled)
                }
                "isRemoteControlEnabled" -> result.success(ScreenStreamService.remoteControlEnabled)
                else -> result.notImplemented()
            }
        }
    }

    private fun startProjection(result: MethodChannel.Result) {
        if (ScreenStreamService.isRunning) {
            result.success(statusMap())
            return
        }
        if (pendingStartResult != null) {
            result.error("BUSY", "Une demande de capture est déjà en cours.", null)
            return
        }
        pendingStartResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION)
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_MEDIA_PROJECTION) return

        val pending = pendingStartResult
        pendingStartResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            pending?.error("PERMISSION_DENIED", "Capture d'écran refusée.", null)
            return
        }

        val serviceIntent = Intent(this, ScreenStreamService::class.java).apply {
            action = ScreenStreamService.ACTION_START
            putExtra(ScreenStreamService.EXTRA_RESULT_CODE, resultCode)
            putExtra(ScreenStreamService.EXTRA_RESULT_DATA, data)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }

        // Laisse au service le temps d'ouvrir son serveur avant de répondre à Dart.
        // L'écran Flutter interroge ensuite /status jusqu'à ce que la capture soit active.
        Handler(Looper.getMainLooper()).postDelayed({
            pending?.success(statusMap())
        }, 700)
    }

    private fun statusMap(): Map<String, Any?> {
        val ip = localIpv4()
        val port = ScreenStreamService.activePort
        return mapOf(
            "running" to ScreenStreamService.isRunning,
            "ip" to ip,
            "port" to port.takeIf { it > 0 },
            "url" to if (ip != null && port > 0) "http://$ip:$port/" else null,
            "error" to ScreenStreamService.lastError,
        )
    }

    private fun isRemoteControlAccessibilityEnabled(): Boolean {
        val manager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = manager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_GENERIC,
        )
        return enabledServices.any { it.resolveInfo.serviceInfo.packageName == packageName }
    }

    private fun localIpv4(): String? {
        var fallback: String? = null
        try {
            for (networkInterface in NetworkInterface.getNetworkInterfaces()) {
                if (!networkInterface.isUp || networkInterface.isLoopback) continue
                for (address in networkInterface.inetAddresses) {
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                        val ip = address.hostAddress ?: continue
                        val name = networkInterface.name.lowercase()
                        if (name.startsWith("wlan") || name.startsWith("ap") || name.startsWith("eth")) {
                            return ip
                        }
                        if (fallback == null) fallback = ip
                    }
                }
            }
        } catch (_: Exception) {
            // Aucune interface exploitable : l'URL restera indisponible.
        }
        return fallback
    }
}
