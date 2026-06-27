//
//  ConfettiView.swift
//  Memory Match Kids
//
//  Celebratory confetti burst. Particles fan out across the full screen width,
//  tumble with spin + wobble under gravity, come in mixed shapes/colors, and
//  arrive as a short staggered flurry. Suppressed under Reduce Motion.
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let age = now - p.birth
                    guard age >= 0, age < p.lifetime else { continue }

                    let progress = age / p.lifetime
                    let x = p.startXFraction * size.width
                        + p.vx * age
                        + sin(age * p.wobbleSpeed + p.phase) * p.wobbleAmp
                    let y = p.startY + p.vy0 * age + 0.5 * p.gravity * age * age
                    guard y < size.height + 60 else { continue }

                    // Fade out over the last 20% of life.
                    let opacity = progress < 0.8 ? 1 : max(0, 1 - (progress - 0.8) / 0.2)
                    let color = p.color.opacity(opacity)

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(p.spin0 + p.spinSpeed * age))

                    if p.isCircle {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: -p.size / 2, y: -p.size / 2,
                                                   width: p.size, height: p.size)),
                            with: .color(color)
                        )
                    } else {
                        let w = p.size * 0.62
                        let h = p.size
                        ctx.fill(
                            Path(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h),
                                 cornerRadius: 1.5),
                            with: .color(color)
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { spawn() }
        }
        .onAppear {
            if isActive { spawn() }
        }
    }

    private func spawn() {
        guard !reduceMotion else { particles = []; return }

        let colors: [Color] = [
            Color(hex: "FF6B9D"), Color(hex: "FFD60A"), Color(hex: "FF9500"),
            Color(hex: "34C759"), Color(hex: "5B8DEF"), Color(hex: "C44DFF"),
            .mint, .cyan, .white
        ]
        let now = Date().timeIntervalSinceReferenceDate

        particles = (0..<150).map { _ in
            ConfettiParticle(
                startXFraction: CGFloat.random(in: -0.05...1.05),
                startY: CGFloat.random(in: -80 ... -10),
                vx: CGFloat.random(in: -70...70),
                vy0: CGFloat.random(in: 20...80),
                gravity: CGFloat.random(in: 90...160),
                size: CGFloat.random(in: 7...15),
                color: colors.randomElement() ?? .pink,
                spin0: Double.random(in: 0...(2 * .pi)),
                spinSpeed: Double.random(in: -7...7),
                wobbleSpeed: Double.random(in: 2...5),
                wobbleAmp: CGFloat.random(in: 8...28),
                phase: Double.random(in: 0...(2 * .pi)),
                isCircle: Bool.random(),
                lifetime: Double.random(in: 3...4.8),
                birth: now + Double.random(in: 0...0.55)
            )
        }
    }
}

private struct ConfettiParticle {
    var startXFraction: CGFloat
    var startY: CGFloat
    var vx: CGFloat
    var vy0: CGFloat
    var gravity: CGFloat
    var size: CGFloat
    var color: Color
    var spin0: Double
    var spinSpeed: Double
    var wobbleSpeed: Double
    var wobbleAmp: CGFloat
    var phase: Double
    var isCircle: Bool
    var lifetime: Double
    var birth: Double
}
