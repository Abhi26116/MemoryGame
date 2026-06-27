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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.progressTrack(for: colorScheme))
                    Capsule()
                        .fill(gradient)
                        .frame(width: max(0, geo.size.width * min(1, progress)))
                        .animation(DS.Motion.respecting(reduceMotion, DS.Motion.spring), value: progress)
                }
            }
            .frame(height: height)
        }
    }
}
