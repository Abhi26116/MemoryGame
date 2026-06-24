//
//  ConfettiView.swift
//  Memory Match Kids
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let isActive: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let p = particle
                    let age = now - p.birth
                    guard age < p.lifetime else { continue }
                    let x = p.startX + sin(age * p.wobbleSpeed) * 30
                    let y = p.startY + age * p.fallSpeed
                    let rect = CGRect(x: x, y: y, width: p.size, height: p.size * 0.6)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(p.color.opacity(1 - age / p.lifetime))
                    )
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
        let colors: [Color] = [
            .pink, .orange, .yellow, .green, .blue, .purple, .mint, .cyan
        ]
        particles = (0..<80).map { _ in
            ConfettiParticle(
                startX: CGFloat.random(in: 0...400),
                startY: CGFloat.random(in: -80...0),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? .pink,
                fallSpeed: CGFloat.random(in: 80...160),
                wobbleSpeed: Double.random(in: 2...6),
                lifetime: Double.random(in: 2...3.5),
                birth: Date().timeIntervalSinceReferenceDate
            )
        }
    }
}

private struct ConfettiParticle {
    var startX: CGFloat
    var startY: CGFloat
    var size: CGFloat
    var color: Color
    var fallSpeed: CGFloat
    var wobbleSpeed: Double
    var lifetime: Double
    var birth: Double
}
