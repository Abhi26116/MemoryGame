package com.memogame.app.services

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams

/**
 * "Remove Ads" one-time purchase via Google Play Billing — port of the iOS
 * StoreKit StoreManager. The entitlement is cached locally so the app stays
 * ad-free offline once purchased.
 */
class StoreManager private constructor(context: Context) : PurchasesUpdatedListener {

    companion object {
        /**
         * Purchases are ON. Requires the `com.memogame.removeads` one-time
         * product to exist and be ACTIVE in Play Console (Monetize →
         * Products → In-app products) before this build reaches testers —
         * otherwise loadProduct() finds nothing and the buy button shows
         * "Couldn't load the purchase price."
         */
        const val PURCHASES_ENABLED = true

        // Must match the in-app product ID created in the Play Console.
        const val REMOVE_ADS_PRODUCT_ID = "com.memogame.removeads"

        @Volatile
        private var instance: StoreManager? = null

        fun get(context: Context): StoreManager =
            instance ?: synchronized(this) {
                instance ?: StoreManager(context.applicationContext).also { instance = it }
            }
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences("memory_game_store", Context.MODE_PRIVATE)

    private val adsRemovedState = mutableStateOf(prefs.getBoolean("adsRemoved", false))
    val adsRemoved: Boolean get() = adsRemovedState.value
    var isWorking by mutableStateOf(false)
        private set
    var statusMessage by mutableStateOf<String?>(null)
        private set
    var isStatusError by mutableStateOf(false)
        private set
    var removeAdsProduct by mutableStateOf<ProductDetails?>(null)
        private set

    /** Localized Play Store price, e.g. "$2.99" or "₹249". */
    val removeAdsDisplayPrice: String?
        get() = removeAdsProduct?.oneTimePurchaseOfferDetailsList
            ?.firstOrNull()
            ?.formattedPrice
            ?: removeAdsProduct?.oneTimePurchaseOfferDetails?.formattedPrice

    /** Primary CTA label with localized price once Billing has loaded it. */
    val removeAdsButtonTitle: String
        get() = removeAdsDisplayPrice?.let { "Remove Ads — $it" } ?: "Remove Ads"

    private val billingClient: BillingClient = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()
        )
        .enableAutoServiceReconnection()
        .build()

    // Billing callbacks can arrive on binder threads while the UI thread queues
    // actions, so all pendingActions access is guarded by this lock.
    @Volatile
    private var connected = false
    private val pendingLock = Any()
    private val pendingActions = mutableListOf<() -> Unit>()

    init {
        connect()
    }

    fun clearStatus() {
        statusMessage = null
        isStatusError = false
    }

    private fun setError(message: String) {
        statusMessage = message
        isStatusError = true
    }

    private fun connect() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    connected = true
                    val actions = synchronized(pendingLock) {
                        val copy = pendingActions.toList()
                        pendingActions.clear()
                        copy
                    }
                    actions.forEach { it() }
                    loadProduct()
                    refresh()
                }
            }

            override fun onBillingServiceDisconnected() {
                connected = false
            }
        })
    }

    private fun withConnection(action: () -> Unit) {
        if (connected) {
            action()
        } else {
            synchronized(pendingLock) { pendingActions.add(action) }
            connect()
        }
    }

    fun loadProduct() = withConnection {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(REMOVE_ADS_PRODUCT_ID)
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build()
                )
            )
            .build()
        // PBL 8+: callback receives QueryProductDetailsResult (not a bare list).
        billingClient.queryProductDetailsAsync(params) { result, detailsResult ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                removeAdsProduct = detailsResult.productDetailsList.firstOrNull()
            }
        }
    }

    /** Re-checks owned purchases (Play's equivalent of current entitlements). */
    fun refresh(onDone: (Boolean) -> Unit = {}) = withConnection {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()
        billingClient.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                val owned = purchases.any { purchase ->
                    REMOVE_ADS_PRODUCT_ID in purchase.products &&
                        purchase.purchaseState == Purchase.PurchaseState.PURCHASED
                }
                purchases.forEach { acknowledgeIfNeeded(it) }
                setAdsRemoved(owned)
                onDone(owned)
            } else {
                onDone(adsRemoved)
            }
        }
    }

    fun purchaseRemoveAds(activity: Activity) {
        isWorking = true
        clearStatus()
        withConnection {
            // This action can run much later (queued until billing connects),
            // by which point the player may have left — launching over a
            // finishing/destroyed activity can crash.
            if (activity.isFinishing || activity.isDestroyed) {
                isWorking = false
                return@withConnection
            }
            val product = removeAdsProduct
            if (product == null) {
                // One retry: load the product, then launch.
                loadProduct()
                setError("Couldn't load the purchase price. Check your connection and try again.")
                isWorking = false
                return@withConnection
            }
            // PBL 8+ one-time products can expose multiple offers — pick the
            // first eligible offer token when launching the flow.
            val offerToken = product.oneTimePurchaseOfferDetailsList
                ?.firstOrNull()
                ?.offerToken
                ?: product.oneTimePurchaseOfferDetails?.offerToken
            val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
                .setProductDetails(product)
            if (offerToken != null) {
                productParams.setOfferToken(offerToken)
            }
            val params = BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(listOf(productParams.build()))
                .build()
            val result = billingClient.launchBillingFlow(activity, params)
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                setError("Purchase couldn't be started. Please try again.")
                isWorking = false
            }
            // isWorking is cleared in onPurchasesUpdated.
        }
    }

    fun restore() {
        isWorking = true
        clearStatus()
        refresh { owned ->
            isWorking = false
            if (!owned) {
                setError("No previous Remove Ads purchase was found for this Google account.")
            }
        }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        isWorking = false
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    if (REMOVE_ADS_PRODUCT_ID in purchase.products) {
                        when (purchase.purchaseState) {
                            Purchase.PurchaseState.PURCHASED -> {
                                acknowledgeIfNeeded(purchase)
                                setAdsRemoved(true)
                            }
                            Purchase.PurchaseState.PENDING -> {
                                setError("Purchase is waiting for approval. You'll get ad-free access once it's approved.")
                            }
                        }
                    }
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                // Silent, same as iOS.
            }
            BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> {
                setAdsRemoved(true)
            }
            BillingClient.BillingResponseCode.NETWORK_ERROR -> {
                setError("Network error. Check your connection and try again.")
            }
            else -> {
                setError("Purchase couldn't be completed. Please try again.")
            }
        }
    }

    private fun acknowledgeIfNeeded(purchase: Purchase) {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED && !purchase.isAcknowledged) {
            val params = AcknowledgePurchaseParams.newBuilder()
                .setPurchaseToken(purchase.purchaseToken)
                .build()
            billingClient.acknowledgePurchase(params) {}
        }
    }

    private fun setAdsRemoved(value: Boolean) {
        adsRemovedState.value = value
        prefs.edit().putBoolean("adsRemoved", value).apply()
        if (value) AdsManager.bannerIsVisible = false
    }
}
