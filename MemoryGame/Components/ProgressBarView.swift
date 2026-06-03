//
//  ProgressBarView.swift
//  Memory Match Kids
//

import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var label: String? = nil
    var height: CGFloat = 14
    var gradient: LinearGradient = AppTheme.primaryGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.progressTrack)
                    Capsule()
                        .fill(gradient)
                        .frame(width: max(0, geo.size.width * min(1, progress)))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: height)
        }
    }
}
