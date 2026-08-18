package com.memogame.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError
import com.memogame.app.core.LocalDSColors
import com.memogame.app.services.AdsManager

/**
 * Anchored adaptive banner (full width, no letterboxing). The slot takes ZERO
 * height until THIS AdView instance actually loads an ad — so there is never
 * an empty strip above the tab bar while loading, matching the iOS behaviour.
 */
@Composable
fun BannerAdSlot(adsRemoved: Boolean) {
    if (adsRemoved) return
    val ds = LocalDSColors.current

    // Local to this AdView instance: a fresh slot always starts collapsed.
    var loadedHeightDp by remember { mutableIntStateOf(0) }

    AndroidView(
        modifier = Modifier
            .fillMaxWidth()
            .height(loadedHeightDp.dp)
            .background(ds.surface),
        factory = { context ->
            val metrics = context.resources.displayMetrics
            // Floored: a 0/near-0 computed width (e.g. mid multi-window resize)
            // would otherwise hand adaptive-size lookup an invalid width and
            // setAdSize/loadAd would throw.
            val adWidthDp = (metrics.widthPixels / metrics.density).toInt().coerceAtLeast(320)
            val adSize = AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, adWidthDp)

            AdView(context).apply {
                setAdSize(adSize)
                adUnitId = AdsManager.bannerUnitId
                adListener = object : AdListener() {
                    override fun onAdLoaded() {
                        loadedHeightDp = adSize.height
                        AdsManager.bannerIsVisible = true
                    }

                    override fun onAdFailedToLoad(error: LoadAdError) {
                        loadedHeightDp = 0
                        AdsManager.bannerIsVisible = false
                    }
                }
                loadAd(AdRequest.Builder().build())
            }
        },
        // Without this, leaving/re-entering the tab (banner mounts only on
        // Play/game routes) creates a fresh WebView-backed AdView every time
        // and never releases the old one — an unbounded leak on repeated
        // navigation.
        onRelease = { adView -> adView.destroy() }
    )
}
