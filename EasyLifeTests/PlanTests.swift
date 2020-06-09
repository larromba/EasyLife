import AsyncAwait
@testable import EasyLife
import Foundation
import TestExtensions
import XCTest

// swiftlint:disable file_length type_body_length
final class PlanTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: PlanViewController!
    private var env: AppTestEnvironment!

    override func setUp() {
        super.setUp()
        navigationController = UIStoryboard.plan.instantiateInitialViewController() as? UINavigationController
        viewController = navigationController.viewControllers.first as? PlanViewController
        env = AppTestEnvironment(viewController: viewController, navigationController: navigationController)
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        navigationController = nil
        viewController = nil
        env = nil
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    // MARK: - other

    func testNoDataHidesTableView() {
        // mocks
        env.inject()
        env.start()

        // test
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    func testDataShowsTableView() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty)
        env.start()

        // test
        waitSync()
        XCTAssertFalse(viewController.tableView.isHidden)
    }

    func testReloadOnAppWillEnterForeground() {
        // mocks
        env.inject()
        env.start()
        let isHidden = viewController.tableView.isHidden

        // sut
        _ = env.todoItem(type: .empty)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // test
        waitSync()
        XCTAssertNotEqual(isHidden, viewController.tableView.isHidden)
    }

    func testErrorAlertShows() {
        // mocks
        env.isLoaded = false
        env.inject()
        env.addToWindow()

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func testFatalErrorReplacesRootView() {
        // mocks
        env.inject()
        env.addToWindow()
        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: ""])

        // sut
        NotificationCenter.default.post(name: .applicationDidReceiveFatalError, object: error)

        // test
        XCTAssertTrue(UIApplication.shared.keyWindow?.rootViewController is FatalViewController)
    }

    func testBadgeValue() {
        // mocks
        let badge = MockBadge()
        env.badge = badge
        env.inject()
        _ = env.todoItem(type: .missed)
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(badge.invocations.find(MockBadge.setNumber1.name).first?
            .parameter(for: MockBadge.setNumber1.params.number) as? Int ?? 0, 2)
    }

    // MARK: - missed

    func testMissedItemAppearsInSection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .missed), 1)
    }

    func testMissedItemCellUI() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed, name: "test")
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .missed) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.red.color)
        XCTAssertEqual(cell.tagView.alpha, 1.0)
        XCTAssertTrue(cell.infoLabel.isHidden)
    }

    func testMissedActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed)
        env.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .missed) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
    }

    func testMissedActionsWithRepeatState() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed, repeatState: .daily)
        env.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .missed) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 3)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
        XCTAssertTrue(actions[safe: 2]?.isSplit ?? false)
    }

    // MARK: - today

    func testTodayItemAppearsInSection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .today), 1)
    }

    func testTodayItemCellUI() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, name: "test")
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, .black)
        XCTAssertEqual(cell.tagView.alpha, 1.0)
        XCTAssertTrue(cell.infoLabel.isHidden)
    }

    func testTodayItemNoNameIsGrey() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.grey.color)
    }

    func testTodayActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .today) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 3)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
        XCTAssertTrue(actions[safe: 2]?.isLater ?? false)
    }

    func testTodayActionsWithRepeatState() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, repeatState: .daily)
        env.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .today) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 4)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
        XCTAssertTrue(actions[safe: 2]?.isLater ?? false)
        XCTAssertTrue(actions[safe: 3]?.isSplit ?? false)
    }

    // MARK: - later

    func testLaterItemAppearsInSection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .later)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .later), 1)
    }

    func testLaterItemNoDateAppearsInSection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .later), 1)
    }

    func testLaterItemCellUI() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .later, name: "test")
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .later) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.grey.color)
        XCTAssertEqual(cell.tagView.alpha, 0.5)
        XCTAssertFalse(cell.infoLabel.isHidden)
    }

    func testLaterActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .later)
        env.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .later) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
    }

    // MARK: - blocking

    func testBlockedItemHidesDoneAction() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        env.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .today) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.filter { $0.isDone }.count, 0)
    }

    func testBlockedViewNotBlocked() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertTrue(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.backgroundColor, .clear)
    }

    func testBlockedViewBlockedBy() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertTrue(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.backgroundColor, Asset.Colors.red.color)
    }

    func testBlockedViewBlocking() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .later) else { return XCTFail("expected PlanCell") }
        XCTAssertTrue(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.backgroundColor, Asset.Colors.grey.color)
    }

    func testBlockedViewBlockedByAndBlocking() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        let item3 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        item.addToBlocking(item3)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertFalse(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.bottomView.backgroundColor, Asset.Colors.grey.color)
        XCTAssertEqual(cell.blockedView.backgroundColor, Asset.Colors.red.color)
    }

    // MARK: - other cell ui

    func testNotesIndicatorShows() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, notes: "test")
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.notesLabel.text, "...")
    }

    func testNotesIndicatorHides() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.notesLabel.text, "")
    }

    func testRecurringIconShows() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, repeatState: .daily)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.iconImageView.image, Asset.Assets.recurring.image)
    }

    func testNoIcon() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertNil(cell.iconImageView.image)
    }

    func testNoDateIcon() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty)
        env.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .later) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.iconImageView.image, Asset.Assets.nodate.image)
    }

    // MARK: - actions

    func testDoneMakesItemDone() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Done" }) else { return XCTFail("expected action") }
        action.fire()

        // test
        waitSync()
        XCTAssertTrue(item.done)
    }

    func testDoneMakesRecurringItemIncrementDate() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let date = item.date!
        env.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Done" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertGreaterThanOrEqual(item.date ?? date, date)
    }

    func testDeleteMakesItemDeleted() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Delete" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitAsync(delay: 0.5, queue: .asyncAwait) { completion in
            let items = try? await(self.env.dataManager.fetch(entityClass: TodoItem.self, sortBy: nil, context: .main,
                                                              predicate: nil))
            XCTAssertEqual(items?.count, 0)
            completion()
        }
    }

    func testSplitMakesItemSplit() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, repeatState: .daily)
        let item2 = env.todoItem(type: .empty)
        item.addToBlockedBy(item2)
        let date = item.date!
        env.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Split" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitAsync(delay: 0.5, queue: .asyncAwait) { completion in
            let items = try? await(self.env.dataManager.fetch(entityClass: TodoItem.self, sortBy: nil, context: .main,
                                                              predicate: nil))
            XCTAssertNotNil(items?.first(where: { $0.date == date && $0.repeatState == RepeatState.none }))
            XCTAssertNotNil(items?.first(where: { ($0.date ?? date) > date
                && $0.repeatState == .daily && ($0.blockedBy?.count ?? 0) == 0 }))
            completion()
        }
    }

    func testLaterMakesItemLater() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, repeatState: .daily)
        let date = item.date!
        env.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Later" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertGreaterThanOrEqual(item.date ?? date, date)
    }

    // MARK: - navigation

    func testOpenItemDetail() {
        // mocks
        env.inject()
        env.start()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
    }

    func testCellOpensItemDetail() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
    }

    func testOpenArchive() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        waitSync()
        XCTAssertTrue(viewController.archiveButton.fire())

        // test
        guard let navigationController = navigationController.presentedViewController as? UINavigationController else {
            XCTFail("expected UINavigationController")
            return
        }
        XCTAssertTrue(navigationController.viewControllers.first is ArchiveViewController)
    }

    func testOpenProjects() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.projectsButton.fire())

        // test
        waitSync()
        guard let navigationController = navigationController.presentedViewController as? UINavigationController else {
            XCTFail("expected UINavigationController")
            return
        }
        XCTAssertTrue(navigationController.viewControllers.first is ProjectsViewController)
    }

    func testFocusViewOpensWhenPressingFocusButton() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        waitSync()
        XCTAssertTrue(viewController.focusButton.fire())

        // test
        guard let navigationController = navigationController.presentedViewController as? UINavigationController else {
            XCTFail("expected UINavigationController")
            return
        }
        XCTAssertTrue(navigationController.viewControllers.first is FocusViewController)
    }

    // MARK: - order

    func testMissedOrder() {
        func title(for row: Int) -> String? {
            guard let cell = viewController.cell(row: row, section: .missed) else { return "not found" }
            return cell.titleLabel.text
        }

        // mocks
        env.inject()
        let project1 = env.project(priority: 0)
        let project2 = env.project(priority: 1)
        let project3 = env.project(priority: 2)
        let project4 = env.project(priority: Project.defaultPriority)
        _ = env.todoItem(type: .missed, name: "item1", project: project1)
        _ = env.todoItem(type: .missed, name: "item2", project: project2)
        _ = env.todoItem(type: .missed, name: "item3", project: project3)
        _ = env.todoItem(type: .missed, name: "item4")
        _ = env.todoItem(type: .missed, name: "item5", project: project4)
        _ = env.todoItem(type: .missed, name: "item6", project: project1)
        _ = env.todoItem(type: .missed, name: "item7", project: project1)
        _ = env.todoItem(type: .missed, name: "item8", project: project2)
        _ = env.todoItem(type: .missed, name: "item9")
        _ = env.todoItem(type: .missed)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(title(for: 0), "item1")
        XCTAssertEqual(title(for: 1), "item6")
        XCTAssertEqual(title(for: 2), "item7")
        XCTAssertEqual(title(for: 3), "item2")
        XCTAssertEqual(title(for: 4), "item8")
        XCTAssertEqual(title(for: 5), "item3")
        XCTAssertEqual(title(for: 6), "item5")
        XCTAssertEqual(title(for: 7), "item4")
        XCTAssertEqual(title(for: 8), "item9")
        XCTAssertEqual(title(for: 9), "[no name]")
    }

    func testTodayOrder() {
        func title(for row: Int) -> String? {
            guard let cell = viewController.cell(row: row, section: .today) else { return "not found" }
            return cell.titleLabel.text
        }

        // mocks
        env.inject()
        let project1 = env.project(priority: 0)
        let project2 = env.project(priority: 1)
        let project3 = env.project(priority: 2)
        let project4 = env.project(priority: Project.defaultPriority)
        _ = env.todoItem(type: .today, name: "item1", project: project1)
        _ = env.todoItem(type: .today, name: "item2", project: project2)
        _ = env.todoItem(type: .today, name: "item3", project: project3)
        _ = env.todoItem(type: .today, name: "item4")
        _ = env.todoItem(type: .today, name: "item5", project: project4)
        _ = env.todoItem(type: .today, name: "item6", project: project1)
        _ = env.todoItem(type: .today, name: "item7", project: project1)
        _ = env.todoItem(type: .today, name: "item8", project: project2)
        _ = env.todoItem(type: .today, name: "item9")
        _ = env.todoItem(type: .today)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(title(for: 0), "item1")
        XCTAssertEqual(title(for: 1), "item6")
        XCTAssertEqual(title(for: 2), "item7")
        XCTAssertEqual(title(for: 3), "item2")
        XCTAssertEqual(title(for: 4), "item8")
        XCTAssertEqual(title(for: 5), "item3")
        XCTAssertEqual(title(for: 6), "item5")
        XCTAssertEqual(title(for: 7), "item4")
        XCTAssertEqual(title(for: 8), "item9")
        XCTAssertEqual(title(for: 9), "[no name]")
    }

    func testLaterOrder() {
        func title(for row: Int) -> String? {
            guard let cell = viewController.cell(row: row, section: .later) else { return "not found" }
            return cell.titleLabel.text
        }
        func date(_ string: String) -> Date {
            let dateFormatter = ISO8601DateFormatter()
            return dateFormatter.date(from: string)!
        }

        // mocks
        env.inject()
        let project1 = env.project(priority: 0)
        let project2 = env.project(priority: 1)
        let project3 = env.project(priority: 2)
        let project4 = env.project(priority: Project.defaultPriority)
        _ = env.todoItem(type: .laterDay(1), name: "item1", project: project1)
        _ = env.todoItem(type: .laterDay(2), name: "item2", project: project2)
        _ = env.todoItem(type: .laterDay(3), name: "item3", project: project3)
        _ = env.todoItem(type: .laterDay(3), name: "item4")
        _ = env.todoItem(type: .laterDay(1), name: "item5", project: project4)
        _ = env.todoItem(type: .laterDay(1), name: "item6", project: project1)
        _ = env.todoItem(type: .empty, name: "item7", project: project1)
        _ = env.todoItem(type: .empty, name: "item8", project: project2)
        _ = env.todoItem(type: .laterDay(1), name: "item9")
        // #bug 30jul19: dates with same day appearing in wrong order
        _ = env.todoItem(type: .laterDate(date("3001-04-14T10:44:00+0000")), name: "item10", project: project1)
        _ = env.todoItem(type: .laterDate(date("3000-04-14T10:44:00+0000")), name: "item11", project: project1)
        _ = env.todoItem(type: .empty)
        env.start()

        // test
        waitSync()
        XCTAssertEqual(title(for: 0), "item7")
        XCTAssertEqual(title(for: 1), "item8")
        XCTAssertEqual(title(for: 2), "[no name]")
        XCTAssertEqual(title(for: 3), "item1")
        XCTAssertEqual(title(for: 4), "item6")
        XCTAssertEqual(title(for: 5), "item5")
        XCTAssertEqual(title(for: 6), "item9")
        viewController.tableView.scrollUp(by: 200) // assuming iphone6
        XCTAssertEqual(title(for: 7), "item2")
        XCTAssertEqual(title(for: 8), "item3")
        XCTAssertEqual(title(for: 9), "item4")
        XCTAssertEqual(title(for: 10), "item11")
        XCTAssertEqual(title(for: 11), "item10")
    }
}

// MARK: - UITableViewRowAction

private extension UITableViewRowAction {
    var isDelete: Bool { return title == "Delete" && backgroundColor == Asset.Colors.red.color }
    var isDone: Bool { return title == "Done" && backgroundColor == Asset.Colors.green.color }
    var isSplit: Bool { return title == "Split" && backgroundColor == Asset.Colors.grey.color }
    var isLater: Bool { return title == "Later" && backgroundColor == Asset.Colors.grey.color }
}

// MARK: - PlanViewController

private extension PlanViewController {
    func rows(for section: PlanSection) -> Int {
        return tableView(tableView, numberOfRowsInSection: section.rawValue)
    }

    func cell(row: Int, section: PlanSection) -> PlanCell? {
        let indexPath = IndexPath(row: row, section: section.rawValue)
        return tableView.cellForRow(at: indexPath) as? PlanCell
    }

    func actions(row: Int, section: PlanSection) -> [UITableViewRowAction]? {
        let indexPath = IndexPath(row: 0, section: section.rawValue)
        return tableView(tableView, editActionsForRowAt: indexPath)
    }
}
