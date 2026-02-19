import SwiftUI

struct NotificationBannerView: View {
    let banner: AppBanner

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            MindSenseIconBadge(systemName: icon, tint: banner.severity.color, style: .filled, size: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(severityLabel)
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(banner.severity.color)
                        .tracking(0.9)
                    Text(banner.title)
                        .font(MindSenseTypography.caption)
                }
                Text(banner.detail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
    }

    private var severityLabel: String {
        switch banner.severity {
        case .success:
            return "SUCCESS"
        case .info:
            return "SYSTEM"
        case .warning:
            return "ATTENTION"
        case .error:
            return "ALERT"
        }
    }

    private var icon: String {
        switch banner.severity {
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

struct MetricRingView: View {
    let metric: String
    let value: Int
    let subtitle: String
    let progress: Double
    let color: Color
    var definition: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.16), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: max(0, min(progress, 1)))
                        .stroke(
                            color,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text("\(value)")
                            .font(MindSenseTypography.metricDisplay)
                            .monospacedDigit()
                        Text("/100")
                            .font(MindSenseTypography.metricCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 90, height: 90)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(metric)
                        .font(MindSenseTypography.bodyStrong)
                    Text(subtitle)
                        .font(MindSenseTypography.body)
                        .foregroundStyle(.secondary)
                    if let definition {
                        Text(definition)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric), \(value), \(subtitle)")
    }
}

struct DriverImpactRowView: View {
    let driver: DriverImpact

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(driver.name)
                        .font(MindSenseTypography.bodyStrong)
                    Text(driver.detail)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                PillChip(label: "\(Int(driver.impact * 100))%", state: .unselected)
            }

            GeometryReader { proxy in
                let width = proxy.size.width * max(0.04, min(driver.impact, 1))
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(MindSensePalette.surfaceInset)
                    Capsule(style: .continuous)
                        .fill(MindSensePalette.warning.opacity(0.42))
                        .frame(width: width)
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, 2)
    }
}

struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let points = normalizedPoints(in: proxy.size)
            ZStack {
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round)
                )

                Path { path in
                    guard let first = points.first, let last = points.last else { return }
                    path.move(to: CGPoint(x: first.x, y: proxy.size.height))
                    path.addLine(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: last.x, y: proxy.size.height))
                    path.closeSubpath()
                }
                .fill(
                    color.opacity(0.2)
                )
            }
        }
        .frame(height: 94)
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let span = max(maxValue - minValue, 0.0001)

        return values.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(max(values.count - 1, 1)) * size.width
            let normalized = (value - minValue) / span
            let y = size.height - (CGFloat(normalized) * size.height)
            return CGPoint(x: x, y: y)
        }
    }
}

struct InterventionRowView: View {
    let intervention: Intervention
    let showStartButton: Bool
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            MindSenseIconBadge(systemName: intervention.icon, tint: MindSensePalette.accent)

            VStack(alignment: .leading, spacing: 3) {
                Text(intervention.title)
                    .font(MindSenseTypography.bodyStrong)
                Text(intervention.detail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if showStartButton {
                Button("Start") { onTap?() }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false))
            } else {
                PillChip(label: intervention.duration, selected: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .fill(MindSensePalette.surfaceInset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }
}

struct ProtocolTokenStripView: View {
    let what: String
    let why: String
    let expectedEffect: String
    let time: String
    var maxValueLines: Int = 2
    var minimumCellHeight: CGFloat = 72

    private var tokens: [(label: String, value: String)] {
        [
            ("What", what),
            ("Why", why),
            ("Expected effect", expectedEffect),
            ("Time", time)
        ]
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: MindSenseSpacing.xs), GridItem(.flexible(), spacing: MindSenseSpacing.xs)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: MindSenseSpacing.xs) {
            ForEach(tokens, id: \.label) { token in
                VStack(alignment: .leading, spacing: MindSenseSpacing.xxs) {
                    Text(token.label)
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                    Text(token.value)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(maxValueLines)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: minimumCellHeight, alignment: .topLeading)
                .padding(.horizontal, MindSenseLayout.tileHorizontalInset)
                .padding(.vertical, MindSenseLayout.tileVerticalInset)
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                )
            }
        }
    }
}
