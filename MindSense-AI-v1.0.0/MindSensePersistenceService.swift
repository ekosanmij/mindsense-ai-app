import Foundation

struct PersistenceLoadResult<Value> {
    let value: Value
    let issue: String?
}

final class MindSensePersistenceService {
    private static let analyticsEventsKey = "analytics.events.v1"
    private static let analyticsMaxEventCount = 400
    private static let analyticsMaxPayloadBytes = 350_000
    private static let analyticsPersistDelay: TimeInterval = 1.0
    private static let legacySessionEmailKey = "auth.fallback_session_email"
    private static let sessionEmailKey = "auth.session.email.v2"
    private static let sessionAppleUserIDKey = "auth.session.apple_user_id.v1"
    private static let sessionDisplayNameKey = "auth.session.display_name.v1"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let analyticsWriteQueue = DispatchQueue(label: "com.mindsense.persistence.analytics", qos: .utility)
    private var pendingAnalyticsWrite: DispatchWorkItem?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Scalar keys

    var hasSeenIntro: Bool {
        defaults.bool(forKey: "hasSeenIntro")
    }

    func setHasSeenIntro(_ seen: Bool) {
        defaults.set(seen, forKey: "hasSeenIntro")
    }

    var paywallSeen: Bool {
        defaults.bool(forKey: "paywall.post_activation.seen")
    }

    func setPaywallSeen(_ seen: Bool) {
        defaults.set(seen, forKey: "paywall.post_activation.seen")
    }

    var kpiReviewedAt: Date? {
        guard let epoch = defaults.object(forKey: "kpi.last_reviewed_at.v1") as? Double else {
            return nil
        }
        return Date(timeIntervalSince1970: epoch)
    }

    func setKPIReviewedAt(_ date: Date?) {
        if let date {
            defaults.set(date.timeIntervalSince1970, forKey: "kpi.last_reviewed_at.v1")
        } else {
            defaults.removeObject(forKey: "kpi.last_reviewed_at.v1")
        }
    }

    var demoLastUpdatedAt: Date {
        guard let epoch = defaults.object(forKey: "demo.last_updated.v1") as? Double else {
            return Date()
        }
        return Date(timeIntervalSince1970: epoch)
    }

    func setDemoLastUpdatedAt(_ date: Date) {
        defaults.set(date.timeIntervalSince1970, forKey: "demo.last_updated.v1")
    }

    // MARK: - Session

    func loadSession() -> AuthSession? {
        let storedEmail = defaults.string(forKey: Self.sessionEmailKey)
            ?? defaults.string(forKey: Self.legacySessionEmailKey)
        guard let email = storedEmail else {
            return nil
        }
        let appleUserID = defaults.string(forKey: Self.sessionAppleUserIDKey)
        let displayName = defaults.string(forKey: Self.sessionDisplayNameKey)
        return AuthSession(email: email, appleUserID: appleUserID, displayName: displayName)
    }

    func persistSession(email: String, appleUserID: String?, displayName: String?) {
        let normalizedEmail = email.lowercased()
        defaults.set(normalizedEmail, forKey: Self.sessionEmailKey)
        defaults.set(normalizedEmail, forKey: Self.legacySessionEmailKey)

        if let appleUserID = trimmedNonEmpty(appleUserID) {
            defaults.set(appleUserID, forKey: Self.sessionAppleUserIDKey)
            persistKnownAppleEmail(normalizedEmail, for: appleUserID)
        } else {
            defaults.removeObject(forKey: Self.sessionAppleUserIDKey)
        }

        if let displayName = trimmedNonEmpty(displayName) {
            defaults.set(displayName, forKey: Self.sessionDisplayNameKey)
        } else {
            defaults.removeObject(forKey: Self.sessionDisplayNameKey)
        }
    }

    func clearSession() {
        defaults.removeObject(forKey: Self.legacySessionEmailKey)
        defaults.removeObject(forKey: Self.sessionEmailKey)
        defaults.removeObject(forKey: Self.sessionAppleUserIDKey)
        defaults.removeObject(forKey: Self.sessionDisplayNameKey)
        defaults.removeObject(forKey: "auth.magic_link.pending.v1")
    }

    func loadKnownAppleEmail(for userID: String) -> String? {
        guard let userID = trimmedNonEmpty(userID) else {
            return nil
        }
        return defaults.string(forKey: appleEmailLookupKey(for: userID))
    }

    func persistKnownAppleEmail(_ email: String, for userID: String) {
        guard let userID = trimmedNonEmpty(userID) else {
            return
        }
        let normalizedEmail = email.lowercased()
        defaults.set(normalizedEmail, forKey: appleEmailLookupKey(for: userID))
    }

    private func appleEmailLookupKey(for userID: String) -> String {
        "auth.apple.email_lookup.\(userID)"
    }

    private func trimmedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Onboarding

    func onboardingKey(for email: String) -> String {
        "onboarding.progress.\(email.lowercased())"
    }

    func loadOnboarding(for email: String) -> OnboardingProgress {
        guard let data = defaults.data(forKey: onboardingKey(for: email)) else {
            return OnboardingProgress()
        }
        return (try? decoder.decode(OnboardingProgress.self, from: data)) ?? OnboardingProgress()
    }

    func persistOnboarding(_ onboarding: OnboardingProgress, for email: String) {
        if let data = try? encoder.encode(onboarding) {
            defaults.set(data, forKey: onboardingKey(for: email))
            defaults.set(Date().timeIntervalSince1970, forKey: "widget.onboarding.synced_at")
        }
    }

    func startOnboardingTimerIfNeeded() {
        if defaults.object(forKey: "onboarding.started_at.v1") == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: "onboarding.started_at.v1")
        }
    }

    func onboardingCompletionMS() -> Int? {
        guard let startedAt = defaults.object(forKey: "onboarding.started_at.v1") as? Double else {
            return nil
        }
        return Int((Date().timeIntervalSince1970 - startedAt) * 1000)
    }

    func clearOnboardingTimer() {
        defaults.removeObject(forKey: "onboarding.started_at.v1")
    }

    // MARK: - Regulate

    func persistRegulateSessionHistory(_ history: [RegulateSessionRecord]) {
        if let data = try? encoder.encode(history) {
            defaults.set(data, forKey: "regulate.session.history.v1")
        }
    }

    func loadRegulateSessionHistory() -> PersistenceLoadResult<[RegulateSessionRecord]> {
        guard let data = defaults.data(forKey: "regulate.session.history.v1") else {
            return .init(value: [], issue: nil)
        }
        do {
            return .init(
                value: try decoder.decode([RegulateSessionRecord].self, from: data),
                issue: nil
            )
        } catch {
            return .init(value: [], issue: "Session history could not be restored.")
        }
    }

    func persistActiveRegulateSession(_ session: RegulateSessionRecord?) {
        if let session,
           let data = try? encoder.encode(session) {
            defaults.set(data, forKey: "regulate.session.active.v1")
            return
        }
        defaults.removeObject(forKey: "regulate.session.active.v1")
    }

    func loadActiveRegulateSession() -> PersistenceLoadResult<RegulateSessionRecord?> {
        guard let data = defaults.data(forKey: "regulate.session.active.v1") else {
            return .init(value: nil, issue: nil)
        }
        do {
            return .init(
                value: try decoder.decode(RegulateSessionRecord.self, from: data),
                issue: nil
            )
        } catch {
            return .init(value: nil, issue: "Active session state could not be restored.")
        }
    }

    // MARK: - Experiments

    func persistExperiments(_ experiments: [Experiment]) {
        if let data = try? encoder.encode(experiments) {
            defaults.set(data, forKey: "data.experiments.v1")
        }
    }

    func loadExperiments() -> PersistenceLoadResult<[Experiment]> {
        guard let data = defaults.data(forKey: "data.experiments.v1") else {
            return .init(value: [], issue: nil)
        }
        do {
            return .init(value: try decoder.decode([Experiment].self, from: data), issue: nil)
        } catch {
            return .init(value: [], issue: "Experiment data could not be restored.")
        }
    }

    // MARK: - Analytics

    func persistAnalyticsEvents(_ events: [AnalyticsEventRecord]) {
        let trimmed = Array(events.suffix(Self.analyticsMaxEventCount))
        pendingAnalyticsWrite?.cancel()

        let defaults = self.defaults
        let key = Self.analyticsEventsKey
        let work = DispatchWorkItem {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(trimmed) {
                defaults.set(data, forKey: key)
            }
        }

        pendingAnalyticsWrite = work
        analyticsWriteQueue.asyncAfter(deadline: .now() + Self.analyticsPersistDelay, execute: work)
    }

    func loadAnalyticsEvents() -> [AnalyticsEventRecord] {
        let key = Self.analyticsEventsKey
        guard let data = defaults.data(forKey: key) else { return [] }

        if data.count > Self.analyticsMaxPayloadBytes {
            defaults.removeObject(forKey: key)
            return []
        }

        let decoded = (try? decoder.decode([AnalyticsEventRecord].self, from: data)) ?? []
        guard decoded.count > Self.analyticsMaxEventCount else {
            return decoded
        }

        let trimmed = Array(decoded.suffix(Self.analyticsMaxEventCount))
        persistAnalyticsEvents(trimmed)
        return trimmed
    }

    func clearAnalyticsEvents() {
        pendingAnalyticsWrite?.cancel()
        defaults.removeObject(forKey: Self.analyticsEventsKey)
    }

    // MARK: - Demo

    func persistDemoScenario(_ scenario: DemoScenario) {
        defaults.set(scenario.rawValue, forKey: "demo.scenario.v1")
    }

    func loadDemoScenario() -> DemoScenario {
        guard let raw = defaults.string(forKey: "demo.scenario.v1") else {
            return .balancedDay
        }
        return DemoScenario(rawValue: raw) ?? .balancedDay
    }

    func persistDemoMetrics(_ metrics: DemoMetricSnapshot) {
        if let data = try? encoder.encode(metrics) {
            defaults.set(data, forKey: "demo.metrics.v1")
        }
    }

    func loadDemoMetrics(fallback: DemoMetricSnapshot) -> PersistenceLoadResult<DemoMetricSnapshot> {
        guard let data = defaults.data(forKey: "demo.metrics.v1") else {
            return .init(value: fallback, issue: nil)
        }
        do {
            return .init(
                value: try decoder.decode(DemoMetricSnapshot.self, from: data),
                issue: nil
            )
        } catch {
            return .init(value: fallback, issue: "Metrics could not be restored. Default metrics were loaded.")
        }
    }

    func persistDemoEvents(_ events: [DemoEventRecord]) {
        if let data = try? encoder.encode(events) {
            defaults.set(data, forKey: "demo.events.v1")
        }
    }

    func loadDemoEvents(fallback: [DemoEventRecord]) -> PersistenceLoadResult<[DemoEventRecord]> {
        guard let data = defaults.data(forKey: "demo.events.v1") else {
            return .init(value: fallback, issue: nil)
        }
        do {
            return .init(value: try decoder.decode([DemoEventRecord].self, from: data), issue: nil)
        } catch {
            return .init(value: fallback, issue: "Event history could not be restored.")
        }
    }

    func persistDemoHealthProfile(_ profile: DemoHealthProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: "demo.health_profile.v1")
        }
    }

    func loadDemoHealthProfile(fallback: DemoHealthProfile) -> PersistenceLoadResult<DemoHealthProfile> {
        guard let data = defaults.data(forKey: "demo.health_profile.v1") else {
            return .init(value: fallback, issue: nil)
        }
        do {
            return .init(value: try decoder.decode(DemoHealthProfile.self, from: data), issue: nil)
        } catch {
            return .init(value: fallback, issue: "Health profile could not be restored.")
        }
    }

    func persistDemoSavedInsights(_ insights: [DemoSavedInsight]) {
        if let data = try? encoder.encode(insights) {
            defaults.set(data, forKey: "demo.saved_insights.v1")
        }
    }

    func loadDemoSavedInsights() -> PersistenceLoadResult<[DemoSavedInsight]> {
        guard let data = defaults.data(forKey: "demo.saved_insights.v1") else {
            return .init(value: [], issue: nil)
        }
        do {
            return .init(
                value: try decoder.decode([DemoSavedInsight].self, from: data),
                issue: nil
            )
        } catch {
            return .init(value: [], issue: "Saved insights could not be restored.")
        }
    }

    func persistGuidedDemoPathStep(_ step: GuidedDemoPathStep?) {
        if let step {
            defaults.set(step.rawValue, forKey: "demo.guided_path.step.v1")
        } else {
            defaults.removeObject(forKey: "demo.guided_path.step.v1")
        }
    }

    func loadGuidedDemoPathStep() -> GuidedDemoPathStep? {
        guard defaults.object(forKey: "demo.guided_path.step.v1") != nil else {
            return nil
        }
        return GuidedDemoPathStep(rawValue: defaults.integer(forKey: "demo.guided_path.step.v1"))
    }

    func persistDemoDay(_ day: Int) {
        defaults.set(day, forKey: "demo.day.v1")
    }

    func loadDemoDay(fallback: Int) -> Int {
        if defaults.object(forKey: "demo.day.v1") == nil {
            return fallback
        }
        return max(1, defaults.integer(forKey: "demo.day.v1"))
    }

    func clearDemoState() {
        defaults.removeObject(forKey: "demo.scenario.v1")
        defaults.removeObject(forKey: "demo.metrics.v1")
        defaults.removeObject(forKey: "demo.events.v1")
        defaults.removeObject(forKey: "demo.health_profile.v1")
        defaults.removeObject(forKey: "demo.saved_insights.v1")
        defaults.removeObject(forKey: "demo.last_updated.v1")
        defaults.removeObject(forKey: "demo.day.v1")
        defaults.removeObject(forKey: "demo.guided_path.step.v1")
        defaults.removeObject(forKey: "regulate.session.active.v1")
        defaults.removeObject(forKey: "regulate.session.history.v1")
        defaults.removeObject(forKey: "data.experiments.v1")
    }
}
