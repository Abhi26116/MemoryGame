package com.memogame.app.services

import android.app.Activity
import android.content.Context
import android.util.Log
import com.google.android.ump.ConsentDebugSettings
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.FormError
import com.google.android.ump.UserMessagingPlatform
import com.memogame.app.BuildConfig

/**
 * Google UMP (User Messaging Platform) consent gathering — port of the iOS
 * ConsentManager.
 *
 * This has to finish before `MobileAds.initialize`: in the EEA/UK/Switzerland
 * an ad request carrying no consent signal is refused outright — not downgraded
 * to non-personalized, refused — so without this the app serves zero ads there.
 *
 * Both UMP entry points below need an Activity (not an application Context),
 * and both call back on the main thread.
 */
object ConsentManager {
    private const val TAG = "Consent"

    /**
     * Off, so EEA/UK users get the published "European regulations" consent
     * form and Settings shows the Privacy Options row when UMP requires it.
     * Setting it to `true` makes Google treat the form as ineligible and UMP
     * resolves to "no consent needed, serve non-personalized" instead.
     *
     * Note: ad requests are still tagged child-directed ([AdsManager.configure]
     * sets `TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE`), which forces
     * non-personalized ads regardless of what the user picks here.
     */
    private const val TAG_FOR_UNDER_AGE_OF_CONSENT = false

    private var gathered = false
    private var gathering = false
    private val waiters = mutableListOf<() -> Unit>()

    /**
     * UMP's verdict on whether an ad request is allowed at all. False until
     * UMP has resolved the user's region and consent state.
     */
    fun canRequestAds(context: Context): Boolean =
        UserMessagingPlatform.getConsentInformation(context).canRequestAds()

    /**
     * Refreshes consent info and shows the form if UMP says one is required,
     * then runs [onComplete] on the main thread.
     *
     * Safe to call more than once: concurrent callers queue onto the single
     * in-flight run rather than starting a second one, so an ad request can
     * never slip out ahead of consent.
     */
    fun gather(activity: Activity, onComplete: () -> Unit) {
        if (gathered) {
            onComplete()
            return
        }
        waiters += onComplete
        if (gathering) return
        gathering = true

        val paramsBuilder = ConsentRequestParameters.Builder()
            .setTagForUnderAgeOfConsent(TAG_FOR_UNDER_AGE_OF_CONSENT)
        if (BuildConfig.DEBUG) {
            debugSettings(activity)?.let { paramsBuilder.setConsentDebugSettings(it) }
        }

        val consentInformation = UserMessagingPlatform.getConsentInformation(activity)
        consentInformation.requestConsentInfoUpdate(
            activity,
            paramsBuilder.build(),
            { showFormIfRequired(activity, consentInformation) },
            { error ->
                // Leaves canRequestAds() false, so no ads this launch. UMP
                // caches its answer, so the next launch recovers on its own.
                if (BuildConfig.DEBUG) {
                    Log.d(TAG, "Info update failed: ${error.errorCode} — ${error.message}")
                }
                finishGathering()
            }
        )
    }

    private fun showFormIfRequired(activity: Activity, consentInformation: ConsentInformation) {
        UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { error: FormError? ->
            if (BuildConfig.DEBUG) {
                if (error != null) {
                    Log.d(TAG, "Form failed: ${error.errorCode} — ${error.message}")
                }
                Log.d(
                    TAG,
                    "status=${consentInformation.consentStatus} " +
                        "canRequestAds=${consentInformation.canRequestAds()} " +
                        "privacyOptions=${consentInformation.privacyOptionsRequirementStatus}"
                )
            }
            finishGathering()
        }
    }

    private fun finishGathering() {
        gathered = true
        gathering = false
        val pending = waiters.toList()
        waiters.clear()
        pending.forEach { it() }
    }

    // region Privacy options (re-entry from Settings)

    /**
     * True when UMP says this user must be given a way to change their answer
     * after the fact. Settings shows its "Privacy Options" row only then —
     * regulators expect the entry point, and UMP is what knows whether this
     * particular user is owed one.
     */
    fun privacyOptionsRequired(context: Context): Boolean =
        UserMessagingPlatform.getConsentInformation(context)
            .privacyOptionsRequirementStatus ==
            ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

    /** Re-presents the consent form so the user can change their answer. */
    fun showPrivacyOptions(activity: Activity, onComplete: (FormError?) -> Unit) {
        UserMessagingPlatform.showPrivacyOptionsForm(activity) { error: FormError? ->
            if (BuildConfig.DEBUG && error != null) {
                Log.d(TAG, "Privacy options failed: ${error.errorCode} — ${error.message}")
            }
            onComplete(error)
        }
    }

    // endregion

    /**
     * Forces an EEA run on a non-EEA device so the flow can actually be
     * exercised. Needs this device's hashed ID, which UMP logs on launch as
     * "Use new ConsentDebugSettings.Builder().addTestDeviceHashedId("...")" —
     * paste it below. Empty list means no debug override (UMP ignores a
     * geography with no registered device).
     */
    private fun debugSettings(context: Context): ConsentDebugSettings? {
        val testDeviceHashedIds = emptyList<String>()
        if (testDeviceHashedIds.isEmpty()) return null
        return ConsentDebugSettings.Builder(context)
            .setDebugGeography(ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA)
            .apply { testDeviceHashedIds.forEach { addTestDeviceHashedId(it) } }
            .build()
    }
}
