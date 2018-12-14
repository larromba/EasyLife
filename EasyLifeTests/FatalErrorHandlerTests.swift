@testable import EasyLife
import XCTest
import CoreData

class FatalErrorHandlerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }

    func testShowFatalViewControllerOnNotification() {
        // mocks
        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: ""])

        // test
        NotificationCenter.default.post(name: .applicationDidReceiveFatalError, object: error)
        XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController as? FatalViewController)
    }
}
