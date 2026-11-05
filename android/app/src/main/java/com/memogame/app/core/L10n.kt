package com.memogame.app.core

import android.app.Activity
import android.content.Context
import android.content.Intent
import org.json.JSONObject
import java.util.Locale

/**
 * In-app translations — port of the iOS L10n. The tables are the shared
 * localization/l10n/<lang>.json files at the repo root (wired in as an assets
 * dir by app/build.gradle.kts), keyed by the English text, so both platforms
 * always show the same words. Placeholders are {0}, {1}… filled positionally.
 */
object L10n {
    private val supported = setOf("en", "hi", "es", "pt", "id", "de", "fr")
    private const val PREFS = "l10n"
    private const val KEY_OVERRIDE = "language"

    /** Each language's name in itself, in the order the picker lists them. */
    val nativeNames = linkedMapOf(
        "en" to "English", "hi" to "हिन्दी", "es" to "Español", "pt" to "Português",
        "id" to "Bahasa Indonesia", "de" to "Deutsch", "fr" to "Français"
    )

    private lateinit var appContext: Context
    private var loadedLanguage: String? = null
    /** Language of the first lookup this process made. */
    private var processLanguage: String? = null
    private var table: Map<String, String> = emptyMap()

    /**
     * Language picked in the app's own Settings, or null to follow the
     * device. Android 12 and older have no per-app language setting, and many
     * parents keep the phone in English while the child plays in Hindi.
     */
    var override: String? = null
        private set

    fun init(context: Context) {
        appContext = context.applicationContext
        override = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_OVERRIDE, null)?.takeIf { it in supported }
    }

    /** Saves the in-app language ([code] null = device) and relaunches into it. */
    fun setOverride(activity: Activity, code: String?) {
        override = code?.takeIf { it in supported }
        activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_OVERRIDE, override).commit()
        restartIfLanguageChanged(activity)
    }

    /** The device's own language, if the app has a table for it. */
    val deviceLanguage: String
        get() = Locale.getDefault().language.let { if (it == "in") "id" else it }
            .takeIf { it in supported } ?: "en"

    /**
     * The in-app override wins; otherwise the device language. The system
     * per-app picker (Android 13+) changes the default locale without
     * necessarily restarting the process, so this is re-read on every lookup
     * and the table reloaded when it moves.
     */
    val language: String
        get() = override ?: deviceLanguage

    @Synchronized
    fun string(key: String, args: Array<out Any?>): String {
        val lang = language
        if (processLanguage == null) processLanguage = lang
        if (lang != loadedLanguage) {
            table = load(lang)
            loadedLanguage = lang
        }
        var out = table[key] ?: key
        args.forEachIndexed { index, arg -> out = out.replace("{$index}", arg.toString()) }
        return out
    }

    /**
     * True when the app language moved since this process started. Catalogs,
     * enums and tips cache their text once per process, so after a language
     * switch the only clean fix is a fresh process.
     */
    fun languageChangedSinceLaunch(): Boolean =
        processLanguage != null && processLanguage != language

    /** Relaunches the app in a fresh process. Returns true if it did. */
    fun restartIfLanguageChanged(activity: Activity): Boolean {
        if (!languageChangedSinceLaunch()) return false
        val intent = activity.packageManager.getLaunchIntentForPackage(activity.packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        activity.startActivity(intent)
        Runtime.getRuntime().exit(0)
        return true
    }

    private fun load(lang: String): Map<String, String> {
        if (!::appContext.isInitialized) return emptyMap()
        return runCatching {
            val json = appContext.assets.open("l10n/$lang.json").bufferedReader().use { it.readText() }
            val obj = JSONObject(json)
            obj.keys().asSequence().associateWith { obj.getString(it) }
        }.getOrDefault(emptyMap())
    }
}

/** Translates [key] (the English text) into the app language. */
fun tr(key: String, vararg args: Any?): String = L10n.string(key, args)
