// Copyright Bryan Carroll. All rights reserved.
//
//  Trek_Long_IslandUITests.swift
//  Trek Long IslandUITests
//
//  Created by Bryan on 5/29/25.
//

import XCTest

final class Trek_Long_IslandUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    /// Fresh-install launch: splash -> welcome notice -> main tab bar, with no
    /// onboarding and no system permission alert in between. This is the flow that
    /// used to stall on "Continue" and again on the notification prompt, so it
    /// asserts the app stays in the foreground the whole way through.
    @MainActor
    func testFirstLaunchReachesMainAppWithoutOnboarding() throws {
        let app = XCUIApplication()
        app.launch()

        // The splash auto-dismisses, but a tap gets us past it immediately.
        let splashHint = app.staticTexts["Tap anywhere to continue"]
        if splashHint.waitForExistence(timeout: 10) {
            app.tap()
        }

        // Welcome notice sheet, if this build presents it.
        let continueToApp = app.buttons["Continue to App"]
        if continueToApp.waitForExistence(timeout: 10) {
            continueToApp.tap()
        }

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 20), "Main tab bar never appeared on first launch")
        XCTAssertEqual(app.state, .runningForeground, "App crashed or backgrounded during first launch")

        // Launch must never raise the system notification alert -- that modal
        // landing on top of the dismissing splash/welcome covers is what made the
        // app look frozen. Notifications are opt-in from Settings only.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertFalse(
            springboard.buttons["Allow"].waitForExistence(timeout: 6),
            "Launch presented the system notification prompt; it must be user-initiated from Settings"
        )

        // The app must still be interactive after that settling window.
        XCTAssertEqual(app.state, .runningForeground, "App is not in the foreground after launch settled")
        XCTAssertTrue(app.tabBars.firstMatch.isHittable, "Tab bar is not hittable — the UI is blocked")

        // Nothing resembling the removed onboarding flow should be reachable.
        XCTAssertFalse(app.staticTexts["STARFLEET ORIENTATION"].exists, "Onboarding is still presented on first launch")
        XCTAssertFalse(app.buttons["Open Bridge"].exists, "Onboarding is still presented on first launch")
    }

    /// Identity is now the only place the welcome message, name, rank, and
    /// pronouns can be set, so make sure that screen still opens and edits.
    @MainActor
    func testIdentitySettingsExposeWelcomeMessageAndPronouns() throws {
        let app = XCUIApplication()
        app.launch()

        let splashHint = app.staticTexts["Tap anywhere to continue"]
        if splashHint.waitForExistence(timeout: 10) {
            app.tap()
        }

        let continueToApp = app.buttons["Continue to App"]
        if continueToApp.waitForExistence(timeout: 10) {
            continueToApp.tap()
        }

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 20), "Main tab bar never appeared")

        let settingsTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Settings'")).firstMatch
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "Settings tab not found")
        settingsTab.tap()

        let openIdentity = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Open identity settings'")).firstMatch
        XCTAssertTrue(openIdentity.waitForExistence(timeout: 10), "Identity settings entry point not found")
        openIdentity.tap()

        XCTAssertTrue(app.staticTexts["Welcome Message"].waitForExistence(timeout: 10), "Welcome Message card missing from Identity settings")
        XCTAssertTrue(app.staticTexts["Pronouns"].waitForExistence(timeout: 10), "Pronouns section missing from Identity settings")

        let nameField = app.textFields["Your name or captain alias"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10), "Captain name field missing from Identity settings")

        XCTAssertEqual(app.state, .runningForeground, "App crashed while editing identity settings")
    }
}
