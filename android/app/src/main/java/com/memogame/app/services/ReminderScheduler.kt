package com.memogame.app.services

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.memogame.app.MainActivity
import com.memogame.app.R
import java.util.Calendar

/**
 * On-device (local) reminders only — no backend, no push tokens. Port of the
 * iOS NotificationManager: a daily 18:00 nudge plus a one-shot "we miss you"
 * reminder re-armed on every launch.
 */
object ReminderScheduler {
    const val CHANNEL_ID = "reminders"
    private const val DAILY_REQUEST_CODE = 1001
    private const val INACTIVITY_REQUEST_CODE = 1002
    const val ACTION_DAILY = "com.memogame.app.DAILY_REMINDER"
    const val ACTION_INACTIVITY = "com.memogame.app.INACTIVITY_REMINDER"

    fun createChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID, "Reminders", NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Daily play reminders"
        }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        manager.createNotificationChannel(channel)
    }

    fun hasPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    /** Schedules all opt-in local reminders (daily + inactivity). */
    fun scheduleReminders(context: Context) {
        scheduleDailyReminder(context)
        scheduleInactivityReminder(context)
    }

    /** Repeating daily reminder at the given local time (default 18:00). */
    fun scheduleDailyReminder(context: Context, hour: Int = 18, minute: Int = 0) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val next = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        alarmManager.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            next.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pendingIntent(context, DAILY_REQUEST_CODE, ACTION_DAILY)
        )
    }

    /**
     * One-off "we miss you" reminder N days out. Re-armed on every launch, so
     * it only fires if the player stays away that long.
     */
    fun scheduleInactivityReminder(context: Context, afterDays: Int = 2) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val triggerAt = System.currentTimeMillis() + afterDays * 24L * 60 * 60 * 1000
        alarmManager.set(
            AlarmManager.RTC_WAKEUP,
            triggerAt,
            pendingIntent(context, INACTIVITY_REQUEST_CODE, ACTION_INACTIVITY)
        )
    }

    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(pendingIntent(context, DAILY_REQUEST_CODE, ACTION_DAILY))
        alarmManager.cancel(pendingIntent(context, INACTIVITY_REQUEST_CODE, ACTION_INACTIVITY))
    }

    /** Re-arms reminders on launch if enabled (and resets the inactivity clock). */
    fun refreshReminders(context: Context, enabled: Boolean): Boolean {
        if (!enabled) {
            cancelAll(context)
            return false
        }
        if (!hasPermission(context)) return false
        scheduleReminders(context)
        return true
    }

    private fun pendingIntent(context: Context, requestCode: Int, action: String): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).setAction(action)
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ReminderScheduler.hasPermission(context)) return

        val body = when (intent.action) {
            ReminderScheduler.ACTION_INACTIVITY ->
                "We miss you! 🧩 Your next memory challenge is waiting."
            else ->
                "🧠 Ready for today's challenge? Train your memory and keep your streak going!"
        }

        val tapIntent = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, ReminderScheduler.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Memory Match")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(tapIntent)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val id = if (intent.action == ReminderScheduler.ACTION_INACTIVITY) 2 else 1
        runCatching { manager.notify(id, notification) }
    }
}
