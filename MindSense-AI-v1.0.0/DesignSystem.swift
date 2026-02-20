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
    static let xxs: CGFloat = 6
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let ml: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum MindSenseLayout {
    static let pageHorizontal: CGFloat = 16
    static let pageTop: CGFloat = 14
    static let pageBottom: CGFloat = 16

    static let sheetHorizontal: CGFloat = 16
    static let sheetVertical: CGFloat = 20

    static let tileHorizontalInset: CGFloat = 12
    static let tileVerticalInset: CGFloat = 10
    static let tileMinHeight: CGFloat = 60
}

struct MindSenseRadius {
    static let tight: CGFloat = 9
    static let medium: CGFloat = 12
    static let large: CGFloat = 12
    static let pill: CGFloat = 999

    static let chip = medium
    static let tile = medium
    static let card = large
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
