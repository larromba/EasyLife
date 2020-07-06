import XCTest

final class Snapshots: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        setupSnapshot(app)
        continueAfterFailure = false
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testMainSnapshot() {
        // Plan
        app.launch()
        snapshot("Plan")

        // Focus


        // ItemDetail
        app.navigationBars["Todo"].buttons["Add"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let titleTextField = elementsQuery.textFields["Title"]
        titleTextField.tap()
        titleTextField.typeText("a new todo item!")
        snapshot("ItemDetail")

        // BlockedBy
        app.navigationBars["Detail"].buttons["Pause"].tap()
        app.tables.children(matching: .cell).element(boundBy: 0).staticTexts["call landlord"].tap()
        snapshot("BlockedBy")

        // Archive
        app.navigationBars["Blocked by"].buttons["Detail"].tap()
        app.navigationBars["Detail"].buttons["Cancel"].tap()
        app.alerts["Unsaved Changed"].buttons["No"].tap()
        app.navigationBars["Todo"].buttons["Organize"].tap()
        snapshot("Archive")

        // Projects
        app.navigationBars["Archive"].buttons["Done"].tap()
        app.navigationBars["Todo"].buttons["Compose"].tap()
        snapshot("Projects")
    }
}
