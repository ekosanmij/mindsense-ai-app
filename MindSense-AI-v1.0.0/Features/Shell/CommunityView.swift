import SwiftUI

private struct CommunityDrillCard: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let keySignals: [String]
    let moderationBanner: String
    let outcome: String
}

struct CommunityView: View {
    @EnvironmentObject private var store: MindSenseStore
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @AppStorage("appReduceMotion") private var appReduceMotion = false

    @State private var selectedCard: CommunityDrillCard?
    @State private var didAppear = false

    private var reduceMotion: Bool {
        appReduceMotion || accessibilityReduceMotion
    }

    private var drillDownCards: [CommunityDrillCard] {
        switch store.demoScenario {
        case .highStressDay:
            return [
                .init(
                    id: "high_stress_meeting_buffer",
                    title: "Meeting stack buffer protocol",
                    summary: "Members using 3-minute pre-meeting downshifts reported fewer late-day crashes.",
                    keySignals: [
                        "Average self-rated load shift: -5",
                        "Most cited trigger: stacked deadlines",
                        "Most repeated intervention: Calm now"
                    ],
                    moderationBanner: "Simulated moderation: reminders inserted for urgent-care and crisis boundaries.",
                    outcome: "Likely fit when your current load is above 70 and meetings are clustered."
                ),
                .init(
                    id: "high_stress_caffeine_timing",
                    title: "Late caffeine rollback thread",
                    summary: "Read-only synthesis of users replacing late caffeine with brief movement breaks.",
                    keySignals: [
                        "Reported sleep continuity improved in 4-7 days",
                        "Common challenge: 2 PM productivity dip",
                        "Frequent companion action: Focus prep before deep work"
                    ],
                    moderationBanner: "Simulated moderation: stimulant misuse prompts flagged and redirected to safety guidance.",
                    outcome: "Useful when afternoon strain rises after caffeine logs."
                )
            ]
        case .balancedDay:
            return [
                .init(
                    id: "balanced_precision_reset",
                    title: "Precision midday reset exchange",
                    summary: "Community members in stable weeks use one short reset to avoid slow trend drift.",
                    keySignals: [
                        "Average adherence: 74%",
                        "Top reported benefit: smoother afternoon transitions",
                        "Frequent check-in pattern: load remains <60"
                    ],
                    moderationBanner: "Simulated moderation: overtraining and self-criticism language softened by nudges.",
                    outcome: "Best when your day is stable and you want to keep volatility low."
                ),
                .init(
                    id: "balanced_focus_window",
                    title: "Morning focus window design",
                    summary: "Read-only walkthrough on protecting readiness windows before noon.",
                    keySignals: [
                        "Most common duration: 45-60 minutes",
                        "Users pairing Focus prep reported better task completion confidence",
                        "Drop-off risk: back-to-back notifications"
                    ],
                    moderationBanner: "Simulated moderation: productivity pressure language receives wellbeing prompts.",
                    outcome: "Useful when readiness stays high and you want higher output quality."
                )
            ]
        case .recoveryWeek:
            return [
                .init(
                    id: "recovery_evening_anchor",
                    title: "Evening anchor consistency circle",
                    summary: "Recovery-week members share read-only templates for low-friction wind-down routines.",
                    keySignals: [
                        "Top anchor: fixed low-light wind-down",
                        "Most repeated win: reduced rebound load next day",
                        "Best retention pattern: same start time nightly"
                    ],
                    moderationBanner: "Simulated moderation: sleep-disorder claims tagged with seek-professional-care reminder.",
                    outcome: "Best when consistency is your strongest lever and you want to protect it."
                ),
                .init(
                    id: "recovery_readiness_compound",
                    title: "Readiness compounding playbook",
                    summary: "Read-only examples of converting recovery gains into one intentional focus block.",
                    keySignals: [
                        "Typical protocol pairing: Focus prep + one deep-work sprint",
                        "Most cited risk: adding too much intensity too quickly",
                        "Most stable approach: alternate high-intent and low-load days"
                    ],
                    moderationBanner: "Simulated moderation: intensity-escalation advice gated with pacing warnings.",
                    outcome: "Works when readiness is high and load is under control."
                )
            ]
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MindSenseRhythm.section) {
                MindSenseCommandDeck(
                    label: AppIA.community,
                    title: "Community insights (read-only)",
                    detail: "Context-aware examples for \(store.demoScenario.title), safety moderated and read-only.",
                    metric: "Read-only"
                )
                .mindSenseStaggerEntrance(0, isPresented: didAppear, reduceMotion: reduceMotion)

                moderationStatusBlock
                    .mindSenseStaggerEntrance(1, isPresented: didAppear, reduceMotion: reduceMotion)

                drillDownCardsBlock
                    .mindSenseStaggerEntrance(2, isPresented: didAppear, reduceMotion: reduceMotion)

                savedInsightsBlock
                    .mindSenseStaggerEntrance(3, isPresented: didAppear, reduceMotion: reduceMotion)

                safetySupportBlock
                    .mindSenseStaggerEntrance(4, isPresented: didAppear, reduceMotion: reduceMotion)
            }
            .mindSensePageInsets()
        }
        .mindSensePageBackground()
        .navigationTitle(AppIA.community)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MindSenseNavTitleLockup(title: AppIA.community)
            }
            ToolbarItem(placement: .topBarTrailing) {
                ProfileAccessMenu()
            }
        }
        .sheet(item: $selectedCard) { card in
            NavigationStack {
                communityCardDetail(card: card)
            }
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            didAppear = true
            store.track(event: .screenView, surface: .community)
        }
    }

    private var moderationStatusBlock: some View {
        PrimarySurface(tone: .warning) {
            MindSenseSectionHeader(
                model: .init(
                    title: "Simulated moderation status",
                    subtitle: "Safety-first notices are injected for realism.",
                    icon: "checkmark.shield"
                )
            )

            InsetSurface {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        PillChip(label: "Safety banners active", selected: true)
                        PillChip(label: "Read-only mode", selected: true)
                    }
                    Text("Community suggestions are not medical care. Urgent risk always routes to direct support.")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var drillDownCardsBlock: some View {
        FocusSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Community cards",
                    subtitle: "Tap a card to open a drill-down summary.",
                    icon: "person.2.wave.2"
                )
            )

            ForEach(drillDownCards) { card in
                Button {
                    selectedCard = card
                    store.triggerHaptic(intent: .selection)
                    store.track(event: .secondaryActionTapped, surface: .community, action: "open_drill_down_card", metadata: ["id": card.id])
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        MindSenseIconBadge(systemName: "rectangle.stack.person.crop.fill", tint: MindSensePalette.signalCool, style: .filled, size: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.title)
                                .font(MindSenseTypography.bodyStrong)
                                .foregroundStyle(.primary)
                            Text(card.summary)
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Read-only drill-down")
                                .font(MindSenseTypography.micro)
                                .foregroundStyle(MindSensePalette.accent)
                                .tracking(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .fill(MindSenseSurfaceLevel.base.fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tile, style: .continuous)
                            .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var savedInsightsBlock: some View {
        GlassSurface {
            MindSenseSectionHeader(
                model: .init(
                    title: "Saved insights",
                    subtitle: "Revisit key recommendations and outcomes.",
                    icon: "bookmark"
                )
            )

            let insights = Array(store.savedInsightsForCommunity.prefix(5))
            if insights.isEmpty {
                Text("No saved insights yet. Complete a session or experiment to populate this list.")
                    .font(MindSenseTypography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(insight.title)
                                .font(MindSenseTypography.bodyStrong)
                            Spacer()
                            Text(insight.timestamp.formattedTimeLabel())
                                .font(MindSenseTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(insight.detail)
                            .font(MindSenseTypography.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                            .fill(MindSenseSurfaceLevel.base.fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MindSenseRadius.tight, style: .continuous)
                            .stroke(MindSensePalette.strokeSubtle, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var safetySupportBlock: some View {
        PrimarySurface(tone: .warning) {
            MindSenseSectionHeader(
                model: .init(
                    title: "Safety support",
                    subtitle: "Use direct care channels for urgent needs.",
                    icon: "cross.case"
                )
            )

            Text("Community content is read-only and not monitored for real-time intervention.")
                .font(MindSenseTypography.body)
                .foregroundStyle(.secondary)

            Button("Open crisis support (US 988)") {
                openCrisisSupport()
                store.triggerHaptic(intent: .warning)
                store.track(event: .secondaryActionTapped, surface: .community, action: "open_crisis_support")
            }
            .buttonStyle(MindSenseButtonStyle(hierarchy: .primary))
        }
    }

    @ViewBuilder
    private func communityCardDetail(card: CommunityDrillCard) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                MindSenseCommandDeck(
                    label: AppIA.community,
                    title: card.title,
                    detail: card.summary,
                    metric: "Read-only"
                )

                PrimarySurface(tone: .warning) {
                    Text(card.moderationBanner)
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                FocusSurface {
                    MindSenseSectionHeader(model: .init(title: "Key signals", icon: "waveform.path.ecg"))
                    ForEach(card.keySignals, id: \.self) { signal in
                        Text("• \(signal)")
                            .font(MindSenseTypography.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                GlassSurface {
                    MindSenseSectionHeader(model: .init(title: "What this means now", icon: "lightbulb.max"))
                    Text(card.outcome)
                        .font(MindSenseTypography.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Next best action: \(store.primaryRecommendation.summaryLine)")
                        .font(MindSenseTypography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .mindSenseSheetInsets()
        }
        .mindSensePageBackground()
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MindSenseNavTitleLockup(title: "Details")
            }
        }
    }

    private func openCrisisSupport() {
        if let tel = URL(string: "tel://988") {
            openURL(tel)
        }
    }
}
