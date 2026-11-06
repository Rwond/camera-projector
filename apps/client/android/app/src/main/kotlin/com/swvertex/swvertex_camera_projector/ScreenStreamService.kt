package com.swvertex.swvertex_camera_projector

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.DisplayMetrics
import android.util.Log
import android.view.Display
import java.io.BufferedOutputStream
import java.io.BufferedReader
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStreamReader
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.roundToInt

/**
 * Prototype "labo" du mode B : capture l'écran via MediaProjection et le diffuse
 * en MJPEG (multipart/x-mixed-replace) sur le réseau local.
 *
 * Ce n'est pas l'implémentation finale du mode B : aucun protocole projecteur
 * (Miracast/DLNA/...) n'est utilisé ici. Le but est de valider la capture, l'encodage
 * et le transport avant de brancher un vrai récepteur/projecteur.
 */
class ScreenStreamService : Service() {
    companion object {
        private const val TAG = "ScreenStreamService"
        private const val CHANNEL_ID = "swvertex_projection_test"
        private const val NOTIFICATION_ID = 5301
        private const val DEFAULT_PORT = 8080
        private const val MAX_PORT_ATTEMPTS = 20
        private const val MAX_CAPTURE_WIDTH = 720
        private const val JPEG_QUALITY = 60
        private const val FRAME_INTERVAL_MS = 100L // ~10 images/s

        const val ACTION_START = "com.swvertex.swvertex_camera_projector.START_STREAM"
        const val ACTION_STOP = "com.swvertex.swvertex_camera_projector.STOP_STREAM"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"

        @Volatile
        var isRunning: Boolean = false
            private set

        @Volatile
        var activePort: Int = -1
            private set

        @Volatile
        var lastError: String? = null
            private set
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var serverSocket: ServerSocket? = null
    private var serverThread: Thread? = null

    private val captureThread = HandlerThread("swvertex-projection-capture").apply { start() }
    private val captureHandler = Handler(captureThread.looper)

    private val latestFrame = AtomicReference<ByteArray?>(null)
    private val frameSequence = AtomicLong(0)
    private val stopping = AtomicBoolean(false)

    private var captureWidth = 0
    private var captureHeight = 0
    private var lastCaptureAt = 0L

    private var paddedBitmap: Bitmap? = null
    private var outputBitmap: Bitmap? = null
    private var outputCanvas: Canvas? = null
    private val jpegBuffer = ByteArrayOutputStream(256 * 1024)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopStreaming()
            stopSelf()
            return START_NOT_STICKY
        }

        startForegroundNotification()

        if (isRunning) return START_NOT_STICKY

        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, 0) ?: 0
        @Suppress("DEPRECATION")
        val resultData = intent?.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
        if (resultCode == 0 || resultData == null) {
            lastError = "Autorisation de capture d'écran manquante."
            stopSelf()
            return START_NOT_STICKY
        }

        return try {
            startStreaming(resultCode, resultData)
            START_NOT_STICKY
        } catch (e: Exception) {
            Log.e(TAG, "Impossible de démarrer la projection", e)
            lastError = e.message ?: "Erreur inconnue au démarrage de la projection."
            stopStreaming()
            stopSelf()
            START_NOT_STICKY
        }
    }

    override fun onDestroy() {
        stopStreaming()
        captureThread.quitSafely()
        super.onDestroy()
    }

    private fun startForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Projection (test labo)",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Capture d'écran diffusée sur le réseau local"
            }
            manager.createNotificationChannel(channel)
        }

        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Projection en cours")
                .setContentText("Écran diffusé sur le réseau local")
                .setSmallIcon(android.R.drawable.ic_menu_camera)
                .setContentIntent(openApp)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Projection en cours")
                .setContentText("Écran diffusé sur le réseau local")
                .setSmallIcon(android.R.drawable.ic_menu_camera)
                .setContentIntent(openApp)
                .setOngoing(true)
                .build()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun startStreaming(resultCode: Int, resultData: Intent) {
        lastError = null
        stopping.set(false)

        val projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val projection = projectionManager.getMediaProjection(resultCode, resultData)
            ?: throw IllegalStateException("MediaProjection indisponible.")
        mediaProjection = projection
        projection.registerCallback(
            object : MediaProjection.Callback() {
                override fun onStop() {
                    Log.i(TAG, "MediaProjection arrêté par le système")
                    stopStreaming()
                    stopSelf()
                }
            },
            Handler(Looper.getMainLooper()),
        )

        setupCapture(projection)

        val port = openServer()
        if (port <= 0) {
            throw IOException("Impossible d'ouvrir un port pour la diffusion.")
        }

        isRunning = true
        activePort = port
        Log.i(TAG, "Diffusion active sur le port $port")
    }

    private fun setupCapture(projection: MediaProjection) {
        val display = (getSystemService(Context.DISPLAY_SERVICE) as DisplayManager)
            .getDisplay(Display.DEFAULT_DISPLAY)
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        display.getRealMetrics(metrics)

        val sourceWidth = metrics.widthPixels.coerceAtLeast(2)
        val sourceHeight = metrics.heightPixels.coerceAtLeast(2)
        val scale = if (sourceWidth > MAX_CAPTURE_WIDTH) {
            MAX_CAPTURE_WIDTH.toFloat() / sourceWidth
        } else {
            1f
        }
        captureWidth = ((sourceWidth * scale).roundToInt() / 2 * 2).coerceAtLeast(2)
        captureHeight = ((sourceHeight * scale).roundToInt() / 2 * 2).coerceAtLeast(2)
        val density = (metrics.densityDpi * scale).roundToInt().coerceAtLeast(1)

        val reader = ImageReader.newInstance(
            captureWidth,
            captureHeight,
            PixelFormat.RGBA_8888,
            2,
        )
        imageReader = reader
        reader.setOnImageAvailableListener({ source ->
            val image = try {
                source.acquireLatestImage()
            } catch (_: IllegalStateException) {
                null
            } ?: return@setOnImageAvailableListener

            try {
                val now = SystemClock.elapsedRealtime()
                if (now - lastCaptureAt >= FRAME_INTERVAL_MS) {
                    lastCaptureAt = now
                    imageToJpeg(image)?.let { jpeg ->
                        latestFrame.set(jpeg)
                        frameSequence.incrementAndGet()
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Erreur de conversion d'image", e)
            } finally {
                image.close()
            }
        }, captureHandler)

        virtualDisplay = projection.createVirtualDisplay(
            "SwvertexProjectionTest",
            captureWidth,
            captureHeight,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            reader.surface,
            null,
            captureHandler,
        )
    }

    private fun imageToJpeg(image: Image): ByteArray? {
        val plane = image.planes.firstOrNull() ?: return null
        val width = image.width
        val height = image.height
        if (width <= 0 || height <= 0) return null

        val pixelStride = plane.pixelStride
        val rowStride = plane.rowStride
        if (pixelStride <= 0 || rowStride <= 0) return null
        val paddedWidth = maxOf(width, rowStride / pixelStride)

        if (paddedBitmap == null || paddedBitmap!!.width != paddedWidth ||
            paddedBitmap!!.height != height || outputBitmap == null ||
            outputBitmap!!.width != width || outputBitmap!!.height != height
        ) {
            paddedBitmap = Bitmap.createBitmap(paddedWidth, height, Bitmap.Config.ARGB_8888)
            outputBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            outputCanvas = Canvas(outputBitmap!!)
        }

        val padded = paddedBitmap ?: return null
        val output = outputBitmap ?: return null
        val canvas = outputCanvas ?: return null

        val buffer = plane.buffer
        buffer.rewind()
        padded.copyPixelsFromBuffer(buffer)
        canvas.drawBitmap(padded, 0f, 0f, null)

        jpegBuffer.reset()
        if (!output.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, jpegBuffer)) {
            return null
        }
        return jpegBuffer.toByteArray()
    }

    private fun openServer(): Int {
        for (attempt in 0 until MAX_PORT_ATTEMPTS) {
            val port = DEFAULT_PORT + attempt
            try {
                val socket = ServerSocket()
                socket.reuseAddress = true
                socket.bind(InetSocketAddress(port))
                serverSocket = socket
                activePort = port
                serverThread = Thread({ acceptLoop(socket) }, "swvertex-projection-http").apply {
                    isDaemon = true
                    start()
                }
                return port
            } catch (e: IOException) {
                Log.w(TAG, "Port $port indisponible: ${e.message}")
            }
        }
        return -1
    }

    private fun acceptLoop(socket: ServerSocket) {
        while (!socket.isClosed) {
            try {
                val client = socket.accept()
                Thread({ handleClient(client) }, "swvertex-projection-client").apply {
                    isDaemon = true
                    start()
                }
            } catch (e: IOException) {
                if (!socket.isClosed) Log.w(TAG, "Erreur d'acceptation client", e)
            }
        }
    }

    private fun handleClient(client: Socket) {
        try {
            client.soTimeout = 5000
            val reader = BufferedReader(InputStreamReader(client.getInputStream()))
            val requestLine = reader.readLine() ?: return
            val path = requestLine.split(" ").getOrNull(1)?.substringBefore('?') ?: "/"
            when {
                path == "/stream" -> streamFrames(client)
                path == "/status" -> writeResponse(
                    client,
                    "application/json; charset=utf-8",
                    "{\"running\":$isRunning,\"port\":$activePort}",
                )
                else -> writeResponse(client, "text/html; charset=utf-8", RECEIVER_HTML)
            }
        } catch (e: IOException) {
            // Le client s'est déconnecté (fermeture de l'onglet, changement de réseau...).
        } finally {
            try {
                client.close()
            } catch (_: IOException) {
            }
        }
    }

    private fun writeResponse(client: Socket, contentType: String, body: String) {
        val bytes = body.toByteArray(Charsets.UTF_8)
        val output = BufferedOutputStream(client.getOutputStream())
        output.write(
            (
                "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: $contentType\r\n" +
                    "Content-Length: ${bytes.size}\r\n" +
                    "Cache-Control: no-store\r\n" +
                    "Connection: close\r\n\r\n"
                ).toByteArray(Charsets.US_ASCII),
        )
        output.write(bytes)
        output.flush()
    }

    private fun streamFrames(client: Socket) {
        client.soTimeout = 0
        val output = BufferedOutputStream(client.getOutputStream())
        output.write(
            (
                "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: multipart/x-mixed-replace; boundary=frame\r\n" +
                    "Cache-Control: no-store, no-cache, must-revalidate\r\n" +
                    "Pragma: no-cache\r\n" +
                    "Connection: close\r\n\r\n"
                ).toByteArray(Charsets.US_ASCII),
        )
        output.flush()

        var lastSequence = -1L
        while (isRunning && !client.isClosed) {
            val sequence = frameSequence.get()
            if (sequence == lastSequence) {
                Thread.sleep(15)
                continue
            }
            lastSequence = sequence
            val jpeg = latestFrame.get() ?: continue
            output.write("--frame\r\n".toByteArray(Charsets.US_ASCII))
            output.write("Content-Type: image/jpeg\r\n".toByteArray(Charsets.US_ASCII))
            output.write("Content-Length: ${jpeg.size}\r\n\r\n".toByteArray(Charsets.US_ASCII))
            output.write(jpeg)
            output.write("\r\n".toByteArray(Charsets.US_ASCII))
            output.flush()
        }
    }

    private fun stopStreaming() {
        if (!stopping.compareAndSet(false, true)) return

        isRunning = false
        activePort = -1

        try {
            serverSocket?.close()
        } catch (_: IOException) {
        }
        serverSocket = null
        serverThread = null

        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        }
        virtualDisplay = null

        try {
            imageReader?.close()
        } catch (_: Exception) {
        }
        imageReader = null

        val projection = mediaProjection
        mediaProjection = null
        try {
            projection?.stop()
        } catch (_: Exception) {
        }

        captureHandler.removeCallbacksAndMessages(null)
        latestFrame.set(null)
        frameSequence.set(0)
        paddedBitmap = null
        outputBitmap = null
        outputCanvas = null
        lastCaptureAt = 0

        @Suppress("DEPRECATION")
        stopForeground(true)
        stopping.set(false)
    }

    private val RECEIVER_HTML = """
        <!doctype html>
        <html lang="fr">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>SWVERTEX — Récepteur de test</title>
          <style>
            html, body { margin: 0; height: 100%; background: #0b0b10; color: #e8e8f0;
                         font-family: system-ui, sans-serif; }
            header { padding: 12px 16px; background: #171723; border-bottom: 1px solid #2a2a3a;
                     display: flex; align-items: center; justify-content: space-between; gap: 16px; }
            h1 { margin: 0; font-size: 16px; font-weight: 600; }
            #state { font-size: 13px; color: #9f9fb5; }
            main { height: calc(100% - 49px); display: flex; align-items: center;
                   justify-content: center; overflow: hidden; }
            img { max-width: 100%; max-height: 100%; object-fit: contain; background: #000; }
          </style>
        </head>
        <body>
          <header>
            <h1>SWVERTEX CAMERA PROJECTOR — récepteur de test</h1>
            <span id="state">En attente de l'image…</span>
          </header>
          <main><img id="stream" src="/stream" alt="Flux de l'écran du téléphone"></main>
          <script>
            const img = document.getElementById('stream');
            const state = document.getElementById('state');
            img.addEventListener('load', () => { state.textContent = 'Flux actif'; });
            img.addEventListener('error', () => {
              state.textContent = 'Flux interrompu, reconnexion…';
              setTimeout(() => { img.src = '/stream?' + Date.now(); }, 1000);
            });
          </script>
        </body>
        </html>
    """.trimIndent()
}
