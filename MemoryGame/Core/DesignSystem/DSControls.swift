//
//  DSControls.swift
//  Memory Match
//
//  Reusable button components built on the design tokens. These replace the
//  ad-hoc button layouts duplicated across Home / Result / Game / Settings and
//  give every tappable control a consistent press animation, haptic, touch
//  target and Reduce-Motion behaviour.
//

import SwiftUI

// MARK: - Haptics preference

/// Propagates the player's "Haptic Feedback" setting down the view tree so
/// design-system controls can honour it without reaching into the store.
private struct HapticsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var hapticsEnabled: Bool {
        get { self[HapticsEnabledKey.self] }
        set { self[HapticsEnabledKey.self] = newValue }
    }
}

// MARK: - Press feedback

/// Adds a spring scale-down on press plus an optional selection haptic. Apply
/// to any `Button` for tactile feedback consistent across the app. The haptic
/// respects the player's setting and Reduce Motion governs the scale animation.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var haptic: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.hapticsEnabled) private var hapticsEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(DS.Motion.respecting(reduceMotion, DS.Motion.snappy),
                       value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && haptic {
                    HapticManager.selection(enabled: hapticsEnabled)
                }
            }
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

// MARK: - Primary button

/// Full-width filled call-to-action. Gradient background, white label, soft
/// shadow, HIG-compliant height.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var gradient: LinearGradient = DS.Gradient.brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3.bold())
                }
                Text(title)
                    .font(.DSText.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: DS.Layout.minTouchTarget)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(gradient)
                    .dsShadow(.card)
            )
        }
        .buttonStyle(.pressable)
    }
}

// MARK: - Secondary button

/// Tinted / outlined secondary action. Brand-colored label on a soft fill.
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = DS.Color.brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.bold())
                }
                Text(title)
                    .font(.DSText.button)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: DS.Layout.minTouchTarget)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.pressable)
    }
}

// MARK: - Icon button

/// Circular icon control for toolbars and floating actions (gear, pause, back).
struct IconButton: View {
    let systemName: String
    var tint: Color = DS.Color.link
    var size: CGFloat = 44
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(DS.Color.surface).dsShadow(.card))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: DS.Spacing.lg) {
        PrimaryButton(title: "Play Again", icon: "arrow.clockwise.circle.fill") {}
        PrimaryButton(title: "Next Level", icon: "arrow.right.circle.fill",
                      gradient: DS.Gradient.cta) {}
        SecondaryButton(title: "Back to Home", icon: "house.fill") {}
        HStack(spacing: DS.Spacing.lg) {
            IconButton(systemName: "gearshape.fill", accessibilityLabel: "Settings") {}
            IconButton(systemName: "pause.circle.fill", accessibilityLabel: "Pause") {}
            IconButton(systemName: "trophy.fill", tint: DS.Color.star,
                       accessibilityLabel: "Achievements") {}
        }
    }
    .padding(DS.Spacing.xl)
    .frame(maxHeight: .infinity)
    .background(DS.Color.screen)
}
