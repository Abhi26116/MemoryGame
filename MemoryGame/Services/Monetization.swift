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

    /// While `true`, EVERY build (including TestFlight / App Store) uses Google's TEST
    /// ads — safe to tap, never real money. Flip to `false` only when the app is live
    /// and your AdMob app is approved, to serve your real ads. (App ID in Info.plist
    /// is always the real one.)
    static let useTestAds = true

    private static let testInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    private static let testBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    private static let liveInterstitialUnitID = "ca-app-pub-9350608203842553/5602694936"
    private static let liveBannerUnitID = "ca-app-pub-9350608203842553/6247738364"

    static var interstitialUnitID: String { useTestAds ? testInterstitialUnitID : liveInterstitialUnitID }
    static var bannerUnitID: String { useTestAds ? testBannerUnitID : liveBannerUnitID }

    private var interstitial: GADInterstitialAd?
    private var gamesSinceLastAd = 0
    private let showEveryNGames = 3
    private var onInterstitialDismissed: (() -> Void)?

    /// Call once at app launch.
    func configure() {
        let config = GADMobileAds.sharedInstance().requestConfiguration
        config.tagForChildDirectedTreatment = NSNumber(value: true)   // COPPA: child-directed
        config.maxAdContentRating = GADMaxAdContentRating.general      // G-rated only
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadInterstitial()
    }

    func loadInterstitial() {
        GADInterstitialAd.load(withAdUnitID: Self.interstitialUnitID, request: GADRequest()) { [weak self] ad, _ in
            self?.interstitial = ad
            ad?.fullScreenContentDelegate = self
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

    static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}

extension AdsManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitial = nil
        loadInterstitial()
        let callback = onInterstitialDismissed
        onInterstitialDismissed = nil
        callback?()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        let callback = onInterstitialDismissed
        onInterstitialDismissed = nil
        callback?()
    }
}

/// Standard banner for SwiftUI. Show only off the game board (e.g. bottom of Home).
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = AdsManager.bannerUnitID
        banner.rootViewController = AdsManager.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

// MARK: - Remove-Ads purchase (StoreKit 2)

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()
    static let removeAdsProductID = "com.memogame.removeads"

    @Published private(set) var adsRemoved = false
    @Published private(set) var isWorking = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await self?.refresh()
                    await transaction.finish()
                }
            }
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

    func purchaseRemoveAds() async {
        isWorking = true
        defer { isWorking = false }
        guard let product = try? await Product.products(for: [Self.removeAdsProductID]).first else { return }
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result, case .verified(let transaction) = verification {
            adsRemoved = true            // flip the UI immediately — we know it's owned
            await transaction.finish()
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await refresh()
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
