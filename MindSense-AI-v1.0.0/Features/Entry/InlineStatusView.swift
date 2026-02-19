import SwiftUI

struct InlineStatusView: View {
    let text: String
    let severity: BannerSeverity

    var body: some View {
        HStack(spacing: 8) {
            MindSenseIconBadge(systemName: icon, tint: severity.color, style: .filled, size: 28)
            Text(text)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .fill(MindSenseSurfaceLevel.glass.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private var icon: String {
        switch severity {
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }
}
