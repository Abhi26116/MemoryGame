//
//  SplashView.swift
//  Memory Match Kids
//

import SwiftUI

enum SplashTiming {
    static let holdDuration: Duration = .seconds(2)
}

struct SplashView: View {
    @State private var showContent = false

    var body: some View {
        ZStack {
            AppTheme.skyGradient
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "FF6B9D").opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: -90, y: -200)

            Circle()
                .fill(Color(hex: "5B8DEF").opacity(0.2))
                .frame(width: 220, height: 220)
                .blur(radius: 32)
                .offset(x: 110, y: 240)

            VStack(spacing: 28) {
                logoHero
                titleBlock
            }
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1 : 0.92)
            .opacity(showContent ? 1 : 0)
        }
        .kidColorScheme()
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                showContent = true
            }
        }
    }

    private var logoHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(AppTheme.cardSurface)
                .shadow(color: Color(hex: "5B8DEF").opacity(0.2), radius: 24, y: 12)

            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(hex: "B8E6FF").opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .padding(28)
        }
        .frame(width: 280, height: 200)
        .overlay(alignment: .topLeading) {
            miniCard(rotation: -14)
                .offset(x: -18, y: 36)
        }
        .overlay(alignment: .topTrailing) {
            miniCard(rotation: 12)
                .offset(x: 18, y: 44)
        }
        .accessibilityHidden(true)
    }

    private func miniCard(rotation: Double) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(AppTheme.cardBackGradient)
            .frame(width: 44, height: 58)
            .overlay {
                Image(systemName: "star.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "FFD60A"))
            }
            .shadow(color: Color(hex: "5B8DEF").opacity(0.25), radius: 6, y: 3)
            .rotationEffect(.degrees(rotation))
    }

    private var titleBlock: some View {
        VStack(spacing: 10) {
            Text(AppTheme.appName)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FF6B9D"), Color(hex: "5B8DEF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Match • Learn • Play!")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

//#Preview {
//    SplashView()
//}
