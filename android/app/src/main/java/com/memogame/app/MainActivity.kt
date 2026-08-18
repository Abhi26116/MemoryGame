package com.memogame.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.remember
import com.memogame.app.core.MemoryMatchTheme
import com.memogame.app.services.AdsManager
import com.memogame.app.services.GameAudio
import com.memogame.app.services.HapticManager
import com.memogame.app.services.ProgressStore
import com.memogame.app.services.StoreManager
import com.memogame.app.ui.MemoryMatchRoot

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Deferred here rather than Application.onCreate so a receiver-only
        // cold start (daily reminder alarm) never triggers this work.
        HapticManager.init(this)
        AdsManager.configure(this)
        StoreManager.get(this) // connects to Play Billing and refreshes entitlement

        val progressStore = ProgressStore(this)
        GameAudio.soundEnabled = progressStore.settings.soundEnabled

        setContent {
            val store = remember { progressStore }
            MemoryMatchTheme(appearanceMode = store.appearanceMode) {
                MemoryMatchRoot(store)
            }
        }
    }
}
