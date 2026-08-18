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
    /// Font size for the label under an emoji/symbol, shared across every
    /// card in the grid (computed once from the longest label in play) so
    /// cards don't each shrink their own text independently based on their
    /// own word length — that made shorter words render visibly bigger than
    /// longer ones sitting right next to them.
    var labelFontSize: CGFloat = 11
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
                    // NOT `flipDegrees + 180`: at rest (flipDegrees == 180)
                    // that put the front at an effective 360°, which is only
                    // *mathematically* equivalent to 0° — `cos`/`sin` of a
                    // 360°-converted angle aren't perfectly 1/0 in floating
                    // point, so Core Animation still composited it through a
                    // (near-imperceptibly) skewed transform matrix, forcing
                    // GPU-interpolated rendering that read as soft/blurry
                    // text. `flipDegrees - 180` settles at a TRUE 0° — no
                    // transform residue — while animating identically.
                    .rotation3DEffect(.degrees(flipDegrees - 180), axis: (x: 0, y: 1, z: 0))
            }
            // NOT `.drawingGroup()` — it rasterized the corners/border at a
            // fixed bitmap size, so they lost their crisp vector edge (looked
            // like the card design itself had changed) once transformed.
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
                    .font(.system(size: (size * 0.14).rounded(), weight: .black, design: .rounded))
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
        // Rounded to a whole point — Retina rendering looks visibly soft when
        // the font size doesn't land on a pixel boundary.
        switch card.content.label.count {
        case 0...3: return base.rounded()          // "A", "12", "USA"
        case 4...6: return (base * 0.72).rounded()  // "SHARK", "Japan"
        default: return (base * 0.55).rounded()     // "CROCODILE", "South Africa"
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
                        .font(.system(size: (largeText ? size * 0.42 : size * 0.36).rounded()))
                    if !card.content.label.isEmpty, card.content.label != emoji {
                        Text(card.content.label)
                            .font(.system(size: labelFontSize, weight: .bold, design: .rounded))
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
                            .font(.system(size: labelFontSize, weight: .bold, design: .rounded))
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
