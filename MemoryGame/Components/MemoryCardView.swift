//
//  MemoryCardView.swift
//  Memory Match Kids
//

import SwiftUI

struct MemoryCardView: View {
    let card: CardModel
    let size: CGFloat
    var largeText: Bool = false
    var highContrast: Bool = false
    var colorBlindMode: Bool = false
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var flipDegrees: Double = 0
    @State private var pulseScale: CGFloat = 1

    var body: some View {
        Button(action: onTap) {
            ZStack {
                cardBack
                    .opacity(card.isFaceUp || card.isMatched ? 0 : 1)
                    .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0))

                cardFront
                    .opacity(card.isFaceUp || card.isMatched ? 1 : 0)
                    .rotation3DEffect(.degrees(flipDegrees + 180), axis: (x: 0, y: 1, z: 0))
            }
            .frame(width: size, height: size * 1.15)
            .scaleEffect(pulseScale)
            .modifier(ShakeEffect(shakes: card.isShaking ? 3 : 0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.voiceOverLabel)
        .accessibilityHint(card.isMatched ? "Matched pair" : "Double tap to flip")
        .disabled(card.isMatched)
        .onChange(of: card.isFaceUp) { _, faceUp in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                flipDegrees = faceUp || card.isMatched ? 180 : 0
            }
        }
        .onChange(of: card.isMatched) { _, matched in
            if matched {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    pulseScale = 1.08
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) {
                    pulseScale = 1
                }
            }
        }
        .onAppear {
            flipDegrees = card.isFaceUp || card.isMatched ? 180 : 0
        }
    }

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackGradient)
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(.white.opacity(0.35), lineWidth: 2)
            VStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(.white)
                Text("MMK")
                    .font(.system(size: size * 0.12, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            ShineOverlay()
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        }
    }

    private var isMathOrTextCard: Bool {
        MathAssociationHelper.isExpression(card.content.label)
            || MathAssociationHelper.isNumericAnswer(card.content.label)
            || (!card.content.label.isEmpty && card.content.emoji == nil && card.content.symbolName == "plus.forwardslash.minus")
    }

    private var mathTextSize: CGFloat {
        let base = largeText ? size * 0.34 : size * 0.28
        return card.content.label.count > 3 ? base * 0.85 : base
    }

    private var cardFront: some View {
        let accent = Color(hex: colorBlindMode ? "007AFF" : card.content.accentColorHex)
        return ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(highContrast ? .white : AppTheme.cardSurface(for: colorScheme))
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(accent, lineWidth: highContrast ? 4 : 2)
            VStack(spacing: 4) {
                if let emoji = card.content.emoji {
                    Text(emoji)
                        .font(.system(size: largeText ? size * 0.42 : size * 0.36))
                    if !card.content.label.isEmpty, card.content.label != emoji {
                        Text(card.content.label)
                            .font(.system(size: largeText ? 14 : 11, weight: .bold, design: .rounded))
                            .foregroundStyle(highContrast ? .black : AppTheme.textPrimary(for: colorScheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .multilineTextAlignment(.center)
                    }
                } else if isMathOrTextCard {
                    Text(card.content.label)
                        .font(.system(size: mathTextSize, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(highContrast ? .black : AppTheme.textPrimary(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.45)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                } else {
                    Image(systemName: card.content.symbolName)
                        .font(.system(size: largeText ? size * 0.34 : size * 0.28, weight: .semibold))
                        .foregroundStyle(accent)
                    if !card.content.label.isEmpty {
                        Text(card.content.label)
                            .font(.system(size: largeText ? 14 : 11, weight: .bold, design: .rounded))
                            .foregroundStyle(highContrast ? .black : AppTheme.textPrimary(for: colorScheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(6)
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: Int

    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 2) * 6
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct ShineOverlay: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.35), .clear],
            startPoint: UnitPoint(x: phase - 0.3, y: 0),
            endPoint: UnitPoint(x: phase + 0.3, y: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}
