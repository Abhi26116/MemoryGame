//
//  DSContainers.swift
//  Memory Match
//
//  Reusable surface & content components: the universal card, section headers,
//  stat tiles, progress ring and modal dialog. These replace the duplicated
//  `cardBackground` / `resultCardBackground` / `SettingsCardModifier` / HUD
//  tile / `miniStat` / `statPill` / `statTile` implementations scattered across
//  the screens, so visual treatment is defined once.
//

import SwiftUI

// MARK: - Card surface

/// The standard rounded surface used for every content block. Solid fill, soft
/// shadow, hairline border. Use `DSCard { ... }` to wrap content, or
/// `.dsCard()` as a modifier on an existing container.
struct DSCardModifier: ViewModifier {
    var padding: CGFloat = DS.Spacing.lg
    var radius: CGFloat = DS.Radius.lg
    var shadow: DS.Shadow = .card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DS.Color.surface)
                    .dsShadow(shadow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DS.Color.border, lineWidth: 0.75)
            )
    }
}

extension View {
    func dsCard(padding: CGFloat = DS.Spacing.lg,
                radius: CGFloat = DS.Radius.lg,
                shadow: DS.Shadow = .card) -> some View {
        modifier(DSCardModifier(padding: padding, radius: radius, shadow: shadow))
    }
}

struct DSCard<Content: View>: View {
    var padding: CGFloat = DS.Spacing.lg
    var radius: CGFloat = DS.Radius.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            content()
        }
        .dsCard(padding: padding, radius: radius)
    }
}

/// Translucent material card. Falls back to a solid `DSCard` when Reduce
/// Transparency is enabled, satisfying that accessibility setting.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = DS.Spacing.lg
    var radius: CGFloat = DS.Radius.lg
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if reduceTransparency {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DS.Color.surface)
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(DS.Color.border, lineWidth: 0.75)
        )
        .dsShadow(.card)
    }
}

// MARK: - Section header

/// Icon + title used to introduce a content section.
struct SectionHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        Label {
            Text(title).font(.DSText.headline)
        } icon: {
            if let icon { Image(systemName: icon) }
        }
        .foregroundStyle(DS.Color.sectionTitle)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Stat card

/// Compact metric tile: tinted icon, large value, caption label. Replaces the
/// many one-off stat layouts across the app.
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    var tint: Color = DS.Color.brand
    /// `vertical` for grid tiles, `horizontal` for list rows.
    var axis: Axis = .vertical

    var body: some View {
        Group {
            if axis == .vertical {
                VStack(spacing: DS.Spacing.sm) {
                    iconBadge
                    valueText
                    labelText
                }
            } else {
                HStack(spacing: DS.Spacing.md) {
                    iconBadge
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        labelText
                        valueText
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .padding(.horizontal, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(DS.Color.fill)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    private var iconBadge: some View {
        Image(systemName: icon)
            .font(.headline)
            .foregroundStyle(tint)
            .frame(width: 40, height: 40)
            .background(Circle().fill(tint.opacity(0.16)))
    }

    private var valueText: some View {
        Text(value)
            .font(.DSText.score)
            .monospacedDigit()
            .foregroundStyle(DS.Color.textPrimary)
    }

    private var labelText: some View {
        Text(label)
            .font(.DSText.caption)
            .foregroundStyle(DS.Color.textSecondary)
    }
}

// MARK: - Progress ring

/// Circular progress indicator with a gradient stroke and free-form center
/// content. Replaces the bespoke countdown ring in the game preview.
struct ProgressRing<Center: View>: View {
    /// 0...1.
    let progress: Double
    var lineWidth: CGFloat = 7
    var gradient: LinearGradient = DS.Gradient.brand
    var animation: Animation? = DS.Motion.spring
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.Color.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(animation, value: progress)
            center()
        }
    }
}

extension ProgressRing where Center == EmptyView {
    init(progress: Double, lineWidth: CGFloat = 7, gradient: LinearGradient = DS.Gradient.brand) {
        self.init(progress: progress, lineWidth: lineWidth, gradient: gradient) { EmptyView() }
    }
}

// MARK: - Screen background

/// Calm, layered app background: a flat screen color with optional soft brand /
/// accent glows. Replaces the per-screen `homeBackdrop` / `gameBackground` /
/// `celebrationBackground` duplications with one consistent treatment.
struct DSScreenBackground: View {
    var glow: Bool = true

    var body: some View {
        ZStack {
            DS.Color.screen
            if glow {
                Circle().fill(DS.Color.brand.opacity(0.16))
                    .frame(width: 300, height: 300).blur(radius: 70)
                    .offset(x: -130, y: -240)
                Circle().fill(DS.Color.accent.opacity(0.14))
                    .frame(width: 260, height: 260).blur(radius: 64)
                    .offset(x: 140, y: 200)
                Circle().fill(DS.Color.brand.opacity(0.10))
                    .frame(width: 220, height: 220).blur(radius: 58)
                    .offset(x: 60, y: 480)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Places a `DSScreenBackground` behind the view.
    func dsScreenBackground(glow: Bool = true) -> some View {
        ZStack {
            DSScreenBackground(glow: glow)
            self
        }
    }
}

// MARK: - Dialog

/// Centered modal card over a dimmed background. Replaces the bespoke pause /
/// tutorial overlays. Respects Reduce Motion for its entrance.
struct Dialog<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            DS.Color.overlay.ignoresSafeArea()
            VStack(spacing: DS.Spacing.lg) {
                content()
            }
            .padding(DS.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .fill(DS.Color.surfaceElevated)
                    .dsShadow(.elevated)
            )
            .padding(DS.Spacing.xxxl)
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(DS.Motion.respecting(reduceMotion, DS.Motion.bouncy)) {
                appeared = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Containers") {
    ScrollView {
        VStack(spacing: DS.Spacing.xl) {
            DSCard {
                SectionHeader(title: "Your Journey", icon: "map.fill")
                HStack(spacing: DS.Spacing.md) {
                    StatCard(value: "12", label: "Completed", icon: "flag.checkered")
                    StatCard(value: "28", label: "Stars", icon: "star.fill", tint: DS.Color.star)
                }
            }
            HStack(spacing: DS.Spacing.md) {
                StatCard(value: "4", label: "Moves", icon: "arrow.left.arrow.right",
                         axis: .horizontal)
                StatCard(value: "0:42", label: "Time", icon: "clock.fill",
                         tint: DS.Color.accent, axis: .horizontal)
            }
            ProgressRing(progress: 0.7) {
                Text("3").font(.DSText.timer).foregroundStyle(DS.Color.textPrimary)
            }
            .frame(width: 80, height: 80)
        }
        .padding(DS.Spacing.xl)
    }
    .background(DS.Color.screen)
}
