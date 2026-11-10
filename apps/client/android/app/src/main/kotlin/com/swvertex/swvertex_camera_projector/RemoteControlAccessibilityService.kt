package com.swvertex.swvertex_camera_projector

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Service d'accessibilité permettant de rejouer des gestes (tap) sur l'écran
 * à partir d'une commande reçue depuis le récepteur (navigateur), pour le
 * prototype labo de contrôle à distance du mode B.
 *
 * Ce service ne fait RIEN tant que l'utilisateur ne l'a pas explicitement
 * activé dans Réglages > Accessibilité (voir docs/decisions-a-valider.md et
 * le README du client pour l'avertissement de sécurité : tant que le
 * contrôle à distance est activé côté app, quiconque atteint l'adresse du
 * flux sur le réseau local peut envoyer des gestes).
 */
class RemoteControlAccessibilityService : AccessibilityService() {
    companion object {
        private const val TAG = "RemoteControlA11y"

        @Volatile
        var instance: RemoteControlAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "Service de contrôle à distance connecté")
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Ce service n'observe rien : il ne sert qu'à envoyer des gestes.
    }

    override fun onInterrupt() {}

    /** Simule un tap à la position donnée (coordonnées écran réelles, en pixels). */
    fun tap(x: Float, y: Float): Boolean {
        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0, 60)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()
        return dispatchGesture(gesture, null, null)
    }

    /** Simule un glissement entre deux points (ex. défilement). */
    fun swipe(x1: Float, y1: Float, x2: Float, y2: Float, durationMs: Long): Boolean {
        val path = Path().apply {
            moveTo(x1, y1)
            lineTo(x2, y2)
        }
        val stroke = GestureDescription.StrokeDescription(path, 0, durationMs.coerceAtLeast(1))
        val gesture = GestureDescription.Builder().addStroke(stroke).build()
        return dispatchGesture(gesture, null, null)
    }
}
