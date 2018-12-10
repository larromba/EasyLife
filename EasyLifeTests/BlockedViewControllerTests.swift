import XCTest
import CoreData
import UserNotifications
@testable import EasyLife

class BlockedViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }

    func testToggle() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "BlockedViewController") as! BlockedViewController
        let dataSource = BlockedDataSource()

        // prepare
        dataSource.data = [BlockedItem(item: MockTodoItem(), isBlocked: false)]
        vc.dataSource = dataSource
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.tableView.reloadData()

        // test
        vc.tableView(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataSource.data![0].isBlocked)

        vc.tableView(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(dataSource.data![0].isBlocked)
    }
}
