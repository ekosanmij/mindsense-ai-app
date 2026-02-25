import SwiftUI
import UIKit

struct TodayView: View {
    private enum CheckInPromptMode: String {
        case standard
        case reduced
        case lowConfidenceOnly
    }

    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.mindSenseTabBarOverlayClearance) private var tabBarOverlayClearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("appReduceMotion") private var appReduceMotion = false
    @AppStorage("todayCheckInIgnoreStreak") private var checkInIgnoreStreak = 0
    @AppStorage("todayCheckInPromptMode") private var checkInPromptModeRaw = CheckInPromptMode.standard.rawValue
    @AppStorage("todayCheckInReducedLastPromptDayStamp") private var reducedPromptLastShownDayStamp = -1
    @AppStorage("todayCheckInLowConfidenceLastPromptDayStamp") private var lowConfidencePromptLastShownDayStamp = -1
    @AppStorage("todayCheckInLastSavedDayStamp") private var checkInLastSavedDayStamp = -1

    @State private var loadSlider = 5.0
    @State private var didAppear = false
    @State private var showHeroWhy = false
    @State private var showHeroStateExplanation = false
    @State private var showActionDetails = false
    @State private var showAllDrivers = false
    @State private var showSecondarySignals = false
    @State private var showModelDetails = false
    @State private var showConfidenceDetails = false
    @State private var checkInJustSaved = false
    @State private var checkInPromptShownThisVisit = false
    @State private var checkInSavedThisVisit = false
    @State private var shouldShowCheckInPrompt = true
    @State private var selectedCheckInDriver: String?
    @State private var showSignalSourceDetails = false
    @State private var showTimelineDetails = false
    @State private var timelineDetailEpisodeFilter: TodayTimelineDetailSheet.EpisodeFilter = .all
    @State private var selectedTimelineEpisode: StressEpisodeRecord?
    @State private var intensityInfoEpisode: StressEpisodeRecord?
    @State private var selectedMetricDefinition: CoreMetric?
    @State private var focusedContextEpisodeID: UUID?
    @State private var contextTags: Set<String> = []
    @State private var allowMultipleContextTags = false
    @State private var contextPrimaryTag: String?
    @State private var contextSecondaryTag: String?
    @State private var contextNote = ""
    @State private var viewSafeAreaBottomInset: CGFloat = 0

    private let checkInDriverOptions = [
        "Meetings",
        "Workout",
        "Poor sleep",
        "Travel"
    ]
    private let lowCoverageRecommendationThreshold = 25

    private struct HeroMetricCard: Identifiable {
        let metric: CoreMetric
        let title: String
        let value: Int
        let delta: Int?
        let tint: Color

        var id: CoreMetric { metric }
    }

    private var recommendation: DemoRecommendation {
        store.primaryRecommendation
    }

    private var resolvedState: ScreenMode {
        store.screenMode(for: .today)
    }

    private var needsEscalationGuidance: Bool {
        Int(loadSlider.rounded()) >= 9 || store.demoMetrics.load >= 88
    }

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var hasUnfinishedRegulateStep: Bool {
        guard let session = store.activeRegulateSession else { return false }
        return session.isInProgress || session.isAwaitingCheckIn
    }

    private var inlineActionLabel: String {
        if hasUnfinishedRegulateStep {
            return "Continue"
        }
        if isLowCoverageRecommendationMode {
            return "Start check-in"
        }
        return "Start"
    }

    private var inlineActionContextLabel: String {
        if hasUnfinishedRegulateStep {
            if store.activeRegulateSession?.isAwaitingCheckIn == true {
                return "Record impact to finish today's loop."
            }
            return "Resume \(store.activeRegulateSession?.preset.title ?? recommendation.preset.title) session."
        }
        if isLowCoverageRecommendationMode {
            return "Add a quick check-in first while coverage is low."
        }
        return "\(recommendation.preset.title) • \(recommendation.timeMinutes) min"
    }

    private var intentModeBinding: Binding<IntentMode> {
        Binding(
            get: { store.intentMode },
            set: { mode in
                store.triggerHaptic(intent: .selection)
                store.setIntentMode(mode, source: "today_mode_switch")
            }
        )
    }

    private var heroMetricCards: [HeroMetricCard] {
        store.todayMetricCardOrder.map { metric in
            switch metric {
            case .load:
                return HeroMetricCard(
                    metric: .load,
                    title: "Load",
                    value: store.demoMetrics.load,
                    delta: latestDailyDelta?.load,
                    tint: MindSensePalette.warning
                )
            case .readiness:
                return HeroMetricCard(
                    metric: .readiness,
                    title: "Readiness",
                    value: store.demoMetrics.readiness,
                    delta: latestDailyDelta?.readiness,
                    tint: MindSensePalette.success
                )
            case .consistency:
                return HeroMetricCard(
                    metric: .consistency,
                    title: "Consistency",
                    value: store.demoMetrics.consistency,
                    delta: latestDailyDelta?.consistency,
                    tint: MindSensePalette.signalCool
                )
            }
        }
    }

    private var bottomContentPadding: CGFloat {
        MindSenseLayout.pageBottom + (
            hasUnfinishedRegulateStep
                ? MindSenseLayout.tabBarClearance(
                    measuredOverlay: tabBarOverlayClearance,
                    tier: .compact
                )
                : MindSenseLayout.tabBarClearance(
                    measuredOverlay: tabBarOverlayClearance,
                    tier: .standard
                )
        )
    }

    private var stickyDockBottomOffset: CGFloat {
        MindSenseLayout.bottomDockOffset(
            measuredOverlay: tabBarOverlayClearance,
            safeAreaInset: viewSafeAreaBottomInset
        )
    }

    private var checkInPromptMode: CheckInPromptMode {
        CheckInPromptMode(rawValue: checkInPromptModeRaw) ?? .standard
    }

    private var todayDayStamp: Int {
        Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
    }

    private var isLowConfidenceDay: Bool {
        store.confidencePercent < 62 || isLowCoverageRecommendationMode
    }

    private var isLowCoverageRecommendationMode: Bool {
        store.demoDataCoveragePercent <= lowCoverageRecommendationThreshold
    }

    private var shouldForceLowCoverageCheckInPrompt: Bool {
        isLowCoverageRecommendationMode && !hasSavedCheckInToday
    }

    private var hasSavedCheckInToday: Bool {
        checkInLastSavedDayStamp == todayDayStamp
    }

    private var shouldShowCheckInFatigueOffer: Bool {
        shouldShowCheckInPrompt && checkInPromptMode == .standard && checkInIgnoreStreak >= 3
    }

    private var attributionInboxEpisodes: [StressEpisodeRecord] {
        let now = Date()
        return store.recentStressEpisodes.filter { episode in
            !episode.hasContext &&
            episode.end <= now &&
            now.timeIntervalSince(episode.end) <= (24 * 3_600)
        }
    }

    private var attributionInboxCount: Int {
        attributionInboxEpisodes.count
    }

    private var attributionInboxCountLabel: String {
        if attributionInboxCount == 1 {
            return "1 episode needs a label."
        }
        return "\(attributionInboxCount) episodes need labels."
    }

    private func evaluateCheckInPromptVisibilityForVisit() {
        checkInSavedThisVisit = false

        if shouldForceLowCoverageCheckInPrompt {
            shouldShowCheckInPrompt = true
            checkInPromptShownThisVisit = true
            return
        }

        let shouldShow: Bool
        switch checkInPromptMode {
        case .standard:
            shouldShow = true
        case .reduced:
            shouldShow = reducedPromptLastShownDayStamp < 0 || (todayDayStamp - reducedPromptLastShownDayStamp >= 2)
        case .lowConfidenceOnly:
            shouldShow = isLowConfidenceDay && todayDayStamp != lowConfidencePromptLastShownDayStamp
        }

        shouldShowCheckInPrompt = shouldShow
        checkInPromptShownThisVisit = shouldShow

        if shouldShow {
            switch checkInPromptMode {
            case .standard:
                break
            case .reduced:
                reducedPromptLastShownDayStamp = todayDayStamp
            case .lowConfidenceOnly:
                lowConfidencePromptLastShownDayStamp = todayDayStamp
            }
        }
    }

    private func registerIgnoredCheckInIfNeeded() {
        defer {
            checkInPromptShownThisVisit = false
            checkInSavedThisVisit = false
        }

        guard case .ready = resolvedState else { return }
        guard checkInPromptShownThisVisit else { return }
        guard !checkInSavedThisVisit else { return }
        guard !hasSavedCheckInToday else { return }
        guard checkInPromptMode == .standard else { return }
        checkInIgnoreStreak = min(checkInIgnoreStreak + 1, 6)
    }

    private func applyCheckInPromptMode(_ mode: CheckInPromptMode) {
        checkInPromptModeRaw = mode.rawValue
        checkInIgnoreStreak = 0
        checkInPromptShownThisVisit = false
        shouldShowCheckInPrompt = false

        switch mode {
        case .standard:
            shouldShowCheckInPrompt = true
            checkInPromptShownThisVisit = true
        case .reduced:
            reducedPromptLastShownDayStamp = todayDayStamp
        case .lowConfidenceOnly:
            lowConfidencePromptLastShownDayStamp = todayDayStamp
        }
        store.triggerHaptic(intent: .selection)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                ScreenStateContainer(
                    state: resolvedState,
                    retryAction: { store.retryCoreScreen(.today) }
                ) {
                    VStack(spacing: MindSenseRhythm.section) {
                        commandDeck
                            .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)
                        if episodeAwaitingContext != nil {
                            contextCaptureBlock
                                .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                        }
                        driversBlock
                            .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
                        statusSnapshotBlock
                            .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
                        if shouldShowCheckInPrompt {
                            checkInBlock
                                .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
                        }
                        timelineBlock
                            .mindSenseStaggerEntrance(5, isPresented: didAppear, reduceMotion: reduceMotion)
                    }
                    .mindSensePageInsets(bottom: bottomContentPadding)
                }
            }
            .mindSensePageBackground()
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            viewSafeAreaBottomInset = proxy.safeAreaInsets.bottom
                        }
                        .onChange(of: proxy.safeAreaInsets.bottom) { _, newValue in
                            viewSafeAreaBottomInset = newValue
                        }
                }
            }
            .navigationTitle(AppIA.today)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: AppIA.today)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAccessMenu()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if case .ready = resolvedState, hasUnfinishedRegulateStep {
                    primarySessionCTA
                }
            }
            .sheet(isPresented: $showConfidenceDetails) {
                TodayConfidenceSheet(
                    confidencePercent: store.confidencePercent,
                    confidenceLabel: store.confidenceLabel,
                    modelFitPercent: confidenceModelFitPercent,
                    quality: store.demoHealthProfile.quality,
                    improvementActions: confidenceImprovementActions
                )
            }
            .sheet(isPresented: $showModelDetails) {
                TodayModelDetailsSheet(
                    confidenceStatusLine: store.confidenceStatusLine,
                    coveragePercent: store.demoDataCoveragePercent,
                    confidencePercent: store.confidencePercent,
                    lastUpdatedLabel: store.lastUpdatedLabel,
                    modelFitPercent: confidenceModelFitPercent,
                    dataConfidencePercent: store.healthDataQualityScore
                )
            }
            .sheet(isPresented: $showSignalSourceDetails) {
                TodaySignalSourceSheet(
                    sourceLine: store.healthSourceStatusLine,
                    lastSyncRelativeLabel: store.healthLastSyncRelativeLabel,
                    sleepImportLabel: store.demoHealthProfile.sync.lastSleepImportAt.formatted(
                        date: .omitted,
                        time: .shortened
                    ),
                    hrvImportLabel: store.demoHealthProfile.sync.lastHRVSampleAt?.formatted(
                        date: .omitted,
                        time: .shortened
                    ) ?? "Not available",
                    permissions: store.healthPermissions,
                    diagnostics: store.healthQualityDiagnostics,
                    qualityScore: store.healthDataQualityScore,
                    actionHint: store.demoHealthProfile.quality.actionHint
                )
            }
            .sheet(isPresented: $showTimelineDetails, onDismiss: {
                timelineDetailEpisodeFilter = .all
            }) {
                TodayTimelineDetailSheet(
                    episodes: store.recentStressEpisodes,
                    timelineSegments: store.stressTimelineSegments,
                    initialEpisodeFilter: timelineDetailEpisodeFilter,
                    onSelectEpisode: { episode in
                        selectedTimelineEpisode = episode
                        store.triggerHaptic(intent: .selection)
                    },
                    onInspectIntensity: { episode in
                        presentIntensityDetails(for: episode, source: "timeline_detail_sheet")
                    }
                )
            }
            .sheet(item: $intensityInfoEpisode) { episode in
                TodayEpisodeIntensitySheet(
                    episode: episode,
                    higherThanPercentile: store.recentStressEpisodes.higherThanPercent(for: episode)
                )
            }
            .sheet(item: $selectedTimelineEpisode) { episode in
                TodayEpisodeDetailSheet(
                    episode: episode,
                    cognitivePrompt: store.episodeCognitivePrompt(for: episode),
                    recommendedDurationLabel: store.presetDefinition(for: episode.recommendedPreset)?.durationLabel ?? "3 min",
                    onSaveContext: { episodeID, tags, note in
                        persistEpisodeContext(
                            episodeID: episodeID,
                            tags: tags,
                            note: note,
                            shouldResetInlineCapture: false
                        )
                    },
                    onSaveFeedback: { episodeID, feedback in
                        store.saveStressEpisodeAttributionFeedback(
                            episodeID: episodeID,
                            feedback: feedback
                        )
                        if let updated = store.recentStressEpisodes.first(where: { $0.id == episodeID }) {
                            selectedTimelineEpisode = updated
                        }
                    },
                    onStartRecommended: { episode in
                        startEpisodeRecommendation(episode, source: "episode_detail_start")
                        selectedTimelineEpisode = nil
                    }
                )
            }
            .sheet(item: $selectedMetricDefinition) { metric in
                TodayMetricDefinitionSheet(metric: metric)
            }
            .onAppear {
                let firstAppearance = !didAppear
                if firstAppearance {
                    didAppear = true
                }
                if let banner = store.banner,
                   banner.severity == .success,
                   (banner.title == "Setup complete" || banner.title == "Milestone reached") {
                    store.clearBanner()
                }
                applyHeroWhyExpansionPolicy()
                store.prepareCoreScreen(.today)
                loadSlider = Double(max(1, min(10, store.demoMetrics.load / 10)))
                evaluateCheckInPromptVisibilityForVisit()
                consumeContextCaptureLaunchIfNeeded()
                if firstAppearance {
                    store.track(event: .screenView, surface: .today)
                }
            }
            .onDisappear {
                registerIgnoredCheckInIfNeeded()
            }
            .onChange(of: store.demoScenario) { _, _ in
                store.prepareCoreScreen(.today)
                loadSlider = Double(max(1, min(10, store.demoMetrics.load / 10)))
                evaluateCheckInPromptVisibilityForVisit()
                resetInlineContextCaptureState(clearFocusedID: true)
                intensityInfoEpisode = nil
            }
            .onChange(of: store.intentMode) { _, _ in
                store.prepareCoreScreen(.today)
            }
            .onChange(of: store.todayContextCaptureEpisodeID) { _, _ in
                consumeContextCaptureLaunchIfNeeded()
            }
            .onChange(of: store.onboarding.baselineStart) { _, _ in
                applyHeroWhyExpansionPolicy()
            }
        }
        .accessibilityIdentifier("today_screen_root")
    }

    private var commandDeck: some View {
        MindSenseTabHero(
            label: AppIA.today,
            title: heroInterpretation,
            detail: heroReferenceLabel,
            icon: "sun.max.fill",
            tone: .accent,
            watermarkTint: MindSensePalette.accent,
            watermarkHeight: 128
        ) {
            let commandActionHierarchy: MindSenseButtonHierarchy = hasUnfinishedRegulateStep ? .secondary : .primary
            let commandActionMinHeight: CGFloat = hasUnfinishedRegulateStep
                ? MindSenseControlSize.minimumTapTarget
                : MindSenseControlSize.primaryButton

            Button(inlineActionLabel) {
                if isLowCoverageRecommendationMode && !hasUnfinishedRegulateStep {
                    saveCheckIn()
                } else {
                    triggerNextBestAction(source: "today_action_card_cta")
                }
            }
            .accessibilityIdentifier("today_action_card_cta")
            .buttonStyle(
                MindSenseButtonStyle(
                    hierarchy: commandActionHierarchy,
                    minHeight: commandActionMinHeight
                )
            )

            Text(inlineActionContextLabel)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if hasUnfinishedRegulateStep {
                Text("Primary action is pinned in the bottom dock.")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: MindSenseSpacing.xs) {
                    ForEach(heroMetricCards) { card in
                        heroMetricCompactTile(card)
                    }
                }
            } else {
                HStack(spacing: MindSenseSpacing.xs) {
                    ForEach(heroMetricCards) { card in
                        heroMetricCompactTile(card)
                    }
                }
            }

            Button {
                if reduceMotion {
                    toggleHeroWhy()
                } else {
                    withAnimation(MindSenseMotion.selection) {
                        toggleHeroWhy()
                    }
                }
                store.triggerHaptic(intent: .selection)
            } label: {
                HStack(spacing: MindSenseSpacing.xs) {
                    Text(showHeroWhy ? "Hide details" : "Details")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: MindSenseSpacing.xs)
                    Image(systemName: showHeroWhy ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                .padding(.horizontal, MindSenseSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .fill(MindSenseSurfaceLevel.base.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                        .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("today_action_card_why_now")

            if showHeroWhy {
                VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                    heroDiagnosticsDetails
                    heroIntentModeDetails
                    heroActionContextDetails
                    heroStateDisclosureRow
                    if showHeroStateExplanation {
                        heroStateExplanationDetails(useBullets: shouldUseBulletWhyExplanation)
                    }
                }
            }
        }
    }

    private var heroDiagnosticsDetails: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Button {
                showConfidenceDetails = true
                store.triggerHaptic(intent: .selection)
            } label: {
                HStack(spacing: MindSenseSpacing.xs) {
                    Label("Recommendation confidence \(store.confidencePercent)%", systemImage: "chart.bar.xaxis")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: MindSenseSpacing.xs)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
            }
            .buttonStyle(.plain)

            Button {
                showSignalSourceDetails = true
                store.triggerHaptic(intent: .selection)
            } label: {
                HStack(spacing: MindSenseSpacing.xs) {
                    VStack(alignment: .leading, spacing: MindSenseSpacing.xxs) {
                        Text("Signal source and update status")
                            .font(MindSenseTypography.micro)
                            .foregroundStyle(.secondary)
                        Text(store.healthSourceStatusLine)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: MindSenseSpacing.xs)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
            }
            .buttonStyle(.plain)
        }
    }

    private var heroIntentModeDetails: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Text("Session emphasis filter")
                .font(MindSenseTypography.bodyStrong)

            Text("This only changes driver weighting and recommendation framing. Your primary next action remains Start or Continue.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            MindSenseSegmentedControl(
                options: IntentMode.allCases,
                selection: intentModeBinding,
                title: { $0.shortTitle }
            )

            Text(store.intentModeHintLine)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var heroActionContextDetails: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            if hasUnfinishedRegulateStep {
                Text("An active session is already running. Continue the session or record impact to finish today's primary loop.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if isLowCoverageRecommendationMode {
                Text(lowCoverageSummaryLine)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(lowCoverageReasonLine) \(lowCoverageFixLine)")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                actionDetailRow(label: "Why now", value: recommendation.why)
                actionDetailRow(label: "Expected effect", value: recommendation.expectedEffect)
            }

            Button(isLowCoverageRecommendationMode && !hasUnfinishedRegulateStep ? "Choose a protocol manually" : "Pick a different protocol") {
                openRegulateProtocolPicker(source: "today_action_card_pick_protocol")
            }
            .accessibilityIdentifier("today_action_card_pick_protocol")
            .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
        }
    }

    @ViewBuilder
    private func heroStateExplanationDetails(useBullets: Bool) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Text("Why this state now")
                .font(MindSenseTypography.bodyStrong)

            if useBullets {
                ForEach(Array(heroWhyBullets.enumerated()), id: \.offset) { item in
                    Text("• \(item.element)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(heroWhyDetail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var heroStateDisclosureRow: some View {
        Button {
            if reduceMotion {
                toggleHeroStateExplanation()
            } else {
                withAnimation(MindSenseMotion.selection) {
                    toggleHeroStateExplanation()
                }
            }
            store.triggerHaptic(intent: .selection)
        } label: {
            HStack(spacing: MindSenseSpacing.xs) {
                Text(showHeroStateExplanation ? "Hide why this state" : "Why this state")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: MindSenseSpacing.xs)
                Image(systemName: showHeroStateExplanation ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: MindSenseControlSize.minimumTapTarget)
            .padding(.horizontal, MindSenseSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .fill(MindSenseSurfaceLevel.base.fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today_action_card_why_state")
    }

    private var statusSnapshotBlock: some View {
        InsetSurface {
            MindSenseCollapsibleSection(
                model: .init(
                    title: "Now",
                    subtitle: "Updated \(store.lastUpdatedLabel).",
                    icon: "heart.text.square"
                ),
                storageKey: "ui.collapse.today.status_snapshot",
                collapsedSummary: "Load \(store.demoMetrics.load) • Readiness \(store.demoMetrics.readiness) • Consistency \(store.demoMetrics.consistency)"
            ) {
                VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                    Text("Load \(store.demoMetrics.load) (\(loadStateLabel))  •  Readiness \(store.demoMetrics.readiness) (\(readinessStateLabel))")
                        .font(MindSenseTypography.body)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Consistency \(store.demoMetrics.consistency) (\(consistencyStateLabel))")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Daily deltas are shown directly in the KPI cards above.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showModelDetails = true
                    store.triggerHaptic(intent: .selection)
                } label: {
                    Label("Model details", systemImage: "info.circle")
                        .font(MindSenseTypography.caption)
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            }
        }
    }

    private var driversBlock: some View {
        PrimarySurface {
            MindSenseCollapsibleSection(
                model: .init(
                    title: "Top drivers now",
                    subtitle: "The strongest factors shaping your state now, biased for \(store.intentMode.shortTitle.lowercased()) intent. Percentages show each signal's share of top-driver weight.",
                    icon: "bolt.heart"
                ),
                storageKey: "ui.collapse.today.top_drivers",
                collapsedSummary: driverCollapsedSummary
            ) {
                VStack(spacing: MindSenseSpacing.sm) {
                    ForEach(visibleDrivers) { driver in
                        DriverImpactRowView(
                            driver: driver,
                            weightShare: driverWeightShare(for: driver),
                            sourceLine: driverSourceLine(for: driver),
                            controlLine: driverControlLine(for: driver),
                            microActionTitle: driverMicroActionLabel(for: driver),
                            onMicroAction: driverMicroActionLabel(for: driver) == nil
                                ? nil
                                : { triggerDriverMicroAction(for: driver) }
                        )
                    }
                }

                if scenarioIncludesMeetingCallDrivers {
                    Text("Control: Use meeting/call signals is \(store.useMeetingCallSignals ? "On" : "Off") in Settings > Health and data.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if store.todayPrimaryDrivers.count > 2 {
                    Button(showAllDrivers ? "Show fewer drivers" : "See all drivers") {
                        showAllDrivers.toggle()
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }

                if !store.todaySecondaryDrivers.isEmpty {
                    MindSenseSectionDivider(emphasis: MindSenseDividerEmphasis.strong)
                    DisclosureGroup(isExpanded: $showSecondarySignals) {
                        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                            ForEach(store.todaySecondaryDrivers.prefix(2)) { secondary in
                                Text("• \(secondary.name) also appears in your context.")
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, 4)
                    } label: {
                        Text("More signals")
                            .font(MindSenseTypography.caption)
                    }
                }
            }
        }
    }

    private var actionBlock: some View {
        PrimarySurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Do this next",
                    subtitle: isLowCoverageRecommendationMode && !hasUnfinishedRegulateStep
                        ? "Low confidence mode: add a quick check-in before using a precise protocol."
                        : "Do this now.",
                    icon: "scope"
                )
            )

            if isLowCoverageRecommendationMode && !hasUnfinishedRegulateStep {
                HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
                    HStack(spacing: MindSenseSpacing.xs) {
                        MindSenseIconBadge(
                            systemName: "exclamationmark.triangle.fill",
                            tint: MindSensePalette.warning,
                            style: .filled,
                            size: MindSenseControlSize.iconBadge
                        )
                        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                            Text("Low confidence mode")
                                .font(MindSenseTypography.bodyStrong)
                            Text("Precise recommendation hidden until coverage improves.")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: MindSenseSpacing.xs) {
                        PillChip(label: "Coverage \(store.demoDataCoveragePercent)%", state: .unselected)
                        PillChip(label: "Rec. confidence \(store.confidencePercent)%", state: .unselected)
                    }
                }
            } else {
                HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
                    HStack(spacing: MindSenseSpacing.xs) {
                        MindSenseIconBadge(
                            systemName: presetIcon(for: recommendation.preset),
                            tint: MindSensePalette.accent,
                            style: .filled,
                            size: MindSenseControlSize.iconBadge
                        )
                        Text(recommendation.preset.title)
                            .font(MindSenseTypography.body)
                    }
                    Spacer()
                    PillChip(label: store.intentMode.shortTitle, state: .selected)
                    PillChip(label: "\(recommendation.timeMinutes) min", state: .unselected)
                }
            }

            if !hasUnfinishedRegulateStep {
                if isLowCoverageRecommendationMode {
                    Button("Save prefilled check-in") {
                        saveCheckIn()
                    }
                    .accessibilityIdentifier("today_action_card_cta")
                    .buttonStyle(
                        MindSenseButtonStyle(
                            hierarchy: .primary,
                            minHeight: MindSenseControlSize.primaryButton
                        )
                    )
                } else {
                    Button(inlineActionLabel) {
                        triggerNextBestAction(source: "today_action_card_cta")
                    }
                    .accessibilityIdentifier("today_action_card_cta")
                    .buttonStyle(
                        MindSenseButtonStyle(
                            hierarchy: .primary,
                            minHeight: MindSenseControlSize.primaryButton
                        )
                    )
                }
            } else {
                MindSenseSummaryDisclosureText(
                    summary: "An active session is already running. Use the sticky action below to finish the loop.",
                    detail: "We keep one persistent action when a session is in progress so you can resume or record impact without hunting through cards.",
                    collapsedLabel: "Why only one action?",
                    expandedLabel: "Hide rationale"
                )
            }

            if isLowCoverageRecommendationMode && !hasUnfinishedRegulateStep {
                MindSenseSummaryDisclosureText(
                    summary: lowCoverageSummaryLine,
                    detail: "\(lowCoverageReasonLine) \(lowCoverageFixLine)",
                    collapsedLabel: "Why coverage is low",
                    expandedLabel: "Hide coverage details"
                )

                Button("Open signal diagnostics") {
                    showSignalSourceDetails = true
                    store.triggerHaptic(intent: .selection)
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            } else {
                Button {
                    if reduceMotion {
                        showActionDetails.toggle()
                    } else {
                        withAnimation(MindSenseMotion.selection) {
                            showActionDetails.toggle()
                        }
                    }
                    store.triggerHaptic(intent: .selection)
                } label: {
                    HStack(spacing: MindSenseSpacing.xs) {
                        Text("Why this now?")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: MindSenseSpacing.xs)
                        Image(systemName: showActionDetails ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                    .padding(.horizontal, MindSenseSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                            .fill(MindSenseSurfaceLevel.base.fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                            .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("today_action_card_why_now")
            }

            Button(isLowCoverageRecommendationMode && !hasUnfinishedRegulateStep ? "Choose a protocol manually" : "Pick a different protocol") {
                openRegulateProtocolPicker(source: "today_action_card_pick_protocol")
            }
            .accessibilityIdentifier("today_action_card_pick_protocol")
            .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))

            if showActionDetails && !(isLowCoverageRecommendationMode && !hasUnfinishedRegulateStep) {
                VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                    actionDetailRow(label: "Why now", value: recommendation.why)
                    actionDetailRow(label: "Expected effect", value: recommendation.expectedEffect)
                }
            }
        }
    }

    private var timelineBlock: some View {
        InsetSurface {
            MindSenseCollapsibleSection(
                model: .init(
                    title: "Today timeline",
                    subtitle: "Stress episodes and recovery windows inferred from recent signals.",
                    icon: "clock.arrow.circlepath"
                ),
                storageKey: "ui.collapse.today.timeline",
                collapsedSummary: timelineCollapsedSummary
            ) {
                if store.stressTimelineSegments.isEmpty {
                    Text("No stress timeline available yet. Resync health data in Settings.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    timelineSegmentBar

                    HStack(spacing: MindSenseSpacing.xs) {
                        timelineLegendPill(title: "Stable", state: .stable)
                        timelineLegendPill(title: "Activated", state: .activated)
                        timelineLegendPill(title: "Recovery", state: .recovery)
                    }

                    Text("Legend codes: S = Stable, A = Activated, R = Recovery.")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if store.recentStressEpisodes.isEmpty {
                    Text("No detected episodes yet.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let recentEpisodes = Array(store.recentStressEpisodes.prefix(3))
                    VStack(spacing: 0) {
                        ForEach(Array(recentEpisodes.enumerated()), id: \.element.id) { index, episode in
                            stressEpisodeRow(episode, rowIndex: index)
                            if index < recentEpisodes.count - 1 {
                                MindSenseSectionDivider(emphasis: MindSenseDividerEmphasis.subtle)
                            }
                        }
                    }
                }

                if attributionInboxCount > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: MindSenseSpacing.sm) {
                        Label(attributionInboxCountLabel, systemImage: "tag")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: MindSenseSpacing.xs)

                        Button("Review labels") {
                            openTimelineDetails(
                                filter: .needsLabel,
                                source: "today_timeline_attribution_filter"
                            )
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                    }
                }

            }
        }
    }

    private var timelineSegmentBar: some View {
        HStack(spacing: MindSenseSpacing.xxxs) {
            ForEach(store.stressTimelineSegments) { segment in
                TimelineStateSegmentCell(
                    state: segment.state,
                    tint: timelineTint(for: segment.state),
                    height: MindSenseControlSize.timelineSegmentHeight,
                    prefersExpandedLabel: false
                )
            }
        }
        .padding(.vertical, MindSenseSpacing.xxxs)
        .accessibilityElement(children: .contain)
    }

    private func timelineLegendPill(title: String, state: StressTimelineState) -> some View {
        TimelineStateLegendPill(
            title: title,
            state: state,
            tint: timelineTint(for: state)
        )
    }

    private func stressEpisodeRow(_ episode: StressEpisodeRecord, rowIndex: Int) -> some View {
        HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
            MindSenseIconBadge(
                systemName: "waveform.path.ecg",
                tint: timelineTint(for: .activated),
                style: .filled,
                size: MindSenseControlSize.iconBadge
            )

            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                HStack(spacing: MindSenseSpacing.xs) {
                    Text("\(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    if !episode.hasContext {
                        Text("Needs label")
                            .font(MindSenseTypography.micro)
                            .foregroundStyle(MindSensePalette.warning)
                            .padding(.horizontal, MindSenseSpacing.xs)
                            .frame(minHeight: MindSenseSpacing.lg)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(MindSensePalette.warning.opacity(0.18))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(MindSensePalette.warning.opacity(0.45), lineWidth: 1)
                            )
                    }
                    EpisodeIntensityBadge(intensity: episode.intensity) {
                        presentIntensityDetails(for: episode, source: "today_timeline_card")
                    }
                }

                Text("\(episode.likelyDriver.title) driver • attribution confidence \(episode.confidence)%")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Recommended: \(episode.recommendedPreset.title)")
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if episode.hasContext {
                    let contextSummary = episode.contextSummaryLine ?? "Note captured"
                    Text("Context captured: \(contextSummary)")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(MindSensePalette.success)
                        .lineLimit(1)
                } else {
                    Button("Add context") {
                        focusContextCapture(for: episode)
                    }
                    .accessibilityIdentifier("today_timeline_episode_add_context_\(rowIndex)")
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }

                if let feedback = episode.attributionFeedback {
                    Text("Attribution review: \(feedback.title)")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(MindSensePalette.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MindSenseSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTimelineEpisode = episode
            store.track(
                event: .secondaryActionTapped,
                surface: .today,
                action: "timeline_episode_opened",
                metadata: ["episode_id": episode.id.uuidString]
            )
            store.triggerHaptic(intent: .selection)
        }
        .accessibilityIdentifier("today_timeline_episode_row_\(rowIndex)")
        .accessibilityHint("Opens episode details")
        .accessibilityAddTraits(.isButton)
    }

    private func openTimelineDetails(
        filter: TodayTimelineDetailSheet.EpisodeFilter,
        source: String
    ) {
        timelineDetailEpisodeFilter = filter
        showTimelineDetails = true
        store.track(
            event: .secondaryActionTapped,
            surface: .today,
            action: "timeline_details_opened",
            metadata: [
                "source": source,
                "filter": filter.rawValue
            ]
        )
        store.triggerHaptic(intent: .selection)
    }

    private var episodeAwaitingContext: StressEpisodeRecord? {
        if let focusedContextEpisodeID,
           let focused = store.recentStressEpisodes.first(where: { $0.id == focusedContextEpisodeID }),
           !focused.hasContext {
            return focused
        }
        return store.latestStressEpisodeNeedingContext
    }

    @ViewBuilder
    private var contextCaptureBlock: some View {
        if let episode = episodeAwaitingContext {
            FocusSurface {
                MindSenseSectionHeader(
                    model: .init(
                        title: "What caused the spike?",
                        subtitle: "Quick pick one tag. Add another or set primary/secondary if it was multi-causal.",
                        icon: "text.bubble"
                    )
                )

                Text("Episode \(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)

                FlexibleChipGrid(items: DemoHealthSignalEngine.contextTags, selectedItems: $contextTags) { item, isSelected in
                    handleInlineContextTagSelection(item: item, isSelected: isSelected)
                }

                if contextTags.count == 1 && !allowMultipleContextTags {
                    Button("Add another (optional)") {
                        allowMultipleContextTags = true
                        store.track(event: .secondaryActionTapped, surface: .today, action: "stress_context_add_another_enabled")
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }

                if contextTags.count >= 2 {
                    inlineContextWeightingBlock
                }

                VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                    Text("Custom context")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)

                    TextField("Type a context label…", text: $contextNote)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .padding(.horizontal, MindSenseSpacing.sm)
                        .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                        .background(
                            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                                .fill(MindSenseSurfaceLevel.base.fill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                        )
                }

                HStack {
                    Spacer()
                    Button("Skip") {
                        resetInlineContextCaptureState(clearFocusedID: true)
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }

                Button("Save context") {
                    saveContext(for: episode.id)
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: MindSenseControlSize.primaryButton))
                .disabled(contextSaveDisabled)
            }
        }
    }

    private var checkInBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Quick check-in",
                    subtitle: isLowCoverageRecommendationMode
                        ? "Low confidence mode: add a quick check-in to compensate for missing coverage."
                        : "Rate current load in one quick step.",
                    icon: "checkmark.circle"
                )
            )

            HStack(spacing: MindSenseSpacing.xs) {
                MindSenseIconBadge(systemName: "dial.low.fill", tint: checkInTint, style: .filled, size: MindSenseControlSize.iconBadge)
                Text("Load now: \(Int(loadSlider.rounded())) / 10 (\(checkInLabel))")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Save check-in") {
                    saveCheckIn()
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false, minHeight: MindSenseControlSize.minimumTapTarget))
            }

            if isLowCoverageRecommendationMode {
                MindSenseSummaryDisclosureText(
                    summary: lowCoverageCheckInSummaryLine,
                    detail: "\(lowCoverageReasonLine) \(lowCoverageFixLine)",
                    collapsedLabel: "Why coverage is low",
                    expandedLabel: "Hide coverage details"
                )
            } else {
                Text("Prefilled from your current state.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $loadSlider, in: 1...10, step: 1)
                .tint(MindSensePalette.warning)
                .onChange(of: loadSlider) { _, _ in
                    checkInJustSaved = false
                }

            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                Text("1-3 Light / effortless")
                Text("4-6 Moderate / sustainable")
                Text("7-10 Heavy / draining")
            }
            .font(MindSenseTypography.caption)
            .foregroundStyle(.secondary)

            Text("5 = normal workday demand.")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                Text("Main driver today: meetings / workout / poor sleep / travel")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: MindSenseSpacing.xs)], alignment: .leading, spacing: MindSenseSpacing.xs) {
                    ForEach(checkInDriverOptions, id: \.self) { option in
                        Button {
                            if selectedCheckInDriver == option {
                                selectedCheckInDriver = nil
                            } else {
                                selectedCheckInDriver = option
                            }
                            checkInJustSaved = false
                            store.triggerHaptic(intent: .selection)
                        } label: {
                            PillChip(label: option, state: selectedCheckInDriver == option ? .selected : .unselected)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(selectedCheckInDriver == option ? "Double tap to clear." : "Double tap to select.")
                    }
                }
            }

            if checkInJustSaved {
                Text(
                    isLowCoverageRecommendationMode
                        ? "Check-in saved. Self-report is now available while sensor coverage is low."
                        : "This improves tomorrow's recommendation."
                )
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(MindSensePalette.accent)
            }

            if shouldShowCheckInFatigueOffer {
                VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                    Text("Want fewer check-ins?")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: MindSenseSpacing.xs) {
                        Button("Reduce check-ins") {
                            applyCheckInPromptMode(.reduced)
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false, minHeight: MindSenseControlSize.minimumTapTarget))

                        Button("Only ask on low-confidence days") {
                            applyCheckInPromptMode(.lowConfidenceOnly)
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false, minHeight: MindSenseControlSize.minimumTapTarget))
                    }
                }
            }

            if needsEscalationGuidance {
                EscalationGuidanceView(context: .sustainedHighLoad)
            }
        }
    }

    private var primarySessionCTA: some View {
        MindSenseDoItNowDock(
            subtitle: store.activeRegulateSession?.isAwaitingCheckIn == true
                ? "Finish the loop by recording impact."
                : "Resume the active regulate session."
        ) {
            Button(store.activeRegulateSession?.isAwaitingCheckIn == true ? "Record impact" : "Continue session") {
                triggerNextBestAction(source: "today_sticky_cta")
            }
            .accessibilityIdentifier("today_primary_cta")
            .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: MindSenseControlSize.minimumTapTarget))
        }
        .padding(.bottom, stickyDockBottomOffset)
    }

    private var driverCollapsedSummary: String {
        if let lead = visibleDrivers.first {
            let extraCount = max(0, visibleDrivers.count - 1)
            if extraCount > 0 {
                return "Lead driver: \(lead.name) • +\(extraCount) more"
            }
            return "Lead driver: \(lead.name)"
        }
        return "No driver signals are available yet."
    }

    private var timelineCollapsedSummary: String {
        let segmentCount = store.stressTimelineSegments.count
        let episodeCount = store.recentStressEpisodes.count
        let unlabeledCount = attributionInboxCount
        if segmentCount == 0 && episodeCount == 0 {
            return "No timeline data yet."
        }
        if unlabeledCount > 0 {
            return "\(episodeCount) recent episodes • \(unlabeledCount) need labels"
        }
        return "\(episodeCount) recent episodes • \(segmentCount) timeline segments"
    }

    private var lowCoverageSummaryLine: String {
        "Low confidence mode: \(store.demoDataCoveragePercent)% coverage is too low for a precise recommendation."
    }

    private var lowCoverageReasonLine: String {
        let reasons = lowCoverageReasons
        guard !reasons.isEmpty else {
            return "What's missing: recent signal collection is incomplete."
        }
        return "What's missing: \(reasons.joined(separator: "; "))."
    }

    private var lowCoverageFixLine: String {
        let hint = store.demoHealthProfile.quality.actionHint.trimmingCharacters(in: .whitespacesAndNewlines)
        if hint.isEmpty {
            return "How to fix it: add a quick check-in now, sync Apple Health, and wear your watch overnight."
        }
        return "How to fix it: \(hint)"
    }

    private var lowCoverageCheckInSummaryLine: String {
        "Coverage is \(store.demoDataCoveragePercent)%. A quick check-in adds self-report data so today can degrade gracefully."
    }

    private var lowCoverageReasons: [String] {
        let quality = store.demoHealthProfile.quality
        var reasons: [String] = []

        let missingHRVDays = max(0, 7 - capturedDays(from: quality.hrvAvailability))
        if missingHRVDays > 0 {
            reasons.append("missing HRV \(missingHRVDays)/7 days")
        }

        let missingOvernightNights = max(0, 7 - capturedDays(from: quality.sleepCoverage))
        if missingOvernightNights > 0 {
            let nightLabel = missingOvernightNights == 1 ? "night" : "nights"
            reasons.append("watch not worn overnight \(missingOvernightNights) \(nightLabel)")
        }

        if quality.heartRateDensity < 60 {
            reasons.append("limited daytime heart-rate coverage")
        }

        return Array(reasons.prefix(3))
    }

    private func capturedDays(from qualityPercent: Int) -> Int {
        let bounded = max(0, min(100, qualityPercent))
        return Int((Double(bounded) * 7.0 / 100.0).rounded())
    }

    private func actionDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)
            Text(value)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var contextSaveDisabled: Bool {
        contextTags.isEmpty && contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func focusContextCapture(for episode: StressEpisodeRecord) {
        focusedContextEpisodeID = episode.id
        contextTags = Set(episode.userTags)
        allowMultipleContextTags = episode.userTags.count > 1
        contextPrimaryTag = episode.primaryContextTag ?? episode.userTags.first
        contextSecondaryTag = episode.secondaryContextTag
        normalizeInlineContextTagWeights()
        contextNote = episode.userNote ?? ""
        store.triggerHaptic(intent: .selection)
    }

    private func consumeContextCaptureLaunchIfNeeded() {
        guard let episodeID = store.consumeTodayContextCaptureEpisodeID() else { return }
        guard let episode = store.recentStressEpisodes.first(where: { $0.id == episodeID }) else {
            store.showActionFeedback(.updated, detail: "Episode context is no longer available.")
            return
        }
        focusContextCapture(for: episode)
    }

    @ViewBuilder
    private var inlineContextWeightingBlock: some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Text("Optional weighting")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Text("If more than one factor contributed, mark primary and secondary.")
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            inlineContextWeightRow(title: "Primary", selectedTag: contextPrimaryTag, allowNone: false) { tag in
                contextPrimaryTag = tag
                if contextSecondaryTag == tag {
                    contextSecondaryTag = nil
                }
                store.triggerHaptic(intent: .selection)
            }

            inlineContextWeightRow(title: "Secondary", selectedTag: contextSecondaryTag, allowNone: true) { tag in
                guard tag != contextPrimaryTag else { return }
                contextSecondaryTag = tag
                store.triggerHaptic(intent: .selection)
            }
        }
    }

    private func inlineContextWeightRow(
        title: String,
        selectedTag: String?,
        allowNone: Bool,
        onSelect: @escaping (String?) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Text(title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MindSenseSpacing.xs) {
                    if allowNone {
                        Button {
                            onSelect(nil)
                        } label: {
                            Text("None")
                                .font(MindSenseTypography.micro)
                                .foregroundStyle(selectedTag == nil ? MindSensePalette.signalCoolStrong : .secondary)
                                .padding(.horizontal, MindSenseSpacing.sm)
                                .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(selectedTag == nil ? MindSensePalette.accentMuted : MindSenseSurfaceLevel.base.fill)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(
                                            selectedTag == nil ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(weightingTagOptions, id: \.self) { tag in
                        Button(tag) {
                            onSelect(tag)
                        }
                        .buttonStyle(.plain)
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(selectedTag == tag ? MindSensePalette.signalCoolStrong : .secondary)
                        .padding(.horizontal, MindSenseSpacing.sm)
                        .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedTag == tag ? MindSensePalette.accentMuted : MindSenseSurfaceLevel.base.fill)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(
                                    selectedTag == tag ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle,
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
    }

    private var weightingTagOptions: [String] {
        contextTags.sorted()
    }

    private func handleInlineContextTagSelection(item: String, isSelected: Bool) {
        if isSelected, !allowMultipleContextTags {
            contextTags = [item]
        }

        normalizeInlineContextTagWeights()
        store.triggerHaptic(intent: .selection)
    }

    private func normalizeInlineContextTagWeights() {
        if contextTags.count <= 1 {
            allowMultipleContextTags = false
        }

        if let primary = contextPrimaryTag, !contextTags.contains(primary) {
            contextPrimaryTag = nil
        }
        if contextPrimaryTag == nil {
            contextPrimaryTag = contextTags.sorted().first
        }

        if let secondary = contextSecondaryTag,
           !contextTags.contains(secondary) || secondary == contextPrimaryTag {
            contextSecondaryTag = nil
        }

        if contextTags.count < 2 {
            contextSecondaryTag = nil
        }
    }

    private func orderedContextTags(
        from tags: Set<String>,
        primaryTag: String?,
        secondaryTag: String?
    ) -> [String] {
        var ordered: [String] = []

        func appendTag(_ tag: String?) {
            guard let tag, tags.contains(tag), !ordered.contains(tag) else { return }
            ordered.append(tag)
        }

        appendTag(primaryTag)
        appendTag(secondaryTag)

        for tag in tags.sorted() where !ordered.contains(tag) {
            ordered.append(tag)
        }
        return ordered
    }

    private func resetInlineContextCaptureState(clearFocusedID: Bool) {
        if clearFocusedID {
            focusedContextEpisodeID = nil
        }
        contextTags = []
        allowMultipleContextTags = false
        contextPrimaryTag = nil
        contextSecondaryTag = nil
        contextNote = ""
    }

    private func saveContext(for episodeID: UUID) {
        persistEpisodeContext(
            episodeID: episodeID,
            tags: contextTags,
            note: contextNote,
            primaryTag: contextPrimaryTag,
            secondaryTag: contextSecondaryTag,
            shouldResetInlineCapture: true
        )
    }

    private func persistEpisodeContext(
        episodeID: UUID,
        tags: Set<String>,
        note: String,
        primaryTag: String? = nil,
        secondaryTag: String? = nil,
        shouldResetInlineCapture: Bool
    ) {
        store.saveStressEpisodeContext(
            episodeID: episodeID,
            tags: orderedContextTags(from: tags, primaryTag: primaryTag, secondaryTag: secondaryTag),
            note: note,
            primaryTag: primaryTag,
            secondaryTag: secondaryTag
        )
        if shouldResetInlineCapture {
            resetInlineContextCaptureState(clearFocusedID: true)
            store.triggerHaptic(intent: .success)
        }
        if let updated = store.recentStressEpisodes.first(where: { $0.id == episodeID }) {
            selectedTimelineEpisode = updated
        }
    }

    private func saveCheckIn() {
        let tags = selectedCheckInDriver.map { Set([$0.lowercased()]) } ?? []
        store.saveTodayCheckIn(loadScore: Int(loadSlider.rounded()), tags: tags, showFeedback: false)
        store.triggerHaptic(intent: .success)
        checkInJustSaved = true
        checkInSavedThisVisit = true
        checkInIgnoreStreak = 0
        checkInLastSavedDayStamp = todayDayStamp
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            checkInJustSaved = false
        }
    }

    private var visibleDrivers: [DriverImpact] {
        showAllDrivers ? store.todayPrimaryDrivers : Array(store.todayPrimaryDrivers.prefix(2))
    }

    private var topDriverWeightTotal: Double {
        let total = store.todayPrimaryDrivers.reduce(0) { partial, driver in
            partial + max(0, driver.impact)
        }
        return total > 0 ? total : 1
    }

    private var scenarioIncludesMeetingCallDrivers: Bool {
        let scenarioDrivers = store.scenarioProfile.primaryDrivers + store.scenarioProfile.secondaryDrivers
        return scenarioDrivers.contains { $0.source.isMeetingOrCallSignal }
    }

    private func driverSourceLine(for driver: DriverImpact) -> String {
        "Source: \(driver.source.title)"
    }

    private func driverControlLine(for driver: DriverImpact) -> String? {
        guard driver.source.isMeetingOrCallSignal else { return nil }
        return "Control: Use meeting/call signals is \(store.useMeetingCallSignals ? "On" : "Off")"
    }

    private func driverMicroActionLabel(for driver: DriverImpact) -> String? {
        switch driver.id {
        case "moderate_meeting_load":
            return "Add buffer"
        case "meeting_stack":
            return "Schedule recovery"
        case "stable_sleep":
            return "Downshift tonight"
        case "training_response":
            return "Light day tomorrow"
        default:
            return nil
        }
    }

    private func triggerDriverMicroAction(for driver: DriverImpact) {
        switch driver.id {
        case "moderate_meeting_load", "meeting_stack":
            store.openRegulatePreset(.calmNow, startImmediately: false)
            store.showBanner(
                title: "Recovery buffer queued",
                detail: "Calm now is ready for your next meeting transition.",
                severity: .info
            )
        case "stable_sleep":
            store.openRegulatePreset(.sleepDownshift, startImmediately: false)
            store.showBanner(
                title: "Downshift queued",
                detail: "Sleep downshift is ready in Regulate for tonight.",
                severity: .info
            )
        case "training_response":
            store.showBanner(
                title: "Light day planned",
                detail: "Keep tomorrow low-intensity and preserve recovery capacity.",
                severity: .info
            )
        default:
            return
        }

        store.track(
            event: .secondaryActionTapped,
            surface: .today,
            action: "driver_micro_action",
            metadata: [
                "driver_id": driver.id,
                "label": driverMicroActionLabel(for: driver) ?? "unknown"
            ]
        )
        store.triggerHaptic(intent: .selection)
    }

    private func driverWeightShare(for driver: DriverImpact) -> Double {
        max(0, driver.impact) / topDriverWeightTotal
    }

    private func stateLabel(for metric: CoreMetric, value: Int) -> String {
        let bounded = max(0, min(100, value))
        return metric.thresholdBands.first(where: { $0.range.contains(bounded) })?.label ?? "Unclassified"
    }

    private func triggerNextBestAction(source: String) {
        if hasUnfinishedRegulateStep {
            store.resumeWhereLeftOff()
            store.track(event: .primaryCTATapped, surface: .today, action: "resume_where_left_off", metadata: ["source": source])
        } else {
            store.openRegulatePreset(recommendation.preset, startImmediately: true, source: source)
            store.track(
                event: .primaryCTATapped,
                surface: .today,
                action: "start_mapped_\(recommendation.preset.rawValue)",
                metadata: ["source": source]
            )
        }
        store.triggerHaptic(intent: .primary)
    }

    private var loadStateLabel: String {
        stateLabel(for: .load, value: store.demoMetrics.load)
    }

    private var readinessStateLabel: String {
        stateLabel(for: .readiness, value: store.demoMetrics.readiness)
    }

    private var consistencyStateLabel: String {
        stateLabel(for: .consistency, value: store.demoMetrics.consistency)
    }

    private func openRegulateProtocolPicker(source: String) {
        store.regulateLaunchRequest = nil
        store.selectedTab = .regulate
        store.track(
            event: .secondaryActionTapped,
            surface: .today,
            action: "open_regulate_picker",
            metadata: ["source": source]
        )
        store.triggerHaptic(intent: .selection)
    }

    private func startEpisodeRecommendation(_ episode: StressEpisodeRecord, source: String) {
        store.openRegulatePreset(
            episode.recommendedPreset,
            startImmediately: true,
            source: "episode:\(episode.id.uuidString)|\(source)"
        )
        store.track(
            event: .primaryCTATapped,
            surface: .today,
            action: "episode_recommendation_start_\(episode.recommendedPreset.rawValue)",
            metadata: ["source": source, "episode_id": episode.id.uuidString]
        )
        store.triggerHaptic(intent: .primary)
    }

    private func presentIntensityDetails(for episode: StressEpisodeRecord, source: String) {
        intensityInfoEpisode = episode

        var metadata: [String: String] = [
            "source": source,
            "episode_id": episode.id.uuidString,
            "intensity": "\(episode.intensity)"
        ]
        if let percentile = store.recentStressEpisodes.higherThanPercent(for: episode) {
            metadata["higher_than_percentile"] = "\(percentile)"
        }

        store.track(
            event: .secondaryActionTapped,
            surface: .today,
            action: "episode_intensity_explainer_opened",
            metadata: metadata
        )
        store.triggerHaptic(intent: .selection)
    }

    private func presetIcon(for preset: RegulatePresetID) -> String {
        switch preset {
        case .calmNow:
            return "wind"
        case .focusPrep:
            return "scope"
        case .sleepDownshift:
            return "moon.stars.fill"
        }
    }

    private var heroDelta: (load: Int, readiness: Int, consistency: Int) {
        if let delta = store.latestCheckInDeltaSummary {
            return (
                load: delta.loadDelta,
                readiness: delta.readinessDelta,
                consistency: delta.consistencyDelta
            )
        }

        let baseline = store.demoScenario.baseMetrics
        return (
            load: store.demoMetrics.load - baseline.load,
            readiness: store.demoMetrics.readiness - baseline.readiness,
            consistency: store.demoMetrics.consistency - baseline.consistency
        )
    }

    private var heroReferenceLabel: String {
        if isLowCoverageRecommendationMode {
            return "Updated \(store.lastUpdatedLabel). Add a quick check-in to improve guidance while coverage recovers."
        }
        return "Updated \(store.lastUpdatedLabel)."
    }

    private var heroInterpretation: String {
        if isLowCoverageRecommendationMode {
            return "Low confidence mode is active because signal coverage is limited."
        }
        if heroDelta.load <= -2 && heroDelta.readiness >= 2 {
            return "Load is easing while readiness is recovering."
        }
        if heroDelta.load >= 2 && heroDelta.readiness <= -1 {
            return "Load is rising while readiness is softening."
        }
        if abs(heroDelta.load) <= 1 && abs(heroDelta.readiness) <= 1 {
            return "Signals are mostly stable right now."
        }
        if heroDelta.readiness >= 2 {
            return "Readiness is improving; this is a good leverage window."
        }
        if heroDelta.load >= 2 {
            return "Load is climbing; protect capacity before the next push."
        }
        return "State is mixed; run one regulate session to clarify the trend."
    }

    private var heroWhyDetail: String {
        if let delta = store.latestCheckInDeltaSummary {
            return delta.explanation
        }
        return store.todayInsightDetail
    }

    private var shouldUseBulletWhyExplanation: Bool {
        isWithinFirstSevenDays
    }

    private var isWithinFirstSevenDays: Bool {
        guard let baselineStart = store.onboarding.baselineStart else {
            return !store.onboarding.isComplete(.baseline)
        }
        let elapsedDays = Calendar.current.dateComponents([.day], from: baselineStart, to: Date()).day ?? 0
        return elapsedDays < 7
    }

    private var heroWhyBullets: [String] {
        var bullets: [String] = []

        if let delta = latestDailyDelta {
            bullets.append(
                "Compared with yesterday: load \(deltaMovementText(delta.load)), readiness \(deltaMovementText(delta.readiness)), consistency \(deltaMovementText(delta.consistency))."
            )
        } else {
            bullets.append("Compared with yesterday: insufficient data, so this state leans more on baseline and recent context.")
        }

        for driver in store.todayPrimaryDrivers.prefix(2) {
            bullets.append("\(driver.name): \(driver.detail)")
        }

        if bullets.count < 2 {
            bullets.append(heroWhyDetail)
        }

        return Array(bullets.prefix(3))
    }

    private func deltaMovementText(_ value: Int) -> String {
        if value == 0 {
            return "is unchanged"
        }
        let points = abs(value)
        return value > 0 ? "is up \(points) pt\(points == 1 ? "" : "s")" : "is down \(points) pt\(points == 1 ? "" : "s")"
    }

    private func applyHeroWhyExpansionPolicy() {
        showHeroWhy = false
        showHeroStateExplanation = false
    }

    private func toggleHeroWhy() {
        showHeroWhy.toggle()
        if !showHeroWhy {
            showHeroStateExplanation = false
        }
    }

    private func toggleHeroStateExplanation() {
        showHeroStateExplanation.toggle()
    }

    private var latestDailyDelta: (load: Int, readiness: Int, consistency: Int)? {
        guard let delta = store.latestCheckInDeltaSummary else { return nil }
        return (load: delta.loadDelta, readiness: delta.readinessDelta, consistency: delta.consistencyDelta)
    }

    private var confidenceModelFitPercent: Int {
        let coverageFactor = (store.demoDataCoverageScore - 0.5) * 0.22
        let modelFitScore = min(1.0, max(0.0, store.confidenceScore - coverageFactor))
        return Int((modelFitScore * 100).rounded())
    }

    private var confidenceImprovementActions: [String] {
        let quality = store.demoHealthProfile.quality
        var actions: [String] = []

        let overnightGap = nightsNeeded(for: quality.sleepCoverage)
        if overnightGap > 0 {
            actions.append("Wear watch overnight \(overnightGap)/7 nights more.")
        }
        if quality.heartRateDensity < 68 {
            actions.append("Keep watch on during the day and enable Background App Refresh to raise HR density.")
        }
        if quality.hrvAvailability < 68 {
            let hrvGranted = store.healthPermissions.first(where: { $0.signal == .hrv })?.state == .granted
            if hrvGranted {
                let hrvGap = max(1, nightsNeeded(for: quality.hrvAvailability))
                actions.append("Capture HRV on \(hrvGap)/7 more days by wearing your watch overnight.")
            } else {
                actions.append("Allow HRV in Apple Health permissions to raise HRV availability.")
            }
        }
        let wearGap = nightsNeeded(for: quality.watchWear)
        if wearGap > 0 {
            actions.append("Increase wear continuity by keeping your watch on for \(wearGap)/7 more full days.")
        }
        if !store.hasCompletedTodayPrimaryLoop {
            actions.append("Complete one regulate session and one check-in today to improve model fit.")
        } else if let activeExperiment = store.activeExperiment, activeExperiment.adherencePercent < 70 {
            actions.append("Raise experiment adherence above 70% to strengthen model fit.")
        }
        if actions.isEmpty {
            actions.append("Keep overnight wear and daily check-ins consistent to maintain strong confidence.")
        }

        return Array(actions.prefix(3))
    }

    private func nightsNeeded(for qualityPercent: Int, targetPercent: Int = 68) -> Int {
        let currentNights = (qualityPercent * 7) / 100
        let targetNights = (targetPercent * 7 + 99) / 100
        return max(0, targetNights - currentNights)
    }

    private func heroMetricCompactTile(_ card: HeroMetricCard) -> some View {
        let bounded = max(0, min(100, card.value))
        let deltaTone = card.delta.map { deltaTint(metric: card.metric, value: $0) } ?? Color.secondary

        return VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Text(card.title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(alignment: .firstTextBaseline, spacing: MindSenseSpacing.xs) {
                Text("\(bounded)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(card.tint)
                    .monospacedDigit()
                    .lineLimit(1)

                Text(compactMetricDeltaLabel(card.delta))
                    .font(MindSenseTypography.micro)
                    .foregroundStyle(deltaTone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, MindSenseSpacing.sm)
        .padding(.vertical, MindSenseSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 70 : 64, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroMetricVoiceOverSummary(title: card.title, value: bounded, delta: card.delta, metric: card.metric))
    }

    private func compactMetricDeltaLabel(_ delta: Int?) -> String {
        guard let delta else { return "No delta" }
        if delta == 0 {
            return "No change"
        }
        return signed(delta)
    }

    private func heroMetricTile(
        title: String,
        value: Int,
        delta: Int?,
        metric: CoreMetric,
        tint: Color
    ) -> some View {
        let bounded = max(0, min(100, value))
        let deltaTone = delta.map { deltaTint(metric: metric, value: $0) } ?? Color.secondary
        return VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
            Text(title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.trailing, 24)
            Text("\(bounded)")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(metricDirectionalLegend(for: metric))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .truncationMode(.tail)
            Rectangle()
                .fill(MindSensePalette.strokeSubtle.opacity(0.9))
                .frame(height: 1)
            HStack(spacing: MindSenseSpacing.xxxs) {
                Image(systemName: deltaSymbol(for: delta))
                    .font(.system(size: 10, weight: .semibold))
                Text(deltaLabel(for: delta))
                    .font(MindSenseTypography.micro)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .foregroundStyle(deltaTone)
            .frame(maxWidth: .infinity, alignment: .leading)
            metricThresholdBandRows(metric: metric, value: bounded, tint: tint)
        }
        .padding(.horizontal, MindSenseLayout.tileHorizontalInset)
        .padding(.vertical, MindSenseLayout.tileVerticalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: MindSenseLayout.tileMinHeight)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroMetricVoiceOverSummary(title: title, value: bounded, delta: delta, metric: metric))
        .overlay(alignment: .topTrailing) {
            Button {
                selectedMetricDefinition = metric
                store.triggerHaptic(intent: .selection)
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .padding(.top, MindSenseLayout.tileVerticalInset + 1)
            .padding(.trailing, MindSenseLayout.tileHorizontalInset)
            .accessibilityLabel("About \(title)")
        }
    }

    private func heroMetricVoiceOverSummary(
        title: String,
        value: Int,
        delta: Int?,
        metric: CoreMetric
    ) -> String {
        let state = stateLabel(for: metric, value: value)
        let deltaSummary = heroMetricDeltaVoiceOverPhrase(delta)
        return "\(title): \(value), \(state), \(deltaSummary), confidence \(store.confidencePercent) percent"
    }

    private func heroMetricDeltaVoiceOverPhrase(_ delta: Int?) -> String {
        guard let delta else { return "insufficient comparison data vs yesterday" }
        if delta == 0 {
            return "unchanged vs yesterday"
        }
        let direction = delta > 0 ? "up" : "down"
        return "\(direction) \(abs(delta)) vs yesterday"
    }

    private func deltaSymbol(for delta: Int?) -> String {
        guard let delta else { return "minus" }
        if delta > 0 {
            return "arrow.up.right"
        }
        if delta < 0 {
            return "arrow.down.right"
        }
        return "minus"
    }

    private func deltaLabel(for delta: Int?) -> String {
        guard let delta else { return "Insufficient data today" }
        if delta == 0 {
            return "No change vs yesterday"
        }
        return "\(signed(delta)) vs yesterday"
    }

    private func deltaTint(metric: CoreMetric, value: Int) -> Color {
        switch metric {
        case .load:
            if value > 0 {
                return MindSensePalette.warning
            }
            if value < 0 {
                return MindSensePalette.success
            }
        case .readiness, .consistency:
            if value > 0 {
                return MindSensePalette.success
            }
            if value < 0 {
                return MindSensePalette.warning
            }
        }
        return MindSensePalette.accent
    }

    private func metricDirectionalLegend(for metric: CoreMetric) -> String {
        switch metric {
        case .load:
            return "Higher = more strain / demand"
        case .readiness:
            return "Higher = more capacity"
        case .consistency:
            return "Higher = more predictable stability"
        }
    }

    private func metricThresholdBandRows(metric: CoreMetric, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text("Threshold bands")
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            ForEach(metric.thresholdBands) { band in
                thresholdBandRow(band: band, value: value, tint: tint)
            }
        }
    }

    private func thresholdBandRow(band: MetricThresholdBand, value: Int, tint: Color) -> some View {
        let isActive = band.range.contains(value)
        return HStack(spacing: MindSenseSpacing.xs) {
            Text(band.rangeLabel)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Text(band.label)
                .font(MindSenseTypography.micro)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isActive ? .primary : .secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, MindSenseSpacing.xs)
        .padding(.vertical, MindSenseSpacing.xxxs)
        .background(
            RoundedRectangle(cornerRadius: MindSenseRadius.micro, style: .continuous)
                .fill(isActive ? tint.opacity(0.15) : MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MindSenseRadius.micro, style: .continuous)
                .stroke(isActive ? tint.opacity(0.48) : MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private func timelineTint(for state: StressTimelineState) -> Color {
        switch state {
        case .stable:
            return MindSensePalette.signalCoolSoft
        case .activated:
            return MindSensePalette.warning
        case .recovery:
            return MindSensePalette.signalCoolStrong
        }
    }

    private func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private var checkInLabel: String {
        switch Int(loadSlider.rounded()) {
        case 0...3:
            return "light"
        case 4...6:
            return "moderate"
        default:
            return "heavy"
        }
    }

    private var checkInTint: Color {
        switch Int(loadSlider.rounded()) {
        case 0...3:
            return MindSensePalette.success
        case 4...6:
            return MindSensePalette.accent
        case 7...8:
            return MindSensePalette.warning
        default:
            return MindSensePalette.critical
        }
    }
}

private struct TodayConfidenceSheet: View {
    @Environment(\.dismiss) private var dismiss

    let confidencePercent: Int
    let confidenceLabel: String
    let modelFitPercent: Int
    let quality: DemoHealthQualityBreakdown
    let improvementActions: [String]

    private var factors: [(String, Int)] {
        [
            ("Sleep coverage", quality.sleepCoverage),
            ("HR density", quality.heartRateDensity),
            ("HRV availability", quality.hrvAvailability),
            ("Wear continuity", quality.watchWear),
            ("Model confidence (fit)", modelFitPercent)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Recommendation confidence \(confidencePercent)%",
                                subtitle: "\(confidenceLabel) trust in today's recommendations."
                            )
                        )
                        Text("Recommendation confidence is based on sleep coverage, HR density, HRV availability, wear continuity, and model confidence (fit).")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(practicalTrustLine)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(MindSensePalette.accent)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "What drives it",
                                subtitle: "Current factor quality."
                            )
                        )
                        ForEach(factors, id: \.0) { factor in
                            factorRow(label: factor.0, value: factor.1)
                        }
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "What would raise it",
                                subtitle: "Highest-leverage next steps."
                            )
                        )
                        ForEach(Array(improvementActions.enumerated()), id: \.offset) { action in
                            Text("• \(action.element)")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Safety and limits",
                                subtitle: "Use this to calibrate trust, not replace clinical care."
                            )
                        )
                        Text("This is not medical advice.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Signals can be influenced by illness, alcohol, travel, and sensor gaps.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Recommendation confidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Recommendation confidence")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    private var practicalTrustLine: String {
        if confidencePercent >= 82 {
            return "High trust: recommendations are usually reliable as direct actions."
        }
        if confidencePercent >= 62 {
            return "Directional trust: use recommendations as guidance, then confirm with your next check-in."
        }
        return "Lower trust: improve coverage before making major routine changes."
    }

    private func factorRow(label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .font(MindSenseTypography.bodyStrong)
                .monospacedDigit()
        }
    }
}

private struct TodayMetricDefinitionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let metric: CoreMetric

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "\(metric.title) metric",
                                subtitle: "How this score is estimated and what movement means.",
                                icon: metricIcon,
                                iconTint: metricTint
                            )
                        )
                        Text(metric.definition)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "How to interpret",
                                subtitle: "Scores are normalized to a 0-100 range."
                            )
                        )
                        detailRow(label: "Higher score", value: higherInterpretation)
                        detailRow(label: "Lower score", value: lowerInterpretation)
                        Text("Use the 1d delta in the card for short-term direction, and combine it with the trend chart for context.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(metricTint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("\(metric.title) metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Metric details")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    private var metricIcon: String {
        switch metric {
        case .load:
            return "waveform.path.ecg"
        case .readiness:
            return "bolt.heart.fill"
        case .consistency:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        }
    }

    private var metricTint: Color {
        switch metric {
        case .load:
            return MindSensePalette.warning
        case .readiness:
            return MindSensePalette.success
        case .consistency:
            return MindSensePalette.signalCool
        }
    }

    private var higherInterpretation: String {
        switch metric {
        case .load:
            return "More accumulated strain and lower short-term recovery buffer."
        case .readiness:
            return "Stronger recovery capacity and better tolerance for focused demand."
        case .consistency:
            return "More stable daily rhythm with lower physiological variability."
        }
    }

    private var lowerInterpretation: String {
        switch metric {
        case .load:
            return "Lower immediate strain; recovery systems are carrying less stress."
        case .readiness:
            return "Lower available capacity; prioritize recovery before high demand blocks."
        case .consistency:
            return "Greater day-to-day rhythm disruption and less predictable recovery response."
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.4)
            Text(value)
                .font(MindSenseTypography.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MindSenseSpacing.xxxs)
    }
}

private struct TodayModelDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MindSenseStore

    let confidenceStatusLine: String
    let coveragePercent: Int
    let confidencePercent: Int
    let lastUpdatedLabel: String
    let modelFitPercent: Int
    let dataConfidencePercent: Int

    private var completedOutcomes: [SessionOutcome] {
        store.regulateSessionHistory.compactMap(\.outcome)
    }

    private var ratedOutcomeCount: Int {
        completedOutcomes.filter(\.isRated).count
    }

    private var unratedOutcomeCount: Int {
        completedOutcomes.filter { !$0.isRated }.count
    }

    private var reviewedAttributionCount: Int {
        store.demoHealthProfile.stressEpisodes.filter { $0.attributionFeedback != nil }.count
    }

    private var pendingAttributionCount: Int {
        max(0, store.demoHealthProfile.stressEpisodes.count - reviewedAttributionCount)
    }

    private var activeExperimentAdherenceLine: String {
        if let active = store.activeExperiment {
            return "\(active.title): adherence \(active.adherencePercent)% (affects recommendation confidence and experiment estimates)."
        }
        return "No active experiment. When an experiment is active, adherence contributes a small bonus to recommendation confidence."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Model details",
                                subtitle: "Diagnostics stay available without taking over the main dashboard."
                            )
                        )
                        VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                            detailRow(label: "Recommendation confidence", value: "\(confidencePercent)%")
                            detailRow(label: "Coverage", value: "\(coveragePercent)%")
                            detailRow(label: "Data confidence", value: "\(dataConfidencePercent)")
                            detailRow(label: "Last updated", value: lastUpdatedLabel)
                            Text(confidenceStatusLine)
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Inputs used and not used",
                                subtitle: "Scope is shown explicitly so confidence is calibrated."
                            )
                        )
                        noteRow(
                            label: "Used for today's recommendation ranking",
                            value: "Current Load, Readiness, and Consistency; intent mode; recent event-derived stress/recovery signals; and \(store.useMeetingCallSignals ? "meeting/call metadata drivers" : "meeting/call metadata drivers are disabled by your setting")."
                        )
                        noteRow(
                            label: "Used for recommendation confidence",
                            value: "Data coverage, completion of today's primary loop, active experiment adherence, and repeated session cancellations (penalty)."
                        )
                        MindSenseSummaryDisclosureText(
                            summary: "Not used in the recommendation confidence percent: episode attribution labels, note text, and optional respiratory/audio context.",
                            detail: "Episode attribution feedback is saved for review. Session notes and tags are stored with outcomes, but the recommendation confidence percent is computed from coverage and behavior evidence. Respiratory rate and environmental audio are optional context signals and are not required for confidence scoring.",
                            collapsedLabel: "What is not used",
                            expandedLabel: "Hide exclusions"
                        )
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Baseline definition",
                                subtitle: "What baseline means in the current build."
                            )
                        )
                        noteRow(
                            label: "Onboarding baseline",
                            value: "\(store.baselineText). This is a 14-day baseline-building progress tracker."
                        )
                        noteRow(
                            label: "Recommendation anchor",
                            value: "Today's recommendations compare current metrics with scenario baseline anchors (Load \(store.demoScenario.baseMetrics.load), Readiness \(store.demoScenario.baseMetrics.readiness), Consistency \(store.demoScenario.baseMetrics.consistency)) plus recent context signals."
                        )
                        MindSenseSummaryDisclosureText(
                            summary: "Rolling 30-day personalized baseline is not used in the current recommendation score.",
                            detail: "This build uses scenario base metrics plus recent sessions/events for recommendation ranking. Stress episode intensity compares deviation from derived HR/HRV baseline patterns plus duration, and the derived health baseline can be rebuilt from Settings.",
                            collapsedLabel: "How baseline is used",
                            expandedLabel: "Hide baseline details"
                        )
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "What confidence means",
                                subtitle: "Trust estimate, not certainty or diagnosis."
                            )
                        )
                        noteRow(
                            label: "Recommendation confidence (\(confidencePercent)%)",
                            value: "An estimate of how reliable today's ranked recommendations are given current evidence quality and recent behavior signal coverage. It is not a guarantee of outcome."
                        )
                        noteRow(
                            label: "Data confidence (\(dataConfidencePercent))",
                            value: "Signal quality and coverage from imports such as sleep, heart-rate density, HRV availability, and wear continuity."
                        )
                        noteRow(
                            label: "Model confidence (fit) (\(modelFitPercent)%)",
                            value: "A fit proxy shown in the confidence sheet to separate model fit from data coverage when explaining recommendation confidence."
                        )
                        MindSenseSummaryDisclosureText(
                            summary: "Current formula uses a scenario confidence base plus evidence adjustments.",
                            detail: "Recommendation confidence is adjusted by data coverage, a small bonus when today's primary loop is completed, a small bonus from active experiment adherence, and a penalty for repeated cancelled sessions.",
                            collapsedLabel: "How confidence is calculated",
                            expandedLabel: "Hide formula details"
                        )
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "How your labels affect learning",
                                subtitle: "Structured labels carry explicit learning weight."
                            )
                        )
                        noteRow(
                            label: "Regulate outcome labels",
                            value: "Helped, Mixed, and Didn't help are saved with full learning weight (1.00). No rating is saved with reduced learning weight (0.35)."
                        )
                        detailRow(label: "Rated outcomes", value: "\(ratedOutcomeCount)")
                        detailRow(label: "No-rating outcomes", value: "\(unratedOutcomeCount)")
                        noteRow(
                            label: "Experiment check-ins",
                            value: activeExperimentAdherenceLine
                        )
                        noteRow(
                            label: "Episode attribution labels",
                            value: "\(reviewedAttributionCount) reviewed, \(pendingAttributionCount) pending. Attribution feedback is stored for audit/review and does not currently change today's recommendation confidence score."
                        )
                        MindSenseSummaryDisclosureText(
                            summary: "Structured outcome labels affect learning weight; free-text notes are context.",
                            detail: "The learning reward uses direction, helpfulness, feeling rating, and measured effect metrics, then applies learning weight. Note text is saved for context and history, not parsed into the learning-weight calculation.",
                            collapsedLabel: "How learning weight works",
                            expandedLabel: "Hide learning details"
                        )
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Safety guardrails",
                                subtitle: "Keep interpretation bounded."
                            )
                        )
                        Text("This is not medical advice.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Signals can be influenced by illness, alcohol, travel, and sensor gaps.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Diagnostics")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(MindSenseTypography.bodyStrong)
                .monospacedDigit()
        }
    }

    private func noteRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.4)
            Text(value)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MindSenseSpacing.xxxs)
    }
}

private struct TodaySignalSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRemediationGuide: DemoHealthPermissionRemediationGuide?

    let sourceLine: String
    let lastSyncRelativeLabel: String
    let sleepImportLabel: String
    let hrvImportLabel: String
    let permissions: [DemoHealthPermissionStatus]
    let diagnostics: [(String, Int)]
    let qualityScore: Int
    let actionHint: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Signal source",
                                subtitle: "Current pipeline status and health diagnostics."
                            )
                        )
                        Text(sourceLine)
                            .font(MindSenseTypography.bodyStrong)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Last sync \(lastSyncRelativeLabel)")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Import freshness",
                                subtitle: "Latest sample timestamps."
                            )
                        )
                        infoRow(label: "Sleep import", value: sleepImportLabel)
                        infoRow(label: "HRV sample", value: hrvImportLabel)
                        infoRow(label: "Data confidence", value: "\(qualityScore)")
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Permissions",
                                subtitle: "Requested Apple Health data types."
                            )
                        )
                        ForEach(permissions) { permission in
                            permissionRow(permission)
                        }

                        Text("Recommendation confidence uses sleep coverage, heart-rate density, HRV availability, and watch wear continuity. Respiratory rate and environmental audio are optional context signals.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Data confidence diagnostics",
                                subtitle: "Coverage checks driving data confidence."
                            )
                        )
                        ForEach(diagnostics, id: \.0) { item in
                            infoRow(label: item.0, value: "\(item.1)")
                        }
                        Text(actionHint)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(MindSensePalette.accent)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Signal Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Signal Diagnostics")
                }
            }
            .sheet(item: $selectedRemediationGuide) { guide in
                TodayPermissionRemediationSheet(guide: guide)
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    @ViewBuilder
    private func permissionRow(_ permission: DemoHealthPermissionStatus) -> some View {
        if let remediationGuide = permission.remediationGuide {
            Button {
                selectedRemediationGuide = remediationGuide
            } label: {
                permissionRowContent(permission, showsDisclosure: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens setup steps")
        } else {
            permissionRowContent(permission, showsDisclosure: false)
        }
    }

    private func permissionRowContent(_ permission: DemoHealthPermissionStatus, showsDisclosure: Bool) -> some View {
        HStack(spacing: MindSenseSpacing.sm) {
            Image(systemName: permission.state.statusIcon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(permissionTint(for: permission.state))
            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                Text(permission.signal.title)
                    .font(MindSenseTypography.bodyStrong)
                Text(permission.state.title)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                if let statusDetail = permission.statusDetail {
                    Text(statusDetail)
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, MindSenseSpacing.xxxs)
    }

    private func permissionTint(for state: DemoHealthPermissionState) -> Color {
        switch state {
        case .granted:
            return MindSensePalette.success
        case .missing:
            return MindSensePalette.warning
        case .unsupported:
            return MindSensePalette.critical
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(MindSenseTypography.bodyStrong)
                .monospacedDigit()
        }
    }
}

private struct TodayPermissionRemediationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let guide: DemoHealthPermissionRemediationGuide

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: guide.title,
                                subtitle: "How to enable"
                            )
                        )
                        Text(guide.summary)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Checklist",
                                subtitle: "Complete each step in order."
                            )
                        )
                        ForEach(Array(guide.checklist.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: MindSenseSpacing.xs) {
                                Text("\(index + 1).")
                                    .font(MindSenseTypography.bodyStrong)
                                    .foregroundStyle(.secondary)
                                Text(item)
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }

                    InsetSurface {
                        Text(guide.expectedTimeToPopulate)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(MindSensePalette.accent)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(guide.modelUsageNote)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("How to enable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "How to enable")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }
}

private struct EpisodeIntensityBadge: View {
    let intensity: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MindSenseSpacing.xxxs) {
                Text("Episode intensity \(intensity)")
                    .font(MindSenseTypography.micro)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(MindSensePalette.warning)
            .padding(.horizontal, MindSenseSpacing.xs)
            .padding(.vertical, MindSenseSpacing.xxxs)
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
        .accessibilityLabel("Episode intensity \(intensity). Show episode severity interpretation.")
    }
}

private struct TodayTimelineDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    private enum DayFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"

        var id: String { rawValue }
    }

    enum EpisodeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case needsLabel = "Needs label"

        var id: String { rawValue }
    }

    let episodes: [StressEpisodeRecord]
    let timelineSegments: [StressTimelineSegment]
    let onSelectEpisode: (StressEpisodeRecord) -> Void
    let onInspectIntensity: (StressEpisodeRecord) -> Void

    @State private var dayFilter: DayFilter = .today
    @State private var episodeFilter: EpisodeFilter

    init(
        episodes: [StressEpisodeRecord],
        timelineSegments: [StressTimelineSegment],
        initialEpisodeFilter: EpisodeFilter = .all,
        onSelectEpisode: @escaping (StressEpisodeRecord) -> Void,
        onInspectIntensity: @escaping (StressEpisodeRecord) -> Void
    ) {
        self.episodes = episodes
        self.timelineSegments = timelineSegments
        self.onSelectEpisode = onSelectEpisode
        self.onInspectIntensity = onInspectIntensity
        _episodeFilter = State(initialValue: initialEpisodeFilter)
    }

    private var filteredEpisodes: [StressEpisodeRecord] {
        let calendar = Calendar.current
        let dayFiltered = episodes.filter { episode in
            switch dayFilter {
            case .today:
                return calendar.isDateInToday(episode.end)
            case .yesterday:
                return calendar.isDateInYesterday(episode.end)
            }
        }

        return dayFiltered.filter { episode in
            switch episodeFilter {
            case .all:
                return true
            case .needsLabel:
                return !episode.hasContext
            }
        }
    }

    private var filteredEpisodeEmptyState: String {
        switch episodeFilter {
        case .all:
            return "No episodes detected for \(dayFilter.rawValue.lowercased())."
        case .needsLabel:
            return "No unlabeled episodes for \(dayFilter.rawValue.lowercased())."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Timeline map",
                                subtitle: "Stable, activated, and recovery windows for selected day."
                            )
                        )

                        MindSenseSegmentedControl(
                            options: DayFilter.allCases,
                            selection: $dayFilter,
                            title: { $0.rawValue }
                        )

                        if dayFilter == .today {
                            HStack(spacing: MindSenseSpacing.xxxs) {
                                ForEach(timelineSegments) { segment in
                                    TimelineStateSegmentCell(
                                        state: segment.state,
                                        tint: timelineTint(for: segment.state),
                                        height: 24,
                                        prefersExpandedLabel: true
                                    )
                                }
                            }
                            HStack(spacing: MindSenseSpacing.xs) {
                                TimelineStateLegendPill(title: "Stable", state: .stable, tint: timelineTint(for: .stable))
                                TimelineStateLegendPill(title: "Activated", state: .activated, tint: timelineTint(for: .activated))
                                TimelineStateLegendPill(title: "Recovery", state: .recovery, tint: timelineTint(for: .recovery))
                            }
                        } else {
                            Text("Timeline detail for yesterday appears after enough imported history.")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    FocusSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Detected episodes",
                                subtitle: "Filter episodes, then open one to review trigger context and next action."
                            )
                        )

                        MindSenseSegmentedControl(
                            options: EpisodeFilter.allCases,
                            selection: $episodeFilter,
                            title: { $0.rawValue }
                        )

                        if filteredEpisodes.isEmpty {
                            Text(filteredEpisodeEmptyState)
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(filteredEpisodes) { episode in
                                timelineEpisodeRow(episode)
                            }
                        }
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Timeline")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }

    private func timelineTint(for state: StressTimelineState) -> Color {
        switch state {
        case .stable:
            return MindSensePalette.signalCoolSoft
        case .activated:
            return MindSensePalette.warning
        case .recovery:
            return MindSensePalette.signalCoolStrong
        }
    }

    private func timelineEpisodeRow(_ episode: StressEpisodeRecord) -> some View {
        HStack(alignment: .top, spacing: MindSenseSpacing.sm) {
            VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
                HStack(spacing: MindSenseSpacing.xs) {
                    Text("\(episode.start.formattedDateLabel()) \(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    EpisodeIntensityBadge(intensity: episode.intensity) {
                        onInspectIntensity(episode)
                    }
                }
                Text("\(episode.likelyDriver.title) • attribution confidence \(episode.confidence)%")
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if episode.hasContext {
                    let tags = episode.contextSummaryLine ?? "Note captured"
                    Text("Context: \(tags)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(MindSensePalette.success)
                        .lineLimit(1)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .contentShape(RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous))
        .onTapGesture {
            onSelectEpisode(episode)
            dismiss()
        }
        .accessibilityHint("Opens episode details")
        .accessibilityAddTraits(.isButton)
    }
}

private struct TimelineStateSegmentCell: View {
    let state: StressTimelineState
    let tint: Color
    var height: CGFloat = 22
    var prefersExpandedLabel = false

    var body: some View {
        RoundedRectangle(cornerRadius: MindSenseRadius.pill, style: .continuous)
            .fill(segmentFill)
            .overlay(
                RoundedRectangle(cornerRadius: MindSenseRadius.pill, style: .continuous)
                    .stroke(MindSensePalette.strokeStrong.opacity(0.9), lineWidth: 1)
            )
            .overlay {
                overlayLabel
                    .padding(.horizontal, MindSenseSpacing.xs)
                    .padding(.vertical, MindSenseSpacing.xxxs)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(state.timelineDisplayTitle) segment")
    }

    private var segmentFill: Color {
        switch state {
        case .stable:
            return tint.opacity(0.92)
        case .activated:
            return tint.opacity(0.95)
        case .recovery:
            return tint.opacity(0.94)
        }
    }

    @ViewBuilder
    private var overlayLabel: some View {
        if prefersExpandedLabel {
            ViewThatFits(in: .horizontal) {
                labelRow(text: state.timelineDisplayTitle)
                labelRow(text: state.timelineShortCode)
                compactGlyph
            }
        } else {
            ViewThatFits(in: .horizontal) {
                labelRow(text: state.timelineShortCode)
                compactGlyph
            }
        }
    }

    private func labelRow(text: String) -> some View {
        HStack(spacing: MindSenseSpacing.xxxs) {
            Image(systemName: state.timelineSymbolName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text(text)
                .font(MindSenseTypography.micro)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(contentForeground)
        .frame(maxWidth: .infinity)
    }

    private var compactGlyph: some View {
        Image(systemName: state.timelineSymbolName)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(contentForeground)
            .frame(maxWidth: .infinity)
    }

    private var contentForeground: Color {
        switch state {
        case .stable:
            return .primary
        case .activated:
            return MindSensePalette.textPrimary.opacity(0.82)
        case .recovery:
            return MindSensePalette.onAccent
        }
    }
}

private struct TimelineStateLegendPill: View {
    let title: String
    let state: StressTimelineState
    let tint: Color

    var body: some View {
        HStack(spacing: MindSenseSpacing.xs) {
            Circle()
                .fill(tint)
                .frame(width: 12, height: 12)
                .overlay(
                    Image(systemName: state.timelineSymbolName)
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(MindSensePalette.onAccent)
                )
            Text(title)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
            Text(state.timelineShortCode)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(minHeight: MindSenseControlSize.minimumTapTarget)
        .padding(.horizontal, MindSenseSpacing.sm)
        .padding(.vertical, MindSenseSpacing.xxxs)
        .background(
            Capsule(style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) timeline state, code \(state.timelineShortCode)")
    }
}

private extension StressTimelineState {
    var timelineDisplayTitle: String {
        switch self {
        case .stable:
            return "Stable"
        case .activated:
            return "Activated"
        case .recovery:
            return "Recovery"
        }
    }

    var timelineShortCode: String {
        switch self {
        case .stable:
            return "S"
        case .activated:
            return "A"
        case .recovery:
            return "R"
        }
    }

    var timelineSymbolName: String {
        switch self {
        case .stable:
            return "pause.fill"
        case .activated:
            return "bolt.fill"
        case .recovery:
            return "arrow.counterclockwise"
        }
    }
}

private struct TodayEpisodeIntensitySheet: View {
    @Environment(\.dismiss) private var dismiss

    let episode: StressEpisodeRecord
    let higherThanPercentile: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Episode intensity \(episode.intensity)",
                                subtitle: "\(episode.start.formattedDateLabel()) \(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())"
                            )
                        )
                        Text("Episode intensity is based on deviation from baseline HR/HRV patterns plus duration.")
                            .font(MindSenseTypography.bodyStrong)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Higher values indicate stronger or longer activation spikes relative to your baseline. Use Load for overall daily strain.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Personal percentile",
                                subtitle: "Compared with your recent episodes."
                            )
                        )
                        if let higherThanPercentile {
                            Text("\(episode.intensity) = higher than your typical \(higherThanPercentile)% of episodes.")
                                .font(MindSenseTypography.bodyStrong)
                                .foregroundStyle(MindSensePalette.warning)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Track a few more episodes to personalize this percentile.")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Episode intensity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Episode intensity")
                }
            }
        }
        .mindSenseSheetPresentationChrome()
    }
}

struct TodayEpisodeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    let episode: StressEpisodeRecord
    let cognitivePrompt: String
    let recommendedDurationLabel: String
    let onSaveContext: (UUID, Set<String>, String) -> Void
    let onSaveFeedback: (UUID, StressEpisodeAttributionFeedback) -> Void
    let onStartRecommended: (StressEpisodeRecord) -> Void

    @State private var tags: Set<String>
    @State private var feedback: StressEpisodeAttributionFeedback?
    @State private var showEvidenceDetails = false

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private struct ConfounderQuickTag: Identifiable {
        let label: String
        let storedTag: String
        var id: String { storedTag }
    }

    private let confounderQuickTags: [ConfounderQuickTag] = [
        .init(label: "I'm sick", storedTag: "Illness"),
        .init(label: "I traveled", storedTag: "Travel"),
        .init(label: "I drank", storedTag: "Alcohol")
    ]

    init(
        episode: StressEpisodeRecord,
        cognitivePrompt: String,
        recommendedDurationLabel: String,
        onSaveContext: @escaping (UUID, Set<String>, String) -> Void,
        onSaveFeedback: @escaping (UUID, StressEpisodeAttributionFeedback) -> Void,
        onStartRecommended: @escaping (StressEpisodeRecord) -> Void
    ) {
        self.episode = episode
        self.cognitivePrompt = cognitivePrompt
        self.recommendedDurationLabel = recommendedDurationLabel
        self.onSaveContext = onSaveContext
        self.onSaveFeedback = onSaveFeedback
        self.onStartRecommended = onStartRecommended
        _tags = State(initialValue: Set(episode.userTags))
        _feedback = State(initialValue: episode.attributionFeedback)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: MindSenseSpacing.md) {
                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Episode summary",
                                subtitle: "\(episode.start.formattedDateLabel()) \(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())"
                            )
                        )

                        VStack(alignment: .leading, spacing: MindSenseSpacing.sm) {
                            infoRow(label: "State", value: "Activation spike • \(durationLabel)")
                            infoRow(label: "Likely driver", value: "\(episode.likelyDriver.title) (\(confidenceLabel))")
                            infoRow(label: "Body signals", value: bodySignalSummary)
                        }

                        Button {
                            if reduceMotion {
                                showEvidenceDetails.toggle()
                            } else {
                                withAnimation(MindSenseMotion.selection) {
                                    showEvidenceDetails.toggle()
                                }
                            }
                        } label: {
                            HStack(spacing: MindSenseSpacing.xs) {
                                Text(showEvidenceDetails ? "Hide why we flagged this" : "Why we flagged this")
                                    .font(MindSenseTypography.bodyStrong)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: MindSenseSpacing.xs)
                                Image(systemName: showEvidenceDetails ? "chevron.up" : "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                                    .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showEvidenceDetails ? "Hide why we flagged this" : "Why we flagged this")
                        .accessibilityHint(showEvidenceDetails ? "Collapses evidence details" : "Expands evidence details")

                        if showEvidenceDetails {
                            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                                evidenceRow(label: "Heart-rate evidence", value: heartRateEvidenceLine)
                                evidenceRow(label: "HRV pattern", value: hrvEvidenceLine)
                                evidenceRow(label: "Time-of-day typicality", value: timeOfDayEvidenceLine)
                                evidenceRow(label: "Movement level", value: movementEvidenceLine)
                            }
                            .padding(.top, 2)
                        }
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Was this accurate?",
                                subtitle: "Quick feedback that improves attribution quality."
                            )
                        )

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 132), spacing: MindSenseSpacing.sm)],
                            alignment: .leading,
                            spacing: MindSenseSpacing.sm
                        ) {
                            accuracyButton(title: "Looks right", value: .accurate)
                            accuracyButton(title: "Unsure", value: .unsure)
                            accuracyButton(title: "Not accurate", value: .inaccurate)
                        }

                        VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                            Text("Quick confounder tags")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                            Text("Signals can be influenced by illness, alcohol, travel, and sensor gaps.")
                                .font(MindSenseTypography.micro)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 120), spacing: MindSenseSpacing.xs)],
                                alignment: .leading,
                                spacing: MindSenseSpacing.xs
                            ) {
                                ForEach(confounderQuickTags) { item in
                                    Button {
                                        applyConfounderQuickTag(item)
                                    } label: {
                                        PillChip(
                                            label: item.label,
                                            state: tags.contains(item.storedTag) ? .selected : .unselected
                                        )
                                        .frame(minHeight: MindSenseControlSize.minimumTapTarget)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(item.label)
                                    .accessibilityValue(tags.contains(item.storedTag) ? "Selected" : "Not selected")
                                    .accessibilityHint("Marks this episode as influenced by \(item.storedTag.lowercased()) and saves context.")
                                }
                            }
                        }
                        .padding(.top, MindSenseSpacing.xs)

                        if feedback == .inaccurate {
                            VStack(alignment: .leading, spacing: MindSenseSpacing.xs) {
                                Text("What was it mostly?")
                                    .font(MindSenseTypography.caption)
                                    .foregroundStyle(.secondary)

                                FlexibleChipGrid(items: DemoHealthSignalEngine.contextTags, selectedItems: $tags) { item, isSelected in
                                    saveInaccurateAttributionTag(item: item, isSelected: isSelected)
                                }
                            }
                            .padding(.top, MindSenseSpacing.xs)
                        }

                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: MindSenseSpacing.xs) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption.weight(.semibold))
                                Text("Edit later")
                                    .font(MindSenseTypography.caption)
                            }
                            .foregroundStyle(.secondary)
                            .frame(minHeight: MindSenseControlSize.minimumTapTarget, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        Text("You can revisit attribution from Data > History.")
                            .font(MindSenseTypography.micro)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "What to do now",
                                subtitle: "One best next step based on this episode."
                            )
                        )

                        HStack(spacing: MindSenseSpacing.sm) {
                            Text(episode.recommendedPreset.title)
                                .font(MindSenseTypography.bodyStrong)
                            Spacer(minLength: MindSenseSpacing.xs)
                            Text(recommendedDurationLabel)
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, MindSenseSpacing.sm)
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

                        Text("Why now: rapid downshift helps interrupt carryover load into the next block.")
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("Start \(episode.recommendedPreset.title)") {
                            onStartRecommended(episode)
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: MindSenseControlSize.primaryButton))
                        .accessibilityHint("Starts the recommended protocol for this episode.")
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "What to think",
                                subtitle: "Short reframing prompt for this state."
                            )
                        )
                        Text(cognitivePrompt)
                            .font(MindSenseTypography.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            UIPasteboard.general.string = cognitivePrompt
                        } label: {
                            HStack(spacing: MindSenseSpacing.xs) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption.weight(.semibold))
                                Text("Copy prompt")
                                    .font(MindSenseTypography.micro)
                            }
                            .foregroundStyle(.secondary)
                            .frame(minHeight: MindSenseControlSize.minimumTapTarget, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Copies this prompt to the clipboard.")
                    }

                }
                .mindSenseSheetInsets()
            }
            .mindSensePageBackground()
            .navigationTitle("Episode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MindSenseNavTitleLockup(title: "Episode")
                }
            }
        }
        .accessibilityIdentifier("today_episode_detail_sheet_root")
        .mindSenseSheetPresentationChrome()
    }

    private var durationLabel: String {
        let minutes = max(1, Int(episode.end.timeIntervalSince(episode.start) / 60))
        return "\(minutes) min"
    }

    private var confidenceLabel: String {
        if episode.confidence >= 78 {
            return "high confidence"
        }
        if episode.confidence >= 62 {
            return "medium confidence"
        }
        return "low confidence"
    }

    private var bodySignalSummary: String {
        guard let evidence = episode.evidence else {
            return "Heart-rate elevation detected versus your baseline."
        }

        var fragments = ["HR +\(evidence.heartRateAboveBaselineBPM) bpm for \(evidence.elevatedDurationMinutes) min"]
        if let shift = evidence.hrvShiftMS {
            fragments.append("HRV \(hrvShiftLabel(shift))")
        }
        return fragments.joined(separator: " • ")
    }

    private var heartRateEvidenceLine: String {
        guard let evidence = episode.evidence else {
            return "Heart-rate elevation detected across \(durationLabel)."
        }
        return "HR above baseline band by +\(evidence.heartRateAboveBaselineBPM) bpm for \(evidence.elevatedDurationMinutes) min."
    }

    private var hrvEvidenceLine: String {
        guard let shift = episode.evidence?.hrvShiftMS else {
            return "HRV pattern was not used for this episode."
        }
        if shift == 0 {
            return "HRV stayed near baseline."
        }
        if shift < 0 {
            return "HRV dropped by \(abs(shift)) ms versus baseline."
        }
        return "HRV rose by \(shift) ms versus baseline."
    }

    private var timeOfDayEvidenceLine: String {
        guard let typicality = episode.evidence?.timeOfDayTypicality else {
            return "Time-of-day pattern is not available."
        }
        if typicality >= 75 {
            return "Typical timing for your recent spikes (\(typicality)% match)."
        }
        if typicality >= 50 {
            return "Moderately typical timing (\(typicality)% match)."
        }
        return "Less typical timing (\(typicality)% match)."
    }

    private var movementEvidenceLine: String {
        guard let level = episode.evidence?.movementLevel else {
            return "Movement level is not available."
        }
        return "\(level.title) movement during this spike."
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: MindSenseSpacing.md) {
            Text(label)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)

            Text(value)
                .font(MindSenseTypography.bodyStrong)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func evidenceRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: MindSenseSpacing.xxxs) {
            Text(label)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
                .tracking(0.7)
            Text(value)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func hrvShiftLabel(_ shift: Int) -> String {
        if shift == 0 {
            return "0 ms"
        }
        let sign = shift > 0 ? "+" : "-"
        return "\(sign)\(abs(shift)) ms"
    }

    private func saveInaccurateAttributionTag(item: String, isSelected: Bool) {
        if isSelected {
            tags = [item]
            onSaveContext(episode.id, tags, episode.userNote ?? "")
        } else {
            tags.remove(item)
        }
    }

    private func applyConfounderQuickTag(_ item: ConfounderQuickTag) {
        if feedback != .inaccurate {
            feedback = .inaccurate
            onSaveFeedback(episode.id, .inaccurate)
        }
        tags = [item.storedTag]
        onSaveContext(episode.id, tags, episode.userNote ?? "")
    }

    private func accuracyButton(
        title: String,
        value: StressEpisodeAttributionFeedback
    ) -> some View {
        let selected = feedback == value
        return Button {
            feedback = value
            onSaveFeedback(episode.id, value)
        } label: {
            HStack(spacing: MindSenseSpacing.xs) {
                Text(title)
                    .font(MindSenseTypography.bodyStrong)
                    .foregroundStyle(selected ? MindSensePalette.onAccent : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(MindSensePalette.onAccent)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: MindSenseControlSize.minimumTapTarget)
            .background(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .fill(selected ? MindSensePalette.accent : MindSenseSurfaceLevel.base.fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .stroke(selected ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityHint("Saves attribution feedback.")
    }
}

private extension Array where Element == StressEpisodeRecord {
    func higherThanPercent(for episode: StressEpisodeRecord) -> Int? {
        let comparisonPool = filter { $0.id != episode.id }
        guard !comparisonPool.isEmpty else { return nil }

        let lowerIntensityCount = comparisonPool.filter { $0.intensity < episode.intensity }.count
        let ratio = Double(lowerIntensityCount) / Double(comparisonPool.count)
        return Int((ratio * 100).rounded())
    }
}

private extension StressEpisodeRecord {
    var contextSummaryLine: String? {
        if let primaryContextTag, let secondaryContextTag {
            return "Primary: \(primaryContextTag) • Secondary: \(secondaryContextTag)"
        }
        if let primaryContextTag {
            return "Primary: \(primaryContextTag)"
        }
        if !userTags.isEmpty {
            return userTags.joined(separator: ", ")
        }
        if let userNote, !userNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return userNote
        }
        return nil
    }
}
