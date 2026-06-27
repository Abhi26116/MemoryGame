//
//  SplashView.swift
//  Memory Match Kids
//

import SwiftUI

enum SplashTiming {
    static let holdDuration: Duration = .seconds(2.5)
}

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var orbit = false
    @State private var shimmer = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                splashBackground(time: time)
                SplashSparkleLayer()
                    .opacity(0.9)

                VStack(spacing: 0) {
                    Spacer(minLength: 48)

                    heroScene(time: time)
                        .padding(.horizontal, 24)

                    Spacer(minLength: 36)

                    titleSection
                        .padding(.horizontal, 28)

                    Spacer(minLength: 28)

                    loadingBar
                        .padding(.horizontal, 48)
                        .padding(.bottom, 52)
                }
                .scaleEffect(appeared ? 1 : 0.88)
                .opacity(appeared ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.72)) {
                appeared = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                orbit = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }

    // MARK: - Background

    private func splashBackground(time: TimeInterval) -> some View {
        ZStack {
            AppTheme.skyGradient(for: colorScheme)
                .ignoresSafeArea()

            blob(
                color: Color(hex: "FF6B9D"),
                size: 320,
                blur: 55,
                x: -90 + 24 * sin(time * 0.7),
                y: -280 + 18 * cos(time * 0.5)
            )
            blob(
                color: Color(hex: "5B8DEF"),
                size: 300,
                blur: 50,
                x: 110 + 20 * cos(time * 0.6),
                y: 300 + 22 * sin(time * 0.55)
            )
            blob(
                color: Color(hex: "C44DFF"),
                size: 200,
                blur: 42,
                x: 40 * sin(time * 0.9),
                y: 80 + 15 * cos(time * 0.8)
            )
            blob(
                color: Color(hex: "FFD60A"),
                size: 160,
                blur: 38,
                x: -60 + 16 * cos(time * 1.1),
                y: 120 + 14 * sin(time * 0.95)
            )
        }
    }

    private func blob(color: Color, size: CGFloat, blur: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(colorScheme == .dark ? 0.22 : 0.28))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
    }

    // MARK: - Hero

    private func heroScene(time: TimeInterval) -> some View {
        let floatY = sin(time * 1.4) * 10
        let breathe = 1.0 + 0.02 * sin(time * 1.2)

        return ZStack {
            // Soft halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "5B8DEF").opacity(0.35),
                            Color(hex: "FF6B9D").opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(breathe)

            // Orbiting cards
            ForEach(0..<6, id: \.self) { index in
                let angle = (Double(index) / 6.0) * .pi * 2 + (orbit ? time * 0.45 : 0)
                let radius: CGFloat = 118
                SplashOrbitCard(index: index)
                    .offset(
                        x: cos(angle) * radius,
                        y: sin(angle) * radius + floatY * 0.3
                    )
                    .rotationEffect(.degrees(sin(time + Double(index)) * 6))
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7).delay(0.05 + Double(index) * 0.04),
                        value: appeared
                    )
            }

            // Main logo card
            mainLogoCard(time: time, floatY: floatY, breathe: breathe)
        }
        .frame(height: 340)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(AppTheme.appName) loading")
    }

    private func mainLogoCard(time: TimeInterval, floatY: CGFloat, breathe: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.95),
                            Color(hex: "E8F4FF").opacity(colorScheme == .dark ? 0.12 : 0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.9),
                                    Color(hex: "B8E6FF").opacity(0.5),
                                    Color(hex: "FF6B9D").opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: Color(hex: "5B8DEF").opacity(0.28), radius: 28, y: 14)
                .shadow(color: Color(hex: "FF6B9D").opacity(0.12), radius: 12, y: 6)

            VStack(spacing: 14) {
                ZStack {
                    Text("🧠")
                        .font(.system(size: 72))
                        .scaleEffect(breathe)

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "FFD60A"))
                        .offset(x: 44, y: -32)
                        .opacity(0.7 + 0.3 * sin(time * 2.2))

                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "FF6B9D"))
                        .offset(x: -48, y: -28)
                        .opacity(0.6 + 0.4 * cos(time * 1.8))
                }

                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 72)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
        }
        .frame(width: 280, height: 220)
        .scaleEffect(breathe)
        .offset(y: floatY)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 14) {
            Text(AppTheme.appName)
                .font(AppTheme.display(36))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF6B9D"), Color(hex: "C44DFF"), Color(hex: "5B8DEF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(shimmerOverlay)
                .shadow(color: Color(hex: "5B8DEF").opacity(0.25), radius: 8, y: 4)

            Text("Flip · Match · Remember!")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            HStack(spacing: 16) {
                tagPill(icon: "star.fill", text: "50 Levels", color: "FFD60A")
                tagPill(icon: "brain.head.profile", text: "Brain Boost", color: "5B8DEF")
            }
        }
    }

    private var shimmerOverlay: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.55), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 120)
        .offset(x: shimmer ? 180 : -180)
        .mask(
            Text(AppTheme.appName)
                .font(AppTheme.display(36))
                .multilineTextAlignment(.center)
        )
        .allowsHitTesting(false)
    }

    private func tagPill(icon: String, text: String, color: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .bold))
        }
        .foregroundStyle(Color(hex: color))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.cardSurface(for: colorScheme).opacity(0.85))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
    }

    // MARK: - Loading

    private var loadingBar: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.progressTrack(for: colorScheme))

                    Capsule()
                        .fill(AppTheme.primaryGradient)
                        .frame(width: geo.size.width * (orbit ? 0.72 : 0.2))
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: orbit)
                }
            }
            .frame(height: 8)

            Text("Getting ready…")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
    }
}

// MARK: - Orbit card

private struct SplashOrbitCard: View {
    let index: Int

    private var emoji: String {
        ["⭐️", "🍎", "🚗", "🐶", "🔵", "🎈"][index % 6]
    }

    private var gradient: LinearGradient {
        let sets: [LinearGradient] = [
            LinearGradient(colors: [Color(hex: "5B8DEF"), Color(hex: "7B5BEF")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "FF6B9D"), Color(hex: "C44DFF")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "FF9500"), Color(hex: "FF5E3A")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "34C759"), Color(hex: "5AC8FA")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "AF52DE"), Color(hex: "5B8DEF")], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [Color(hex: "FFD60A"), Color(hex: "FF9500")], startPoint: .topLeading, endPoint: .bottomTrailing)
        ]
        return sets[index % sets.count]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(gradient)
                .frame(width: 52, height: 68)
                .shadow(color: Color(hex: "5B8DEF").opacity(0.3), radius: 8, y: 4)

            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.45), lineWidth: 1.5)
                .frame(width: 52, height: 68)

            Text(emoji)
                .font(.system(size: 28))
        }
    }
}

// MARK: - Sparkles

private struct SplashSparkleLayer: View {
    @State private var sparkles: [SplashSparkle] = []

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for sparkle in sparkles {
                        let age = now - sparkle.birth
                        guard age < sparkle.lifetime else { continue }

                        let progress = age / sparkle.lifetime
                        let x = sparkle.x + sin(age * sparkle.wobble) * 12
                        let y = sparkle.y - age * sparkle.riseSpeed
                        let alpha = 1 - progress
                        let starSize = sparkle.size * (0.8 + 0.2 * sin(age * 4))

                        var path = Path()
                        path.addEllipse(in: CGRect(x: x, y: y, width: starSize, height: starSize))
                        context.fill(path, with: .color(sparkle.color.opacity(alpha)))
                    }
                }
            }
            .onAppear {
                if sparkles.isEmpty {
                    sparkles = makeSparkles(in: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func makeSparkles(in size: CGSize) -> [SplashSparkle] {
        let colors: [Color] = [
            Color(hex: "FFD60A"), Color(hex: "FF6B9D"), Color(hex: "5B8DEF"),
            .white, Color(hex: "C44DFF"), Color(hex: "FF9500")
        ]
        let now = Date().timeIntervalSinceReferenceDate
        return (0..<52).map { _ in
            SplashSparkle(
                x: CGFloat.random(in: 0...max(size.width, 1)),
                y: CGFloat.random(in: 0...max(size.height, 1)),
                size: CGFloat.random(in: 3...9),
                color: colors.randomElement() ?? .white,
                lifetime: Double.random(in: 2.5...5),
                birth: now + Double.random(in: 0...2),
                riseSpeed: CGFloat.random(in: 20...48),
                wobble: Double.random(in: 1.5...3.5)
            )
        }
    }
}

private struct SplashSparkle {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let lifetime: Double
    let birth: TimeInterval
    let riseSpeed: CGFloat
    let wobble: Double
}

#Preview {
    SplashView()
}
