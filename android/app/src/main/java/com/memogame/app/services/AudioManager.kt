package com.memogame.app.services

import android.media.AudioManager
import android.media.ToneGenerator

/**
 * Lightweight sound effects using system tones — no bundled audio assets, same
 * as the iOS build (which uses Apple system sound IDs).
 */
object GameAudio {
    @Volatile
    var soundEnabled = true

    private fun play(tone: Int, durationMs: Int = 120) {
        if (!soundEnabled) return
        try {
            val generator = ToneGenerator(AudioManager.STREAM_MUSIC, 70)
            generator.startTone(tone, durationMs)
            // Release after the tone finishes to avoid leaking the generator.
            // The sleep is guarded too: an uncaught InterruptedException on a
            // background thread would kill the whole process.
            Thread {
                runCatching { Thread.sleep(durationMs + 80L) }
                runCatching { generator.release() }
            }.start()
        } catch (_: RuntimeException) {
            // ToneGenerator can fail if audio resources are unavailable — sound
            // is a nicety, never crash for it.
        }
    }

    fun playFlip() = play(ToneGenerator.TONE_PROP_BEEP, 90)
    fun playSuccess() = play(ToneGenerator.TONE_PROP_ACK, 150)
    fun playComplete() = play(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 300)
    fun playMismatch() = play(ToneGenerator.TONE_PROP_NACK, 150)
}
