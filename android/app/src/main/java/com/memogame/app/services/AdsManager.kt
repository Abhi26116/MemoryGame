package com.memogame.app.services

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.OnUserEarnedRewardListener
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.memogame.app.BuildConfig

/**
 * AdMob (kid-safe, non-personalized) — port of the iOS AdsManager.
 * Debug builds use Google's test ad units (safe to tap); release builds use
 * the live units once you fill them in below.
 */
object AdsManager {
    private const val TAG = "Ads"

    /** Debug builds use Google's test ad units. */
    val useTestAds: Boolean = BuildConfig.DEBUG

    // Google's public Android test units — always safe.
    private const val TEST_INTERSTITIAL_UNIT_ID = "ca-app-pub-3940256099942544/1033173712"
    private const val TEST_BANNER_UNIT_ID = "ca-app-pub-3940256099942544/6300978111"
    private const val TEST_REWARDED_UNIT_ID = "ca-app-pub-3940256099942544/5224354917"

    // Live Android ad units (AdMob → Tiny Genius Hub: Memory Match — Android).
    // Debug builds never use these: useTestAds routes every getter to the
    // Google test units above.
    private const val LIVE_INTERSTITIAL_UNIT_ID = "ca-app-pub-9350608203842553/7665739156"
    private const val LIVE_BANNER_UNIT_ID = "ca-app-pub-9350608203842553/6769645792"
    private const val LIVE_REWARDED_UNIT_ID = "ca-app-pub-9350608203842553/3389251094"

    val interstitialUnitId: String
        get() = if (useTestAds || LIVE_INTERSTITIAL_UNIT_ID.isBlank()) TEST_INTERSTITIAL_UNIT_ID
        else LIVE_INTERSTITIAL_UNIT_ID

    val bannerUnitId: String
        get() = if (useTestAds || LIVE_BANNER_UNIT_ID.isBlank()) TEST_BANNER_UNIT_ID
        else LIVE_BANNER_UNIT_ID

    val rewardedUnitId: String
        get() = if (useTestAds || LIVE_REWARDED_UNIT_ID.isBlank()) TEST_REWARDED_UNIT_ID
        else LIVE_REWARDED_UNIT_ID

    private var interstitial: InterstitialAd? = null
    private var gamesSinceLastAd = 0
    private const val SHOW_EVERY_N_GAMES = 3

    private var rewardedAd: RewardedAd? = null

    /**
     * True only after a banner actually loads — keeps the tab bar flush at the
     * bottom when ads are removed or the request fails.
     */
    var bannerIsVisible by mutableStateOf(false)

    /**
     * True once a rewarded ad is actually loaded and ready to show — callers
     * gate their "Watch Ad" buttons on this so tapping one never dead-ends.
     */
    var rewardedAdAvailable by mutableStateOf(false)
        private set

    /**
     * True while a full-screen ad (interstitial/rewarded) is on screen. The
     * game screen blanks itself behind this flag: the ad activity leaves the
     * status-bar strip transparent, so without it the back button / level
     * title peek through above the ad.
     */
    var fullScreenAdShowing by mutableStateOf(false)
        private set

    /**
     * Call once at app launch. SDK init runs on a background thread —
     * MobileAds.initialize can block for seconds and ANR the app otherwise.
     */
    fun configure(context: Context) {
        val config = RequestConfiguration.Builder()
            .setTagForChildDirectedTreatment(RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE) // COPPA
            .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G) // G-rated only
            .build()
        MobileAds.setRequestConfiguration(config)
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "Mode: ${if (useTestAds) "TEST (Debug build)" else "LIVE (Release build)"}")
        }
        val appContext = context.applicationContext
        Thread {
            MobileAds.initialize(appContext) {
                Handler(Looper.getMainLooper()).post {
                    loadInterstitial(appContext)
                    loadRewardedAd(appContext)
                }
            }
        }.start()
    }

    fun loadInterstitial(context: Context) {
        InterstitialAd.load(
            context.applicationContext,
            interstitialUnitId,
            AdRequest.Builder().build(),
            object : InterstitialAdLoadCallback() {
                override fun onAdLoaded(ad: InterstitialAd) {
                    interstitial = ad
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    interstitial = null
                    if (BuildConfig.DEBUG) Log.d(TAG, "Interstitial failed: ${error.message}")
                }
            }
        )
    }

    fun loadRewardedAd(context: Context) {
        RewardedAd.load(
            context.applicationContext,
            rewardedUnitId,
            AdRequest.Builder().build(),
            object : RewardedAdLoadCallback() {
                override fun onAdLoaded(ad: RewardedAd) {
                    rewardedAd = ad
                    rewardedAdAvailable = true
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    rewardedAd = null
                    rewardedAdAvailable = false
                    if (BuildConfig.DEBUG) Log.d(TAG, "Rewarded failed: ${error.message}")
                }
            }
        )
    }

    /**
     * Shows the rewarded ad if one is ready. [onReward] fires only when the
     * player actually earns the reward (never grant it just for opening the
     * ad — that's AdMob policy); [onClosed] always fires once the ad flow
     * ends, whether or not a reward was earned, so callers can clean up.
     */
    fun showRewardedAd(activity: Activity?, onReward: () -> Unit, onClosed: () -> Unit) {
        val ad = rewardedAd
        if (ad == null || activity == null) {
            onClosed()
            return
        }
        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() {
                fullScreenAdShowing = false
                rewardedAd = null
                rewardedAdAvailable = false
                loadRewardedAd(activity)
                onClosed()
            }

            override fun onAdFailedToShowFullScreenContent(error: AdError) {
                fullScreenAdShowing = false
                rewardedAd = null
                rewardedAdAvailable = false
                onClosed()
            }
        }
        fullScreenAdShowing = true
        ad.show(activity, OnUserEarnedRewardListener { onReward() })
    }

    /**
     * Call when a level finishes (win OR loss). Shows an interstitial on every
     * 3rd finished game (never if ads are removed), then runs [onReadyForResult]
     * — otherwise runs it immediately.
     */
    fun handleLevelFinished(activity: Activity?, adsRemoved: Boolean, onReadyForResult: () -> Unit) {
        gamesSinceLastAd += 1
        val ad = interstitial
        val due = !adsRemoved && gamesSinceLastAd >= SHOW_EVERY_N_GAMES && ad != null
        if (!due || activity == null) {
            onReadyForResult()
            return
        }
        gamesSinceLastAd = 0
        ad?.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() {
                fullScreenAdShowing = false
                interstitial = null
                loadInterstitial(activity)
                onReadyForResult()
            }

            override fun onAdFailedToShowFullScreenContent(error: AdError) {
                fullScreenAdShowing = false
                interstitial = null
                onReadyForResult()
            }
        }
        fullScreenAdShowing = true
        ad?.show(activity)
    }
}
