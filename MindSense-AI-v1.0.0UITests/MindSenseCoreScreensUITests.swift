import XCTest

private enum UITestAppearance: String, CaseIterable {
    case system
    case light
    case dark

    var launchFlag: String {
        "-uitest-\(rawValue)"
    }
}

final class MindSenseCoreScreensUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCoreScreenNavigationAndPrimaryCTAs() {
        let app = launchReadyApp()

        XCTAssertTrue(app.buttons["today_primary_cta"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Regulate"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Data"].tap()
        XCTAssertTrue(app.buttons["data_primary_cta"].waitForExistence(timeout: 3))

        app.buttons["Profile and access"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    func testTodayPrimaryCTADeterministicRegulateOutcomeLoop() {
        let app = launchReadyApp()

        XCTAssertTrue(app.buttons["today_primary_cta"].waitForExistence(timeout: 5))
        app.buttons["today_primary_cta"].tap()

        XCTAssertTrue(app.buttons["regulate_complete_now_cta"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["regulate_session_timer"].waitForExistence(timeout: 3))

        app.buttons["regulate_complete_now_cta"].tap()
        XCTAssertTrue(app.staticTexts["regulate_active_preset_label"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["regulate_outcome_submit_cta"].waitForExistence(timeout: 3))

        app.buttons["regulate_outcome_submit_cta"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))
    }

    func testDataExperimentLifecycle() {
        let app = launchReadyApp()

        app.tabBars.buttons["Data"].tap()
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

        XCTAssertTrue(app.buttons["today_primary_cta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["today_primary_cta"].isHittable, "Today primary CTA should remain tappable at large text sizes.")
        attachSnapshot(named: "dynamic_type_today_axxxl")

        app.tabBars.buttons["Regulate"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["regulate_primary_cta"].isHittable, "Regulate CTA should remain tappable at large text sizes.")
        attachSnapshot(named: "dynamic_type_regulate_axxxl")

        app.tabBars.buttons["Data"].tap()
        XCTAssertTrue(app.buttons["data_primary_cta"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["data_primary_cta"].isHittable, "Data CTA should remain tappable at large text sizes.")
        attachSnapshot(named: "dynamic_type_data_axxxl")
    }

    func testInteractionLatencyAndMotionSmoothnessBudget() {
        let app = launchReadyApp(
            appearance: .dark,
            reset: true,
            enableHaptics: false
        )
        let premiumLatencyBudgetMS = 750.0

        XCTAssertTrue(app.buttons["today_primary_cta"].waitForExistence(timeout: 5))

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
                waitFor: app.buttons["today_primary_cta"],
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
        let app = XCUIApplication()
        var arguments = ["-uitest-ready", appearance.launchFlag]
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
        XCTAssertTrue(app.buttons["today_primary_cta"].waitForExistence(timeout: 5))
        attachSnapshot(named: "\(prefix)_today")

        app.tabBars.buttons["Regulate"].tap()
        XCTAssertTrue(app.buttons["regulate_primary_cta"].waitForExistence(timeout: 3))
        attachSnapshot(named: "\(prefix)_regulate")

        app.tabBars.buttons["Data"].tap()
        XCTAssertTrue(app.buttons["data_primary_cta"].waitForExistence(timeout: 3))
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
}
