//
//  Monetization.swift
//  Memory Match Kids
//
//  AdMob (kid-safe, non-personalized) + a parent-gated "Remove Ads" purchase.
//  Targets Google Mobile Ads SDK v11.x (compatible with Xcode 15).
//

import SwiftUI
import StoreKit
import GoogleMobileAds

// MARK: - Ads

@MainActor
final class AdsManager: NSObject, ObservableObject {
    static let shared = AdsManager()

    /// Debug builds use Google's test ad units (safe to tap). Release / TestFlight /
    /// App Store builds use live ad units. App ID in Info.plist is always the real one.
    #if DEBUG
    static let useTestAds = true
    #else
    static let useTestAds = false
    #endif

    private static let testInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    private static let testBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    private static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"
    private static let liveInterstitialUnitID = "ca-app-pub-9350608203842553/5602694936"
    private static let liveBannerUnitID = "ca-app-pub-9350608203842553/6247738364"
    private static let liveRewardedUnitID = "ca-app-pub-9350608203842553/7384774761"

    static var interstitialUnitID: String { useTestAds ? testInterstitialUnitID : liveInterstitialUnitID }
    static var bannerUnitID: String { useTestAds ? testBannerUnitID : liveBannerUnitID }
    static var rewardedUnitID: String {
        (useTestAds || liveRewardedUnitID.isEmpty) ? testRewardedUnitID : liveRewardedUnitID
    }

    private var interstitial: GADInterstitialAd?
    private var gamesSinceLastAd = 0
    private let showEveryNGames = 3
    private var onInterstitialDismissed: (() -> Void)?

    private var rewardedAd: GADRewardedAd?
    private var onRewardedAdClosed: (() -> Void)?

    /// True only after a banner actually loads — keeps the tab bar flush at the
    /// bottom when ads are removed or the request fails.
    @Published private(set) var bannerIsVisible = false

    /// True once a rewarded ad is actually loaded and ready to show — callers
    /// gate their "Watch Ad" buttons on this so tapping one never dead-ends.
    @Published private(set) var rewardedAdAvailable = false

    func setBannerVisible(_ visible: Bool) {
        bannerIsVisible = visible
    }

    /// Call once at app launch.
    func configure() {
        let config = GADMobileAds.sharedInstance().requestConfiguration
        config.tagForChildDirectedTreatment = NSNumber(value: true)   // COPPA: child-directed
        config.maxAdContentRating = GADMaxAdContentRating.general      // G-rated only
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #if DEBUG
        print("[Ads] Mode: \(Self.useTestAds ? "TEST (Debug build)" : "LIVE (Release build)")")
        #endif
        loadInterstitial()
        loadRewardedAd()
    }

    func loadInterstitial() {
        GADInterstitialAd.load(withAdUnitID: Self.interstitialUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error {
                #if DEBUG
                print("[Ads] Interstitial failed: \(error.localizedDescription)")
                #endif
                return
            }
            self?.interstitial = ad
            ad?.fullScreenContentDelegate = self
        }
    }

    func loadRewardedAd() {
        GADRewardedAd.load(withAdUnitID: Self.rewardedUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error {
                self?.rewardedAd = nil
                self?.rewardedAdAvailable = false
                #if DEBUG
                print("[Ads] Rewarded failed: \(error.localizedDescription)")
                #endif
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAdAvailable = true
            ad?.fullScreenContentDelegate = self
        }
    }

    /// Shows the rewarded ad if one is ready. `onReward` fires only when the
    /// player actually earns the reward (never grant it just for opening the
    /// ad — that's AdMob policy); `onClosed` always fires once the ad flow
    /// ends, whether or not a reward was earned, so callers can clean up.
    func showRewardedAd(onReward: @escaping () -> Void, onClosed: @escaping () -> Void) {
        guard let ad = rewardedAd, let root = Self.rootViewController else {
            onClosed()
            return
        }
        onRewardedAdClosed = onClosed
        ad.present(fromRootViewController: root) {
            onReward()
        }
    }

    /// Call when a level finishes (win OR loss). Shows an interstitial on every 3rd
    /// finished game (never if ads are removed), then runs `onReadyForResult` —
    /// otherwise runs it immediately.
    func handleLevelFinished(adsRemoved: Bool, onReadyForResult: @escaping () -> Void) {
        gamesSinceLastAd += 1
        let due = !adsRemoved && gamesSinceLastAd >= showEveryNGames && interstitial != nil
        guard due, let root = Self.rootViewController else {
            onReadyForResult()
            return
        }
        gamesSinceLastAd = 0
        onInterstitialDismissed = onReadyForResult
        interstitial?.present(fromRootViewController: root)
    }

    /// The topmost presented view controller — NOT just the window's base
    /// rootViewController. Ads must present from whichever VC is actually on
    /// screen: the rewarded "Watch Ad to Continue" button is tapped while
    /// ResultView is already showing as a `.fullScreenCover`, so presenting
    /// from the base root VC (which already has that cover presented on it)
    /// silently fails to show anything.
    static var rootViewController: UIViewController? {
        guard let base = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        var top = base
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

extension AdsManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if ad is GADRewardedAd {
            rewardedAd = nil
            rewardedAdAvailable = false
            loadRewardedAd()
            let callback = onRewardedAdClosed
            onRewardedAdClosed = nil
            callback?()
        } else {
            interstitial = nil
            loadInterstitial()
            let callback = onInterstitialDismissed
            onInterstitialDismissed = nil
            callback?()
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if ad is GADRewardedAd {
            rewardedAd = nil
            rewardedAdAvailable = false
            let callback = onRewardedAdClosed
            onRewardedAdClosed = nil
            callback?()
        } else {
            let callback = onInterstitialDismissed
            onInterstitialDismissed = nil
            callback?()
        }
    }
}

/// Fixed-height slot for `BannerAdView` — 0-height until the ad actually
/// loads (`AdsManager.bannerIsVisible`), so a screen doesn't reserve dead
/// space while a request is in flight or ads are removed.
///
/// (Tried reserving the 50pt immediately regardless of load state, to stop
/// `cardGrid` resizing out from under itself once the ad landed — that DID
/// stop the resize, but permanently shrank cards enough that their labels
/// looked noticeably worse/blurrier, which was the bigger complaint. Back to
/// grow-on-load; the brief resize when the ad lands is the smaller problem.)
///
/// Apply via `.safeAreaInset(edge: .bottom)` on the hosting screen so
/// `cardGrid`'s `GeometryReader` sees the reduced height and never overlaps
/// the banner. The ad's own reserved frame is a plain fixed 50pt (kept
/// simple on purpose — that's what makes it sit in the same spot every
/// time); only its background bleeds further down to reach the true screen
/// edge.
struct AdBannerSlot: View {
    @ObservedObject private var ads = AdsManager.shared
    let adsRemoved: Bool

    var body: some View {
        Group {
            if !adsRemoved && !UserDefaults.standard.bool(forKey: "SCREENSHOT_MODE") {  // SHOT-TEMP
                BannerAdView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    // The ad's own reserved frame stays a plain, fixed 50pt —
                    // that's what kept its position stable last time. Only
                    // the BACKGROUND color bleeds through the home-indicator
                    // zone below it (a background is allowed to be a
                    // different size than the view it's attached to, and
                    // nothing here clips it back), so there's no visible gap
                    // at the true screen edge without the ad itself being
                    // resized/repositioned.
                    .background(DS.Color.surface.ignoresSafeArea(edges: .bottom))
                    .opacity(ads.bannerIsVisible ? 1 : 0)
            }
        }
        .frame(height: (!adsRemoved && ads.bannerIsVisible) ? 50 : 0)
        // NOT `.clipped()` — it would cut the background bleed above right
        // back down to this 50pt reservation, undoing the flush-to-edge fix.
        // Nothing here has any other reason to overflow, so there's nothing
        // else for clipping to guard against.
    }
}

/// Standard banner for SwiftUI. Hosted inside `AdBannerSlot` on the game screen.
struct BannerAdView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = AdsManager.bannerUnitID
        banner.rootViewController = AdsManager.rootViewController
        banner.delegate = context.coordinator
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    final class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            Task { @MainActor in
                AdsManager.shared.setBannerVisible(true)
            }
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            Task { @MainActor in
                AdsManager.shared.setBannerVisible(false)
                #if DEBUG
                print("[Ads] Banner failed: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// MARK: - Remove-Ads purchase (StoreKit 2)

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()
    static let removeAdsProductID = "com.memogame.removeads"

    @Published private(set) var adsRemoved = false
    @Published private(set) var isWorking = false
    @Published private(set) var removeAdsProduct: Product?
    @Published private(set) var statusMessage: String?
    @Published private(set) var isStatusError = false

    private var updatesTask: Task<Void, Never>?

    /// Localized App Store price, e.g. "$2.99" or "₹249".
    var removeAdsDisplayPrice: String? { removeAdsProduct?.displayPrice }

    /// Primary CTA label with localized price once StoreKit has loaded it.
    var removeAdsButtonTitle: String {
        guard let price = removeAdsDisplayPrice else { return "Remove Ads" }
        return "Remove Ads — \(price)"
    }

    private init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await self?.refresh()
                    await transaction.finish()
                }
            }
        }
        Task { [weak self] in await self?.loadProduct() }
    }

    func clearStatus() {
        statusMessage = nil
        isStatusError = false
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.removeAdsProductID])
            removeAdsProduct = products.first
        } catch {
            // Price may appear on retry when the screen is shown again.
        }
    }

    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               t.productID == Self.removeAdsProductID,
               t.revocationDate == nil {
                owned = true
            }
        }
        adsRemoved = owned
    }

    @discardableResult
    func purchaseRemoveAds() async -> Bool {
        isWorking = true
        clearStatus()
        defer { isWorking = false }

        do {
            var product = removeAdsProduct
            if product == nil {
                let products = try await Product.products(for: [Self.removeAdsProductID])
                product = products.first
                removeAdsProduct = product
            }
            guard let product else {
                setError("Couldn't load the purchase price. Check your connection and try again.")
                return false
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    adsRemoved = true
                    await transaction.finish()
                    return true
                case .unverified:
                    setError("Purchase couldn't be verified. Please try again or contact support.")
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                setError("Purchase is waiting for approval. You'll get ad-free access once it's approved.")
                return false
            @unknown default:
                setError("Something went wrong. Please try again.")
                return false
            }
        } catch {
            let message = friendlyMessage(for: error, context: .purchase)
            if !message.isEmpty { setError(message) }
            return false
        }
    }

    @discardableResult
    func restore() async -> Bool {
        isWorking = true
        clearStatus()
        defer { isWorking = false }

        do {
            try await AppStore.sync()
            await refresh()
            if adsRemoved {
                return true
            }
            setError("No previous Remove Ads purchase was found for this Apple ID.")
            return false
        } catch {
            let message = friendlyMessage(for: error, context: .restore)
            if !message.isEmpty { setError(message) }
            return false
        }
    }

    private enum ActionContext { case purchase, restore }

    private func setError(_ message: String) {
        statusMessage = message
        isStatusError = true
    }

    private func friendlyMessage(for error: Error, context: ActionContext) -> String {
        if let storeError = error as? StoreKitError {
            switch storeError {
            case .networkError:
                return "Network error. Check your connection and try again."
            case .notAvailableInStorefront:
                return "This purchase isn't available in your App Store region."
            case .notEntitled:
                return context == .restore
                    ? "No previous Remove Ads purchase was found for this Apple ID."
                    : "Purchase isn't available right now. Please try again later."
            case .userCancelled:
                return ""
            default:
                break
            }
        }
        if (error as NSError).domain == NSURLErrorDomain {
            return "Network error. Check your connection and try again."
        }
        switch context {
        case .purchase:
            return "Purchase couldn't be completed. Please try again."
        case .restore:
            return "Couldn't restore purchases. Please try again."
        }
    }
}

/// Inline purchase / restore feedback for Remove Ads screens.
struct StoreStatusBanner: View {
    @ObservedObject var store: StoreManager

    var body: some View {
        if let message = store.statusMessage, !message.isEmpty {
            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                Image(systemName: store.isStatusError ? "exclamationmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(store.isStatusError ? DS.Color.danger : DS.Color.brand)
                Text(message)
                    .font(.DSText.caption)
                    .foregroundStyle(store.isStatusError ? DS.Color.danger : DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(store.isStatusError
                          ? DS.Color.danger.opacity(0.12)
                          : DS.Color.brand.opacity(0.12))
            )
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Parental gate

/// Simple grown-up check (a small sum) shown before any purchase, as required for
/// children's apps.
struct ParentalGateView: View {
    let onPass: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var a = 3
    @State private var b = 4
    @State private var options: [Int] = []
    @State private var wrong = false

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "person.fill.checkmark")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.linkBlue(for: colorScheme))

            Text("Ask a grown-up")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text("What is \(a) + \(b)?")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: 14) {
                ForEach(options, id: \.self) { option in
                    Button {
                        if option == a + b { dismiss(); onPass() } else { regenerate(showWrong: true) }
                    } label: {
                        Text("\(option)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Circle().fill(AppTheme.primaryGradient))
                    }
                    .buttonStyle(.plain)
                }
            }

            if wrong {
                Text("Try again!")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(Color(hex: "FF3B30"))
            }

            Button("Cancel") { dismiss() }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.linkBlue(for: colorScheme))
                .padding(.top, 4)
        }
        .padding(28)
        .dsIPadTypeScale()
        .onAppear { regenerate(showWrong: false) }
    }

    private func regenerate(showWrong: Bool) {
        wrong = showWrong
        a = Int.random(in: 2...9)
        b = Int.random(in: 2...9)
        var set: Set<Int> = [a + b]
        while set.count < 3 { set.insert(Int.random(in: 4...18)) }
        options = set.shuffled()
    }
}
