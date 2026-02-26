import SwiftUI

enum MindSenseVisualBrief {
    static let adjectives = ["warm", "sleek", "intelligent", "calm", "premium"]
    static let antiAdjectives = ["cold", "noisy", "gimmicky"]
}

enum MindSenseToneGuide {
    static let voice = "calm, factual, directive, non-alarmist"
    static let principles = [
        "State signal first, then one action.",
        "Frame model outputs as estimates with confidence context.",
        "Favor one clear next step over multiple options.",
        "Use escalation language only in risk-relevant contexts."
    ]
}

struct MindSensePalette {
    // Redesign parity tokens (DS-03).
    static let primary = dynamic(
        light: UIColor(red: 27 / 255, green: 111 / 255, blue: 87 / 255, alpha: 1),
        dark: UIColor(red: 134 / 255, green: 210 / 255, blue: 186 / 255, alpha: 1)
    )
    static let primaryTint = dynamic(
        light: UIColor(red: 237 / 255, green: 243 / 255, blue: 242 / 255, alpha: 1),
        dark: UIColor(red: 30 / 255, green: 42 / 255, blue: 38 / 255, alpha: 1)
    )
    static let accentLoad = dynamic(
        light: UIColor(red: 149 / 255, green: 85 / 255, blue: 31 / 255, alpha: 1),
        dark: UIColor(red: 236 / 255, green: 184 / 255, blue: 96 / 255, alpha: 1)
    )
    static let bg = dynamic(
        light: UIColor(red: 247 / 255, green: 248 / 255, blue: 250 / 255, alpha: 1),
        dark: UIColor(red: 16 / 255, green: 17 / 255, blue: 19 / 255, alpha: 1)
    )
    static let card = dynamic(
        light: UIColor(red: 243 / 255, green: 244 / 255, blue: 246 / 255, alpha: 1),
        dark: UIColor(red: 36 / 255, green: 38 / 255, blue: 41 / 255, alpha: 1)
    )
    static let textPrimary = dynamic(
        light: UIColor(red: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1),
        dark: UIColor(red: 235 / 255, green: 239 / 255, blue: 244 / 255, alpha: 1)
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 75 / 255, green: 85 / 255, blue: 99 / 255, alpha: 1),
        dark: UIColor(red: 189 / 255, green: 198 / 255, blue: 210 / 255, alpha: 1)
    )
    static let border = dynamic(
        light: UIColor(red: 209 / 255, green: 213 / 255, blue: 219 / 255, alpha: 1),
        dark: UIColor(red: 84 / 255, green: 90 / 255, blue: 100 / 255, alpha: 1)
    )

    static let signalCool = dynamic(
        light: UIColor(red: 17 / 255, green: 122 / 255, blue: 105 / 255, alpha: 1),
        dark: UIColor(red: 134 / 255, green: 210 / 255, blue: 186 / 255, alpha: 1)
    )
    static let signalCoolStrong = dynamic(
        light: UIColor(red: 12 / 255, green: 94 / 255, blue: 81 / 255, alpha: 1),
        dark: UIColor(red: 108 / 255, green: 186 / 255, blue: 162 / 255, alpha: 1)
    )
    static let signalCoolSoft = dynamic(
        light: UIColor(red: 223 / 255, green: 241 / 255, blue: 235 / 255, alpha: 1),
        dark: UIColor(red: 30 / 255, green: 42 / 255, blue: 38 / 255, alpha: 1)
    )

    static let glowWarm = dynamic(
        light: UIColor(red: 19 / 255, green: 130 / 255, blue: 108 / 255, alpha: 1),
        dark: UIColor(red: 166 / 255, green: 203 / 255, blue: 183 / 255, alpha: 1)
    )
    static let glowWarmStrong = dynamic(
        light: UIColor(red: 13 / 255, green: 101 / 255, blue: 83 / 255, alpha: 1),
        dark: UIColor(red: 128 / 255, green: 170 / 255, blue: 149 / 255, alpha: 1)
    )
    static let glowWarmSoft = dynamic(
        light: UIColor(red: 226 / 255, green: 242 / 255, blue: 236 / 255, alpha: 1),
        dark: UIColor(red: 35 / 255, green: 45 / 255, blue: 41 / 255, alpha: 1)
    )

    static let accent = signalCool
    static let accentStrong = signalCoolStrong
    static let accentSoft = signalCoolSoft
    static let onAccent = dynamic(
        light: UIColor.white,
        dark: UIColor(red: 16 / 255, green: 24 / 255, blue: 21 / 255, alpha: 1)
    )
    static let accentMuted = dynamic(
        light: UIColor(red: 235 / 255, green: 247 / 255, blue: 243 / 255, alpha: 1),
        dark: UIColor(red: 38 / 255, green: 48 / 255, blue: 45 / 255, alpha: 1)
    )

    static let success = dynamic(
        light: UIColor(red: 25 / 255, green: 124 / 255, blue: 84 / 255, alpha: 1),
        dark: UIColor(red: 112 / 255, green: 224 / 255, blue: 178 / 255, alpha: 1)
    )
    static let warning = dynamic(
        light: UIColor(red: 171 / 255, green: 98 / 255, blue: 24 / 255, alpha: 1),
        dark: UIColor(red: 236 / 255, green: 184 / 255, blue: 96 / 255, alpha: 1)
    )
    static let critical = dynamic(
        light: UIColor(red: 170 / 255, green: 50 / 255, blue: 58 / 255, alpha: 1),
        dark: UIColor(red: 243 / 255, green: 123 / 255, blue: 130 / 255, alpha: 1)
    )

    static let canvasTop = dynamic(
        light: UIColor(red: 245 / 255, green: 247 / 255, blue: 249 / 255, alpha: 1),
        dark: UIColor(red: 16 / 255, green: 17 / 255, blue: 19 / 255, alpha: 1)
    )
    static let canvasBottom = dynamic(
        light: UIColor(red: 240 / 255, green: 243 / 255, blue: 246 / 255, alpha: 1),
        dark: UIColor(red: 20 / 255, green: 21 / 255, blue: 24 / 255, alpha: 1)
    )

    static let surfaceBase = dynamic(
        light: UIColor(red: 237 / 255, green: 241 / 255, blue: 245 / 255, alpha: 1),
        dark: UIColor(red: 30 / 255, green: 32 / 255, blue: 35 / 255, alpha: 1)
    )
    static let surfaceRaised = dynamic(
        light: UIColor(red: 249 / 255, green: 251 / 255, blue: 253 / 255, alpha: 1),
        dark: UIColor(red: 36 / 255, green: 38 / 255, blue: 41 / 255, alpha: 1)
    )
    static let surfaceGlass = dynamic(
        light: UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 0.64),
        dark: UIColor(red: 53 / 255, green: 56 / 255, blue: 60 / 255, alpha: 0.44)
    )
    static let surfaceFocus = dynamic(
        light: UIColor(red: 246 / 255, green: 249 / 255, blue: 252 / 255, alpha: 1),
        dark: UIColor(red: 42 / 255, green: 44 / 255, blue: 48 / 255, alpha: 1)
    )

    static let surfacePrimary = surfaceRaised
    static let surfaceInset = surfaceBase
    @available(*, deprecated, message: "Use surfaceFocus.")
    static let surfaceHero = surfaceFocus
    @available(*, deprecated, message: "Use surfaceRaised.")
    static let surfaceStandard = surfaceRaised

    static let strokeSubtle = dynamic(
        light: UIColor.black.withAlphaComponent(0.08),
        dark: UIColor.white.withAlphaComponent(0.1)
    )
    static let strokeStrong = dynamic(
        light: UIColor.black.withAlphaComponent(0.17),
        dark: UIColor.white.withAlphaComponent(0.22)
    )
    static let strokeEdge = dynamic(
        light: UIColor.black.withAlphaComponent(0.12),
        dark: UIColor.white.withAlphaComponent(0.15)
    )
    static let strokeFocus = dynamic(
        light: UIColor.black.withAlphaComponent(0.16),
        dark: UIColor.white.withAlphaComponent(0.2)
    )

    static let shineTop = dynamic(
        light: UIColor.white.withAlphaComponent(0.58),
        dark: UIColor.white.withAlphaComponent(0.18)
    )
    static let shineEdge = dynamic(
        light: UIColor.white.withAlphaComponent(0.38),
        dark: UIColor.white.withAlphaComponent(0.2)
    )

    static let shadowAmbient = dynamic(
        light: UIColor.black.withAlphaComponent(0.06),
        dark: UIColor.black.withAlphaComponent(0.32)
    )
    static let shadowDirectional = dynamic(
        light: UIColor.black.withAlphaComponent(0.1),
        dark: UIColor.black.withAlphaComponent(0.44)
    )

    @available(*, deprecated, message: "Use shadowDirectional.")
    static let shadow = shadowDirectional

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

enum MindSenseContrastUsage {
    // WCAG anchors used by Scripts/contrast_audit.swift.
    static let minimumPrimaryTextRatio: Double = 7.0
    static let minimumBodyTextRatio: Double = 4.5
    static let minimumInteractiveGraphicRatio: Double = 3.0
    // Decorative dividers are non-interactive and intentionally softer.
    static let minimumDecorativeDividerRatio: Double = 1.3
}

enum MindSenseGradients {
    static var hero: LinearGradient {
        LinearGradient(
            colors: [
                MindSensePalette.canvasTop,
                MindSensePalette.canvasBottom,
                MindSensePalette.signalCoolSoft.opacity(0.3),
                MindSensePalette.glowWarmSoft.opacity(0.26)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var surface: LinearGradient {
        LinearGradient(
            colors: [
                MindSensePalette.surfaceRaised,
                MindSensePalette.surfaceRaised
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cta(tint: Color = MindSensePalette.accent) -> LinearGradient {
        LinearGradient(
            colors: [
                tint,
                tint
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func chartFill(color: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(0.26),
                MindSensePalette.glowWarm.opacity(0.14),
                color.opacity(0.03)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

enum MindSenseSurfaceLevel {
    case base
    case raised
    case glass
    case focus

    var fill: Color {
        switch self {
        case .base:
            return MindSensePalette.surfaceBase
        case .raised:
            return MindSensePalette.surfaceRaised
        case .glass:
            return MindSensePalette.surfaceGlass
        case .focus:
            return MindSensePalette.surfaceFocus
        }
    }

    var wash: LinearGradient {
        switch self {
        case .base:
            return LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        case .raised:
            return LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        case .glass:
            return LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        case .focus:
            return LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct MindSenseSpacing {
    // 4pt baseline scale.
    static let xxxs: CGFloat = 4
    static let xxs: CGFloat = xxxs
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let ml: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}

enum MindSenseControlSize {
    static let minimumTapTarget: CGFloat = 44
    static let compactPill: CGFloat = 24
    static let chip: CGFloat = 30
    static let iconBadge: CGFloat = 28
    static let iconBadgeLarge: CGFloat = 32
    static let iconBadgeXL: CGFloat = 40
    static let profileBadge: CGFloat = 34
    static let timelineSegmentHeight: CGFloat = 24
    static let primaryButton: CGFloat = 52
    static let thinProgressTrack: CGFloat = 5
}

enum MindSenseDividerEmphasis {
    static let subtle: CGFloat = 0.08
    static let regular: CGFloat = 0.12
    static let section: CGFloat = 0.14
    static let strong: CGFloat = 0.28
    static let hero: CGFloat = 0.43
}

enum MindSenseProgress {
    static let minimumFillRatio: Double = 0.08
}

enum MindSenseLayout {
    static let pageHorizontal: CGFloat = MindSenseSpacing.md
    static let pageTop: CGFloat = MindSenseSpacing.md
    static let pageBottom: CGFloat = MindSenseSpacing.md
    static let floatingTabBarCompactClearance: CGFloat = 72
    static let floatingTabBarStandardClearance: CGFloat = 88
    static let floatingTabBarExpandedClearance: CGFloat = 104

    static let sheetHorizontal: CGFloat = MindSenseSpacing.md
    static let sheetVertical: CGFloat = MindSenseSpacing.ml

    static let tileHorizontalInset: CGFloat = MindSenseSpacing.md
    static let tileVerticalInset: CGFloat = MindSenseSpacing.sm
    static let tileMinHeight: CGFloat = 60
    static let cardContentPadding: CGFloat = 18

    static func tabBarClearance(
        measuredOverlay: CGFloat,
        tier: MindSenseTabBarClearanceTier
    ) -> CGFloat {
        switch tier {
        case .compact:
            return max(floatingTabBarCompactClearance, measuredOverlay - 16)
        case .standard:
            return max(floatingTabBarStandardClearance, measuredOverlay)
        case .expanded:
            return max(floatingTabBarExpandedClearance, measuredOverlay + 16)
        }
    }

    static func bottomDockOffset(
        measuredOverlay: CGFloat,
        safeAreaInset: CGFloat
    ) -> CGFloat {
        guard measuredOverlay > 0 else { return 0 }

        let baseOffset = max(0, measuredOverlay - safeAreaInset)
        let compactThreshold = floatingTabBarCompactClearance + MindSenseSpacing.xs
        let visualGap = measuredOverlay <= compactThreshold ? MindSenseSpacing.sm : MindSenseSpacing.xs
        return baseOffset + visualGap
    }
}

enum MindSenseTabBarClearanceTier {
    case compact
    case standard
    case expanded
}

struct MindSenseRadius {
    static let micro: CGFloat = 6
    static let tight: CGFloat = 9
    static let medium: CGFloat = 12
    static let large: CGFloat = 12
    static let controlPrimary: CGFloat = 20
    static let controlText: CGFloat = 18
    static let pill: CGFloat = 999

    static let chip = medium
    static let tile = medium
    static let card = large
}

enum MindSenseComponentState {
    static let pressedControlOpacity: Double = 0.92
    static let pressedOverlayPrimary: Double = 0.09
    static let pressedOverlaySecondary: Double = 0.08
    static let disabledSaturation: Double = 0.2
    static let disabledTextTintOpacity: Double = 0.45
    static let disabledChipOpacity: Double = 0.45
    static let secondaryShadowOpacity: Double = 0.16
    static let textShadowOpacity: Double = 0.12
}

enum MindSenseTypography {
    static let display = Font.system(size: 27, weight: .bold, design: .rounded)
    static let hero = Font.system(size: 26, weight: .bold, design: .rounded)
    static let title = Font.system(size: 23, weight: .semibold, design: .rounded)
    static let titleCompact = Font.system(size: 19, weight: .semibold, design: .rounded)
    static let bodyStrong = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let micro = Font.system(size: 11, weight: .semibold, design: .rounded)

    static let metric = Font.system(size: 30, weight: .semibold, design: .monospaced)
    static let metricDisplay = Font.system(size: 40, weight: .bold, design: .monospaced)
    static let metricBody = Font.system(size: 17, weight: .semibold, design: .monospaced)
    static let metricCaption = Font.system(size: 12, weight: .medium, design: .monospaced)
}

enum MindSenseElevation {
    case none
    case base
    case raised
    case focus
    @available(*, deprecated, message: "Use raised.")
    case primary
    @available(*, deprecated, message: "Use base.")
    case inset
    @available(*, deprecated, message: "Use raised.")
    case hero
    @available(*, deprecated, message: "Use base.")
    case standard
    @available(*, deprecated, message: "Use base.")
    case utility

    var ambientColor: Color {
        switch resolved {
        case .none:
            return .clear
        case .base:
            return MindSensePalette.shadowAmbient.opacity(0.46)
        case .raised:
            return MindSensePalette.shadowAmbient
        case .focus:
            return MindSensePalette.shadowAmbient.opacity(1.1)
        }
    }

    var ambientRadius: CGFloat {
        switch resolved {
        case .none:
            return 0
        case .base:
            return 1
        case .raised:
            return 2
        case .focus:
            return 3
        }
    }

    var ambientY: CGFloat {
        switch resolved {
        case .none:
            return 0
        case .base:
            return 0
        case .raised:
            return 1
        case .focus:
            return 1
        }
    }

    var directionalColor: Color {
        switch resolved {
        case .none:
            return .clear
        case .base:
            return MindSensePalette.shadowDirectional.opacity(0.44)
        case .raised:
            return MindSensePalette.shadowDirectional.opacity(0.62)
        case .focus:
            return MindSensePalette.shadowDirectional.opacity(0.72)
        }
    }

    var directionalRadius: CGFloat {
        switch resolved {
        case .none:
            return 0
        case .base:
            return 1
        case .raised:
            return 3
        case .focus:
            return 4
        }
    }

    var directionalX: CGFloat {
        switch resolved {
        case .none, .base:
            return 0
        case .raised:
            return 0
        case .focus:
            return 0
        }
    }

    var directionalY: CGFloat {
        switch resolved {
        case .none:
            return 0
        case .base:
            return 1
        case .raised:
            return 1
        case .focus:
            return 2
        }
    }

    var radius: CGFloat { directionalRadius }
    var y: CGFloat { directionalY }

    private var resolved: Resolved {
        switch self {
        case .none:
            return .none
        case .base, .inset, .standard, .utility:
            return .base
        case .raised, .primary, .hero:
            return .raised
        case .focus:
            return .focus
        }
    }

    private enum Resolved {
        case none
        case base
        case raised
        case focus
    }
}

enum MindSenseMotion {
    static let screen = Animation.easeOut(duration: 0.18)
    static let cardReveal = Animation.easeOut(duration: 0.16)
    static let selection = Animation.easeOut(duration: 0.12)
    static let selectionSpring = Animation.easeOut(duration: 0.14)
    static let confirmation = Animation.easeOut(duration: 0.15)
    static let completionSpring = Animation.easeOut(duration: 0.18)
    static let chartInteraction = Animation.easeOut(duration: 0.1)
    static let backgroundDrift = Animation.easeInOut(duration: 24).repeatForever(autoreverses: true)

    static func entrance(index: Int) -> Animation {
        let delay = min(Double(max(0, index)) * 0.03, 0.12)
        return Animation
            .easeOut(duration: 0.18)
            .delay(delay)
    }

    static func screenTransition(reduceMotion: Bool) -> AnyTransition {
        .opacity
    }

    static func cardTransition(reduceMotion: Bool) -> AnyTransition {
        .opacity
    }
}

private struct MindSenseStaggeredEntranceModifier: ViewModifier {
    let index: Int
    let isPresented: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        let shouldShow = reduceMotion || isPresented

        return content
            .opacity(shouldShow ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (isPresented ? 0 : 8))
            .animation(reduceMotion ? nil : MindSenseMotion.entrance(index: index), value: isPresented)
    }
}

extension View {
    func mindSenseStaggerEntrance(_ index: Int, isPresented: Bool, reduceMotion: Bool) -> some View {
        modifier(
            MindSenseStaggeredEntranceModifier(
                index: index,
                isPresented: isPresented,
                reduceMotion: reduceMotion
            )
        )
    }

    func mindSensePageInsets(bottom: CGFloat = MindSenseLayout.pageBottom) -> some View {
        padding(.horizontal, MindSenseLayout.pageHorizontal)
            .padding(.top, MindSenseLayout.pageTop)
            .padding(.bottom, bottom)
    }

    func mindSenseSheetInsets() -> some View {
        padding(.horizontal, MindSenseLayout.sheetHorizontal)
            .padding(.vertical, MindSenseLayout.sheetVertical)
    }

    func mindSenseSheetPresentationChrome() -> some View {
        presentationDragIndicator(.visible)
    }
}

private struct MindSenseTabBarOverlayClearanceKey: EnvironmentKey {
    static let defaultValue: CGFloat = MindSenseLayout.floatingTabBarStandardClearance
}

extension EnvironmentValues {
    var mindSenseTabBarOverlayClearance: CGFloat {
        get { self[MindSenseTabBarOverlayClearanceKey.self] }
        set { self[MindSenseTabBarOverlayClearanceKey.self] = newValue }
    }
}

struct ScreenEmptyState: Equatable {
    let title: String
    let message: String
}

struct ScreenErrorState: Equatable {
    let title: String
    let message: String
}

enum ScreenMode: Equatable {
    case loading
    case ready
    case empty(ScreenEmptyState)
    case error(ScreenErrorState)
}

typealias ScreenLoadState = ScreenMode

extension String {
    var mindSenseHeadlineSafe: String {
        var value = self
        value = value.replacingOccurrences(of: " -", with: "\u{00A0}-")
        value = value.replacingOccurrences(of: " +", with: "\u{00A0}+")
        value = value.replacingOccurrences(of: "-", with: "\u{2011}")
        return value
    }
}

struct MindSenseGlossarySheet: View {
    private let confidenceEntries: [MindSenseGlossaryEntry] = [
        .init(
            term: "Recommendation confidence",
            summary: "How much trust to place in the app's current suggestions.",
            detail: "This combines data coverage and model fit. Lower values mean the app is giving directional guidance, not a strong recommendation."
        ),
        .init(
            term: "Model confidence (fit)",
            summary: "How well today's signals match the model's learned baseline and patterns.",
            detail: "Model confidence is one factor inside recommendation confidence. Good fit improves trust, but it does not replace data coverage."
        ),
        .init(
            term: "Data confidence",
            summary: "Signal coverage and quality supporting today's estimates.",
            detail: "This reflects usable imports such as sleep, HR, HRV, and wear continuity. Low data confidence usually lowers recommendation confidence."
        ),
        .init(
            term: "Attribution confidence",
            summary: "How certain the app is about a likely driver for a detected episode.",
            detail: "This is specific to an episode explanation and is separate from recommendation confidence for today's actions."
        )
    ]

    private let scoreEntries: [MindSenseGlossaryEntry] = [
        .init(
            term: "Load",
            summary: "Overall strain across the day or recent carryover window.",
            detail: "Use Load to judge general demand on your system. It is not the same as the severity of a single stress episode."
        ),
        .init(
            term: "Episode intensity",
            summary: "Severity of one detected stress episode.",
            detail: "Episode intensity is based on deviation from baseline patterns and duration for that event only. Use Load for overall strain."
        )
    ]

    private let stateEntries: [MindSenseGlossaryEntry] = [
        .init(
            term: "Flow ready / Flow running",
            summary: "Regulate-session state labels, not readiness scores.",
            detail: "Flow ready means conditions suggest a focus/regulate session is a good time to start. Flow running means a session is currently active."
        ),
        .init(
            term: "Managed / Ready / Steady",
            summary: "Band labels shown inside different score types.",
            detail: "These labels are metric-specific: Managed is a Load band, Ready is a Readiness band, and Steady is a Consistency band."
        )
    ]

    private var sections: [MindSenseGlossarySection] {
        [
            .init(
                title: "Confidence terms",
                subtitle: "Different confidence labels mean different things.",
                icon: "checkmark.shield",
                entries: confidenceEntries
            ),
            .init(
                title: "Scores",
                subtitle: "Load and episode intensity describe different scopes.",
                icon: "gauge.with.dots.needle.50percent",
                entries: scoreEntries
            ),
            .init(
                title: "State labels",
                subtitle: "App state labels that are easy to confuse with score labels.",
                icon: "tag",
                entries: stateEntries
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.lg) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "How terms are used",
                                subtitle: "Choose a term to open a dedicated definition page used across Today, Regulate, and Data.",
                                icon: "text.book.closed"
                            )
                        )
                    }

                    ForEach(sections) { section in
                        glossarySection(section)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Glossary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Glossary")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    private func glossarySection(_ section: MindSenseGlossarySection) -> some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: section.title,
                    subtitle: section.subtitle,
                    icon: section.icon
                )
            )

            VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink {
                        MindSenseGlossaryEntryDetailView(
                            sectionTitle: section.title,
                            entry: entry
                        )
                    } label: {
                        HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.term)
                                    .font(MindSenseTypography.bodyStrong)
                                    .foregroundStyle(.primary)
                                Text(entry.summary)
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(3)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens full glossary definition")

                    if index < section.entries.count - 1 {
                        MindSenseSectionDivider(emphasis: 0.18)
                    }
                }
            }
        }
    }
}

private struct MindSenseGlossaryEntryDetailView: View {
    let sectionTitle: String
    let entry: MindSenseGlossaryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MindSenseSpacing.lg) {
                Text("Glossary • \(sectionTitle)")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(entry.term)
                    .font(MindSenseTypography.title)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                InsetSurface {
                    VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                        Text("Quick summary")
                            .font(MindSenseTypography.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(entry.summary)
                            .font(MindSenseTypography.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                InsetSurface {
                    VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                        Text("Full definition")
                            .font(MindSenseTypography.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(entry.detail)
                            .font(MindSenseTypography.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: 560, alignment: .leading)
            .mindSenseSheetInsets()
        }
        .mindSensePageBackground()
        .navigationTitle(entry.term)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MindSenseGlossarySection: Identifiable {
    let title: String
    let subtitle: String
    let icon: String
    let entries: [MindSenseGlossaryEntry]

    var id: String { title }
}

private struct MindSenseGlossaryEntry: Identifiable {
    let term: String
    let summary: String
    let detail: String

    var id: String { term }
}
