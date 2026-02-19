import SwiftUI
import UIKit

struct TodayView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    @State private var loadSlider = 4.0
    @State private var didAppear = false
    @State private var showHeroWhy = false
    @State private var showActionDetails = false
    @State private var showAllDrivers = false
    @State private var showSecondarySignals = false
    @State private var showModelDetails = false
    @State private var checkInJustSaved = false
    @State private var showSignalSourceDetails = false
    @State private var showTimelineDetails = false
    @State private var selectedTimelineEpisode: StressEpisodeRecord?
    @State private var focusedContextEpisodeID: UUID?
    @State private var contextTags: Set<String> = []
    @State private var contextNote = ""

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
            return store.activeRegulateSession?.isAwaitingCheckIn == true
                ? "Continue: Record impact"
                : "Continue: \(store.activeRegulateSession?.preset.title ?? recommendation.preset.title) session"
        }
        return "Start \(recommendation.preset.title) (\(recommendation.timeMinutes) min)"
    }

    private var bottomContentPadding: CGFloat {
        16
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
                        actionBlock
                            .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)
                        timelineBlock
                            .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)
                        if episodeAwaitingContext != nil {
                            contextCaptureBlock
                                .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)
                        }
                        driversBlock
                            .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
                        statusSnapshotBlock
                            .mindSenseStaggerEntrance(5, isPresented: didAppear, reduceMotion: reduceMotion)
                        checkInBlock
                            .mindSenseStaggerEntrance(6, isPresented: didAppear, reduceMotion: reduceMotion)
                    }
                    .mindSensePageInsets(bottom: bottomContentPadding)
                }
            }
            .mindSensePageBackground()
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
            .sheet(isPresented: $showModelDetails) {
                TodayModelDetailsSheet(
                    confidenceStatusLine: store.confidenceStatusLine,
                    coveragePercent: store.demoDataCoveragePercent,
                    confidencePercent: store.confidencePercent,
                    lastUpdatedLabel: store.lastUpdatedLabel
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
            .sheet(isPresented: $showTimelineDetails) {
                TodayTimelineDetailSheet(
                    episodes: store.recentStressEpisodes,
                    timelineSegments: store.stressTimelineSegments,
                    onSelectEpisode: { episode in
                        selectedTimelineEpisode = episode
                        store.triggerHaptic(intent: .selection)
                    }
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
            .onAppear {
                let firstAppearance = !didAppear
                if firstAppearance {
                    didAppear = true
                }
                loadSlider = Double(max(0, min(10, store.demoMetrics.load / 10)))
                store.prepareCoreScreen(.today)
                if firstAppearance {
                    store.track(event: .screenView, surface: .today)
                }
            }
            .onChange(of: store.demoScenario) { _, _ in
                store.prepareCoreScreen(.today)
                loadSlider = Double(max(0, min(10, store.demoMetrics.load / 10)))
                focusedContextEpisodeID = nil
                contextTags = []
                contextNote = ""
            }
        }
        .accessibilityIdentifier("today_screen_root")
    }

    private var commandDeck: some View {
        PrimarySurface(tone: .accent) {
            Text("STATE NOW")
                .font(MindSenseTypography.micro)
                .foregroundStyle(MindSensePalette.signalCoolStrong)
                .tracking(1.2)

            Button {
                showSignalSourceDetails = true
                store.triggerHaptic(intent: .selection)
            } label: {
                HStack(spacing: 8) {
                    Text(store.healthSourceStatusLine)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "info.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            HStack(spacing: MindSenseSpacing.xs) {
                heroDeltaTile(
                    title: "Load Δ",
                    value: heroDelta.load,
                    tint: deltaTint(metric: .load, value: heroDelta.load)
                )
                heroDeltaTile(
                    title: "Readiness Δ",
                    value: heroDelta.readiness,
                    tint: deltaTint(metric: .readiness, value: heroDelta.readiness)
                )
                heroDeltaTile(
                    title: "Consistency Δ",
                    value: heroDelta.consistency,
                    tint: deltaTint(metric: .consistency, value: heroDelta.consistency)
                )
            }

            Text(heroInterpretation)
                .font(MindSenseTypography.display)
                .fixedSize(horizontal: false, vertical: true)

            Text(heroReferenceLabel)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if reduceMotion {
                    showHeroWhy.toggle()
                } else {
                    withAnimation(MindSenseMotion.selection) {
                        showHeroWhy.toggle()
                    }
                }
                store.triggerHaptic(intent: .selection)
            } label: {
                HStack(spacing: MindSenseSpacing.xs) {
                    Text("Why this state")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: MindSenseSpacing.xs)
                    Image(systemName: showHeroWhy ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44)
                .padding(.horizontal, 12)
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

            if showHeroWhy {
                Text(heroWhyDetail)
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .overlay(alignment: .topTrailing) {
            MindSenseLogoWatermark(height: 128, tint: MindSensePalette.accent)
                .padding(.top, 8)
                .padding(.trailing, 2)
        }
    }

    private var statusSnapshotBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Current state",
                    subtitle: "Updated \(store.lastUpdatedLabel).",
                    icon: "heart.text.square"
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Load \(store.demoMetrics.load) (\(loadStateLabel))  •  Readiness \(store.demoMetrics.readiness) (\(readinessStateLabel))")
                    .font(MindSenseTypography.bodyStrong)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Consistency \(store.demoMetrics.consistency) (\(consistencyStateLabel))")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }

            if let delta = store.latestCheckInDeltaSummary {
                Text("Since \(delta.baselineTitle): Load \(signed(delta.loadDelta)), Readiness \(signed(delta.readinessDelta)).")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Save your first check-in to unlock day-over-day changes.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            }

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

    private var driversBlock: some View {
        PrimarySurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Top drivers now",
                    subtitle: "The strongest factors shaping your state now.",
                    icon: "bolt.heart"
                )
            )

            VStack(spacing: 10) {
                ForEach(visibleDrivers) { driver in
                    DriverImpactRowView(driver: driver)
                }
            }

            if store.todayPrimaryDrivers.count > 2 {
                Button(showAllDrivers ? "Show fewer drivers" : "See all drivers") {
                    showAllDrivers.toggle()
                    store.triggerHaptic(intent: .selection)
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            }

            if !store.todaySecondaryDrivers.isEmpty {
                MindSenseSectionDivider(emphasis: 0.28)
                DisclosureGroup(isExpanded: $showSecondarySignals) {
                    VStack(alignment: .leading, spacing: 8) {
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

    private var actionBlock: some View {
        PrimarySurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Your best next step",
                    subtitle: "Do this now.",
                    icon: "scope"
                )
            )

            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 8) {
                    MindSenseIconBadge(
                        systemName: presetIcon(for: recommendation.preset),
                        tint: MindSensePalette.accent,
                        style: .filled,
                        size: 28
                    )
                    Text(recommendation.preset.title)
                        .font(MindSenseTypography.bodyStrong)
                }
                Spacer()
                PillChip(label: "\(recommendation.timeMinutes) min", state: .unselected)
            }

            Text("Reason: \(recommendation.why)")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Expected effect: \(recommendation.expectedEffect)")
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Button(inlineActionLabel) {
                triggerNextBestAction(source: "today_action_card_cta")
            }
            .accessibilityIdentifier("today_action_card_cta")
            .buttonStyle(
                MindSenseButtonStyle(
                    hierarchy: hasUnfinishedRegulateStep ? .secondary : .primary,
                    minHeight: 52
                )
            )

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
                    Text("See details")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: MindSenseSpacing.xs)
                    Image(systemName: showActionDetails ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44)
                .padding(.horizontal, 12)
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

            if showActionDetails {
                VStack(alignment: .leading, spacing: 8) {
                    actionDetailRow(label: "Protocol", value: recommendation.what)
                    actionDetailRow(label: "Estimate", value: store.whatIfPreviewLine)
                }
            }
        }
    }

    private var timelineBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Today timeline",
                    subtitle: "Stress episodes and recovery windows inferred from recent signals.",
                    icon: "clock.arrow.circlepath"
                )
            )

            if store.stressTimelineSegments.isEmpty {
                Text("No stress timeline available yet. Resync health data in Settings.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            } else {
                timelineSegmentBar

                HStack(spacing: 8) {
                    timelineLegendPill(title: "Stable", state: .stable)
                    timelineLegendPill(title: "Activated", state: .activated)
                    timelineLegendPill(title: "Recovery", state: .recovery)
                }
            }

            if store.recentStressEpisodes.isEmpty {
                Text("No detected episodes yet.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.recentStressEpisodes.prefix(3)) { episode in
                        stressEpisodeRow(episode)
                    }
                }
            }

            Button("View timeline details") {
                showTimelineDetails = true
                store.triggerHaptic(intent: .selection)
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
        }
    }

    private var timelineSegmentBar: some View {
        HStack(spacing: 5) {
            ForEach(store.stressTimelineSegments) { segment in
                RoundedRectangle(cornerRadius: MindSenseRadius.pill, style: .continuous)
                    .fill(timelineTint(for: segment.state))
                    .frame(maxWidth: .infinity)
                    .frame(height: 10)
            }
        }
        .padding(.vertical, 2)
    }

    private func timelineLegendPill(title: String, state: StressTimelineState) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(timelineTint(for: state))
                .frame(width: 8, height: 8)
            Text(title)
                .font(MindSenseTypography.micro)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(MindSenseSurfaceLevel.base.fill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
        )
    }

    private func stressEpisodeRow(_ episode: StressEpisodeRecord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            MindSenseIconBadge(
                systemName: "waveform.path.ecg",
                tint: timelineTint(for: .activated),
                style: .filled,
                size: 28
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                    Text("Intensity \(episode.intensity)")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(MindSensePalette.warning)
                        .tracking(0.6)
                }

                Text("\(episode.likelyDriver.title) driver • confidence \(episode.confidence)%")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if episode.hasContext {
                    let contextSummary = episode.userTags.isEmpty
                        ? (episode.userNote ?? "Note captured")
                        : episode.userTags.joined(separator: ", ")
                    Text("Context captured: \(contextSummary)")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(MindSensePalette.success)
                        .lineLimit(1)
                } else {
                    Button("Add context") {
                        focusContextCapture(for: episode)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }

                if let feedback = episode.attributionFeedback {
                    Text("Attribution review: \(feedback.title)")
                        .font(MindSenseTypography.micro)
                        .foregroundStyle(MindSensePalette.accent)
                }

                Button("View details") {
                    selectedTimelineEpisode = episode
                    store.triggerHaptic(intent: .selection)
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
            }
            Spacer(minLength: 8)

            PillChip(label: episode.recommendedPreset.title, state: .unselected)
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
                        subtitle: "Label one context signal to improve future attribution.",
                        icon: "text.bubble"
                    )
                )

                Text("Episode \(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)

                FlexibleChipGrid(items: DemoHealthSignalEngine.contextTags, selectedItems: $contextTags) { _, _ in
                    store.triggerHaptic(intent: .selection)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom context")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)

                    TextField("Type a context label…", text: $contextNote)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
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
                        focusedContextEpisodeID = nil
                        contextTags = []
                        contextNote = ""
                        store.triggerHaptic(intent: .selection)
                    }
                    .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                }

                Button("Save context") {
                    saveContext(for: episode.id)
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                .disabled(contextSaveDisabled)
            }
        }
    }

    private var checkInBlock: some View {
        InsetSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Quick check-in",
                    subtitle: "Capture load now to keep tomorrow's recommendation accurate.",
                    icon: "checkmark.circle"
                )
            )

            HStack(spacing: 8) {
                MindSenseIconBadge(systemName: "dial.low.fill", tint: checkInTint, style: .filled, size: 28)
                Text("Load now: \(Int(loadSlider.rounded())) / 10 (\(checkInLabel))")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(checkInJustSaved ? "Saved" : "Save check-in") {
                    saveCheckIn()
                }
                .buttonStyle(MindSenseButtonStyle(hierarchy: .secondary, fullWidth: false, minHeight: 40))
                .disabled(checkInJustSaved)
            }

            DisclosureGroup("Adjust load score") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How does your current load feel?")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                Slider(value: $loadSlider, in: 0...10, step: 1)
                    .tint(MindSensePalette.warning)

                HStack {
                    Text("Calm")
                    Spacer()
                    Text("High")
                }
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                }
            }
            .font(MindSenseTypography.caption)

            if needsEscalationGuidance {
                EscalationGuidanceView(context: .sustainedHighLoad)
            }
        }
    }

    private var primarySessionCTA: some View {
        MindSenseBottomActionDock {
            Button(store.activeRegulateSession?.isAwaitingCheckIn == true ? "Record impact" : "Continue session") {
                triggerNextBestAction(source: "today_sticky_cta")
            }
            .accessibilityIdentifier("today_primary_cta")
            .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 42))
        }
    }

    private func actionDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
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
        contextNote = episode.userNote ?? ""
        store.triggerHaptic(intent: .selection)
    }

    private func saveContext(for episodeID: UUID) {
        persistEpisodeContext(
            episodeID: episodeID,
            tags: contextTags,
            note: contextNote,
            shouldResetInlineCapture: true
        )
    }

    private func persistEpisodeContext(
        episodeID: UUID,
        tags: Set<String>,
        note: String,
        shouldResetInlineCapture: Bool
    ) {
        store.saveStressEpisodeContext(
            episodeID: episodeID,
            tags: tags,
            note: note
        )
        if shouldResetInlineCapture {
            focusedContextEpisodeID = nil
            contextTags = []
            contextNote = ""
            store.triggerHaptic(intent: .success)
        }
        if let updated = store.recentStressEpisodes.first(where: { $0.id == episodeID }) {
            selectedTimelineEpisode = updated
        }
    }

    private func saveCheckIn() {
        store.saveTodayCheckIn(loadScore: Int(loadSlider.rounded()), tags: [], showFeedback: false)
        store.triggerHaptic(intent: .success)
        checkInJustSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            checkInJustSaved = false
        }
    }

    private var visibleDrivers: [DriverImpact] {
        showAllDrivers ? store.todayPrimaryDrivers : Array(store.todayPrimaryDrivers.prefix(2))
    }

    private var loadStateLabel: String {
        store.demoMetrics.load >= 70 ? "Elevated" : "Managed"
    }

    private var readinessStateLabel: String {
        store.demoMetrics.readiness >= 70 ? "Ready" : "Recovering"
    }

    private var consistencyStateLabel: String {
        store.demoMetrics.consistency >= 70 ? "Steady" : "Variable"
    }

    private func triggerNextBestAction(source: String) {
        if hasUnfinishedRegulateStep {
            store.resumeWhereLeftOff()
            store.track(event: .primaryCTATapped, surface: .today, action: "resume_where_left_off", metadata: ["source": source])
        } else {
            store.openRegulatePreset(recommendation.preset, startImmediately: true)
            store.track(
                event: .primaryCTATapped,
                surface: .today,
                action: "start_mapped_\(recommendation.preset.rawValue)",
                metadata: ["source": source]
            )
        }
        store.triggerHaptic(intent: .primary)
    }

    private func startEpisodeRecommendation(_ episode: StressEpisodeRecord, source: String) {
        store.openRegulatePreset(episode.recommendedPreset, startImmediately: true)
        store.track(
            event: .primaryCTATapped,
            surface: .today,
            action: "episode_recommendation_start_\(episode.recommendedPreset.rawValue)",
            metadata: ["source": source, "episode_id": episode.id.uuidString]
        )
        store.triggerHaptic(intent: .primary)
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
        if let delta = store.latestCheckInDeltaSummary {
            return "Change since \(delta.baselineTitle)"
        }
        return "Change vs baseline"
    }

    private var heroInterpretation: String {
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

    private func heroDeltaTile(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(MindSenseTypography.caption)
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(signed(value))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
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
            return "calm"
        case 4...6:
            return "steady"
        case 7...8:
            return "elevated"
        default:
            return "high"
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

private struct TodayModelDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let confidenceStatusLine: String
    let coveragePercent: Int
    let confidencePercent: Int
    let lastUpdatedLabel: String

    var body: some View {
        NavigationStack {
            ScrollView {
                InsetSurface {
                    MindSenseSectionHeader(
                        model: .init(
                            title: "Model details",
                            subtitle: "Diagnostics stay available without taking over the main dashboard."
                        )
                    )
                    VStack(alignment: .leading, spacing: 10) {
                        detailRow(label: "Confidence", value: "\(confidencePercent)%")
                        detailRow(label: "Coverage", value: "\(coveragePercent)%")
                        detailRow(label: "Last updated", value: lastUpdatedLabel)
                        Text(confidenceStatusLine)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
}

private struct TodaySignalSourceSheet: View {
    @Environment(\.dismiss) private var dismiss

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
                VStack(spacing: 14) {
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
                        infoRow(label: "Data quality", value: "\(qualityScore)")
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Permissions",
                                subtitle: "Requested Apple Health data types."
                            )
                        )

                        ForEach(permissions) { permission in
                            HStack(spacing: 10) {
                                Image(systemName: permission.state.statusIcon)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(permissionTint(for: permission.state))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(permission.signal.title)
                                        .font(MindSenseTypography.bodyStrong)
                                    Text(permission.state.title)
                                        .font(MindSenseTypography.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Data quality diagnostics",
                                subtitle: "Coverage checks driving confidence."
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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

private struct TodayTimelineDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    private enum DayFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"

        var id: String { rawValue }
    }

    let episodes: [StressEpisodeRecord]
    let timelineSegments: [StressTimelineSegment]
    let onSelectEpisode: (StressEpisodeRecord) -> Void

    @State private var dayFilter: DayFilter = .today

    private var filteredEpisodes: [StressEpisodeRecord] {
        let calendar = Calendar.current
        return episodes.filter { episode in
            switch dayFilter {
            case .today:
                return calendar.isDateInToday(episode.end)
            case .yesterday:
                return calendar.isDateInYesterday(episode.end)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
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
                            HStack(spacing: 5) {
                                ForEach(timelineSegments) { segment in
                                    RoundedRectangle(cornerRadius: MindSenseRadius.pill, style: .continuous)
                                        .fill(timelineTint(for: segment.state))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 10)
                                }
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
                                subtitle: "Tap an episode to review trigger context and next action."
                            )
                        )

                        if filteredEpisodes.isEmpty {
                            Text("No episodes detected for \(dayFilter.rawValue.lowercased()).")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(filteredEpisodes) { episode in
                                Button {
                                    onSelectEpisode(episode)
                                    dismiss()
                                } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Text("\(episode.start.formattedDateLabel()) \(episode.start.formattedTimeLabel())-\(episode.end.formattedTimeLabel())")
                                                    .font(MindSenseTypography.caption)
                                                    .foregroundStyle(.secondary)
                                                Spacer()
                                                Text("Intensity \(episode.intensity)")
                                                    .font(MindSenseTypography.micro)
                                                    .foregroundStyle(MindSensePalette.warning)
                                            }
                                            Text("\(episode.likelyDriver.title) • confidence \(episode.confidence)%")
                                                .font(MindSenseTypography.bodyStrong)
                                                .foregroundStyle(.primary)
                                                .fixedSize(horizontal: false, vertical: true)
                                            if episode.hasContext {
                                                let tags = episode.userTags.isEmpty ? "Note captured" : episode.userTags.joined(separator: ", ")
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
                                }
                                .buttonStyle(.plain)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
}

private struct TodayEpisodeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let episode: StressEpisodeRecord
    let cognitivePrompt: String
    let recommendedDurationLabel: String
    let onSaveContext: (UUID, Set<String>, String) -> Void
    let onSaveFeedback: (UUID, StressEpisodeAttributionFeedback) -> Void
    let onStartRecommended: (StressEpisodeRecord) -> Void

    @State private var tags: Set<String>
    @State private var note: String
    @State private var feedback: StressEpisodeAttributionFeedback?

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
        _note = State(initialValue: episode.userNote ?? "")
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
                            infoRow(label: "Body signal", value: "Heart-rate elevation versus your baseline.")
                        }
                    }

                    FocusSurface {
                        MindSenseSectionHeader(model: contextHeaderModel)

                        FlexibleChipGrid(items: DemoHealthSignalEngine.contextTags, selectedItems: $tags) { _, _ in
                            // Selection feedback is triggered by the parent flow.
                        }

                        VStack(alignment: .leading, spacing: MindSenseSpacing.xxs) {
                            Text("Custom context")
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: MindSenseSpacing.xs) {
                                TextField("Type a context label…", text: $note)
                                    .textInputAutocapitalization(.sentences)
                                    .disableAutocorrection(false)

                                if !trimmedNote.isEmpty {
                                    Button {
                                        note = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Clear custom context")
                                }
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                                    .fill(MindSenseSurfaceLevel.base.fill)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                                    .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                            )
                        }

                        Button("Save context") {
                            onSaveContext(episode.id, tags, note)
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
                        .disabled(!hasContextDraft)
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
                                .padding(.horizontal, 12)
                                .frame(minHeight: 30)
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
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .primary, minHeight: 52))
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
                            Label("Copy prompt", systemImage: "doc.on.doc")
                                .font(MindSenseTypography.caption)
                        }
                        .buttonStyle(MindSenseButtonStyle(hierarchy: .text, fullWidth: false))
                    }

                    InsetSurface {
                        MindSenseSectionHeader(
                            model: .init(
                                title: "Was this accurate?",
                                subtitle: "This helps tune episode attribution quality."
                            )
                        )

                        HStack(spacing: 10) {
                            feedbackButton(title: "Accurate", icon: "hand.thumbsup.fill", value: .accurate)
                            feedbackButton(title: "Not accurate", icon: "hand.thumbsdown.fill", value: .inaccurate)
                        }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasContextDraft: Bool {
        !tags.isEmpty || !trimmedNote.isEmpty
    }

    private var contextHeaderModel: SectionHeaderModel {
        SectionHeaderModel(
            title: "What might have triggered this?",
            subtitle: "Add one context tag to improve attribution over time.",
            actionTitle: hasContextDraft ? "Clear" : nil,
            action: hasContextDraft ? { clearContextDraft() } : nil
        )
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

    private func clearContextDraft() {
        tags = []
        note = ""
    }

    private func feedbackButton(
        title: String,
        icon: String,
        value: StressEpisodeAttributionFeedback
    ) -> some View {
        let selected = feedback == value
        return Button {
            feedback = value
            onSaveFeedback(episode.id, value)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(title)
                    .font(MindSenseTypography.caption)
            }
            .foregroundStyle(selected ? MindSensePalette.signalCoolStrong : .secondary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .fill(selected ? MindSensePalette.accentMuted : MindSenseSurfaceLevel.base.fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                    .stroke(selected ? MindSensePalette.strokeEdge : MindSensePalette.strokeSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
