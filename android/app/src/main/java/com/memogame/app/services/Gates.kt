package com.memogame.app.services

import android.app.Activity
import android.content.Context
import com.google.android.play.core.review.ReviewManagerFactory
import java.util.Calendar

/**
 * Decides WHEN it's appropriate to ask for Play's native in-app rating prompt.
 * Google itself caps how often the prompt actually shows, but we still
 * self-limit so we're not calling it at every single win.
 */
object ReviewPromptGate {
    private const val LAST_REQUEST_KEY = "reviewLastRequestDate"
    private const val REQUEST_COUNT_KEY = "reviewRequestCount"
    private const val MIN_DAYS_BETWEEN_REQUESTS = 60
    private const val MAX_LIFETIME_REQUESTS = 4

    private fun prefs(context: Context) =
        context.getSharedPreferences("memory_game_store", Context.MODE_PRIVATE)

    fun shouldRequest(context: Context): Boolean {
        val p = prefs(context)
        if (p.getInt(REQUEST_COUNT_KEY, 0) >= MAX_LIFETIME_REQUESTS) return false

        val last = p.getLong(LAST_REQUEST_KEY, 0L)
        if (last > 0L) {
            val days = (System.currentTimeMillis() - last) / (24L * 60 * 60 * 1000)
            if (days < MIN_DAYS_BETWEEN_REQUESTS) return false
        }
        return true
    }

    fun markRequested(context: Context) {
        val p = prefs(context)
        p.edit()
            .putLong(LAST_REQUEST_KEY, System.currentTimeMillis())
            .putInt(REQUEST_COUNT_KEY, p.getInt(REQUEST_COUNT_KEY, 0) + 1)
            .apply()
    }

    /** Fires the Play in-app review flow (Play decides whether to actually show it). */
    fun launchReview(activity: Activity) {
        val manager = ReviewManagerFactory.create(activity)
        manager.requestReviewFlow().addOnCompleteListener { task ->
            // The flow resolves async — the player may have left by then, and
            // launching over a finishing activity can crash.
            if (task.isSuccessful && !activity.isFinishing && !activity.isDestroyed) {
                manager.launchReviewFlow(activity, task.result)
            }
        }
    }
}

/**
 * Tracks the last time ANY "Remove Ads" showcase was shown so a player is
 * never shown more than one ad-free pitch per calendar day.
 */
object RemoveAdsPromptGate {
    private const val LAST_SHOWN_KEY = "removeAdsPromptLastShownDate"

    private fun prefs(context: Context) =
        context.getSharedPreferences("memory_game_store", Context.MODE_PRIVATE)

    fun shownToday(context: Context): Boolean {
        val last = prefs(context).getLong(LAST_SHOWN_KEY, 0L)
        if (last == 0L) return false
        val lastCal = Calendar.getInstance().apply { timeInMillis = last }
        val today = Calendar.getInstance()
        return lastCal.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
            lastCal.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR)
    }

    fun markShownToday(context: Context) {
        prefs(context).edit().putLong(LAST_SHOWN_KEY, System.currentTimeMillis()).apply()
    }
}
