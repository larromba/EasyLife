import Foundation
@testable import EasyLife
import TestExtensions
import XCTest

final class PlanTests: XCTestCase {
    private var viewController: PlanViewController!
    private var env: PlanEnvironment!

    override func setUp() {
        super.setUp()
        viewController = UIStoryboard.plan
            .instantiateViewController(withIdentifier: "PlanViewController") as? PlanViewController
        env = PlanEnvironment(viewController: viewController, persistentContainer: .mock())
    }

    override func tearDown() {
        viewController = nil
        env = nil
        super.tearDown()
    }

    // MARK: - other

    func testNoDataHidesTableView() {
        // mocks
        env.inject()
        viewController.prepareView()

        // test
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    func testDataShowsTableView() {
        // mocks
        env.inject()
        _ = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            XCTAssertFalse(self.viewController.tableView.isHidden)
        }
    }

    func testReloadOnAppWillEnterForeground() {
        // mocks
        env.inject()
        viewController.prepareView()
        env.planController.start()
        let isHidden = viewController.tableView.isHidden

        // sut
        _ = self.env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        NotificationCenter.default.post(name: .UIApplicationWillEnterForeground, object: nil)

        // test
        wait {
            XCTAssertNotEqual(isHidden, self.viewController.tableView.isHidden)
        }
    }

    func testAlertShows() {
        XCTFail()
    }

    // MARK: - missed

    func testMissedItemAppearsInSection() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date().minusDays(2)
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            XCTAssertEqual(self.viewController.tableView(self.viewController.tableView,
                                                         numberOfRowsInSection: PlanSection.missed.rawValue), 1)
        }
    }

    func testMissedItemCellUI() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date().minusDays(2); item.name = "test"
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.missed.rawValue)
            guard let cell = self.viewController.tableView.cellForRow(at: indexPath) as? PlanCell else {
                XCTFail("expected PlanCell")
                return
            }
            XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.red.color)
            XCTAssertEqual(cell.tagView.alpha, 1.0)
            XCTAssertTrue(cell.infoLabel.isHidden)
        }
    }

    func testMissedActions() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date().minusDays(2)
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.missed.rawValue)
            guard let actions = self.viewController
                .tableView(self.viewController.tableView, editActionsForRowAt: indexPath) else {
                    XCTFail("expected actions")
                    return
            }
            XCTAssertEqual(actions.count, 2)
            XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
            XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
        }
    }

    func testMissedActionsWithRepeatState() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date().minusDays(2); item.repeatState = .daily
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.missed.rawValue)
            guard let actions = self.viewController
                .tableView(self.viewController.tableView, editActionsForRowAt: indexPath) else {
                    XCTFail("expected actions")
                    return
            }
            XCTAssertEqual(actions.count, 3)
            XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
            XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
            XCTAssertTrue(actions[safe: 2]?.isSplit ?? false)
        }
    }

    // MARK: - today

    func testTodayItemAppearsInSection() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date()
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            XCTAssertEqual(self.viewController.tableView(self.viewController.tableView,
                                                         numberOfRowsInSection: PlanSection.today.rawValue), 1)
        }
    }

    func testTodayItemCellUI() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date(); item.name = "test"
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.today.rawValue)
            guard let cell = self.viewController.tableView.cellForRow(at: indexPath) as? PlanCell else {
                XCTFail("expected PlanCell")
                return
            }
            XCTAssertEqual(cell.titleLabel?.textColor, .black)
            XCTAssertEqual(cell.tagView.alpha, 1.0)
            XCTAssertTrue(cell.infoLabel.isHidden)
        }
    }

    func testTodayActions() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date()
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.today.rawValue)
            guard let actions = self.viewController
                .tableView(self.viewController.tableView, editActionsForRowAt: indexPath) else {
                    XCTFail("expected actions")
                    return
            }
            XCTAssertEqual(actions.count, 3)
            XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
            XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
            XCTAssertTrue(actions[safe: 2]?.isLater ?? false)
        }
    }

    func testTodayActionsWithRepeatState() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date(); item.repeatState = .daily
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.today.rawValue)
            guard let actions = self.viewController
                .tableView(self.viewController.tableView, editActionsForRowAt: indexPath) else {
                    XCTFail("expected actions")
                    return
            }
            XCTAssertEqual(actions.count, 4)
            XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
            XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
            XCTAssertTrue(actions[safe: 2]?.isLater ?? false)
            XCTAssertTrue(actions[safe: 3]?.isSplit ?? false)
        }
    }

    // MARK: - later

    func testLaterItemAppearsInSection() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date().plusDays(2)
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            XCTAssertEqual(self.viewController.tableView(self.viewController.tableView,
                                                         numberOfRowsInSection: PlanSection.later.rawValue), 1)
        }
    }

    func testLaterItemNoDateAppearsInSection() {
        // mocks
        env.inject()
        _ = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            XCTAssertEqual(self.viewController.tableView(self.viewController.tableView,
                                                         numberOfRowsInSection: PlanSection.later.rawValue), 1)
        }
    }

    func testLaterItemCellUI() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date().plusDays(2); item.name = "test"
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.later.rawValue)
            guard let cell = self.viewController.tableView.cellForRow(at: indexPath) as? PlanCell else {
                XCTFail("expected PlanCell")
                return
            }
            XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.grey.color)
            XCTAssertEqual(cell.tagView.alpha, 0.5)
            XCTAssertFalse(cell.infoLabel.isHidden)
        }
    }

    func testLaterActions() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date().minusDays(2)
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.later.rawValue)
            guard let actions = self.viewController
                .tableView(self.viewController.tableView, editActionsForRowAt: indexPath) else {
                    XCTFail("expected actions")
                    return
            }
            XCTAssertEqual(actions.count, 2)
            XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
            XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
        }
    }

    // MARK: - other cell ui

    func testBlockedItemHidesDoneAction() {
        // mocks
        env.inject()
        let item = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        let item2 = env.dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.date = Date(); item.addToBlockedBy(item2)
        viewController.prepareView()
        env.planController.start()

        // test
        wait {
            let indexPath = IndexPath(row: 0, section: PlanSection.today.rawValue)
            guard let actions = self.viewController
                .tableView(self.viewController.tableView, editActionsForRowAt: indexPath) else {
                    XCTFail("expected actions")
                    return
            }
            XCTAssertEqual(actions.filter { $0.isDone }.count, 0)
        }
    }

    func testBlockedViewShows() {
        XCTFail()
    }

    func testBlockedViewHides() {
        XCTFail()
    }

    func testNotes() {
        XCTFail()
    }

    func testRecurringIcon() {
        XCTFail()
    }

    // MARK: - actions

    func testDoneMakesItemDone() {
        XCTFail()
    }

    func testDeleteMakesItemDeleted() {
        XCTFail()
    }

    func testSkipMakesItemSkipped() {
        XCTFail()
    }

    func testLaterMakesItemLater() {
        XCTFail()
    }

    // MARK: - navigation

    func testOpenItemDetail() {
        XCTFail()
    }

    func testCellOpensItemDetail() {
        XCTFail()
    }

    func testOpenArchive() {
        XCTFail()
    }

    func testOpenProjects() {
        XCTFail()
    }

    // MARK: - order

    func testMissedOrder() {
        XCTFail()
    }

    func testTodayOrder() {
        XCTFail()
    }

    func testLaterOrder() {
        XCTFail()
    }
}

// MARK: - UITableViewRowAction

private extension UITableViewRowAction {
    var isDelete: Bool {
        return title == "Delete" && backgroundColor == Asset.Colors.red.color
    }
    var isDone: Bool {
        return title == "Done" && backgroundColor == Asset.Colors.green.color
    }
    var isSplit: Bool {
        return title == "Split" && backgroundColor == Asset.Colors.grey.color
    }
    var isLater: Bool {
        return title == "Later" && backgroundColor == Asset.Colors.grey.color
    }
}
