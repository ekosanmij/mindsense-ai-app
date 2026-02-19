import Foundation

final class MindSenseBootstrapService {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func seedDefaultsIfNeeded() {
        if defaults.object(forKey: "enableHaptics") == nil {
            defaults.set(true, forKey: "enableHaptics")
        }
        if defaults.object(forKey: "appReduceMotion") == nil {
            defaults.set(false, forKey: "appReduceMotion")
        }
        if defaults.object(forKey: "appearanceMode") == nil {
            defaults.set(AppearanceMode.system.rawValue, forKey: "appearanceMode")
        }
        if defaults.object(forKey: "notifications.gentlePrompts") == nil {
            defaults.set(true, forKey: "notifications.gentlePrompts")
        }
        if defaults.object(forKey: "notifications.weeklyReview") == nil {
            defaults.set(true, forKey: "notifications.weeklyReview")
        }
        if defaults.object(forKey: "paywall.post_activation.seen") == nil {
            defaults.set(false, forKey: "paywall.post_activation.seen")
        }
        if defaults.object(forKey: "demo.scenario.v1") == nil {
            defaults.set(DemoScenario.balancedDay.rawValue, forKey: "demo.scenario.v1")
        }
        if defaults.object(forKey: "demo.day.v1") == nil {
            defaults.set(DemoScenario.balancedDay.defaultDay, forKey: "demo.day.v1")
        }
        if defaults.object(forKey: "demo.last_updated.v1") == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: "demo.last_updated.v1")
        }
        if defaults.object(forKey: "demo.metrics.v1") == nil,
           let data = try? encoder.encode(DemoScenario.balancedDay.baseMetrics) {
            defaults.set(data, forKey: "demo.metrics.v1")
        }
        if defaults.object(forKey: "demo.events.v1") == nil,
           let data = try? encoder.encode(MindSenseDemoSeedCatalog.seededEvents(for: .balancedDay)) {
            defaults.set(data, forKey: "demo.events.v1")
        }
        if defaults.object(forKey: "demo.health_profile.v1") == nil,
           let data = try? encoder.encode(
            MindSenseDemoSeedCatalog.seededHealthProfile(
                for: .balancedDay,
                demoDay: DemoScenario.balancedDay.defaultDay
            )
           ) {
            defaults.set(data, forKey: "demo.health_profile.v1")
        }
        if defaults.object(forKey: "demo.saved_insights.v1") == nil,
           let data = try? encoder.encode([DemoSavedInsight]()) {
            defaults.set(data, forKey: "demo.saved_insights.v1")
        }
    }

    func applyLaunchOverridesIfNeeded(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains("-uitest-reset"),
           let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }

        guard arguments.contains("-uitest-ready") else { return }

        defaults.set(true, forKey: "hasSeenIntro")
        defaults.set("uitest@mindsense.ai", forKey: "auth.fallback_session_email")
        defaults.set(true, forKey: "auth.fallback_session_is_demo")

        var onboarding = OnboardingProgress()
        OnboardingStep.allCases.forEach { onboarding.markComplete($0) }
        onboarding.baselineStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        onboarding.firstCheckInValue = 4
        if let data = try? encoder.encode(onboarding) {
            defaults.set(data, forKey: "onboarding.progress.uitest@mindsense.ai")
        }

        let seededScenario: DemoScenario = .highStressDay
        defaults.set(seededScenario.rawValue, forKey: "demo.scenario.v1")
        defaults.set(seededScenario.defaultDay, forKey: "demo.day.v1")
        defaults.set(Date().timeIntervalSince1970, forKey: "demo.last_updated.v1")

        if let data = try? encoder.encode(seededScenario.baseMetrics) {
            defaults.set(data, forKey: "demo.metrics.v1")
        }
        if let data = try? encoder.encode(MindSenseDemoSeedCatalog.seededEvents(for: seededScenario)) {
            defaults.set(data, forKey: "demo.events.v1")
        }
        if let data = try? encoder.encode(
            MindSenseDemoSeedCatalog.seededHealthProfile(
                for: seededScenario,
                demoDay: seededScenario.defaultDay
            )
        ) {
            defaults.set(data, forKey: "demo.health_profile.v1")
        }
        defaults.removeObject(forKey: "demo.saved_insights.v1")
        defaults.removeObject(forKey: "demo.guided_path.step.v1")

        let seededExperiments = MindSenseDemoSeedCatalog.defaultExperiments(for: seededScenario)
        if let data = try? encoder.encode(seededExperiments) {
            defaults.set(data, forKey: "data.experiments.v1")
        }

        defaults.removeObject(forKey: "regulate.session.active.v1")
        defaults.removeObject(forKey: "regulate.session.history.v1")
        defaults.removeObject(forKey: "analytics.events.v1")
        defaults.removeObject(forKey: "onboarding.started_at.v1")
        defaults.set(true, forKey: "paywall.post_activation.seen")

        if arguments.contains("-uitest-light") {
            defaults.set(AppearanceMode.light.rawValue, forKey: "appearanceMode")
        } else if arguments.contains("-uitest-dark") {
            defaults.set(AppearanceMode.dark.rawValue, forKey: "appearanceMode")
        } else if arguments.contains("-uitest-system") {
            defaults.set(AppearanceMode.system.rawValue, forKey: "appearanceMode")
        }

        if let reduceMotionIndex = arguments.firstIndex(of: "-uitest-reduce-motion"),
           arguments.indices.contains(reduceMotionIndex + 1) {
            defaults.set(arguments[reduceMotionIndex + 1] == "1", forKey: "appReduceMotion")
        }

        if let hapticsIndex = arguments.firstIndex(of: "-uitest-enable-haptics"),
           arguments.indices.contains(hapticsIndex + 1) {
            defaults.set(arguments[hapticsIndex + 1] == "1", forKey: "enableHaptics")
        }
    }
}
