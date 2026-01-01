import XCTest

final class ScreenshotTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testTakeAllScreenshots() throws {
        // Wait for app to load
        sleep(1)

        // 1. Main screen (idle state)
        let mainScreenshot = XCUIScreen.main.screenshot()
        let mainAttachment = XCTAttachment(screenshot: mainScreenshot)
        mainAttachment.name = "main-screen"
        mainAttachment.lifetime = .keepAlways
        add(mainAttachment)

        // 2. Tap Start Monitoring
        let startButton = app.buttons["Start Monitoring"]
        if startButton.exists {
            startButton.tap()
            sleep(3) // Wait for monitoring to capture some data

            let monitoringScreenshot = XCUIScreen.main.screenshot()
            let monitoringAttachment = XCTAttachment(screenshot: monitoringScreenshot)
            monitoringAttachment.name = "monitoring"
            monitoringAttachment.lifetime = .keepAlways
            add(monitoringAttachment)

            // Stop monitoring
            let stopButton = app.buttons["Stop"]
            if stopButton.exists {
                stopButton.tap()
                sleep(1)
            }
        }

        // 3. Alert Settings
        let alertButton = app.buttons.element(boundBy: 1) // Alert bell button
        if alertButton.exists {
            alertButton.tap()
            sleep(1)

            let alertScreenshot = XCUIScreen.main.screenshot()
            let alertAttachment = XCTAttachment(screenshot: alertScreenshot)
            alertAttachment.name = "alert-settings"
            alertAttachment.lifetime = .keepAlways
            add(alertAttachment)

            // Go back
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // 4. History
        let historyButton = app.buttons.element(boundBy: 0) // History clock button
        if historyButton.exists {
            historyButton.tap()
            sleep(1)

            let historyScreenshot = XCUIScreen.main.screenshot()
            let historyAttachment = XCTAttachment(screenshot: historyScreenshot)
            historyAttachment.name = "history"
            historyAttachment.lifetime = .keepAlways
            add(historyAttachment)
        }
    }
}
