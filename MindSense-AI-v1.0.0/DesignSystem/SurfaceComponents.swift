import SwiftUI

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
    var minHeight: CGFloat = 46

    init(
        hierarchy: MindSenseButtonHierarchy,
        tint: Color = MindSensePalette.accent,
        fullWidth: Bool = true,
        minHeight: CGFloat = 46
    ) {
        self.hierarchy = hierarchy
        self.tint = tint
        self.fullWidth = fullWidth
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
        let isPressed = configuration.isPressed

        Group {
            switch hierarchy {
            case .primary:
                configuration.label
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(isEnabled ? MindSensePalette.onAccent : MindSensePalette.strokeStrong)
                    .frame(maxWidth: fullWidth ? .infinity : nil)
                    .frame(minHeight: minHeight)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .fill(primaryFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .stroke(primaryStroke, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .fill(MindSensePalette.shadowDirectional.opacity(isEnabled && isPressed ? 0.1 : 0))
                    )

            case .secondary:
                configuration.label
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(isEnabled ? tint : MindSensePalette.strokeStrong)
                    .frame(maxWidth: fullWidth ? .infinity : nil)
                    .frame(minHeight: minHeight)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .fill(MindSenseSurfaceLevel.raised.fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .stroke(MindSensePalette.strokeSubtle.opacity(isEnabled ? 1 : 0.7), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .fill(MindSensePalette.shadowDirectional.opacity(isEnabled && isPressed ? 0.06 : 0))
                    )

            case .text:
                configuration.label
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(tint.opacity(isEnabled ? (isPressed ? 0.62 : 1) : 0.45))
                    .frame(maxWidth: fullWidth ? .infinity : nil)
                    .frame(minHeight: max(40, minHeight - 2))
            }
        }
        .opacity(isPressed && isEnabled ? 0.9 : 1)
        .saturation(isEnabled ? 1 : 0.2)
        .contentShape(Rectangle())
        .hoverEffect(hierarchy == .text ? .highlight : .lift)
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
        .padding(20)
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

struct MindSenseCommandDeck: View {
    let label: String
    let title: String
    let detail: String
    var metric: String? = nil
    var tone: MindSenseSurfaceTone = .accent

    var body: some View {
        FocusSurface {
            VStack(alignment: .leading, spacing: MindSenseRhythm.regular) {
                HStack(alignment: .center, spacing: MindSenseSpacing.sm) {
                    HStack(spacing: MindSenseSpacing.xs) {
                        MindSenseIconBadge(systemName: "waveform.path.ecg", tint: headerTint, style: .filled, size: 30)
                        Text(label.uppercased())
                            .font(MindSenseTypography.micro)
                            .foregroundStyle(headerTint.opacity(0.95))
                            .tracking(1.35)
                    }
                    Spacer()
                    if let metric {
                        Text(metric)
                            .font(MindSenseTypography.metricCaption)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 30)
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

                MindSenseSectionDivider(emphasis: 0.43)

                Text(title.mindSenseHeadlineSafe)
                    .font(MindSenseTypography.display)
                    .lineSpacing(1.5)
                    .lineLimit(3)
                    .minimumScaleFactor(0.92)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(MindSenseTypography.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: MindSenseSpacing.xs) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(headerTint)
                    Text("Recommended next step")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
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
    let model: SectionHeaderModel

    var body: some View {
        HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
            if let icon = model.icon {
                MindSenseIconBadge(
                    systemName: icon,
                    tint: model.iconTint,
                    style: model.iconStyle,
                    size: 28
                )
                .padding(.top, 1)
                .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                Text(model.title.mindSenseHeadlineSafe)
                    .font(MindSenseTypography.titleCompact)
                    .tracking(0.15)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle = model.actionTitle, let action = model.action {
                Button(actionTitle, action: action)
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    static let compact: CGFloat = 10
    static let regular: CGFloat = 16
    static let section: CGFloat = 24
    static let page: CGFloat = 32
}

struct MindSenseSectionDivider: View {
    var inset: CGFloat = 0
    var emphasis: Double = 0.3

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
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background {
            Rectangle()
                .fill(MindSenseSurfaceLevel.base.fill.opacity(0.96))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MindSensePalette.strokeSubtle.opacity(0.7))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
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
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
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
            .opacity(state == .disabled ? 0.45 : 1)
            .animation(reduceMotion ? nil : MindSenseMotion.selection, value: state)
            .accessibilityLabel(label)
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
    var onSelectionChanged: ((Option) -> Void)? = nil

    private let containerCornerRadius = MindSenseRadius.tile

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                segmentButton(for: option)
            }
        }
        .padding(4)
        .background(containerBackground)
        .overlay(containerStroke)
    }

    private func segmentButton(for option: Option) -> some View {
        let isSelected = selection == option

        return Button {
            guard selection != option else { return }
            selection = option
            onSelectionChanged?(option)
        } label: {
            MindSenseSegmentOptionView(
                text: title(option),
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
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

    private let cornerRadius = MindSenseRadius.tile - 2

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        Text(text)
            .font(isSelected ? MindSenseTypography.bodyStrong : MindSenseTypography.body)
            .foregroundStyle(isSelected ? MindSensePalette.signalCoolStrong : .primary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 42)
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
