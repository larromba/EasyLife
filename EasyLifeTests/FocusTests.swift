import AsyncAwait
@testable import EasyLife
import Foundation
import TestExtensions
import UserNotifications
import XCTest

// swiftlint:disable type_body_length file_length
final class FocusTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: FocusViewController!
    private var alertController: AlertController!
    private var env: AppTestEnvironment!
    private var kvo: NSKeyValueObservation!

    override func setUp() {
        super.setUp()
        navigationController = UIStoryboard.focus.instantiateInitialViewController() as? UINavigationController
        viewController = navigationController.viewControllers.first as? FocusViewController
        viewController.prepareView()
        alertController = AlertController(presenter: viewController)
        env = AppTestEnvironment(navigationController: navigationController)
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        env = nil
        viewController = nil
        navigationController = nil
        kvo = nil
        UIView.setAnimationsEnabled(true)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        super.tearDown()
    }

    // MARK: - cell actions

    func test_item_whenOpened_expectDoneAction() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0) else { return XCTFail("expected actions") }
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions.filter { $0.isDone }.count, 1)
    }

    // MARK: - display logic

    func test_item_whenDone_expectIsDoneAndShownNextItem() {
        // mocks
        env.inject()
        let firstItem = env.todoItem(type: .today, name: "a")
        _ = env.todoItem(type: .today, name: "b")
        env.focusController.setViewController(viewController)

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0)?.first else { return XCTFail("expected actions") }
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(), 1)
        XCTAssertTrue(firstItem.done)
    }

    func test_lastItem_whenDone_expectIsDoneAndHidesView() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, name: "a")
        let presenter = addToPresenter()
        env.focusController.setViewController(viewController)

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0)?.first else { return XCTFail("expected actions") }
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertTrue(item.done)
        XCTAssertNil(presenter.presentedViewController)
    }

    // MARK: - missing item alert

    func test_onAppear_whenMissingItems_expectAlertDisplayed() {
        // mocks
        env.inject()
        env.addToWindow()
        setupMissingItems()
        env.focusCoordinator.setAlertController(alertController)
        env.focusController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.title, "Missing Items")
    }

    func test_missingItemsAlert_whenNoPressed_expectViewDismissed() {
        // mocks
        env.inject()
        setupMissingItems()
        let presenter = addToPresenter()
        env.focusCoordinator.setAlertController(alertController)
        env.focusController.setViewController(viewController)

        // sut
        waitSync()
        guard let alertController = navigationController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }
        XCTAssertTrue(alertController.actions[safe: 0]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertNil(presenter.presentedViewController)
    }

    func test_missingItemsAlert_whenYesPressed_expectMovesMissingItems() {
        // mocks
        env.inject()
        setupMissingItems()
        _ = addToPresenter()
        env.focusCoordinator.setAlertController(alertController)
        env.focusController.setViewController(viewController)

        // sut
        waitSync()
        guard let alertController = navigationController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }
        XCTAssertTrue(alertController.actions[safe: 1]?.fire() ?? false)

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let items = try? await(self.env.planRepository.fetchTodayItems())
                XCTAssertEqual(items?.count ?? 0, 3)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    // MARK: - blocked items alert

    func test_onAppear_whenAllItemsBlocked_expectAlertDisplayed() {
        // mocks
        env.inject()
        env.addToWindow()
        setupBlockedItems()
        env.focusCoordinator.setAlertController(alertController)
        env.focusController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.title, "All Blocked")
    }

    func test_blockedItemsAlert_whenOkPressed_expectViewDismissed() {
        // mocks
        env.inject()
        env.focusCoordinator.setNavigationController(navigationController)
        setupBlockedItems()
        let presenter = addToPresenter()
        env.focusCoordinator.setAlertController(alertController)
        env.focusController.setViewController(viewController)

        // sut
        waitSync()
        guard let alertController = navigationController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }
        XCTAssertTrue(alertController.actions[safe: 0]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertNil(presenter.presentedViewController)
    }

    // MARK: - ui

    func test_view_whenAppears_expectUIConfiguration() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.timeLabel.text, "00:00:00")
        XCTAssertEqual(viewController.view.backgroundColor, .black)
        XCTAssertEqual(viewController.timerButton.titleLabel?.text, "Focus")
    }

    // MARK: - timer button

    func test_timerButton_whenFocusPressed_expectShowsPickerWithDefaultValue() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)

        // sut
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())

        // test
        XCTAssertTrue(viewController.datePickerTextField.isFirstResponder)
        XCTAssertEqual(viewController.timeLabel.text, "00:15:00")
    }

    func test_timerButton_whenStopPressed_expectUIConfiguration() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())
        XCTAssertTrue(viewController.toolbar.items?[safe: 2]?.fire() ?? false)

        // sut
        XCTAssertTrue(viewController.timerButton.fire())

        // test
        waitSync(for: 2.0) // if timer not stopped, would expect -00:00:02
        XCTAssertEqual(viewController.timeLabel.text, "00:00:00")
        XCTAssertEqual(viewController.view.backgroundColor, .black)
        XCTAssertEqual(viewController.timerButton.titleLabel?.text, "Focus")
    }

    func test_timerButton_whenStopPressed_expectAllLocalNotificationsRemoved() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())
        XCTAssertTrue(viewController.toolbar.items?[safe: 2]?.fire() ?? false)

        // sut
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())

        // test
        waitAsync { completion in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                XCTAssertEqual(requests.count, 0)
                completion()
            }
        }
    }

    // MARK: - toolbar

    func test_toolbarCancelButton_whenPressed_expectClosesPicker() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())

        // sut
        XCTAssertTrue(viewController.toolbar.items?[safe: 0]?.fire() ?? false)

        // test
        XCTAssertFalse(viewController.datePickerTextField.isFirstResponder)
    }

    func test_toolbarCancelButton_whenPressed_expectUIConfiguration() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())

        // sut
        XCTAssertTrue(viewController.toolbar.items?[safe: 0]?.fire() ?? false)

        // test
        XCTAssertEqual(viewController.timeLabel.text, "00:00:00")
        XCTAssertEqual(viewController.view.backgroundColor, .black)
        XCTAssertEqual(viewController.timerButton.titleLabel?.text, "Focus")
    }

    func test_toolbarStartButton_whenPressed_expectUIConfiguration() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())

        // sut
        XCTAssertTrue(viewController.toolbar.items?[safe: 2]?.fire() ?? false)

        // test
        waitSync(for: 2.5)
        XCTAssertEqual(viewController.timeLabel.text, "00:14:58")
        XCTAssertEqual(viewController.view.backgroundColor, .darkGray)
        XCTAssertEqual(viewController.timerButton.titleLabel?.text, "Stop")
    }

    func test_toolbarStartButton_whenPressed_expectLocalNotificationTriggered() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())

        // sut
        waitSync()
        XCTAssertTrue(viewController.toolbar.items?[safe: 2]?.fire() ?? false)

        // test
        waitAsync { completion in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                XCTAssertEqual(requests.count, 1)
                completion()
            }
        }
    }

    // MARK: - timer

    func test_timer_whenCountDownFinished_expectAlarmTriggeredAndScreenFlashes() {
        // mocks
        let alarm = MockAlarm()
        env.alarm = alarm
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        XCTAssertTrue(viewController.timerButton.fire())
        XCTAssertTrue(viewController.toolbar.items?[safe: 2]?.fire() ?? false)

        // sut
        viewController.viewState?.focusTime = .custom(1.0)

        // test
        waitSync(for: 1.5)
        XCTAssertTrue(alarm.invocations.isInvoked(MockAlarm.start1.name))

        var colors = [UIColor?]()
        kvo = viewController.view.observe(\.backgroundColor, options: .new) { value, _ in
            colors.append(value.backgroundColor)
        }
        waitSync(for: 1.5)
        XCTAssertEqual(colors, [.darkGray, .red, .darkGray, .red])
    }

    func test_leaveApp_whenReturn_expectTimerCaughtUp() {
        // mocks
        let alarm = MockAlarm()
        env.alarm = alarm
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        var viewState = viewController.viewState
        viewState?.focusTime = .custom(2.0)
        viewController.viewState = viewState?.copy(timerButtonViewState: TimerButtonViewState(action: .stop))

        // sut
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil, userInfo: nil)
        waitSync(for: 0.5)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)

        // test
        XCTAssertEqual(viewController?.timeLabel.text, "00:00:01")
    }

    func test_leaveApp_whenReturnAfterTimesUp_expectTimerFired() {
        // mocks
        let alarm = MockAlarm()
        env.alarm = alarm
        env.inject()
        env.addToWindow()
        _ = env.todoItem(type: .today)
        env.focusController.setViewController(viewController)
        waitSync()
        var viewState = viewController.viewState
        viewState?.focusTime = .custom(0.5)
        viewController.viewState = viewState?.copy(timerButtonViewState: TimerButtonViewState(action: .stop))

        // sut
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil, userInfo: nil)
        waitSync(for: 1.0)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)

        // test
        XCTAssertTrue(alarm.invocations.isInvoked(MockAlarm.start1.name))
    }

    // MARK: - private

    private func setupMissingItems() {
        let laterItem = env.todoItem(type: .later)
        _ = env.todoItem(type: .today, blockedBy: [laterItem])
        _ = env.todoItem(type: .today)
    }

    private func setupBlockedItems() {
        let itemA = env.todoItem(type: .today)
        let itemB = env.todoItem(type: .today)
        let itemC = env.todoItem(type: .today)
        itemA.addToBlockedBy(itemB)
        itemB.addToBlockedBy(itemC)
        itemC.addToBlockedBy(itemA)
    }

    private func addToPresenter() -> UINavigationController {
        let presenter = UINavigationController()
        env.window.rootViewController = presenter
        env.window.makeKeyAndVisible()
        env.focusCoordinator.setNavigationController(presenter)
        presenter.present(navigationController, animated: false, completion: nil)
        return presenter
    }
}

// MARK: - UITableViewRowAction

private extension UITableViewRowAction {
    var isDone: Bool { return title == "Done" && backgroundColor == Asset.Colors.green.color }
}

// MARK: - FocusViewController

private extension FocusViewController {
    func rows() -> Int {
        return tableView(tableView, numberOfRowsInSection: 0)
    }

    func cell(row: Int) -> PlanCell? {
        let indexPath = IndexPath(row: row, section: 0)
        return tableView.cellForRow(at: indexPath) as? PlanCell
    }

    func actions(row: Int) -> [UITableViewRowAction]? {
        let indexPath = IndexPath(row: row, section: 0)
        return tableView(tableView, editActionsForRowAt: indexPath)
    }
}
