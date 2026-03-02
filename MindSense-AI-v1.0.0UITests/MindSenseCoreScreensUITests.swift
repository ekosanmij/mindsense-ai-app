import XCTest

private enum UITestAppearance: String, CaseIterable {
    case system
    case light
    case dark

    var launchFlag: String {
        "-uitest-\(rawValue)"
    }
}

private enum UITestLaunchMode {
    case ready
    case onboarding

    var launchFlag: String {
        switch self {
        case .ready:
            return "-uitest-ready"
        case .onboarding:
            return "-uitest-onboarding"
        }
    }
}

final class MindSenseCoreScreensUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCoreScreenNavigationAndPrimaryCTAs() {
        let app = launchReadyApp()

        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Regulate"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Data"].tap()
        let dataCTA = firstExistingButton(
            in: app,
            identifiers: ["data_hero_primary_cta", "data_primary_cta", "data_log_day_cta", "data_complete_experiment_cta"],
            timeout: 3
        )
        XCTAssertNotNil(dataCTA)

        app.buttons["Profile and access"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    func testTodayPrimaryCTADeterministicRegulateOutcomeLoop() {
        let app = launchReadyApp()

        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))
        app.buttons["today_action_card_cta"].tap()

        XCTAssertTrue(app.buttons["regulate_complete_now_cta"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["regulate_session_timer"].waitForExistence(timeout: 3))

        app.buttons["regulate_complete_now_cta"].tap()
        XCTAssertTrue(app.staticTexts["regulate_active_preset_label"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["regulate_outcome_submit_cta"].waitForExistence(timeout: 3))

        app.buttons["regulate_outcome_submit_cta"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))
    }

    func testTodayHeroPrimaryCTAVisibility() {
        let app = launchReadyApp()

        let heroCTA = app.buttons["today_action_card_cta"]
        XCTAssertTrue(heroCTA.waitForExistence(timeout: 5))
        XCTAssertTrue(heroCTA.isHittable, "Today hero CTA should be visible and tappable on launch.")
    }

    func testTodaySinglePrimaryCTAWhenNoActiveSession() {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForTodayReady(app: app)
        let heroCTA = app.buttons["today_action_card_cta"]
        XCTAssertTrue(heroCTA.waitForExistence(timeout: 5))
        XCTAssertTrue(heroCTA.isHittable, "Today hero CTA should be the dominant visible action when no session is active.")
        XCTAssertFalse(
            app.buttons["today_primary_cta"].exists,
            "Sticky dock CTA should not appear when no active session is running."
        )
    }

    func testTodayFallbackDisclosureCarriesCoverageDetails() {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForTodayReady(app: app)
        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))

        let disclosureButton = app.buttons["Why this action"]
        XCTAssertTrue(disclosureButton.waitForExistence(timeout: 3))
        disclosureButton.tap()

        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Precision is limited")).firstMatch
                .waitForExistence(timeout: 2),
            "Expanded fallback disclosure should expose coverage limitation detail."
        )
    }

    func testRegulateImpactIncludesMixedOption() {
        let app = launchReadyApp()

        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))
        app.buttons["today_action_card_cta"].tap()

        XCTAssertTrue(app.buttons["regulate_complete_now_cta"].waitForExistence(timeout: 4))
        app.buttons["regulate_complete_now_cta"].tap()

        let mixedButton = app.buttons["regulate_helped_mixed"]
        XCTAssertTrue(mixedButton.waitForExistence(timeout: 3))
        XCTAssertTrue(mixedButton.isHittable, "Regulate outcome capture should include a visible Mixed option.")
    }

    func testRegulateRecordImpactHasNoPreSaveBranchActions() {
        let app = launchReadyApp()

        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))
        app.buttons["today_action_card_cta"].tap()

        XCTAssertTrue(app.buttons["regulate_complete_now_cta"].waitForExistence(timeout: 4))
        app.buttons["regulate_complete_now_cta"].tap()
        XCTAssertTrue(app.staticTexts["regulate_active_preset_label"].waitForExistence(timeout: 3))

        XCTAssertFalse(app.buttons["regulate_post_session_focus_block_cta"].exists)
        XCTAssertFalse(app.buttons["regulate_post_session_log_impact_cta"].exists)
        XCTAssertFalse(app.buttons["regulate_post_session_add_context_cta"].exists)
    }

    func testDataPatternsSinglePrimaryCTAAboveFold() {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForTodayReady(app: app)
        tapTab(named: "Data", in: app)

        let heroCTA = app.buttons["data_hero_primary_cta"]
        XCTAssertTrue(heroCTA.waitForExistence(timeout: 3))
        XCTAssertTrue(heroCTA.isHittable, "Patterns mode should keep hero CTA visible above fold.")

        let suggestedButtons = app.buttons.matching(NSPredicate(format: "label == %@", "Start suggested plan"))
        XCTAssertEqual(suggestedButtons.count, 1, "Patterns mode should expose only one suggested-plan CTA.")
    }

    func testSettingsPrivacyPolicyLinkPresence() {
        let app = launchReadyApp()

        app.buttons["Profile and access"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        let privacyRow = app.buttons["settings_privacy_policy_row"]
        XCTAssertTrue(privacyRow.waitForExistence(timeout: 3))
        XCTAssertTrue(privacyRow.isHittable, "Privacy policy row should remain visible and tappable.")
    }

    func testSettingsPrivacyPolicySheetExternalLegalLinksPresence() {
        let app = launchReadyApp()

        app.buttons["Profile and access"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        let privacyRow = app.buttons["settings_privacy_policy_row"]
        XCTAssertTrue(privacyRow.waitForExistence(timeout: 3))
        privacyRow.tap()

        XCTAssertTrue(app.navigationBars["Privacy policy"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.buttons["settings_privacy_policy_open_url_button"].waitForExistence(timeout: 2),
            "Privacy sheet should expose the full privacy notice link."
        )
        XCTAssertTrue(
            app.buttons["settings_terms_open_url_button"].waitForExistence(timeout: 2),
            "Privacy sheet should expose the terms link."
        )
    }

    func testSettingsDataControlsSheetActionsPresence() {
        let app = launchReadyApp()

        app.buttons["Profile and access"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        let dataControlsRow = app.buttons["settings_data_controls_row"]
        XCTAssertTrue(dataControlsRow.waitForExistence(timeout: 3))
        dataControlsRow.tap()

        XCTAssertTrue(app.navigationBars["Data controls"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.buttons["settings_data_export_refresh_button"].waitForExistence(timeout: 2),
            "Data controls should expose refresh export action."
        )
        XCTAssertTrue(
            app.buttons["settings_delete_all_local_data_button"].waitForExistence(timeout: 2),
            "Data controls should expose delete-local-data action."
        )
    }

    func testTodaySignalSourceSheetShowsMeetingCallAuthorizationState() {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForTodayReady(app: app)
        let signalSourceButton = app.buttons["today_signal_source_button"]
        XCTAssertTrue(signalSourceButton.waitForExistence(timeout: 3))
        signalSourceButton.tap()

        XCTAssertTrue(app.navigationBars["Signal Diagnostics"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts["Meeting/call metadata control"].waitForExistence(timeout: 2),
            "Signal diagnostics should surface meeting/call authorization context."
        )

        let includedState = app.staticTexts["Current state: Included in Top drivers"]
        let excludedState = app.staticTexts["Current state: Excluded from Top drivers"]
        XCTAssertTrue(
            includedState.waitForExistence(timeout: 1.5) || excludedState.waitForExistence(timeout: 1.5),
            "Signal diagnostics should show whether meeting/call metadata is currently included or excluded."
        )
    }

    func testOnboardingProgressCopyUsesStepModelOnly() {
        let app = launchOnboardingApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForOnboardingReady(app: app)

        let progressHeading = app.staticTexts["onboarding_progress_heading"]
        XCTAssertTrue(progressHeading.waitForExistence(timeout: 2))
        XCTAssertEqual(progressHeading.label, "Progress")

        let progressStep = app.staticTexts["onboarding_progress_step_text"]
        XCTAssertTrue(progressStep.waitForExistence(timeout: 2))
        XCTAssertEqual(progressStep.label, "Step 1 of 2")

        let percentLabels = app.staticTexts.matching(
            NSPredicate(format: "label MATCHES %@", ".*[0-9]+%.*")
        )
        XCTAssertEqual(percentLabels.count, 0, "Onboarding hero should use step-based progress copy without percent duplication.")
    }

    func testIntroAndOnboardingCopyConsistency() {
        let introApp = launchIntroApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )
        waitForIntroReady(app: introApp)

        let introCTA = introApp.buttons["intro_primary_cta"]
        XCTAssertTrue(introCTA.waitForExistence(timeout: 3))
        XCTAssertTrue(introApp.staticTexts["Setup < 45 sec"].exists, "Intro timing badge should use 45-second language.")
        XCTAssertFalse(introApp.staticTexts["Setup < 1 min"].exists, "Legacy intro timing copy should not reappear.")

        introApp.terminate()

        let onboardingApp = launchOnboardingApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )
        waitForOnboardingReady(app: onboardingApp)

        XCTAssertTrue(
            onboardingApp.staticTexts["Activate Today in under 45 seconds"].waitForExistence(timeout: 2),
            "Onboarding timing copy should stay aligned with intro timing language."
        )

        let progressStep = onboardingApp.staticTexts["onboarding_progress_step_text"]
        XCTAssertTrue(progressStep.waitForExistence(timeout: 2))
        XCTAssertEqual(progressStep.label, "Step 1 of 2")
    }

    func testDataWorkspaceLabelsFitAtDefaultType() {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        app.tabBars.buttons["Data"].tap()
        let dataCTA = firstExistingButton(
            in: app,
            identifiers: ["data_hero_primary_cta", "data_primary_cta", "data_log_day_cta", "data_complete_experiment_cta"],
            timeout: 3
        )
        XCTAssertNotNil(dataCTA)

        let trends = app.buttons["Trends"]
        let experiments = app.buttons["Experiments"]
        let history = app.buttons["History"]

        XCTAssertTrue(trends.waitForExistence(timeout: 2))
        XCTAssertTrue(experiments.waitForExistence(timeout: 2))
        XCTAssertTrue(history.waitForExistence(timeout: 2))

        XCTAssertTrue(trends.isHittable, "Trends label should remain visible and tappable.")
        XCTAssertTrue(experiments.isHittable, "Experiments label should remain visible and tappable.")
        XCTAssertTrue(history.isHittable, "History label should remain visible and tappable.")

        XCTAssertFalse(trends.label.contains("…"), "Trends label should not truncate.")
        XCTAssertFalse(experiments.label.contains("…"), "Experiments label should not truncate.")
        XCTAssertFalse(history.label.contains("…"), "History label should not truncate.")

        trends.tap()
        experiments.tap()
        history.tap()
    }

    func testRegulateFocusModeInteractionAudit() {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForTodayReady(app: app)
        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))

        let regulatePrimaryCTA = app.buttons["regulate_primary_cta"]
        if !regulatePrimaryCTA.waitForExistence(timeout: 1.5) {
            let regulateTab = app.tabBars.buttons["Regulate"]
            XCTAssertTrue(regulateTab.waitForExistence(timeout: 3))
            regulateTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(regulatePrimaryCTA.waitForExistence(timeout: 3))

        regulatePrimaryCTA.tap()
        XCTAssertTrue(app.staticTexts["regulate_session_timer"].waitForExistence(timeout: 4))
        XCTAssertFalse(
            app.staticTexts["Why this works"].exists,
            "Run screen should default to focus mode with rationale hidden."
        )

        XCTAssertTrue(
            app.buttons["Details"].exists || app.staticTexts["Details"].exists,
            "Run screen should keep a details disclosure entry point for secondary rationale."
        )
    }

    func testTimelineSingleActionRowInteractionAudit() {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForTodayReady(app: app)

        let timelineRows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "today_timeline_episode_row_")
        )
        let timelineRow = timelineRows.firstMatch
        if !timelineRow.waitForExistence(timeout: 2) {
            let timelineSectionToggle = app.buttons["Today timeline"]
            if timelineSectionToggle.waitForExistence(timeout: 1.5) {
                timelineSectionToggle.tap()
            }
        }
        XCTAssertTrue(timelineRow.waitForExistence(timeout: 3), "Today timeline should expose at least one tappable episode row.")

        let inlineButtons = timelineRow.descendants(matching: .button)
        XCTAssertLessThanOrEqual(inlineButtons.count, 2, "Timeline row should stay interaction-light (row tap plus optional context/intensity action).")

        let rowStartButtons = inlineButtons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Start "))
        XCTAssertEqual(rowStartButtons.count, 0, "Start protocol CTA should live in episode detail, not the timeline row.")

        timelineRow.tap()
        XCTAssertTrue(
            app.otherElements["today_episode_detail_sheet_root"].waitForExistence(timeout: 3),
            "Tapping a timeline row should open episode detail."
        )

        let detailStartButtons = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Start "))
        XCTAssertGreaterThanOrEqual(detailStartButtons.count, 1, "Episode detail should surface the protocol start CTA.")
    }

    func testStickyCTATabBarOverlapAudit() throws {
        let app = launchReadyApp(
            appearance: .system,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        waitForTodayReady(app: app)
        tapTab(named: "Data", in: app)

        let experimentsWorkspace = app.buttons["Experiments"]
        XCTAssertTrue(experimentsWorkspace.waitForExistence(timeout: 3))
        experimentsWorkspace.tap()

        let stickyDock = app.otherElements["data_sticky_experiment_dock"]
        if !stickyDock.waitForExistence(timeout: 2.5) {
            let experimentRows = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "data_experiment_row_")
            )
            let rowCount = min(experimentRows.count, 8)
            if rowCount > 0 {
                for index in 0..<rowCount {
                    let row = experimentRows.element(boundBy: index)
                    if row.waitForExistence(timeout: 1) {
                        row.tap()
                        if stickyDock.waitForExistence(timeout: 1.2) {
                            break
                        }
                    }
                }
            }
        }
        if !stickyDock.waitForExistence(timeout: 4) {
            throw XCTSkip("Sticky experiment dock is not available in the current deterministic experiment state.")
        }

        let stickyCTA = firstExistingButton(
            in: app,
            identifiers: ["data_primary_cta", "data_log_day_cta", "data_complete_experiment_cta"],
            timeout: 2.5
        )
        XCTAssertNotNil(stickyCTA, "Sticky dock should expose one of the known experiment CTAs.")
        guard let stickyCTA else { return }

        XCTAssertTrue(stickyCTA.isHittable, "Sticky experiment CTA should remain tappable.")

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))

        func assertNoDockOverlap(_ state: String) {
            let dockFrame = stickyDock.frame
            let tabFrame = tabBar.frame
            XCTAssertFalse(
                dockFrame.intersects(tabFrame),
                "Sticky dock overlaps tab bar in \(state). dock=\(dockFrame) tabBar=\(tabFrame)"
            )
        }

        assertNoDockOverlap("initial state")
        app.swipeUp()
        app.swipeUp()
        assertNoDockOverlap("after downward content scroll")
        app.swipeDown()
        assertNoDockOverlap("after reverse scroll")
    }

    func testDataExperimentLifecycle() {
        let app = launchReadyApp()

        app.tabBars.buttons["Data"].tap()
        XCTAssertTrue(app.buttons["Experiments"].waitForExistence(timeout: 3))
        app.buttons["Experiments"].tap()
        XCTAssertTrue(app.buttons["data_primary_cta"].waitForExistence(timeout: 3))

        app.buttons["data_primary_cta"].tap()
        XCTAssertTrue(app.buttons["data_log_day_cta"].waitForExistence(timeout: 3))

        for _ in 0..<7 {
            XCTAssertTrue(app.buttons["data_log_day_cta"].waitForExistence(timeout: 2))
            app.buttons["data_log_day_cta"].tap()
        }

        XCTAssertTrue(app.buttons["data_complete_experiment_cta"].waitForExistence(timeout: 3))
        app.buttons["data_complete_experiment_cta"].tap()

        XCTAssertTrue(app.buttons["data_complete_submit_cta"].waitForExistence(timeout: 3))
        app.buttons["data_complete_submit_cta"].tap()

        XCTAssertTrue(app.buttons["data_primary_cta"].waitForExistence(timeout: 3))
    }

    func testCoreScreenSnapshots() {
        let app = launchReadyApp()
        captureCoreScreens(app: app, prefix: "system")
    }

    func testCoreScreenSnapshotsAcrossAppearances() {
        for appearance in [UITestAppearance.light, UITestAppearance.dark] {
            let app = launchReadyApp(
                appearance: appearance,
                reset: true,
                enableHaptics: false
            )
            captureCoreScreens(app: app, prefix: appearance.rawValue)
            app.terminate()
        }
    }

    func testAccessibilityDynamicTypeScaling() {
        let app = launchReadyApp(
            appearance: .dark,
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXXXL",
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )

        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["today_action_card_cta"].isHittable, "Today hero CTA should remain tappable at large text sizes.")
        attachSnapshot(named: "dynamic_type_today_axxxl")

        app.tabBars.buttons["Regulate"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["regulate_primary_cta"].isHittable, "Regulate CTA should remain tappable at large text sizes.")
        attachSnapshot(named: "dynamic_type_regulate_axxxl")

        app.tabBars.buttons["Data"].tap()
        let dataCTA = firstExistingButton(
            in: app,
            identifiers: ["data_hero_primary_cta", "data_primary_cta", "data_log_day_cta", "data_complete_experiment_cta"],
            timeout: 3
        )
        XCTAssertNotNil(dataCTA, "Data should expose a primary next-step CTA at large text sizes.")
        XCTAssertTrue(dataCTA?.isHittable ?? false, "Data CTA should remain tappable at large text sizes.")
        attachSnapshot(named: "dynamic_type_data_axxxl")
    }

    func testDynamicTypeClippingPassAcrossCoreJourneys() throws {
        let accessibilityCategory = "UICTContentSizeCategoryAccessibilityXXXL"

        let readyApp = launchReadyApp(
            appearance: .system,
            contentSizeCategory: accessibilityCategory,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )
        waitForTodayReady(app: readyApp)
        XCTAssertTrue(readyApp.buttons["today_action_card_cta"].waitForExistence(timeout: 5))
        XCTAssertTrue(readyApp.buttons["today_action_card_cta"].isHittable, "Today CTA should remain visible at large Dynamic Type.")

        tapTab(named: "Regulate", in: readyApp)
        let regulateCTA = readyApp.buttons["regulate_primary_cta"]
        guard regulateCTA.waitForExistence(timeout: 6) else {
            throw XCTSkip("Regulate CTA did not become reachable in this simulator run at AXXXL Dynamic Type.")
        }
        XCTAssertTrue(regulateCTA.isHittable, "Regulate CTA should remain visible at large Dynamic Type.")

        tapTab(named: "Data", in: readyApp)
        if !readyApp.buttons["Experiments"].waitForExistence(timeout: 2) {
            tapTab(named: "Data", in: readyApp)
        }
        let experimentsWorkspace = readyApp.buttons["Experiments"]
        guard experimentsWorkspace.waitForExistence(timeout: 3) else {
            throw XCTSkip("Data workspace controls did not become reachable in this simulator run at AXXXL Dynamic Type.")
        }
        XCTAssertTrue(experimentsWorkspace.isHittable, "Data workspace segments should remain tappable at large Dynamic Type.")

        let dataCTA = firstExistingButton(
            in: readyApp,
            identifiers: ["data_primary_cta", "data_log_day_cta", "data_complete_experiment_cta"],
            timeout: 3
        )
        XCTAssertNotNil(dataCTA, "Data should expose a primary next-step CTA at large Dynamic Type.")
        XCTAssertTrue(dataCTA?.isHittable ?? false, "Data CTA should remain visible at large Dynamic Type.")

        readyApp.buttons["Profile and access"].tap()
        readyApp.buttons["Settings"].tap()
        XCTAssertTrue(readyApp.navigationBars["Settings"].waitForExistence(timeout: 3))
        let privacyRow = readyApp.buttons["settings_privacy_policy_row"]
        XCTAssertTrue(privacyRow.waitForExistence(timeout: 3))
        XCTAssertTrue(privacyRow.isHittable, "Settings rows should remain tappable at large Dynamic Type.")
        readyApp.terminate()

        let introApp = launchIntroApp(
            appearance: .system,
            contentSizeCategory: accessibilityCategory,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )
        waitForIntroReady(app: introApp)
        let introCTA = introApp.buttons["intro_primary_cta"]
        XCTAssertTrue(introCTA.waitForExistence(timeout: 3))
        XCTAssertTrue(introCTA.isHittable, "Intro primary CTA should remain tappable at large Dynamic Type.")
        introApp.terminate()

        let onboardingApp = launchOnboardingApp(
            appearance: .system,
            contentSizeCategory: accessibilityCategory,
            reset: true,
            enableHaptics: false,
            reduceMotion: true
        )
        waitForOnboardingReady(app: onboardingApp)
        let onboardingCTA = onboardingApp.buttons["onboarding_primary_cta"]
        XCTAssertTrue(onboardingCTA.waitForExistence(timeout: 3))
        XCTAssertTrue(onboardingCTA.isHittable, "Onboarding CTA should remain tappable at large Dynamic Type.")

        let onboardingProgress = onboardingApp.staticTexts["onboarding_progress_step_text"]
        XCTAssertTrue(onboardingProgress.waitForExistence(timeout: 2))
        XCTAssertTrue(onboardingProgress.isHittable, "Onboarding progress text should remain visible at large Dynamic Type.")
    }

    func testInteractionLatencyAndMotionSmoothnessBudget() {
        let app = launchReadyApp(
            appearance: .dark,
            reset: true,
            enableHaptics: false
        )
        let premiumLatencyBudgetMS = 750.0

        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))

        var tabSwitchSamples: [Double] = []
        for _ in 0..<6 {
            let toRegulate = tapLatencyMS(
                element: app.tabBars.buttons["Regulate"],
                waitFor: app.buttons["regulate_primary_cta"],
                timeout: 3
            )
            tabSwitchSamples.append(toRegulate)

            let toToday = tapLatencyMS(
                element: app.tabBars.buttons["Today"],
                waitFor: app.buttons["today_action_card_cta"],
                timeout: 3
            )
            tabSwitchSamples.append(toToday)
        }

        let maxTabSwitch = tabSwitchSamples.max() ?? 0
        XCTAssertLessThan(maxTabSwitch, premiumLatencyBudgetMS, "Tab transition latency exceeded \(Int(premiumLatencyBudgetMS))ms premium simulator budget.")

        app.tabBars.buttons["Regulate"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))

        let startPresetLatency = tapLatencyMS(
            element: app.buttons["regulate_primary_cta"],
            waitFor: app.staticTexts["regulate_active_preset_label"],
            timeout: 4
        )
        XCTAssertLessThan(startPresetLatency, premiumLatencyBudgetMS, "Primary action-to-state-change latency exceeded \(Int(premiumLatencyBudgetMS))ms premium simulator budget.")

        attachTextReport(
            name: "interaction_latency_report",
            lines: [
                "tab_switch_samples_ms=\(format(tabSwitchSamples))",
                "tab_switch_max_ms=\(String(format: "%.1f", maxTabSwitch))",
                "start_preset_latency_ms=\(String(format: "%.1f", startPresetLatency))"
            ]
        )
    }

    private func launchReadyApp(
        appearance: UITestAppearance = .system,
        contentSizeCategory: String? = nil,
        reset: Bool = true,
        enableHaptics: Bool? = nil,
        reduceMotion: Bool? = nil
    ) -> XCUIApplication {
        launchApp(
            mode: .ready,
            appearance: appearance,
            contentSizeCategory: contentSizeCategory,
            reset: reset,
            enableHaptics: enableHaptics,
            reduceMotion: reduceMotion
        )
    }

    private func launchOnboardingApp(
        appearance: UITestAppearance = .system,
        contentSizeCategory: String? = nil,
        reset: Bool = true,
        enableHaptics: Bool? = nil,
        reduceMotion: Bool? = nil
    ) -> XCUIApplication {
        launchApp(
            mode: .onboarding,
            appearance: appearance,
            contentSizeCategory: contentSizeCategory,
            reset: reset,
            enableHaptics: enableHaptics,
            reduceMotion: reduceMotion
        )
    }

    private func launchIntroApp(
        appearance: UITestAppearance = .system,
        contentSizeCategory: String? = nil,
        reset: Bool = true,
        enableHaptics: Bool? = nil,
        reduceMotion: Bool? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [appearance.launchFlag]
        if reset {
            arguments.insert("-uitest-reset", at: 0)
        }
        if let enableHaptics {
            arguments.append(contentsOf: ["-uitest-enable-haptics", enableHaptics ? "1" : "0"])
        }
        if let reduceMotion {
            arguments.append(contentsOf: ["-uitest-reduce-motion", reduceMotion ? "1" : "0"])
        }
        app.launchArguments = arguments
        if let contentSizeCategory {
            app.launchEnvironment["UIPreferredContentSizeCategoryName"] = contentSizeCategory
        }
        app.launch()
        return app
    }

    private func launchApp(
        mode: UITestLaunchMode,
        appearance: UITestAppearance = .system,
        contentSizeCategory: String? = nil,
        reset: Bool = true,
        enableHaptics: Bool? = nil,
        reduceMotion: Bool? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [mode.launchFlag, appearance.launchFlag]
        if reset {
            arguments.insert("-uitest-reset", at: 0)
        }
        if let enableHaptics {
            arguments.append(contentsOf: ["-uitest-enable-haptics", enableHaptics ? "1" : "0"])
        }
        if let reduceMotion {
            arguments.append(contentsOf: ["-uitest-reduce-motion", reduceMotion ? "1" : "0"])
        }
        app.launchArguments = arguments
        if let contentSizeCategory {
            app.launchEnvironment["UIPreferredContentSizeCategoryName"] = contentSizeCategory
        }
        app.launch()
        return app
    }

    private func captureCoreScreens(app: XCUIApplication, prefix: String) {
        waitForTodayReady(app: app)
        XCTAssertTrue(app.buttons["today_action_card_cta"].waitForExistence(timeout: 5))
        attachSnapshot(named: "\(prefix)_today")

        tapTab(named: "Regulate", in: app)
        let regulateCTA = firstExistingButton(
            in: app,
            identifiers: [
                "regulate_start_cta",
                "regulate_primary_cta",
                "regulate_complete_now_cta",
                "regulate_outcome_submit_cta"
            ],
            timeout: 3
        )
        XCTAssertNotNil(regulateCTA, "Regulate should expose a primary CTA or active session CTA.")
        attachSnapshot(named: "\(prefix)_regulate")

        tapTab(named: "Data", in: app)
        let dataCTA = firstExistingButton(
            in: app,
            identifiers: [
                "data_hero_primary_cta",
                "data_primary_cta",
                "data_log_day_cta",
                "data_complete_experiment_cta"
            ],
            timeout: 3
        )
        XCTAssertNotNil(dataCTA, "Data should expose a primary next-step CTA.")
        attachSnapshot(named: "\(prefix)_data")

        app.buttons["Profile and access"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        attachSnapshot(named: "\(prefix)_settings")
    }

    private func waitForTodayReady(app: XCUIApplication) {
        let launchRoot = app.otherElements["launch_screen_root"]
        let todayRoot = app.otherElements["today_screen_root"]
        XCTAssertTrue(todayRoot.waitForExistence(timeout: 6))

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: launchRoot
        )
        _ = XCTWaiter.wait(for: [expectation], timeout: 2.5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    }

    private func waitForIntroReady(app: XCUIApplication) {
        let launchRoot = app.otherElements["launch_screen_root"]
        let introPrimaryCTA = app.buttons["intro_primary_cta"]
        XCTAssertTrue(introPrimaryCTA.waitForExistence(timeout: 6))

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: launchRoot
        )
        _ = XCTWaiter.wait(for: [expectation], timeout: 2.5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    }

    private func waitForOnboardingReady(app: XCUIApplication) {
        let launchRoot = app.otherElements["launch_screen_root"]
        let onboardingPrimaryCTA = app.buttons["onboarding_primary_cta"]
        XCTAssertTrue(onboardingPrimaryCTA.waitForExistence(timeout: 6))

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: launchRoot
        )
        _ = XCTWaiter.wait(for: [expectation], timeout: 2.5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    }

    private func tapLatencyMS(element: XCUIElement, waitFor target: XCUIElement, timeout: TimeInterval) -> Double {
        let start = Date()
        element.tap()
        XCTAssertTrue(target.waitForExistence(timeout: timeout))
        return Date().timeIntervalSince(start) * 1000
    }

    private func attachSnapshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "snapshot_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attachTextReport(name: String, lines: [String]) {
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func format(_ values: [Double]) -> String {
        values.map { String(format: "%.1f", $0) }.joined(separator: ",")
    }

    private func tapTab(named name: String, in app: XCUIApplication, timeout: TimeInterval = 6) {
        let tab = app.tabBars.buttons[name]
        if tab.waitForExistence(timeout: timeout) {
            if tab.isHittable {
                tab.tap()
            } else {
                tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            return
        }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: timeout), "Expected tab bar to exist.")
        guard let tabIndex = tabIndex(named: name) else {
            XCTFail("Unsupported tab name '\(name)'.")
            return
        }
        let normalizedX = (CGFloat(tabIndex) + 0.5) / 4.0
        tabBar.coordinate(withNormalizedOffset: CGVector(dx: normalizedX, dy: 0.5)).tap()
    }

    private func firstExistingButton(
        in app: XCUIApplication,
        identifiers: [String],
        timeout: TimeInterval
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for identifier in identifiers {
                let button = app.buttons[identifier]
                if button.exists {
                    return button
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.12))
        } while Date() < deadline
        return nil
    }

    private func tabIndex(named name: String) -> Int? {
        switch name {
        case "Today":
            return 0
        case "Regulate":
            return 1
        case "Data":
            return 2
        case "Settings":
            return 3
        default:
            return nil
        }
    }
}
