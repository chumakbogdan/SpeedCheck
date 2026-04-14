import XCTest

final class ContentViewUITests: XCTestCase {

    func testStartButtonExists() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Start"].exists)
    }

    func testStartOpensLiveTestView() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Start"].tap()
        XCTAssertTrue(app.staticTexts["LiveTestTitle"].waitForExistence(timeout: 3))
    }
}

final class LiveTestCancelUITests: XCTestCase {

    func testCancelAlertAppears() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Start"].tap()
        app.buttons["xmark"].tap()

        XCTAssertTrue(app.alerts["Cancel test?"].exists)
    }
}


final class LiveTestFinishUITests: XCTestCase{
    
    func testCompletionButtonsAppear() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Start"].tap()

        XCTAssertTrue(app.buttons["Run Again"].waitForExistence(timeout: 25))
        XCTAssertTrue(app.buttons["Details"].exists)
    }
}

