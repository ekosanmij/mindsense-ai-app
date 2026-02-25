import SwiftUI

private extension DynamicTypeSize {
    var mindSenseCardReflowPreferred: Bool {
        isAccessibilitySize || self >= .xxLarge
    }
}

enum MindSenseButtonHierarchy {
    case primary
    case secondary
    case text
}

enum MindSenseButtonKind {
    case primary
    case secondary
    case quiet
    case destructive
}

struct MindSenseButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let hierarchy: MindSenseButtonHierarchy
    var tint: Color = MindSensePalette.accent
    var fullWidth: Bool = true
    var isLoading: Bool = false
    var minHeight: CGFloat = MindSenseControlSize.minimumTapTarget

    init(
        hierarchy: MindSenseButtonHierarchy,
        tint: Color = MindSensePalette.accent,
        fullWidth: Bool = true,
        isLoading: Bool = false,
        minHeight: CGFloat = MindSenseControlSize.minimumTapTarget
    ) {
        self.hierarchy = hierarchy
        self.tint = tint
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.minHeight = minHeight
    }

    init(kind: MindSenseButtonKind) {
        switch kind {
        case .primary:
            self.init(hierarchy: .primary)
        case .secondary:
            self.init(hierarchy: .secondary)
        case .quiet:
            self.init(hierarchy: .text, fullWidth: false)
        case .destructive:
            self.init(hierarchy: .text, tint: MindSensePalette.critical, fullWidth: false)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !isLoading
        let cornerRadius = controlCornerRadius

        Group {
            switch hierarchy {
            case .primary:
                configuration.label
                    .opacity(isLoading ? 0 : 1)
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(isEnabled ? MindSensePalette.onAccent : MindSensePalette.strokeStrong)
                    .frame(maxWidth: fullWidth ? .infinity : nil)
                    .frame(minHeight: max(MindSenseControlSize.primaryButton, minHeight))
                    .padding(.horizontal, MindSenseSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(primaryFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(primaryStroke, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                Color.black.opacity(
                                    isEnabled && isPressed ? MindSenseComponentState.pressedOverlayPrimary : 0
                                )
                            )
                    )
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(MindSensePalette.onAccent)
                        }
                    }

            case .secondary:
                configuration.label
                    .opacity(isLoading ? 0 : 1)
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(isEnabled ? tint : MindSensePalette.strokeStrong)
                    .frame(maxWidth: fullWidth ? .infinity : nil)
                    .frame(minHeight: max(MindSenseControlSize.minimumTapTarget, minHeight))
                    .padding(.horizontal, MindSenseSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(secondaryFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(secondaryStroke, lineWidth: 1.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                tint.opacity(
                                    isEnabled && isPressed ? MindSenseComponentState.pressedOverlaySecondary : 0
                                )
                            )
                    )
                    .shadow(
                        color: secondaryShadowColor,
                        radius: isEnabled && !isPressed ? 2 : 0,
                        x: 0,
                        y: isEnabled && !isPressed ? 1 : 0
                    )
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(tint)
                        }
                    }

            case .text:
                configuration.label
                    .opacity(isLoading ? 0 : 1)
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(textForeground(isPressed: isPressed))
                    .frame(maxWidth: fullWidth ? .infinity : nil)
                    .frame(minHeight: max(MindSenseControlSize.minimumTapTarget, minHeight - 2))
                    .padding(.horizontal, fullWidth ? 14 : MindSenseSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(textFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(textStroke, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                tint.opacity(
                                    isEnabled && isPressed ? MindSenseComponentState.pressedOverlaySecondary : 0
                                )
                            )
                    )
                    .shadow(
                        color: textShadowColor,
                        radius: isEnabled && !isPressed ? 1.5 : 0,
                        x: 0,
                        y: isEnabled && !isPressed ? 1 : 0
                    )
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(tint)
                        }
                    }
            }
        }
        .opacity(isPressed && isEnabled ? MindSenseComponentState.pressedControlOpacity : 1)
        .saturation(isEnabled ? 1 : MindSenseComponentState.disabledSaturation)
        .contentShape(Rectangle())
        .hoverEffect(hierarchy == .text ? .highlight : .lift)
    }

    private var controlCornerRadius: CGFloat {
        switch hierarchy {
        case .primary, .secondary:
            return MindSenseRadius.controlPrimary
        case .text:
            return MindSenseRadius.controlText
        }
    }

    private var primaryFill: AnyShapeStyle {
        if isEnabled {
            return AnyShapeStyle(tint)
        }
        return AnyShapeStyle(MindSenseSurfaceLevel.base.fill)
    }

    private var primaryStroke: Color {
        isEnabled ? MindSensePalette.strokeEdge.opacity(0.6) : MindSensePalette.strokeSubtle.opacity(0.72)
    }

    private var secondaryFill: Color {
        if isEnabled {
            return tint.opacity(0.08)
        }
        return MindSenseSurfaceLevel.base.fill
    }

    private var secondaryStroke: Color {
        if isEnabled {
            return tint.opacity(0.62)
        }
        return MindSensePalette.strokeSubtle.opacity(0.7)
    }

    private var secondaryShadowColor: Color {
        isEnabled ? MindSensePalette.shadowDirectional.opacity(MindSenseComponentState.secondaryShadowOpacity) : .clear
    }

    private var textFill: Color {
        if isEnabled {
            return MindSenseSurfaceLevel.raised.fill
        }
        return MindSenseSurfaceLevel.base.fill
    }

    private var textStroke: Color {
        if isEnabled {
            return tint.opacity(0.18)
        }
        return MindSensePalette.strokeSubtle.opacity(0.55)
    }

    private var textShadowColor: Color {
        isEnabled ? MindSensePalette.shadowDirectional.opacity(MindSenseComponentState.textShadowOpacity) : .clear
    }

    private func textForeground(isPressed: Bool) -> Color {
        guard isEnabled else { return tint.opacity(MindSenseComponentState.disabledTextTintOpacity) }
        return tint.opacity(isPressed ? 0.68 : 1)
    }
}

enum MindSenseSurfaceTone {
    case standard
    case accent
    case warning
    case critical

    var level: MindSenseSurfaceLevel {
        switch self {
        case .standard:
            return .raised
        case .accent:
            return .raised
        case .warning, .critical:
            return .raised
        }
    }

    var fill: Color {
        level.fill
    }

    var stroke: Color {
        MindSensePalette.strokeSubtle
    }

    var wash: LinearGradient {
        level.wash
    }

    var shine: Color {
        .clear
    }

    var elevation: MindSenseElevation {
        .base
    }
}

private struct CardContainer<Content: View>: View {
    let fill: Color
    let stroke: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.md) {
            content
        }
        .padding(MindSenseLayout.cardContentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.card, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.card, style: .continuous)
                .stroke(stroke, lineWidth: 1)
        )
    }
}

struct PrimarySurface<Content: View>: View {
    var tone: MindSenseSurfaceTone = .standard
    @ViewBuilder var content: Content

    var body: some View {
        CardContainer(
            fill: tone.fill,
            stroke: tone.stroke,
            content: { content }
        )
    }
}

struct InsetSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        CardContainer(
            fill: MindSenseSurfaceLevel.base.fill,
            stroke: MindSensePalette.strokeSubtle,
            content: { content }
        )
    }
}

struct GlassSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        CardContainer(
            fill: MindSenseSurfaceLevel.raised.fill,
            stroke: MindSensePalette.strokeSubtle.opacity(0.9),
            content: { content }
        )
    }
}

struct FocusSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        CardContainer(
            fill: MindSenseSurfaceLevel.raised.fill,
            stroke: MindSensePalette.strokeSubtle,
            content: { content }
        )
    }
}

struct MindSenseTabHero<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let label: String
    let title: String
    let detail: String
    var metric: String? = nil
    var metricAction: (() -> Void)? = nil
    var metricAccessibilityLabel: String? = nil
    var icon: String = "waveform.path.ecg"
    var tone: MindSenseSurfaceTone = .accent
    var watermarkTint: Color? = nil
    var watermarkHeight: CGFloat = 124
    @ViewBuilder var content: Content

    init(
        label: String,
        title: String,
        detail: String,
        metric: String? = nil,
        metricAction: (() -> Void)? = nil,
        metricAccessibilityLabel: String? = nil,
        icon: String = "waveform.path.ecg",
        tone: MindSenseSurfaceTone = .accent,
        watermarkTint: Color? = nil,
        watermarkHeight: CGFloat = 124,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.title = title
        self.detail = detail
        self.metric = metric
        self.metricAction = metricAction
        self.metricAccessibilityLabel = metricAccessibilityLabel
        self.icon = icon
        self.tone = tone
        self.watermarkTint = watermarkTint
        self.watermarkHeight = watermarkHeight
        self.content = content()
    }

    var body: some View {
        FocusSurface {
            VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                headerRow

                MindSenseSectionDivider(emphasis: MindSenseDividerEmphasis.hero)

                Text(title.mindSenseHeadlineSafe)
                    .font(MindSenseTypography.title)
                    .lineSpacing(1.5)
                    .lineLimit(dynamicTypeSize.mindSenseCardReflowPreferred ? 4 : 2)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.92)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.mindSenseCardReflowPreferred ? 4 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                content
            }
            .frame(maxWidth: 620, alignment: .leading)
        }
        .overlay(alignment: .topTrailing) {
            if let watermarkTint {
                MindSenseLogoWatermark(height: watermarkHeight, tint: watermarkTint)
                    .padding(.top, MindSenseSpacing.xs)
                    .padding(.trailing, MindSenseSpacing.xxxs)
            }
        }
    }

    private var headerTint: Color {
        switch tone {
        case .critical:
            return MindSensePalette.critical
        case .warning:
            return MindSensePalette.warning
        case .standard:
            return MindSensePalette.signalCool
        case .accent:
            return MindSensePalette.signalCoolStrong
        }
    }

    @ViewBuilder
    private var headerRow: some View {
        if dynamicTypeSize.mindSenseCardReflowPreferred {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                headerLabelRow
                if hasMetric {
                    headerMetricView
                }
            }
        } else {
            HStack(alignment: .center, spacing: MindSenseSpacing.sm) {
                headerLabelRow
                Spacer(minLength: 8)
                if hasMetric {
                    headerMetricView
                }
            }
        }
    }

    private var hasMetric: Bool {
        guard let metric else { return false }
        return !metric.isEmpty
    }

    private var headerLabelRow: some View {
        HStack(alignment: .center, spacing: MindSenseSpacing.xs) {
            MindSenseIconBadge(systemName: icon, tint: headerTint, style: .filled, size: MindSenseControlSize.chip)
            Text(label.uppercased())
                .font(MindSenseTypography.micro)
                .foregroundStyle(headerTint.opacity(0.95))
                .tracking(1.35)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var headerMetricView: some View {
        if let metric, !metric.isEmpty {
            if let metricAction {
                Button(action: metricAction) {
                    metricPill(metric)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(metricAccessibilityLabel ?? metric)
                .accessibilityHint("Opens details.")
            } else {
                metricPill(metric)
            }
        }
    }

    private func metricPill(_ metric: String) -> some View {
        Text(metric)
            .font(MindSenseTypography.metricCaption)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, MindSenseSpacing.sm)
            .frame(minHeight: MindSenseControlSize.minimumTapTarget)
            .foregroundStyle(.secondary)
            .background(
                Capsule(style: .continuous)
                    .fill(MindSenseSurfaceLevel.base.fill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
            )
    }
}

struct MindSenseCommandDeck: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let label: String
    let title: String
    let detail: String
    var metric: String? = nil
    var tone: MindSenseSurfaceTone = .accent

    var body: some View {
        MindSenseTabHero(
            label: label,
            title: title,
            detail: detail,
            metric: metric,
            icon: "waveform.path.ecg",
            tone: tone
        ) {
            recommendedStepLabel
        }
    }

    private var headerTint: Color {
        switch tone {
        case .critical:
            return MindSensePalette.critical
        case .warning:
            return MindSensePalette.warning
        case .standard:
            return MindSensePalette.signalCool
        case .accent:
            return MindSensePalette.signalCoolStrong
        }
    }

    @ViewBuilder
    private var recommendedStepLabel: some View {
        if dynamicTypeSize.mindSenseCardReflowPreferred {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(headerTint)
                    .accessibilityHidden(true)
                Text("Recommended next step")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        } else {
            HStack(spacing: MindSenseSpacing.xs) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(headerTint)
                    .accessibilityHidden(true)
                Text("Recommended next step")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

@available(*, deprecated, message: "Use PrimarySurface.")
struct HeroCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        PrimarySurface(tone: .accent) { content }
    }
}

@available(*, deprecated, message: "Use PrimarySurface.")
struct StandardCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        PrimarySurface { content }
    }
}

@available(*, deprecated, message: "Use InsetSurface.")
struct UtilityCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        InsetSurface { content }
    }
}

@available(*, deprecated, message: "Use PrimarySurface(tone:).")
struct AlertCard<Content: View>: View {
    let severity: BannerSeverity
    @ViewBuilder var content: Content

    var body: some View {
        let tone: MindSenseSurfaceTone = switch severity {
        case .success, .info:
            .accent
        case .warning:
            .warning
        case .error:
            .critical
        }
        PrimarySurface(tone: tone) { content }
    }
}

@available(*, deprecated, message: "Use PrimarySurface.")
struct PremiumCard<Content: View>: View {
    var highlighted = false
    @ViewBuilder var content: Content

    var body: some View {
        PrimarySurface(tone: highlighted ? .accent : .standard) { content }
    }
}

@available(*, deprecated, message: "Use InsetSurface.")
struct InsetPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        InsetSurface { content }
    }
}

struct SectionHeaderModel {
    let title: String
    var subtitle: String?
    var icon: String? = nil
    var iconTint: Color = MindSensePalette.signalCoolStrong
    var iconStyle: MindSenseIconContainerStyle = .filled
    var actionTitle: String?
    var action: (() -> Void)?
}

struct MindSenseSectionHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: SectionHeaderModel

    var body: some View {
        HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
            if let icon = model.icon {
                MindSenseIconBadge(
                    systemName: icon,
                    tint: model.iconTint,
                    style: model.iconStyle,
                    size: MindSenseControlSize.iconBadge
                )
                .padding(.top, 1)
                .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                Text(model.title.mindSenseHeadlineSafe)
                    .font(MindSenseTypography.bodyStrong)
                    .tracking(0.15)
                    .lineLimit(dynamicTypeSize.mindSenseCardReflowPreferred ? 4 : 2)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.9)
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.mindSenseCardReflowPreferred ? 4 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if shouldStackAction, let actionTitle = model.actionTitle, let action = model.action {
                    Button(actionTitle, action: action)
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }
            }
            if !shouldStackAction {
                Spacer(minLength: MindSenseSpacing.xs)
            }
            if !shouldStackAction, let actionTitle = model.actionTitle, let action = model.action {
                Button(actionTitle, action: action)
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shouldStackAction: Bool {
        dynamicTypeSize.mindSenseCardReflowPreferred && model.actionTitle != nil && model.action != nil
    }
}

struct MindSenseCollapsibleSection<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @AppStorage private var isExpanded: Bool

    let model: SectionHeaderModel
    var collapsedSummary: String?
    private let content: Content

    init(
        model: SectionHeaderModel,
        storageKey: String,
        defaultExpanded: Bool = true,
        collapsedSummary: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.model = model
        self.collapsedSummary = collapsedSummary
        self.content = content()
        self._isExpanded = AppStorage(wrappedValue: defaultExpanded, storageKey)
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.md) {
            sectionHeaderRow

            if !isExpanded, let collapsedSummary, !collapsedSummary.isEmpty {
                Text(collapsedSummary)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isExpanded {
                content
            }
        }
    }

    @ViewBuilder
    private var sectionHeaderRow: some View {
        if dynamicTypeSize.mindSenseCardReflowPreferred {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                MindSenseSectionHeader(model: model)

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    collapseButton
                }
            }
        } else {
            HStack(alignment: .top, spacing: MindSenseSpacing.xs) {
                MindSenseSectionHeader(model: model)
                collapseButton
            }
        }
    }

    private var collapseButton: some View {
        Button {
            if reduceMotion {
                isExpanded.toggle()
            } else {
                withAnimation(MindSenseMotion.selection) {
                    isExpanded.toggle()
                }
            }
        } label: {
            HStack(spacing: MindSenseSpacing.xxxs) {
                Text(isExpanded ? "Hide" : "Show")
                    .font(MindSenseTypography.micro)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, MindSenseSpacing.xs)
            .frame(minHeight: MindSenseControlSize.chip)
            .background(
                Capsule(style: .continuous)
                    .fill(MindSenseSurfaceLevel.base.fill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Hide \(model.title)" : "Show \(model.title)")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Collapses section content." : "Expands section content.")
    }
}

struct MindSenseSummaryDisclosureText: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    let summary: String
    let detail: String
    var collapsedLabel: String = "Details"
    var expandedLabel: String = "Hide details"
    var textStyle: Font = MindSenseTypography.caption
    var textColor: Color = .secondary
    @State private var expanded = false

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var hasExpandableDetail: Bool {
        !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(summary)
                .font(textStyle)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

            if expanded, hasExpandableDetail {
                Text(detail)
                    .font(textStyle)
                    .foregroundStyle(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hasExpandableDetail {
                Button {
                    if reduceMotion {
                        expanded.toggle()
                    } else {
                        withAnimation(MindSenseMotion.selection) {
                            expanded.toggle()
                        }
                    }
                } label: {
                    HStack(spacing: MindSenseSpacing.xxxs) {
                        Text(expanded ? expandedLabel : collapsedLabel)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                }
                .buttonStyle(
                    MindSenseButtonStyle(
                        hierarchy: .text,
                        fullWidth: false,
                        minHeight: MindSenseControlSize.minimumTapTarget
                    )
                )
                .accessibilityLabel(expanded ? expandedLabel : collapsedLabel)
                .accessibilityValue(expanded ? "Expanded" : "Collapsed")
                .accessibilityHint(expanded ? "Collapses details" : "Expands details")
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        MindSenseSectionHeader(
            model: .init(title: title, subtitle: subtitle, actionTitle: nil, action: nil)
        )
    }
}

enum MindSenseRhythm {
    static let compact: CGFloat = MindSenseSpacing.sm
    static let regular: CGFloat = MindSenseSpacing.md
    static let section: CGFloat = MindSenseSpacing.lg
    static let page: CGFloat = MindSenseSpacing.xl
}

struct MindSenseSectionDivider: View {
    var inset: CGFloat = 0
    var emphasis: Double = MindSenseDividerEmphasis.regular

    var body: some View {
        Rectangle()
            .fill(MindSensePalette.strokeSubtle.opacity(0.62 + (emphasis * 0.12)))
            .frame(height: 1)
            .padding(.horizontal, inset)
            .accessibilityHidden(true)
    }
}

struct MindSenseBottomActionDock<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: MindSenseSpacing.xs) {
            content
        }
        .padding(.horizontal, MindSenseSpacing.md)
        .padding(.top, MindSenseSpacing.xxxs)
        .padding(.bottom, MindSenseSpacing.xxxs)
        .background {
            Rectangle()
                .fill(MindSenseSurfaceLevel.base.fill.opacity(0.96))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MindSensePalette.strokeSubtle.opacity(0.7))
                        .frame(height: 1)
                        .padding(.horizontal, MindSenseSpacing.md)
                }
        }
    }
}

struct MindSenseDoItNowDock<Content: View>: View {
    var title: String = "Do it now"
    var subtitle: String?
    @ViewBuilder var content: Content

    var body: some View {
        MindSenseBottomActionDock {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                Text(title)
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .tracking(0.8)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                content
            }
        }
    }
}

extension View {
    func mindSenseRhythm(_ spacing: CGFloat = MindSenseRhythm.regular) -> some View {
        padding(.vertical, spacing / 2)
    }
}

enum MindSenseChipState: Equatable {
    case selected
    case unselected
    case disabled
}

struct PillChip: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    let label: String
    let state: MindSenseChipState

    init(label: String, selected: Bool = false) {
        self.label = label
        self.state = selected ? .selected : .unselected
    }

    init(label: String, state: MindSenseChipState) {
        self.label = label
        self.state = state
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        Text(label)
            .font(MindSenseTypography.caption)
            .lineLimit(1)
            .padding(.horizontal, MindSenseSpacing.sm)
            .frame(minHeight: MindSenseControlSize.chip)
            .foregroundStyle(foreground)
            .background(
                Capsule(style: .continuous)
                    .fill(baseBackground)
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(selectedFill)
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
            .opacity(state == .disabled ? MindSenseComponentState.disabledChipOpacity : 1)
            .animation(reduceMotion ? nil : MindSenseMotion.selection, value: state)
            .accessibilityLabel(label)
            .accessibilityValue(accessibilityStateValue)
    }

    private var foreground: Color {
        state == .selected ? MindSensePalette.signalCoolStrong : .primary
    }

    private var baseBackground: Color {
        state == .selected ? MindSensePalette.accentMuted : MindSenseSurfaceLevel.base.fill
    }

    private var selectedFill: AnyShapeStyle {
        AnyShapeStyle(Color.clear)
    }

    private var border: Color {
        state == .selected ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle
    }

    private var accessibilityStateValue: String {
        switch state {
        case .selected:
            return "Selected"
        case .unselected:
            return "Not selected"
        case .disabled:
            return "Unavailable"
        }
    }
}

enum MindSenseIconContainerStyle {
    case filled
    case muted
    case outlined
}

struct MindSenseIconBadge: View {
    let systemName: String
    var tint: Color = MindSensePalette.accent
    var style: MindSenseIconContainerStyle = .filled
    var size: CGFloat = 36

    var body: some View {
        let cornerRadius = max(MindSenseRadius.tight, size * 0.3)

        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(background)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(border, lineWidth: borderLineWidth)
            Image(systemName: systemName)
                .font(.system(size: max(14, size * 0.43), weight: symbolWeight, design: .rounded))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(foreground)
        }
        .frame(width: size, height: size)
    }

    private var background: AnyShapeStyle {
        switch style {
        case .filled:
            return AnyShapeStyle(tint.opacity(0.18))
        case .muted:
            return AnyShapeStyle(MindSenseSurfaceLevel.glass.fill)
        case .outlined:
            return AnyShapeStyle(Color.clear)
        }
    }

    private var foreground: Color {
        switch style {
        case .filled, .outlined:
            return tint
        case .muted:
            return .secondary
        }
    }

    private var border: Color {
        switch style {
        case .filled:
            return MindSensePalette.strokeEdge.opacity(0.55)
        case .muted:
            return MindSensePalette.strokeSubtle
        case .outlined:
            return MindSensePalette.strokeEdge
        }
    }

    private var borderLineWidth: CGFloat {
        switch style {
        case .filled:
            return 1
        case .muted, .outlined:
            return 1
        }
    }

    private var symbolWeight: Font.Weight {
        switch style {
        case .filled:
            return .semibold
        case .muted:
            return .medium
        case .outlined:
            return .regular
        }
    }
}

struct MindSenseLogoMark: View {
    var height: CGFloat = 18
    var tint: Color = MindSensePalette.accent

    var body: some View {
        Image("LogoMark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(tint)
            .frame(width: height * 1.72, height: height)
            .accessibilityHidden(true)
    }
}

struct MindSenseNavTitleLockup: View {
    let title: String
    var markHeight: CGFloat = 19
    var tint: Color = MindSensePalette.accent

    var body: some View {
        MindSenseLogoMark(height: markHeight, tint: tint)
            .frame(height: markHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
    }
}

struct MindSenseLogoWatermark: View {
    @Environment(\.colorScheme) private var colorScheme

    var height: CGFloat = 138
    var tint: Color = MindSensePalette.accent
    var lightOpacity: Double = 0.055
    var darkOpacity: Double = 0.042
    var blurRadius: CGFloat = 2

    var body: some View {
        MindSenseLogoMark(height: height, tint: tint)
            .opacity(colorScheme == .dark ? darkOpacity : lightOpacity)
            .blur(radius: blurRadius)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct MindSenseLogoBadge: View {
    var size: CGFloat = 28
    var tint: Color = MindSensePalette.signalCoolStrong

    var body: some View {
        let cornerRadius = max(MindSenseRadius.tight, size * 0.32)

        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tint.opacity(0.16))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MindSensePalette.strokeEdge.opacity(0.58), lineWidth: 1)
            )
            .overlay {
                MindSenseLogoMark(height: max(13, size * 0.44), tint: tint)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct MindSenseSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    var enablesHorizontalScrollFallback: Bool = false
    var onSelectionChanged: ((Option) -> Void)? = nil

    private let containerCornerRadius = MindSenseRadius.tile

    var body: some View {
        Group {
            if enablesHorizontalScrollFallback {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MindSenseSpacing.xs) {
                        ForEach(options, id: \.self) { option in
                            segmentButton(for: option, fillAvailableWidth: false)
                        }
                    }
                    .padding(MindSenseSpacing.xxxs)
                }
            } else {
                HStack(spacing: MindSenseSpacing.xs) {
                    ForEach(options, id: \.self) { option in
                        segmentButton(for: option, fillAvailableWidth: true)
                    }
                }
                .padding(MindSenseSpacing.xxxs)
            }
        }
        .background(containerBackground)
        .overlay(containerStroke)
    }

    private func segmentButton(for option: Option, fillAvailableWidth: Bool) -> some View {
        let isSelected = selection == option

        return Button {
            guard selection != option else { return }
            selection = option
            onSelectionChanged?(option)
        } label: {
            MindSenseSegmentOptionView(
                text: title(option),
                isSelected: isSelected,
                fillAvailableWidth: fillAvailableWidth
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title(option))
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Current selection." : "Selects this option.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var containerBackground: some View {
        RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
            .fill(MindSenseSurfaceLevel.glass.fill)
    }

    private var containerStroke: some View {
        RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
            .stroke(MindSensePalette.strokeStrong.opacity(0.65), lineWidth: 1)
    }
}

private struct MindSenseSegmentOptionView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    let text: String
    let isSelected: Bool
    let fillAvailableWidth: Bool

    private let cornerRadius = MindSenseRadius.tile - 2

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        Text(text)
            .font(isSelected ? MindSenseTypography.bodyStrong : MindSenseTypography.body)
            .foregroundStyle(isSelected ? MindSensePalette.signalCoolStrong : .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .allowsTightening(true)
            .padding(.horizontal, fillAvailableWidth ? MindSenseSpacing.xs : MindSenseSpacing.sm)
            .frame(maxWidth: fillAvailableWidth ? .infinity : nil)
            .frame(minHeight: MindSenseControlSize.minimumTapTarget)
            .background(segmentBackground)
            .overlay(segmentStroke)
            .animation(reduceMotion ? nil : MindSenseMotion.selection, value: isSelected)
    }

    private var segmentBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(selectedFill)
    }

    private var segmentStroke: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(isSelected ? MindSensePalette.strokeEdge : .clear, lineWidth: 1)
    }

    private var selectedFill: AnyShapeStyle {
        isSelected
            ? AnyShapeStyle(MindSensePalette.accentMuted)
            : AnyShapeStyle(Color.clear)
    }
}
