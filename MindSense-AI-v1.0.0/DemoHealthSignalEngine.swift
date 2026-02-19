import Foundation

enum DemoHealthSignalType: String, CaseIterable, Codable, Identifiable {
    case sleep
    case heartRate
    case hrv
    case restingHeartRate
    case workouts
    case activity
    case respiratoryRate
    case mindfulMinutes
    case environmentalAudio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep:
            return "Sleep"
        case .heartRate:
            return "Heart rate"
        case .hrv:
            return "HRV (SDNN)"
        case .restingHeartRate:
            return "Resting heart rate"
        case .workouts:
            return "Workouts"
        case .activity:
            return "Activity"
        case .respiratoryRate:
            return "Respiratory rate"
        case .mindfulMinutes:
            return "Mindful minutes"
        case .environmentalAudio:
            return "Environmental audio"
        }
    }
}

enum DemoHealthPermissionState: String, Codable {
    case granted
    case missing
    case unsupported

    var title: String {
        switch self {
        case .granted:
            return "Granted"
        case .missing:
            return "Missing"
        case .unsupported:
            return "Not supported"
        }
    }

    var statusIcon: String {
        switch self {
        case .granted:
            return "checkmark.circle.fill"
        case .missing:
            return "exclamationmark.triangle.fill"
        case .unsupported:
            return "xmark.circle.fill"
        }
    }
}

struct DemoHealthPermissionStatus: Identifiable, Codable, Equatable {
    let signal: DemoHealthSignalType
    var state: DemoHealthPermissionState

    var id: DemoHealthSignalType { signal }
}

struct DemoHealthSyncSnapshot: Codable, Equatable {
    var sourceLabel: String
    var lastSyncAt: Date
    var lastSleepImportAt: Date
    var lastHRVSampleAt: Date?
}

struct DemoHealthQualityBreakdown: Codable, Equatable {
    var sleepCoverage: Int
    var heartRateDensity: Int
    var hrvAvailability: Int
    var watchWear: Int
    var actionHint: String

    var score: Int {
        let weighted = (Double(sleepCoverage) * 0.34)
            + (Double(heartRateDensity) * 0.27)
            + (Double(hrvAvailability) * 0.22)
            + (Double(watchWear) * 0.17)
        return clampInt(Int(weighted.rounded()), min: 0, max: 100)
    }

    var diagnostics: [(String, Int)] {
        [
            ("Sleep coverage (7 nights)", sleepCoverage),
            ("Heart-rate density (24h)", heartRateDensity),
            ("HRV availability (7 days)", hrvAvailability),
            ("Watch wear continuity", watchWear)
        ]
    }
}

enum StressTimelineState: String, Codable {
    case stable
    case activated
    case recovery
}

struct StressTimelineSegment: Identifiable, Codable, Equatable {
    let id: UUID
    let start: Date
    let end: Date
    let state: StressTimelineState
}

enum StressEpisodeDriver: String, Codable, CaseIterable, Identifiable {
    case cognitive
    case physical
    case social
    case environmental

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cognitive:
            return "Cognitive"
        case .physical:
            return "Physical"
        case .social:
            return "Social"
        case .environmental:
            return "Environmental"
        }
    }
}

enum StressEpisodeAttributionFeedback: String, Codable, CaseIterable, Identifiable {
    case accurate
    case inaccurate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accurate:
            return "Accurate"
        case .inaccurate:
            return "Not accurate"
        }
    }
}

struct StressEpisodeRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let start: Date
    let end: Date
    let intensity: Int
    let confidence: Int
    let likelyDriver: StressEpisodeDriver
    let recommendedPreset: RegulatePresetID
    var userTags: [String]
    var userNote: String?
    var attributionFeedback: StressEpisodeAttributionFeedback? = nil

    var hasContext: Bool {
        !userTags.isEmpty || !(userNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}

struct DemoHealthProfile: Codable, Equatable {
    var isConnected: Bool
    var sync: DemoHealthSyncSnapshot
    var quality: DemoHealthQualityBreakdown
    var permissions: [DemoHealthPermissionStatus]
    var timelineSegments: [StressTimelineSegment]
    var stressEpisodes: [StressEpisodeRecord]

    var sortedEpisodes: [StressEpisodeRecord] {
        stressEpisodes.sorted(by: { $0.start > $1.start })
    }
}

enum DemoHealthSignalEngine {
    static let contextTags = [
        "Meeting",
        "Caffeine",
        "Workout",
        "Commute",
        "Conflict",
        "Noise",
        "Screen overload",
        "Unknown"
    ]

    static func seededProfile(
        for scenario: DemoScenario,
        demoDay: Int,
        now: Date = Date()
    ) -> DemoHealthProfile {
        let quality = baseQuality(for: scenario)
        let permissions = defaultPermissions(for: scenario)
        let episodes = seededEpisodes(for: scenario, now: now)
        let timeline = timelineSegments(for: episodes, now: now)
        return DemoHealthProfile(
            isConnected: true,
            sync: .init(
                sourceLabel: "Apple Watch (Demo)",
                lastSyncAt: now.addingTimeInterval(-480),
                lastSleepImportAt: now.addingTimeInterval(-4_500),
                lastHRVSampleAt: permissions.first(where: { $0.signal == .hrv })?.state == .granted
                    ? now.addingTimeInterval(-2_800)
                    : nil
            ),
            quality: adjustedQuality(quality, demoDay: demoDay),
            permissions: permissions,
            timelineSegments: timeline,
            stressEpisodes: episodes
        )
    }

    static func refreshedProfile(
        existing: DemoHealthProfile,
        scenario: DemoScenario,
        metrics: DemoMetricSnapshot,
        demoDay: Int,
        completedSessionCount: Int,
        activeExperimentAdherence: Int,
        now: Date = Date(),
        updateSyncTimestamp: Bool
    ) -> DemoHealthProfile {
        var profile = existing
        let baseline = adjustedQuality(baseQuality(for: scenario), demoDay: demoDay)

        let sessionBoost = min(completedSessionCount * 2, 10)
        let adherenceBoost = min(activeExperimentAdherence / 12, 8)
        let loadPenalty = max(0, (metrics.load - 72) / 4)

        profile.quality.sleepCoverage = clampInt(
            baseline.sleepCoverage + adherenceBoost - loadPenalty,
            min: 42,
            max: 99
        )
        profile.quality.heartRateDensity = clampInt(
            baseline.heartRateDensity + sessionBoost - (metrics.load > 86 ? 4 : 0),
            min: 48,
            max: 99
        )
        profile.quality.hrvAvailability = clampInt(
            baseline.hrvAvailability + (metrics.readiness > 74 ? 2 : -1),
            min: 28,
            max: 97
        )
        profile.quality.watchWear = clampInt(
            baseline.watchWear + (demoDay > 10 ? 2 : 0) - (metrics.consistency < 58 ? 3 : 0),
            min: 38,
            max: 99
        )
        profile.quality.actionHint = qualityActionHint(quality: profile.quality, permissions: profile.permissions)

        if updateSyncTimestamp {
            profile.sync.lastSyncAt = now
            profile.sync.lastSleepImportAt = now.addingTimeInterval(-2_400)
            let hrvGranted = profile.permissions.first(where: { $0.signal == .hrv })?.state == .granted
            profile.sync.lastHRVSampleAt = hrvGranted ? now.addingTimeInterval(-1_900) : nil
        }

        if profile.stressEpisodes.allSatisfy({ now.timeIntervalSince($0.end) > (3 * 3_600) }) {
            profile.stressEpisodes.insert(
                generatedEpisode(for: scenario, now: now),
                at: 0
            )
        }
        profile.stressEpisodes = Array(profile.sortedEpisodes.prefix(12))
        profile.timelineSegments = timelineSegments(for: profile.stressEpisodes, now: now)
        return profile
    }

    static func rebuiltDerivedProfile(
        existing: DemoHealthProfile,
        scenario: DemoScenario,
        demoDay: Int,
        now: Date = Date()
    ) -> DemoHealthProfile {
        var rebuilt = seededProfile(for: scenario, demoDay: demoDay, now: now)
        rebuilt.permissions = existing.permissions
        rebuilt.quality.actionHint = qualityActionHint(quality: rebuilt.quality, permissions: rebuilt.permissions)
        return rebuilt
    }

    static func deletingDerivedProfile(existing: DemoHealthProfile, now: Date = Date()) -> DemoHealthProfile {
        var profile = existing
        profile.stressEpisodes = []
        profile.timelineSegments = []
        profile.sync.lastSyncAt = now
        profile.quality.sleepCoverage = 35
        profile.quality.heartRateDensity = 30
        profile.quality.hrvAvailability = 22
        profile.quality.watchWear = 28
        profile.quality.actionHint = "Derived metrics cleared. Run Resync now to rebuild your state model."
        return profile
    }

    private static func defaultPermissions(for scenario: DemoScenario) -> [DemoHealthPermissionStatus] {
        let map: [DemoHealthSignalType: DemoHealthPermissionState] = switch scenario {
        case .highStressDay:
            [
                .sleep: .granted,
                .heartRate: .granted,
                .hrv: .missing,
                .restingHeartRate: .granted,
                .workouts: .granted,
                .activity: .granted,
                .respiratoryRate: .missing,
                .mindfulMinutes: .granted,
                .environmentalAudio: .unsupported
            ]
        case .balancedDay:
            [
                .sleep: .granted,
                .heartRate: .granted,
                .hrv: .granted,
                .restingHeartRate: .granted,
                .workouts: .granted,
                .activity: .granted,
                .respiratoryRate: .missing,
                .mindfulMinutes: .granted,
                .environmentalAudio: .unsupported
            ]
        case .recoveryWeek:
            [
                .sleep: .granted,
                .heartRate: .granted,
                .hrv: .granted,
                .restingHeartRate: .granted,
                .workouts: .granted,
                .activity: .granted,
                .respiratoryRate: .granted,
                .mindfulMinutes: .granted,
                .environmentalAudio: .unsupported
            ]
        }

        return DemoHealthSignalType.allCases.map { signal in
            .init(signal: signal, state: map[signal] ?? .missing)
        }
    }

    private static func baseQuality(for scenario: DemoScenario) -> DemoHealthQualityBreakdown {
        switch scenario {
        case .highStressDay:
            return .init(
                sleepCoverage: 72,
                heartRateDensity: 84,
                hrvAvailability: 48,
                watchWear: 68,
                actionHint: "Grant HRV permission to improve stress detection confidence."
            )
        case .balancedDay:
            return .init(
                sleepCoverage: 86,
                heartRateDensity: 82,
                hrvAvailability: 78,
                watchWear: 80,
                actionHint: "Wear your watch overnight to keep baseline confidence strong."
            )
        case .recoveryWeek:
            return .init(
                sleepCoverage: 90,
                heartRateDensity: 79,
                hrvAvailability: 86,
                watchWear: 88,
                actionHint: "Data quality is strong. Keep overnight wear consistent."
            )
        }
    }

    private static func adjustedQuality(_ quality: DemoHealthQualityBreakdown, demoDay: Int) -> DemoHealthQualityBreakdown {
        var adjusted = quality
        let baselineLift = clampInt(demoDay - 6, min: -4, max: 8)
        adjusted.sleepCoverage = clampInt(adjusted.sleepCoverage + baselineLift, min: 36, max: 99)
        adjusted.heartRateDensity = clampInt(adjusted.heartRateDensity + (baselineLift / 2), min: 36, max: 99)
        adjusted.hrvAvailability = clampInt(adjusted.hrvAvailability + (baselineLift / 2), min: 24, max: 98)
        adjusted.watchWear = clampInt(adjusted.watchWear + baselineLift, min: 30, max: 99)
        return adjusted
    }

    private static func seededEpisodes(for scenario: DemoScenario, now: Date) -> [StressEpisodeRecord] {
        switch scenario {
        case .highStressDay:
            return [
                .init(
                    id: UUID(),
                    start: now.addingTimeInterval(-4.8 * 3_600),
                    end: now.addingTimeInterval(-4.2 * 3_600),
                    intensity: 79,
                    confidence: 78,
                    likelyDriver: .cognitive,
                    recommendedPreset: .calmNow,
                    userTags: ["Meeting"],
                    userNote: "Stacked deadline handoff."
                ),
                .init(
                    id: UUID(),
                    start: now.addingTimeInterval(-2.4 * 3_600),
                    end: now.addingTimeInterval(-1.9 * 3_600),
                    intensity: 73,
                    confidence: 70,
                    likelyDriver: .social,
                    recommendedPreset: .calmNow,
                    userTags: [],
                    userNote: nil
                ),
                .init(
                    id: UUID(),
                    start: now.addingTimeInterval(-0.9 * 3_600),
                    end: now.addingTimeInterval(-0.2 * 3_600),
                    intensity: 84,
                    confidence: 76,
                    likelyDriver: .cognitive,
                    recommendedPreset: .focusPrep,
                    userTags: [],
                    userNote: nil
                )
            ]
        case .balancedDay:
            return [
                .init(
                    id: UUID(),
                    start: now.addingTimeInterval(-4.1 * 3_600),
                    end: now.addingTimeInterval(-3.6 * 3_600),
                    intensity: 56,
                    confidence: 69,
                    likelyDriver: .physical,
                    recommendedPreset: .calmNow,
                    userTags: ["Workout"],
                    userNote: "Lunch run."
                ),
                .init(
                    id: UUID(),
                    start: now.addingTimeInterval(-1.6 * 3_600),
                    end: now.addingTimeInterval(-0.9 * 3_600),
                    intensity: 63,
                    confidence: 71,
                    likelyDriver: .cognitive,
                    recommendedPreset: .focusPrep,
                    userTags: [],
                    userNote: nil
                )
            ]
        case .recoveryWeek:
            return [
                .init(
                    id: UUID(),
                    start: now.addingTimeInterval(-3.5 * 3_600),
                    end: now.addingTimeInterval(-2.8 * 3_600),
                    intensity: 44,
                    confidence: 74,
                    likelyDriver: .environmental,
                    recommendedPreset: .calmNow,
                    userTags: ["Commute"],
                    userNote: nil
                ),
                .init(
                    id: UUID(),
                    start: now.addingTimeInterval(-1.2 * 3_600),
                    end: now.addingTimeInterval(-0.5 * 3_600),
                    intensity: 51,
                    confidence: 68,
                    likelyDriver: .social,
                    recommendedPreset: .calmNow,
                    userTags: [],
                    userNote: nil
                )
            ]
        }
    }

    private static func generatedEpisode(for scenario: DemoScenario, now: Date) -> StressEpisodeRecord {
        let driver: StressEpisodeDriver = switch scenario {
        case .highStressDay: .cognitive
        case .balancedDay: .social
        case .recoveryWeek: .environmental
        }
        let intensity: Int = switch scenario {
        case .highStressDay: 78
        case .balancedDay: 62
        case .recoveryWeek: 49
        }
        let confidence: Int = switch scenario {
        case .highStressDay: 74
        case .balancedDay: 72
        case .recoveryWeek: 70
        }
        let recommendation: RegulatePresetID = scenario == .highStressDay ? .calmNow : .focusPrep

        return .init(
            id: UUID(),
            start: now.addingTimeInterval(-3_200),
            end: now.addingTimeInterval(-900),
            intensity: intensity,
            confidence: confidence,
            likelyDriver: driver,
            recommendedPreset: recommendation,
            userTags: [],
            userNote: nil
        )
    }

    private static func timelineSegments(for episodes: [StressEpisodeRecord], now: Date) -> [StressTimelineSegment] {
        let windowHours = 12
        let segmentDuration: TimeInterval = 3_600
        let start = now.addingTimeInterval(-Double(windowHours) * segmentDuration)
        let sortedEpisodes = episodes.sorted(by: { $0.start < $1.start })

        return (0..<windowHours).map { index in
            let segmentStart = start.addingTimeInterval(Double(index) * segmentDuration)
            let segmentEnd = segmentStart.addingTimeInterval(segmentDuration)
            let hasActivation = sortedEpisodes.contains {
                overlaps(startA: segmentStart, endA: segmentEnd, startB: $0.start, endB: $0.end)
            }
            let hasRecovery = sortedEpisodes.contains {
                let recoveryEnd = $0.end.addingTimeInterval(5_400)
                return overlaps(startA: segmentStart, endA: segmentEnd, startB: $0.end, endB: recoveryEnd)
            }

            let state: StressTimelineState = hasActivation ? .activated : (hasRecovery ? .recovery : .stable)
            return .init(
                id: UUID(),
                start: segmentStart,
                end: segmentEnd,
                state: state
            )
        }
    }

    private static func qualityActionHint(
        quality: DemoHealthQualityBreakdown,
        permissions: [DemoHealthPermissionStatus]
    ) -> String {
        if permissions.contains(where: { $0.signal == .hrv && $0.state != .granted }) {
            return "Grant HRV permission to improve stress episode confidence."
        }
        if permissions.contains(where: { $0.signal == .sleep && $0.state != .granted }) {
            return "Grant Sleep permission so readiness can be calibrated."
        }
        if quality.sleepCoverage < 68 {
            return "Wear your watch overnight for the next 3 nights."
        }
        if quality.heartRateDensity < 68 {
            return "Enable Background App Refresh to increase heart-rate coverage."
        }
        if quality.watchWear < 68 {
            return "Keep your watch on during the day to improve state updates."
        }
        return "Data quality is strong."
    }

    private static func overlaps(startA: Date, endA: Date, startB: Date, endB: Date) -> Bool {
        startA < endB && startB < endA
    }
}

private func clampInt(_ value: Int, min: Int, max: Int) -> Int {
    Swift.min(Swift.max(value, min), max)
}
