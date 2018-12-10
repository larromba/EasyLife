import XCTest
import CoreData
import UserNotifications
@testable import EasyLife

class PlanViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }

    func testTableViewHideShow() {
        // mocks
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertTrue(vc.tableView.isHidden)

        // prepare
        dataSource.sections[0] = [MockTodoItem()]

        //test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertFalse(vc.tableView.isHidden)
    }

    func testPlusButtonOpensItemDetailViewController() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if viewController is ItemDetailViewController {
                    exp.fulfill()
                }
            }
        }
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = nav.viewControllers.first as! PlanViewController
        let delegate = MockDelegate()

        // prepare
        delegate.exp = exp
        nav.delegate = delegate
        UIApplication.shared.keyWindow!.rootViewController = nav

        // test
        UIApplication.shared.sendAction(vc.addButton.action!, to: vc.addButton.target!, from: nil, for: nil)
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testCellOpensItemDetailViewController() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            var item: MockTodoItem!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if let viewController = viewController as? ItemDetailViewController, viewController.dataSource.item == item {
                    exp.fulfill()
                }
            }
        }
        let dataSource = PlanDataSource()
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = nav.viewControllers.first as! PlanViewController
        let delegate = MockDelegate()
        let item = MockTodoItem()

        // prepare
        vc.dataSource = dataSource
        delegate.exp = exp
        delegate.item = item
        dataSource.sections[0] = [item]
        nav.delegate = delegate
        _ = vc.view
        UIApplication.shared.keyWindow!.rootViewController = nav

        // test
        vc.dataSorceDidLoad(dataSource)
        vc.tableView.delegate!.tableView!(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testLoadCalledOnViewWillAppear() {
        // mocks
        class MockPlanDataSource: PlanDataSource {
            var didLoad = false
            override func load() {
                didLoad = true
            }
        }
        let dataSource = MockPlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        _ = vc.view
        vc.dataSource = dataSource

        // test
        vc.viewWillAppear(false)
        XCTAssertTrue(dataSource.didLoad)
    }

    func testLoadCalledOnUIApplicationWillEnterForeground() {
        // mocks
        class MockPlanDataSource: PlanDataSource {
            var didLoad = false
            override func load() {
                didLoad = true
            }
        }
        let dataSource = MockPlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        _ = vc.view
        vc.dataSource = dataSource
        vc.viewWillAppear(false)
        dataSource.didLoad = false

        // test
        NotificationCenter.default.post(name: .UIApplicationWillEnterForeground, object: nil)
        XCTAssertTrue(dataSource.didLoad)
    }

    // swiftlint:disable function_body_length
    func testUI() {
        // mocks
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        let missedItem = MockTodoItem()
        let missedItemRecurring = MockTodoItem()
        let nowItemNoName = MockTodoItem()
        let nowItemBlockedBy = MockTodoItem()
        let nowItemRecurring = MockTodoItem()
        let laterItem = MockTodoItem()
        let sections = [
            [missedItem, missedItemRecurring],
            [nowItemNoName, nowItemBlockedBy, nowItemRecurring],
            [laterItem]
        ]
        let project = MockProject()

        // prepare
        project.priority = 0
        missedItem.name = "missed"
        missedItem.date = Date()
        missedItem.project = project
        missedItemRecurring.name = "missed_recurring"
        missedItemRecurring.date = Date()
        missedItemRecurring.repeats = 1
        nowItemNoName.name = nil
        nowItemNoName.project = project
        nowItemNoName.notes = "test"
        nowItemBlockedBy.name = "now_blocked"
        nowItemBlockedBy.date = Date()
        nowItemBlockedBy.blockedBy = [nowItemNoName]
        nowItemRecurring.name = "now_recurring"
        nowItemRecurring.date = Date()
        nowItemRecurring.repeats = 1
        laterItem.name = "later"
        laterItem.repeatState = .biweekly
        laterItem.date = Date().addingTimeInterval(24 * 60 * 60)
        laterItem.project = project
        vc.dataSource = dataSource
        dataSource.sections = sections
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.dataSorceDidLoad(dataSource)

        // cells
        let cellMissed = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as! PlanCell
        XCTAssertEqual(cellMissed.titleLabel.text, "missed")
        XCTAssertTrue(cellMissed.notesLabel.isHidden)
        XCTAssertEqual(cellMissed.titleLabel.textColor, UIColor.lightRed)
        XCTAssertTrue(cellMissed.infoLabel.isHidden)
        XCTAssertTrue(cellMissed.iconImageView.isHidden)
        XCTAssertEqual(cellMissed.iconImageType, .none)
        XCTAssertFalse(cellMissed.tagView.isHidden)
        XCTAssertEqual(cellMissed.tagView.cornerColor, .priority1)
        XCTAssertEqual(cellMissed.tagView.alpha, 1.0)
        XCTAssertEqual(cellMissed.blockedView.state, .none)

        let cellMissedRecurring = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 1, section: 0)) as! PlanCell
        XCTAssertEqual(cellMissedRecurring.titleLabel.text, "missed_recurring")
        XCTAssertTrue(cellMissedRecurring.notesLabel.isHidden)
        XCTAssertEqual(cellMissedRecurring.titleLabel.textColor, UIColor.lightRed)
        XCTAssertTrue(cellMissedRecurring.infoLabel.isHidden)
        XCTAssertFalse(cellMissedRecurring.iconImageView.isHidden)
        XCTAssertEqual(cellMissedRecurring.iconImageType, .recurring)
        XCTAssertTrue(cellMissedRecurring.tagView.isHidden)
        XCTAssertEqual(cellMissedRecurring.blockedView.state, .none)

        let cellNowNoName = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 1)) as! PlanCell
        XCTAssertEqual(cellNowNoName.titleLabel.text, "[no name]")
        XCTAssertFalse(cellNowNoName.notesLabel.isHidden)
        XCTAssertEqual(cellNowNoName.titleLabel.textColor, UIColor.appleGrey)
        XCTAssertFalse(cellNowNoName.iconImageView.isHidden)
        XCTAssertEqual(cellNowNoName.iconImageType, .noDate)
        XCTAssertFalse(cellNowNoName.tagView.isHidden)
        XCTAssertEqual(cellMissed.tagView.cornerColor, .priority1)
        XCTAssertEqual(cellMissed.tagView.alpha, 1.0)
        XCTAssertEqual(cellMissed.blockedView.state, .none)

        let cellNowBlockedBy = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 1, section: 1)) as! PlanCell
        XCTAssertEqual(cellNowBlockedBy.titleLabel.text, "now_blocked")
        XCTAssertTrue(cellNowBlockedBy.notesLabel.isHidden)
        XCTAssertEqual(cellNowBlockedBy.titleLabel.textColor, UIColor.black)
        XCTAssertTrue(cellNowBlockedBy.infoLabel.isHidden)
        XCTAssertTrue(cellNowBlockedBy.iconImageView.isHidden)
        XCTAssertEqual(cellNowBlockedBy.iconImageType, .none)
        XCTAssertTrue(cellNowBlockedBy.tagView.isHidden)
        XCTAssertEqual(cellNowBlockedBy.blockedView.state, .blocked)

        let cellNowRecurring = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 2, section: 1)) as! PlanCell
        XCTAssertEqual(cellNowRecurring.titleLabel.text, "now_recurring")
        XCTAssertTrue(cellNowRecurring.notesLabel.isHidden)
        XCTAssertEqual(cellNowRecurring.titleLabel.textColor, UIColor.black)
        XCTAssertTrue(cellNowRecurring.infoLabel.isHidden)
        XCTAssertFalse(cellNowRecurring.iconImageView.isHidden)
        XCTAssertEqual(cellNowRecurring.iconImageType, .recurring)
        XCTAssertTrue(cellNowRecurring.tagView.isHidden)
        XCTAssertEqual(cellNowRecurring.blockedView.state, .none)

        let cellLater = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 2)) as! PlanCell
        XCTAssertEqual(cellLater.titleLabel.text, "later")
        XCTAssertTrue(cellLater.notesLabel.isHidden)
        XCTAssertEqual(cellLater.titleLabel.textColor, UIColor.appleGrey)
        XCTAssertFalse(cellLater.infoLabel.isHidden)
        XCTAssertEqual(cellLater.infoLabel.text, "1 day")
        XCTAssertFalse(cellLater.iconImageView.isHidden)
        XCTAssertEqual(cellLater.iconImageType, .recurring)
        XCTAssertFalse(cellLater.tagView.isHidden)
        XCTAssertEqual(cellLater.tagView.cornerColor, .priority1)
        XCTAssertEqual(cellLater.tagView.alpha, 0.5)
        XCTAssertEqual(cellLater.blockedView.state, .none)

        // header
        let title1 = vc.tableView(vc.tableView, titleForHeaderInSection: 0)
        XCTAssertEqual(title1, "Missed...")

        let title2 = vc.tableView(vc.tableView, titleForHeaderInSection: 1)
        XCTAssertEqual(title2, "Today")

        let title3 = vc.tableView(vc.tableView, titleForHeaderInSection: 2)
        XCTAssertEqual(title3, "Later...")

        // edit actions
        let missedActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(missedActions?.count, 2)
        XCTAssertEqual(missedActions?[1].title, "Delete")
        XCTAssertEqual(missedActions?[0].title, "Done")

        let missedRecurringActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(missedRecurringActions?.count, 3)
        XCTAssertEqual(missedRecurringActions?[2].title, "Split")
        XCTAssertEqual(missedRecurringActions?[1].title, "Delete")
        XCTAssertEqual(missedRecurringActions?[0].title, "Done")

        let nowActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 1))
        XCTAssertEqual(nowActions?.count, 3)
        XCTAssertEqual(nowActions?[2].title, "Later")
        XCTAssertEqual(nowActions?[1].title, "Delete")
        XCTAssertEqual(nowActions?[0].title, "Done")

        let nowBlockedByActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 1, section: 1))
        XCTAssertEqual(nowBlockedByActions?.count, 2)
        XCTAssertEqual(nowBlockedByActions?[1].title, "Later")
        XCTAssertEqual(nowBlockedByActions?[0].title, "Delete")

        let nowRecurringActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 2, section: 1))
        XCTAssertEqual(nowRecurringActions?.count, 4)
        XCTAssertEqual(nowRecurringActions?[3].title, "Split")
        XCTAssertEqual(nowRecurringActions?[2].title, "Later")
        XCTAssertEqual(nowRecurringActions?[1].title, "Delete")
        XCTAssertEqual(nowRecurringActions?[0].title, "Done")

        let laterActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 2))
        XCTAssertEqual(laterActions?.count, 2)
        XCTAssertEqual(laterActions?[1].title, "Delete")
        XCTAssertEqual(laterActions?[0].title, "Done")
    }

    func testTableHeaderHideShow() {
        // mocks
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        vc.dataSource = dataSource
        dataSource.delegate = vc
        dataSource.sections[2] = [MockTodoItem()]
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertFalse(vc.tableView.tableHeaderView!.isHidden)

        // prepare
        dataSource.sections[0] = [MockTodoItem()]
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertTrue(vc.tableView.tableHeaderView!.isHidden)
    }

    func testBadgeNumber() {
        // mocks
        class MockBadge: Badge {
            var _number: Int = 0
            override var number: Int {
                get {
                    return _number
                }
                set {
                    _number = newValue
                }
            }
        }
        let dataSource = PlanDataSource()
        let badge = MockBadge()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        vc.badge = badge
        vc.dataSource = dataSource
        dataSource.delegate = vc
        dataSource.sections[0] = [MockTodoItem()]
        dataSource.sections[1] = [MockTodoItem()]
        dataSource.sections[2] = [MockTodoItem(), MockTodoItem(), MockTodoItem()]
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertEqual(badge.number, 2)
    }

    func testFolderButtonOpensArchiveView() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        UIApplication.shared.sendAction(vc.archiveButton.action!, to: vc.archiveButton.target!, from: nil, for: nil)
        let navController = vc.presentedViewController as! UINavigationController
        let rootViewController = navController.viewControllers.first!
        XCTAssertTrue(rootViewController is ArchiveViewController)
    }

    func testProjectsButtonOpensProjectsView() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        UIApplication.shared.sendAction(vc.projectsButton.action!, to: vc.projectsButton.target!, from: nil, for: nil)
        let navController = vc.presentedViewController as! UINavigationController
        let rootViewController = navController.viewControllers.first!
        XCTAssertTrue(rootViewController is ProjectsViewController)
    }
}
