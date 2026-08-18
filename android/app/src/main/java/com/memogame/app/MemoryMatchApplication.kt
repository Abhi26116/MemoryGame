package com.memogame.app

import android.app.Application
import com.memogame.app.services.ReminderScheduler

class MemoryMatchApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Only the notification channel is created here. AdMob/Billing/haptics
        // init is deferred to MainActivity.onCreate: Application.onCreate also
        // runs for a bare BroadcastReceiver-only process start (the daily
        // reminder alarm with the app closed), and pulling in SDK init,
        // network calls, and a Play Billing service bind on that cold start
        // risks a background ANR for work the receiver never needs.
        ReminderScheduler.createChannel(this)
    }
}
