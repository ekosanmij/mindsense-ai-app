import SwiftUI

struct ScreenPromiseView: View {
    let promise: String
    var successCriteria: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(promise)
                .font(MindSenseTypography.bodyStrong)
            if let successCriteria {
                Text(successCriteria)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct RecommendationRationaleView: View {
    let estimate: String
    let whyRecommended: String
    @State private var expanded = false

    var body: some View {
        InsetSurface {
            DisclosureGroup(isExpanded: $expanded) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(estimate)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    Divider()
                    Text(whyRecommended)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            } label: {
                HStack {
                    Text("Estimate and rationale")
                        .font(MindSenseTypography.bodyStrong)
                    Spacer()
                }
            }
        }
    }
}

enum EscalationContext {
    case immediateRisk
    case sustainedHighLoad
    case communityConcern
}

struct EscalationGuidanceView: View {
    let context: EscalationContext

    var body: some View {
        PrimarySurface(tone: .warning) {
            HStack(alignment: .top, spacing: 10) {
                MindSenseIconBadge(systemName: "exclamationmark.triangle.fill", tint: MindSensePalette.warning, style: .filled, size: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Escalation guidance")
                        .font(MindSenseTypography.bodyStrong)
                    Text(message)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var message: String {
        switch context {
        case .immediateRisk:
            return "If you might harm yourself or someone else, call emergency services now. In the US and Canada, call or text 988."
        case .sustainedHighLoad:
            return "If high distress lasts or worsens despite self-regulation, contact a licensed clinician for direct support."
        case .communityConcern:
            return "Community posts cannot provide urgent care. Use crisis resources immediately if safety risk is present."
        }
    }
}

struct ScreenStateContainer<Content: View>: View {
    let state: ScreenMode
    var retryAction: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        switch state {
        case .loading:
            VStack(spacing: 12) {
                LoadingSkeletonCard()
                LoadingSkeletonCard()
            }

        case .ready:
            content

        case .empty(let emptyState):
            PrimarySurface(tone: .accent) {
                Text(emptyState.title.mindSenseHeadlineSafe)
                    .font(MindSenseTypography.title)
                Text(emptyState.message)
                    .font(MindSenseTypography.body)
                    .foregroundStyle(.secondary)
            }

        case .error(let errorState):
            PrimarySurface(tone: .critical) {
                Text(errorState.title.mindSenseHeadlineSafe)
                    .font(MindSenseTypography.title)
                Text(errorState.message)
                    .font(MindSenseTypography.body)
                    .foregroundStyle(.secondary)
                if let retryAction {
                    Button("Retry", action: retryAction)
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary))
                }
            }
        }
    }
}

struct LoadingSkeletonCard: View {
    var body: some View {
        InsetSurface {
            VStack(alignment: .leading, spacing: 10) {
                skeletonLine(width: 120, height: 14)
                skeletonLine(width: 230, height: 12)
                skeletonLine(width: 190, height: 12)
            }
        }
        .frame(minHeight: 104)
    }

    private func skeletonLine(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(MindSenseSurfaceLevel.base.fill.opacity(0.92))
            .frame(width: width, height: height)
    }
}

private struct MindSensePremiumBackground: View {
    var body: some View {
        MindSensePalette.canvasTop
            .ignoresSafeArea()
    }
}

extension View {
    func mindSensePageBackground() -> some View {
        background(MindSensePremiumBackground())
    }
}
