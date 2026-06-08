//
//  FitnessProUITests.swift
//  FitnessProUITests
//

import XCTest

final class FitnessProUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testLandingScreenLoads() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST-RESET"]
        app.launch()

        // Fresh launch lands on the marketing screen with the primary CTA.
        XCTAssertTrue(
            app.buttons["Get started"].waitForExistence(timeout: 10),
            "Landing CTA should be visible on a fresh launch"
        )
    }

    @MainActor
    func testGetStartedOpensAuth() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST-RESET"]
        app.launch()

        let getStarted = app.buttons["Get started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10))
        getStarted.tap()

        // Auth screen exposes the Log In / Sign Up segmented control.
        XCTAssertTrue(
            app.buttons["Create Account"].waitForExistence(timeout: 5)
            || app.buttons["Log In"].waitForExistence(timeout: 5),
            "Auth screen should appear after Get started"
        )
    }
}
