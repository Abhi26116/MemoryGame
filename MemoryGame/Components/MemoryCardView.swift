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
    var cardBackStyle: CardBackStyle = .classic
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            .modifier(ShakeEffect(shakes: (card.isShaking && !reduceMotion) ? 3 : 0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.voiceOverLabel)
        .accessibilityHint(card.isMatched ? "Matched pair" : "Double tap to flip")
        .disabled(card.isMatched)
        .onChange(of: card.isFaceUp) { _, faceUp in
            withAnimation(DS.Motion.respecting(reduceMotion, DS.Motion.spring)) {
                flipDegrees = faceUp || card.isMatched ? 180 : 0
            }
        }
        .onChange(of: card.isMatched) { _, matched in
            guard matched, !reduceMotion else { return }
            withAnimation(DS.Motion.bouncy) {
                pulseScale = 1.12
            }
            withAnimation(DS.Motion.spring.delay(0.15)) {
                pulseScale = 1
            }
        }
        .onAppear {
            flipDegrees = card.isFaceUp || card.isMatched ? 180 : 0
        }
    }

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(cardBackStyle.gradient)
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(.white.opacity(0.35), lineWidth: 2)
            VStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(.white)
                Text("MM")
                    .font(.system(size: size * 0.14, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(1)
            }
            ShineOverlay()
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        }
    }

    /// Any card without an emoji shows its label as text (letters, words, country
    /// names, math). The current content has no intentional SF-symbol cards, so the
    /// old symbol+label path left a stray ⭐ above letters/words.
    private var isTextCard: Bool {
        card.content.emoji == nil && !card.content.label.isEmpty
    }

    private var textSize: CGFloat {
        let base = largeText ? size * 0.34 : size * 0.28
        switch card.content.label.count {
        case 0...3: return base          // "A", "12", "USA"
        case 4...6: return base * 0.72    // "SHARK", "Japan"
        default: return base * 0.55       // "CROCODILE", "South Africa"
        }
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
                } else if isTextCard {
                    Text(card.content.label)
                        .font(.system(size: textSize, weight: .heavy, design: .rounded))
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.35), .clear],
            startPoint: UnitPoint(x: phase - 0.3, y: 0),
            endPoint: UnitPoint(x: phase + 0.3, y: 1)
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}
