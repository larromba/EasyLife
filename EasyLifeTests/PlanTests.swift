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
        viewController.prepareView()
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

    func test_tableView_whenNoData_expectIsHidden() {
        // mocks
        env.inject()
        env.planController.start()

        // test
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    func test_tableView_whenHasData_expectIsShowing() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty)
        env.planController.start()

        // test
        waitSync()
        XCTAssertFalse(viewController.tableView.isHidden)
    }

    func test_alert_whenDataError_expectThrown() {
        // mocks
        env.persistentContainer = .mock(fetchError: MockError.mock)
        env.inject()
        env.addToWindow()
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.title, "Error")
    }

    func test_notification_whenDidBecomeActive_expectReload() {
        // mocks
        env.inject()
        env.planController.start()
        let isHidden = viewController.tableView.isHidden

        // sut
        _ = env.todoItem(type: .empty)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // test
        waitSync()
        XCTAssertNotEqual(isHidden, viewController.tableView.isHidden)
    }

    func test_notification_whenDidReceieveFatalError_expectRootViewReplaced() {
        // mocks
        env.inject()
        env.addToWindow()
        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: ""])

        // sut
        NotificationCenter.default.post(name: .applicationDidReceiveFatalError, object: error)

        // test
        XCTAssertTrue(UIApplication.shared.keyWindow?.rootViewController is FatalViewController)
    }

    func test_badge_whenNewItemsAdded_expectNewValue() {
        // mocks
        let badge = MockAppBadge()
        env.badge = badge
        env.inject()
        _ = env.todoItem(type: .missed)
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(badge.invocations.find(MockAppBadge.setNumber1.name).first?
            .parameter(for: MockAppBadge.setNumber1.params.number) as? Int ?? 0, 2)
    }

    func test_openApp_whenAlarmNotificationExists_expectFocusViewWithState() {
        // mocks
        let alarmNotificationHandler = MockAlarmNotificationHandler()
        env.alarmNotificationHandler = alarmNotificationHandler
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        alarmNotificationHandler.actions.set(
            returnValue: Async<Date?, Error> { completion in
                completion(.success(Date().addingTimeInterval(60)))
            },
            for: MockAlarmNotificationHandler.currentNotificationDate3.name
        )
        viewController.prepareView()

        // sut
        env.app.start()

        // test
        waitSync()
        guard let navigationController = viewController.presentedViewController as? UINavigationController,
            let focusViewController = navigationController.viewControllers.first as? FocusViewController else {
                XCTFail("expected FocusViewController")
                return
        }
        XCTAssertEqual(focusViewController.timeLabel.text, "00:00:59")
        XCTAssertEqual(focusViewController.timerButton.titleLabel?.text, "Stop")
    }

    // MARK: - missed

    func test_missedItem_whenAppears_expectAppearsInMissedSection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed)
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .missed), 1)
    }

    func test_missedItem_whenAppears_expectUIConfiguration() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed, name: "test")
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .missed) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.red.color)
        XCTAssertEqual(cell.tagView.alpha, 1.0)
        XCTAssertTrue(cell.infoLabel.isHidden)
    }

    func test_missedItem_whenOpened_expectActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed)
        env.planController.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .missed) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
    }

    func test_missedItemWithRepeatState_whenOpened_expectActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .missed, repeatState: .daily)
        env.planController.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .missed) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 3)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
        XCTAssertTrue(actions[safe: 2]?.isSplit ?? false)
    }

    // MARK: - today

    func test_todayItem_whenAppears_expectAppearsInTodaySection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .today), 1)
    }

    func test_todayItem_whenAppears_expectUIConfiguration() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, name: "test")
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, .black)
        XCTAssertEqual(cell.tagView.alpha, 1.0)
        XCTAssertTrue(cell.infoLabel.isHidden)
    }

    func test_todayItemWithNoName_whenAppears_expectNameIsGrey() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.grey.color)
    }

    func test_todayItem_whenOpened_expectActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .today) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 3)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
        XCTAssertTrue(actions[safe: 2]?.isLater ?? false)
    }

    func test_todayItemWithRepeatState_whenOpened_expectActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, repeatState: .daily)
        env.planController.start()

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

    func test_laterItem_whenAppears_expectAppearsInLaterSection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .later)
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .later), 1)
    }

    func test_itemWithNoDate_whenAppears_expectAppearsInLaterSection() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty)
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(for: .later), 1)
    }

    func test_laterItem_whenAppears_expectUIConfiguration() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .later, name: "test")
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .later) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.titleLabel?.textColor, Asset.Colors.grey.color)
        XCTAssertEqual(cell.tagView.alpha, 0.5)
        XCTAssertFalse(cell.infoLabel.isHidden)
    }

    func test_laterItem_whenOpened_expectActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .later)
        env.planController.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .later) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions[safe: 0]?.isDone ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDelete ?? false)
    }

    // MARK: - blocked / blocking

    func test_blockedItem_whenAppears_expectNoDoneAction() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        env.planController.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .today) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.filter { $0.isDone }.count, 0)
    }

    func test_blockingItem_whenAppears_expectDoneAction() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        env.planController.start()

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .later) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.filter { $0.isDone }.count, 1)
    }

    func test_item_whenNotBlocked_expectUIConfiguration() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertTrue(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.backgroundColor, .clear)
    }

    func test_item_whenBlocked_expectUIConfiguration() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertTrue(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.backgroundColor, Asset.Colors.red.color)
    }

    func test_item_whenBlocking_expectUIConfiguration() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .later) else { return XCTFail("expected PlanCell") }
        XCTAssertTrue(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.backgroundColor, Asset.Colors.grey.color)
    }

    func test_item_whenBlockedAndBlocking_expectUIConfiguration() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let item2 = env.todoItem(type: .later)
        let item3 = env.todoItem(type: .later)
        item.addToBlockedBy(item2)
        item.addToBlocking(item3)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertFalse(cell.blockedView.bottomView.isHidden)
        XCTAssertEqual(cell.blockedView.bottomView.backgroundColor, Asset.Colors.grey.color)
        XCTAssertEqual(cell.blockedView.backgroundColor, Asset.Colors.red.color)
    }

    // MARK: - other cell ui

    func test_itemWithNotes_whenAppears_expectNotesIndicatorIsShowing() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, notes: "test")
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.notesLabel.text, "...")
    }

    func test_itemWithNoNotes_whenAppears_expectNotesIndicatorIsHidden() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.notesLabel.text, "")
    }

    func test_recurringItem_whenAppears_expectRecurringIconIsShowing() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today, repeatState: .daily)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.iconImageView.image, Asset.Assets.recurring.image)
    }

    func test_basicItem_whenAppears_expectAllIconsAreHidden() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .today) else { return XCTFail("expected PlanCell") }
        XCTAssertNil(cell.iconImageView.image)
    }

    func test_noDateItem_whenAppears_expectNoDateIconIsShowing() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty)
        env.planController.start()

        // test
        waitSync()
        guard let cell = viewController.cell(row: 0, section: .later) else { return XCTFail("expected PlanCell") }
        XCTAssertEqual(cell.iconImageView.image, Asset.Assets.nodate.image)
    }

    // MARK: - actions

    func test_doneAction_whenSelected_expectItemIsDone() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.planController.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Done" }) else { return XCTFail("expected action") }
        action.fire()

        // test
        waitSync()
        XCTAssertTrue(item.done)
    }

    func test_doneAction_whenSelectedOnRecurringItem_expectDateIncremented() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let date = item.date!
        env.planController.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Done" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertGreaterThanOrEqual(item.date ?? date, date)
    }

    func test_deleteAction_whenSelected_expectItemDeleted() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Delete" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitAsync(delay: 0.5, queue: .asyncAwait) { completion in
            let context = self.env.dataContextProvider.mainContext()
            let items = try? await(context.fetch(entityClass: TodoItem.self, sortBy: nil, predicate: nil))
            XCTAssertEqual(items?.count, 0)
            completion()
        }
    }

    func test_splitAction_whenSelected_expectItemSplitIntoTwoItems_oneInSameSection_anotherOnNextRecurringDate() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, repeatState: .daily)
        let item2 = env.todoItem(type: .empty)
        item.addToBlockedBy(item2)
        let date = item.date!
        env.planController.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Split" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitAsync(delay: 0.5, queue: .asyncAwait) { completion in
            let context = self.env.dataContextProvider.mainContext()
            let items = try? await(context.fetch(entityClass: TodoItem.self, sortBy: nil, predicate: nil))
            XCTAssertNotNil(items?.first(where: { $0.date == date && $0.repeatState == .default }))
            XCTAssertNotNil(items?.first(where: { ($0.date ?? date) > date
                && $0.repeatState == .daily && ($0.blockedBy?.count ?? 0) == 0 }))
            completion()
        }
    }

    func test_laterAction_whenSelected_expectItemHasNoDate() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.planController.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Later" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertNil(item.date)
    }

    func test_laterAction_whenSelectedOnRecurringItem_expectItemHasNextDate() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, repeatState: .daily)
        let date = item.date!
        env.planController.start()

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: .today)?
            .first(where: { $0.title == "Later" }) else { return XCTFail("expected action") }
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertGreaterThanOrEqual(item.date ?? date, date)
    }

    // MARK: - long press actions

    func test_longPressAction_whenMissedCellPressed_expectAlertShown() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .missed)
        env.planController.start()

        // sut
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.title, "Quick Edit")
    }

    func test_longPressAction_whenTodayCellPressed_expectNoAlertShown() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // sut
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // test
        waitSync()
        XCTAssertNil(viewController.presentedViewController)
    }

    func test_longPressAction_whenLaterCellPressed_expectNoShown() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .later)
        env.planController.start()

        // sut
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // test
        waitSync()
        XCTAssertNil(viewController.presentedViewController)
    }

    func test_longPressAction_whenMissedSectionHasOneItem_expectAlertOptions() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .missed)
        env.planController.start()

        // sut
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.actions.count, 3)
    }

    func test_longPressAction_whenMissedSectionHasManyItems_expectAlertOptions() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .missed)
        _ = env.todoItem(type: .missed)
        env.planController.start()

        // sut
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.actions.count, 5)
    }

    func test_longPressTodayAction_whenPressed_expectItemsIsMovedToToday() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .missed)
        env.planController.start()
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // sut
        waitSync()
        XCTAssertTrue(viewController.presentedViewController?.asAlertController?.actions[safe: 1]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertEqual(item.date?.earliest, Date().earliest)
    }

    func test_longPressTomorrowAction_whenPressed_expectItemsIsMovedToTomorrow() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .missed)
        env.planController.start()
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // sut
        waitSync()
        XCTAssertTrue(viewController.presentedViewController?.asAlertController?.actions[safe: 2]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertEqual(item.date?.earliest, Date().addingTimeInterval(24 * 60 * 60).earliest)
    }

    func test_longPressAllTodayAction_whenPressed_expectItemsAllMovedToToday() {
        // mocks
        env.inject()
        env.addToWindow()
        let item1 = env.todoItem(type: .missed)
        let item2 = env.todoItem(type: .missed)
        env.planController.start()
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // sut
        waitSync()
        XCTAssertTrue(viewController.presentedViewController?.asAlertController?.actions[safe: 3]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertEqual(item1.date?.earliest, Date().earliest)
        XCTAssertEqual(item2.date?.earliest, Date().earliest)
    }

    func test_longPressAllTomorrowAction_whenPressed_expectItemsAllMovedToTomorrow() {
        // mocks
        env.inject()
        env.addToWindow()
        let item1 = env.todoItem(type: .missed)
        let item2 = env.todoItem(type: .missed)
        env.planController.start()
        waitSync()
        viewController.longPressCell(row: 0, section: .missed)

        // sut
        waitSync()
        XCTAssertTrue(viewController.presentedViewController?.asAlertController?.actions[safe: 4]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertEqual(item1.date?.earliest, Date().addingTimeInterval(24 * 60 * 60).earliest)
        XCTAssertEqual(item2.date?.earliest, Date().addingTimeInterval(24 * 60 * 60).earliest)
    }

    // MARK: - navigation

    func test_addButton_whenTapped_expectItemDetailShown() {
        // mocks
        env.inject()
        env.planController.start()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
    }

    func test_cell_whenTapped_expectItemDetailShown() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
    }

    func test_archiveButton_whenTapped_expectArchiveShown() {
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

    func test_projectsButton_whenTapped_expectProjectsShown() {
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

    func test_focusButton_whenTapped_expectFocusViewShown() {
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

    func test_focusButton_whenNoTodayItems_expectDisabled() {
        // mocks
        env.inject()
        env.planController.start()

        // test
        XCTAssertFalse(viewController.focusButton.isEnabled)
    }

    func test_focusButton_whenTodayItems_expectEnabled() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()

        // test
        waitSync()
        XCTAssertTrue(viewController.focusButton.isEnabled)
    }

    // MARK: - holiday

    func test_view_whenDoubleTapped_expectShowsHoidayView() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is HolidayViewController)
    }

    func test_holidayView_whenAppears_expectHolidayEnabled() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // test
        waitSync()
        XCTAssertTrue(env.userDefaults.bool(forKey: .holiday))
    }

    func test_holidayView_whenAppears_expectShortcutsCleared() {
        // mocks
        env.inject()
        env.addToWindow()

        // sut
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // test
        waitSync()
        XCTAssertEqual(UIApplication.shared.shortcutItems?.count, 0)
    }

    func test_holidayView_whenAppears_expectNotificationsCleared() {
        // mocks
        let badge = MockAppBadge()
        env.badge = badge
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .empty)
        env.planController.start()

        // sut
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // test
        waitSync()
        XCTAssertEqual(badge.invocations.find(MockAppBadge.setNumber1.name).first?
            .parameter(for: MockAppBadge.setNumber1.params.number) as? Int ?? -1, 0)
    }

    func test_holidayView_whenTapped_expectHidesView() {
        // mocks
        env.inject()
        env.addToWindow()
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // sut
        waitSync()
        guard let holidayViewController = viewController.presentedViewController as? HolidayViewController else {
            XCTFail("expected HolidayViewController")
            return
        }
        holidayViewController.touchesEnded(Set([]), with: nil)

        // test
        waitSync()
        XCTAssertNil(viewController.presentedViewController)
    }

    func test_holidayView_whenHidden_expectHolidayDisabled() {
        // mocks
        env.inject()
        env.addToWindow()
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // sut
        waitSync()
        guard let holidayViewController = viewController.presentedViewController as? HolidayViewController else {
            XCTFail("expected HolidayViewController")
            return
        }
        holidayViewController.touchesEnded(Set([]), with: nil)

        // test
        waitSync()
        XCTAssertFalse(env.userDefaults.bool(forKey: .holiday))
    }

    func test_holidayView_whenHidden_expectShortcutsEnabled() {
        // mocks
        env.inject()
        env.addToWindow()
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // sut
        waitSync()
        guard let holidayViewController = viewController.presentedViewController as? HolidayViewController else {
            XCTFail("expected HolidayViewController")
            return
        }
        holidayViewController.touchesEnded(Set([]), with: nil)

        // test
        waitSync()
        XCTAssertEqual(UIApplication.shared.shortcutItems, ShortcutItem.display.map { $0.item })
    }

    func test_holidayView_whenHidden_expectNotifications() {
        // mocks
        let badge = MockAppBadge()
        env.badge = badge
        env.addToWindow()
        env.inject()
        _ = env.todoItem(type: .today)
        env.planController.start()
        waitSync()
        viewController.view.gestureRecognizers?.first?.state = .ended

        // sut
        waitSync()
        guard let holidayViewController = viewController.presentedViewController as? HolidayViewController else {
            XCTFail("expected HolidayViewController")
            return
        }
        holidayViewController.touchesEnded(Set([]), with: nil)

        // test
        waitSync()
        XCTAssertEqual(badge.invocations.find(MockAppBadge.setNumber1.name).last?
            .parameter(for: MockAppBadge.setNumber1.params.number) as? Int ?? 0, 1)
    }

    func test_holidayIsEnabled_whenAppIsRestarted_expectShowingView() {
        // mocks
        env.inject()
        env.addToWindow()
        env.holidayRepository.isEnabled = true

        // sut
        env.planController.start()

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is HolidayViewController)
    }

    func test_holidayIsDisabled_whenAppIsRestarted_expectNotShowingView() {
        // mocks
        env.inject()
        env.addToWindow()
        env.holidayRepository.isEnabled = false

        // sut
        env.planController.start()

        // test
        waitSync()
        XCTAssertNil(viewController.presentedViewController)
    }

    // MARK: - order

    func test_missedSection_whenLoaded_expectOrder() {
        testOrder(type: .missed, section: .missed)
    }

    func test_todaySection_whenLoaded_expectOrder() {
        testOrder(type: .today, section: .today)
    }

    // swiftlint:disable function_body_length
    func test_laterSection_whenLoaded_expectOrder() {
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
        let blocker = env.todoItem(type: .laterDay(1), name: "blocker", project: project4)
        let sharedBlocker1 = env.todoItem(type: .laterDay(1), name: "shared-blocker1", project: project4,
                                          blockedBy: [blocker])
        let sharedBlocker2 = env.todoItem(type: .laterDay(1), name: "shared-blocker2", project: project4,
                                          blockedBy: [blocker])
        _ = env.todoItem(type: .laterDay(1), name: "blockedBy1", project: project4,
                         blockedBy: [blocker, sharedBlocker1, sharedBlocker2])
        _ = env.todoItem(type: .laterDay(1), name: "blockedBy2", project: project4,
                         blockedBy: [blocker, sharedBlocker1, sharedBlocker2])
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(title(for: 0), "item7")
        XCTAssertEqual(title(for: 1), "item8")
        XCTAssertEqual(title(for: 2), "[no name]")
        XCTAssertEqual(title(for: 3), "item1")
        XCTAssertEqual(title(for: 4), "item6")
        XCTAssertEqual(title(for: 5), "item5")
        XCTAssertEqual(title(for: 6), "blocker")
        viewController.tableView.scrollUp(by: 200) // assuming iphone6
        XCTAssertEqual(title(for: 7), "shared-blocker1")
        XCTAssertEqual(title(for: 8), "shared-blocker2")
        XCTAssertEqual(title(for: 9), "blockedBy1")
        XCTAssertEqual(title(for: 10), "blockedBy2")
        XCTAssertEqual(title(for: 11), "item9")
        XCTAssertEqual(title(for: 12), "item2")
        viewController.tableView.scrollUp(by: 400) // assuming iphone6
        XCTAssertEqual(title(for: 13), "item3")
        XCTAssertEqual(title(for: 14), "item4")
        XCTAssertEqual(title(for: 15), "item11")
        XCTAssertEqual(title(for: 16), "item10")
    }

    // swiftlint:disable function_body_length
    private func testOrder(type: AppTestEnvironment.TodoItemType, section: PlanSection) {
        func title(for row: Int, section: PlanSection) -> String? {
            guard let cell = viewController.cell(row: row, section: section) else { return "not found" }
            return cell.titleLabel.text
        }

        // mocks
        env.inject()
        let project1 = env.project(priority: 0)
        let project2 = env.project(priority: 1)
        let project3 = env.project(priority: 2)
        let project4 = env.project(priority: Project.defaultPriority)
        _ = env.todoItem(type: type, name: "item1", project: project1)
        _ = env.todoItem(type: type, name: "item2", project: project2)
        _ = env.todoItem(type: type, name: "item3", project: project3)
        _ = env.todoItem(type: type, name: "item4")
        _ = env.todoItem(type: type, name: "item5", project: project4)
        _ = env.todoItem(type: type, name: "item6", project: project1)
        _ = env.todoItem(type: type, name: "item7", project: project1)
        _ = env.todoItem(type: type, name: "item8", project: project2)
        _ = env.todoItem(type: type, name: "item9")
        _ = env.todoItem(type: type)
        let blocker = env.todoItem(type: type, name: "blocker", project: project4)
        let sharedBlocker1 = env.todoItem(type: type, name: "shared-blocker1", project: project4,
                                          blockedBy: [blocker])
        let sharedBlocker2 = env.todoItem(type: type, name: "shared-blocker2", project: project4,
                                          blockedBy: [blocker])
        _ = env.todoItem(type: type, name: "blockedBy1", project: project4,
                         blockedBy: [blocker, sharedBlocker1, sharedBlocker2])
        _ = env.todoItem(type: type, name: "blockedBy2", project: project4,
                         blockedBy: [blocker, sharedBlocker1, sharedBlocker2])
        env.planController.start()

        // test
        waitSync()
        XCTAssertEqual(title(for: 0, section: section), "item1")
        XCTAssertEqual(title(for: 1, section: section), "item6")
        XCTAssertEqual(title(for: 2, section: section), "item7")
        XCTAssertEqual(title(for: 3, section: section), "item2")
        XCTAssertEqual(title(for: 4, section: section), "item8")
        XCTAssertEqual(title(for: 5, section: section), "item3")
        XCTAssertEqual(title(for: 6, section: section), "item5")
        XCTAssertEqual(title(for: 7, section: section), "blocker")
        XCTAssertEqual(title(for: 8, section: section), "shared-blocker1")
        XCTAssertEqual(title(for: 9, section: section), "shared-blocker2")
        XCTAssertEqual(title(for: 10, section: section), "blockedBy1")
        XCTAssertEqual(title(for: 11, section: section), "blockedBy2")
        viewController.tableView.scrollUp(by: 200) // assuming iphone6
        XCTAssertEqual(title(for: 12, section: section), "item4")
        XCTAssertEqual(title(for: 13, section: section), "item9")
        XCTAssertEqual(title(for: 14, section: section), "[no name]")
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
        let indexPath = IndexPath(row: row, section: section.rawValue)
        return tableView(tableView, editActionsForRowAt: indexPath)
    }

    func longPressCell(row: Int, section: PlanSection) {
        cell(row: row, section: section)?.gestureRecognizers?[safe: 0]?.state = .began
    }
}
