//
//  ConsentManager.swift
//  Memory Match Kids
//
//  Google UMP (User Messaging Platform) consent gathering. This has to finish
//  before GADMobileAds starts: in the EEA/UK/Switzerland an ad request carrying
//  no consent signal is refused outright — not downgraded to non-personalized,
//  refused — so without this the app serves zero ads there.
//
//  Targets UMP 2.7.0, which is what GoogleMobileAds 11.2.0 resolves to (its
//  Package.swift pins the UMP package to 1.1.0..<3.0.0). Those headers carry no
//  NS_SWIFT_NAME, so the ObjC `UMP*` names ARE the Swift names — the 3.x
//  spellings (`ConsentInformation.shared`) don't exist here.
//

import UIKit
import UserMessagingPlatform

@MainActor
final class ConsentManager: NSObject {
    static let shared = ConsentManager()

    /// Off, so EEA/UK users get the published "European regulations" consent
    /// form and Settings shows the Privacy Options row when UMP requires it.
    /// Setting it to `true` makes Google treat the form as ineligible and UMP
    /// resolves to "no consent needed, serve non-personalized" instead.
    ///
    /// Note: ad requests are still tagged child-directed
    /// (`tagForChildDirectedTreatment` in `AdsManager.startAds`), which forces
    /// non-personalized ads regardless of what the user picks here.
    private static let tagForUnderAgeOfConsent = false

    private var isGathering = false
    private var waiters: [() -> Void] = []

    /// True once a gather run has finished — successfully or not. Ads key off
    /// `canRequestAds`, not this.
    private(set) var hasGathered = false

    /// UMP's verdict on whether an ad request is allowed at all. False until
    /// UMP has resolved the user's region and consent state.
    var canRequestAds: Bool {
        UMPConsentInformation.sharedInstance.canRequestAds
    }

    /// Refreshes consent info and presents the form if UMP says one is
    /// required, then runs `completion` on the main actor.
    ///
    /// Safe to call more than once: concurrent callers queue onto the single
    /// in-flight run rather than starting a second one, so an ad request can
    /// never slip out ahead of consent.
    func gather(completion: @escaping () -> Void) {
        if hasGathered {
            completion()
            return
        }
        waiters.append(completion)
        guard !isGathering else { return }
        isGathering = true

        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = Self.tagForUnderAgeOfConsent
        #if DEBUG
        parameters.debugSettings = Self.debugSettings
        #endif

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            if let error {
                // Leaves `canRequestAds` false, so no ads this launch. UMP
                // caches its answer, so the next launch recovers on its own.
                #if DEBUG
                print("[Consent] Info update failed: \(error.localizedDescription)")
                #endif
                self?.finishGathering()
                return
            }
            self?.presentFormIfRequired()
        }
    }

    private func presentFormIfRequired() {
        UMPConsentForm.loadAndPresentIfRequired(from: AdsManager.rootViewController) { [weak self] error in
            #if DEBUG
            if let error {
                print("[Consent] Form failed: \(error.localizedDescription)")
            }
            let info = UMPConsentInformation.sharedInstance
            print("[Consent] status=\(info.consentStatus.rawValue) canRequestAds=\(info.canRequestAds) privacyOptions=\(info.privacyOptionsRequirementStatus.rawValue)")
            #endif
            self?.finishGathering()
        }
    }

    private func finishGathering() {
        hasGathered = true
        isGathering = false
        let pending = waiters
        waiters = []
        for callback in pending { callback() }
    }

    // MARK: - Privacy options (re-entry from Settings)

    /// True when UMP says this user must be given a way to change their answer
    /// after the fact. Settings shows its "Privacy Options" row only then —
    /// regulators expect the entry point, and UMP is what knows whether this
    /// particular user is owed one.
    var privacyOptionsRequired: Bool {
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }

    /// Re-presents the consent form so the user can change their answer.
    func presentPrivacyOptions(completion: @escaping (Error?) -> Void) {
        UMPConsentForm.presentPrivacyOptionsForm(from: AdsManager.rootViewController) { error in
            #if DEBUG
            if let error {
                print("[Consent] Privacy options failed: \(error.localizedDescription)")
            }
            #endif
            completion(error)
        }
    }

    // MARK: - Debug

    #if DEBUG
    /// Forces an EEA run on a non-EEA device so the flow can actually be
    /// exercised. Needs this device's hashed ID, which UMP prints on launch as
    /// "To enable debug mode for this device, set: UMPDebugSettings
    /// .testDeviceIdentifiers = @[ ... ]" — paste it below. Empty list means no
    /// debug override (UMP rejects a geography with no registered device).
    private static var debugSettings: UMPDebugSettings? {
        let testDeviceIdentifiers: [String] = []
        guard !testDeviceIdentifiers.isEmpty else { return nil }
        let settings = UMPDebugSettings()
        settings.testDeviceIdentifiers = testDeviceIdentifiers
        settings.geography = .EEA
        return settings
    }
    #endif
}
