import SwiftUI
import UIKit

struct MainShellView: View {
    @EnvironmentObject private var store: MindSenseStore
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private static var didConfigureTabBarAppearance = false

    init() {
        Self.configureTabBarAppearanceIfNeeded()
    }

    private static func configureTabBarAppearanceIfNeeded() {
        guard !didConfigureTabBarAppearance else { return }
        didConfigureTabBarAppearance = true

        let selected = UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: 142 / 255, green: 220 / 255, blue: 249 / 255, alpha: 1)
            }
            return UIColor(red: 10 / 255, green: 111 / 255, blue: 167 / 255, alpha: 1)
        }
        let normal = UIColor.secondaryLabel.withAlphaComponent(0.74)

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = .clear
        appearance.shadowColor = UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.1)
            }
            return UIColor.black.withAlphaComponent(0.08)
        }

        Self.configure(appearance.stackedLayoutAppearance, selected: selected, normal: normal)
        Self.configure(appearance.inlineLayoutAppearance, selected: selected, normal: normal)
        Self.configure(appearance.compactInlineLayoutAppearance, selected: selected, normal: normal)

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
        tabBar.tintColor = selected
        tabBar.unselectedItemTintColor = normal
        tabBar.itemPositioning = .automatic
    }

    var body: some View {
        TabView(selection: $store.selectedTab) {
            TodayView()
                .tabItem { Label(MainTab.today.title, systemImage: MainTab.today.icon) }
                .tag(MainTab.today)

            RegulateView()
                .tabItem { Label(MainTab.regulate.title, systemImage: MainTab.regulate.icon) }
                .tag(MainTab.regulate)

            DataView()
                .tabItem { Label(MainTab.data.title, systemImage: MainTab.data.icon) }
                .tag(MainTab.data)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .background(
            TabBarMinimizeConfigurator(
                behavior: .onScrollDown
            )
            .allowsHitTesting(false)
        )
        .animation(reduceMotion ? nil : MindSenseMotion.screen, value: store.selectedTab)
        .onChange(of: store.selectedTab) { _, newValue in
            store.track(
                event: .navigationTabChanged,
                metadata: ["tab": newValue.title.lowercased()]
            )
        }
    }

    private static func configure(_ itemAppearance: UITabBarItemAppearance, selected: UIColor, normal: UIColor) {
        let normalFont = roundedFont(size: 11, weight: .medium)
        let selectedFont = roundedFont(size: 11, weight: .semibold)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: normal,
            .font: normalFont
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: selected,
            .font: selectedFont
        ]

        itemAppearance.normal.iconColor = normal
        itemAppearance.normal.titleTextAttributes = normalAttributes
        itemAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)

        itemAppearance.selected.iconColor = selected
        itemAppearance.selected.titleTextAttributes = selectedAttributes
        itemAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
    }

    private static func roundedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let fallback = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = fallback.fontDescriptor.withDesign(.rounded) else {
            return fallback
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

private struct TabBarMinimizeConfigurator: UIViewControllerRepresentable {
    let behavior: UITabBarController.MinimizeBehavior

    func makeUIViewController(context: Context) -> TabBarMinimizeConfiguratorController {
        TabBarMinimizeConfiguratorController()
    }

    func updateUIViewController(_ uiViewController: TabBarMinimizeConfiguratorController, context: Context) {
        uiViewController.applyMinimizeBehavior(behavior)
    }
}

private final class TabBarMinimizeConfiguratorController: UIViewController {
    private var pendingBehavior: UITabBarController.MinimizeBehavior?

    func applyMinimizeBehavior(_ behavior: UITabBarController.MinimizeBehavior) {
        pendingBehavior = behavior
        applyPendingBehaviorIfPossible()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        applyPendingBehaviorIfPossible()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyPendingBehaviorIfPossible()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyPendingBehaviorIfPossible()
    }

    private func applyPendingBehaviorIfPossible() {
        guard let behavior = pendingBehavior else { return }
        guard let tabBarController else { return }
        guard tabBarController.tabBarMinimizeBehavior != behavior else { return }
        tabBarController.tabBarMinimizeBehavior = behavior
    }
}
