package com.memogame.app.services

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Semantic haptic feedback — port of the iOS HapticManager. Every call takes
 * the player's `enabled` preference so haptics stay off when disabled.
 */
object HapticManager {
    private var vibrator: Vibrator? = null

    fun init(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun vibrate(enabled: Boolean, durationMs: Long, amplitude: Int) {
        if (!enabled) return
        val v = vibrator ?: return
        runCatching {
            v.vibrate(VibrationEffect.createOneShot(durationMs, amplitude))
        }
    }

    private fun pattern(enabled: Boolean, timings: LongArray, amplitudes: IntArray) {
        if (!enabled) return
        val v = vibrator ?: return
        runCatching {
            v.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
        }
    }

    /** A card is flipped face-up. */
    fun cardFlip(enabled: Boolean) = vibrate(enabled, 18, 120)

    /** A pair / group matched. */
    fun match(enabled: Boolean) = pattern(enabled, longArrayOf(0, 25, 60, 35), intArrayOf(0, 140, 0, 200))

    /** A wrong guess. */
    fun mismatch(enabled: Boolean) = pattern(enabled, longArrayOf(0, 40, 60, 40), intArrayOf(0, 180, 0, 180))

    /** A life / heart was lost. */
    fun lifeLost(enabled: Boolean) = vibrate(enabled, 45, 255)

    /** Level finished with a win. */
    fun levelComplete(enabled: Boolean) =
        pattern(enabled, longArrayOf(0, 30, 60, 30, 60, 60), intArrayOf(0, 140, 0, 180, 0, 255))

    /** Level lost (out of moves / time / lives). */
    fun levelFailed(enabled: Boolean) = pattern(enabled, longArrayOf(0, 60, 80, 60), intArrayOf(0, 160, 0, 160))

    /** A new achievement unlocked. */
    fun achievement(enabled: Boolean) = match(enabled)

    /** Light selection tick (toggles, segmented choices, theme change). */
    fun selection(enabled: Boolean) = vibrate(enabled, 12, 80)
}
