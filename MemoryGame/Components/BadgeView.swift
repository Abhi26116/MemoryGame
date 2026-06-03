//
//  BadgeView.swift
//  Memory Match Kids
//

import SwiftUI

struct BadgeView: View {
    let tier: BadgeTier
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: tier.colorHex),
                            Color(hex: tier.colorHex).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color(hex: tier.colorHex).opacity(0.4), radius: 4, y: 2)
            Image(systemName: tier.icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("\(tier.rawValue) badge")
    }
}

struct StarRatingView: View {
    let stars: Int
    var max: Int = 3
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i < stars ? Color(hex: "FFD60A") : Color.gray.opacity(0.4))
            }
        }
        .accessibilityLabel("\(stars) of \(max) stars")
    }
}
