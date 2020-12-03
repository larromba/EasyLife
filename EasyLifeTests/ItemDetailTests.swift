import AsyncAwait
@testable import EasyLife
import PPBadgeView
import TestExtensions
import UIKit
import XCTest

// swiftlint:disable type_body_length file_length
final class ItemDetailTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: ItemDetailViewController!
    private var env: AppTestEnvironment!

    override func setUp() {
        super.setUp()
        navigationController = UIStoryboard.plan.instantiateInitialViewController() as? UINavigationController
        viewController = UIStoryboard.plan.instantiateViewController()
        viewController.prepareView()
        navigationController.pushViewController(viewController, animated: false)
        env = AppTestEnvironment(navigationController: navigationController)
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        env = nil
        viewController = nil
        navigationController = nil
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    // MARK: - io

    func test_saveButton_whenPressed_expectNewItemSaved() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()

        // sut
        XCTAssertTrue(viewController.navigationItem.rightBarButtonItem?.fire() ?? false)

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let context = self.env.dataContextProvider.mainContext()
                let items = try await(context.fetch(entityClass: TodoItem.self, sortBy: nil, predicate: nil))
                XCTAssertEqual(items.count, 1)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    // #bug 09 Apr 19 - "Illegal attempt to establish a relationship 'xyz' between objects in different contexts"
    func test_saveButton_whenPressed_expectNewItemSavedWithProjectFromDifferentContext() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, isTransient: true) // child context
        let project = env.project(priority: 1) // main context
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()
        waitSync()

        // sut
        viewController.pickerView(viewController.projectPicker, didSelectRow: 1, inComponent: 0)
        XCTAssertTrue(viewController.navigationItem.rightBarButtonItem?.fire() ?? false)

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let context = self.env.dataContextProvider.mainContext()
                let items = try await(context.fetch(entityClass: TodoItem.self, sortBy: nil, predicate: nil))
                XCTAssertEqual(items.first?.project, project)
                XCTAssertEqual(items.count, 1)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    func test_backButton_whenPressedOnExistingItem_expectSavesChanges() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // precondition
        waitSync()
        item.date = Date()
        XCTAssertTrue(item.hasChanges)

        // sut
        navigationController.popViewController(animated: false)

        // test
        waitSync()
        XCTAssertFalse(item.hasChanges)
    }

    func test_backButton_whenPressed_expectDeletesItem() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // sut
        XCTAssertTrue(viewController.navigationItem.rightBarButtonItem?.fire() ?? false)

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let context = self.env.dataContextProvider.mainContext()
                let items = try await(context.fetch(entityClass: TodoItem.self, sortBy: nil, predicate: nil))
                XCTAssertEqual(items.count, 0)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    func test_item_whenUIChanges_expectUpdated() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let project = env.project(priority: 0)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // sut
        waitSync()
        viewController.titleTextField?.setText("foo")
        viewController.datePicker(viewController.simpleDatePicker, didSelectDate: .distantFuture)
        viewController.pickerView(viewController.repeatPicker, didSelectRow: 1, inComponent: 0)
        viewController.pickerView(viewController.projectPicker, didSelectRow: 1, inComponent: 0)
        viewController.textView.setText("bar")

        // test
        XCTAssertEqual(item.name, "foo")
        XCTAssertEqual(item.date, .distantFuture)
        XCTAssertEqual(item.repeatState, .daily)
        XCTAssertEqual(item.project, project)
        XCTAssertEqual(item.notes, "bar")
    }

    // MARK: - cancel alert

    func test_cancel_whenNewAndHasUpdates_expectAlertDisplays() {
        // mocks
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .empty, isTransient: true)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()
        viewController.titleTextField.setText("foo")

        // sut
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.fire() ?? false)

        // test
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.title, "Unsaved Changed")
    }

    func test_cancelAlert_whenSaveButtonPressed_expectNewItemSaved() {
        // mocks
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()

        // sut
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.fire() ?? false)
        guard let alertController = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }
        XCTAssertTrue(alertController.actions[safe: 1]?.fire() ?? false)

        // test
        waitAsync { completion in
            async({
                let context = self.env.dataContextProvider.mainContext()
                let items = try await(context.fetch(entityClass: TodoItem.self, sortBy: nil, predicate: nil))
                XCTAssertEqual(items.count, 1)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    func test_cancelAlert_whenSaveButtonPressed_expectHidesView() {
        // mocks
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .empty, isTransient: true)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()
        viewController.titleTextField.setText("foo")

        // sut
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.fire() ?? false)
        guard let alertController = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }
        waitSync()
        XCTAssertTrue(alertController.actions[safe: 1]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.first is PlanViewController)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func test_cancelAlert_whenNoPressed_expectNotSaved() {
        // mocks
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .empty, isTransient: true)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()
        viewController.titleTextField.setText("foo")

        // sut
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.fire() ?? false)
        guard let alertController = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }
        XCTAssertTrue(alertController.actions[safe: 0]?.fire() ?? false)

        // test
        waitAsync { completion in
            async({
                let context = self.env.dataContextProvider.mainContext()
                let items = try await(context.fetch(entityClass: TodoItem.self, sortBy: nil, predicate: nil))
                XCTAssertEqual(items.count, 0)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    func test_cancelAlert_whenNoPressed_expectHidesView() {
        // mocks
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .empty, isTransient: true)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()
        viewController.titleTextField.setText("foo")

        // sut
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.fire() ?? false)
        guard let alertController = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }
        waitSync()
        XCTAssertTrue(alertController.actions[safe: 0]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.first is PlanViewController)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    // MARK: - picker

    func test_dateField_whenPressedWithNoDate_expectSimplePicker() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.simpleDatePicker)
    }

    func test_dateField_whenPressedWithDate_expectDatePicker() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // sut
        waitSync()
        viewController.dateTextField.becomeFirstResponder()

        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.datePicker)
    }

    func test_datePicker_whenTomorrowSelectedAndDateButtonPressed_expectRowSelected() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        viewController.dateTextField.becomeFirstResponder()
        waitSync()

        // sut
        let date = Date()
        viewController.simpleDatePicker.pickerView(viewController.simpleDatePicker, didSelectRow: 2, inComponent: 0)
        XCTAssertTrue(viewController.toolbar.items?[safe: 4]?.fire() ?? false)

        // test
        waitSync()
        print(viewController.datePicker.date)
        print(date)
        XCTAssertEqual(viewController.datePicker.date.timeIntervalSince1970,
                       date.addingTimeInterval(24 * 60 * 60).timeIntervalSince1970, accuracy: 60.0)
    }

    func test_simpleDatePicker_whenDateButtonPressed_expectDateClearedAndRowSelected() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        viewController.viewState?.date = Date()
        viewController.dateTextField.becomeFirstResponder()
        waitSync()

        // sut
        XCTAssertTrue(viewController.toolbar.items?[safe: 4]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertEqual(viewController.dateTextField.text, "")
        XCTAssertNil(viewController.viewState?.date)
        XCTAssertEqual(viewController.simpleDatePicker.selectedRow(inComponent: 0), 0)
    }

    func test_repeatField_whenPressed_expectRepeatPicker() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)

        // test
        XCTAssertEqual(viewController.repeatsTextField.inputView, viewController.repeatPicker)
    }

    func test_repeatPicker_whenOpened_expectRowSelected() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty, repeatState: .halfyear)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // sut
        waitSync()
        viewController.repeatsTextField.becomeFirstResponder()

        // test
        waitSync()
        XCTAssertEqual(viewController.repeatPicker.selectedRow(inComponent: 0), RepeatState.halfyear.rawValue)
    }

    func test_projectField_whenPressed_expectProjectPicker() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)

        // test
        XCTAssertEqual(viewController.projectTextField.inputView, viewController.projectPicker)
    }

    func test_projectPicker_whenOpened_expectRowSelected() {
        // mocks
        env.inject()
        env.addToWindow()
        let project = env.project(priority: 0)
        let item = env.todoItem(type: .empty, project: project)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // sut
        waitSync()
        viewController.projectTextField.becomeFirstResponder()

        // test
        waitSync()
        XCTAssertEqual(viewController.projectPicker.selectedRow(inComponent: 0), 1)
    }

    // MARK: - keyboard toolbar

    func test_previousButton_whenPressed_expectPreviousResponder() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.project(priority: 0)
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        let prev = viewController.toolbar.items?[safe: 0]
        viewController.titleTextField.becomeFirstResponder()

        // sut
        waitSync()
        XCTAssertTrue(prev?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.textView.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(prev?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.projectTextField.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(prev?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.repeatsTextField.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(prev?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.dateTextField.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(prev?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.titleTextField.isFirstResponder)
    }

    func test_previousButton_whenPressedAndHasNoProject_expectMissesProjectField() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        let prev = viewController.toolbar.items?[safe: 0]
        viewController.textView.becomeFirstResponder()

        // sut
        waitSync()
        XCTAssertTrue(prev?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.repeatsTextField.isFirstResponder)
    }

    func test_nextButton_whenPressed_expectNextResponder() {
        // mocks
        env.inject()
        env.addToWindow()
        _ = env.project(priority: 0, name: "test")
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        let next = viewController.toolbar.items?[safe: 2]
        viewController.titleTextField.becomeFirstResponder()

        // sut
        waitSync()
        XCTAssertTrue(next?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.dateTextField.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(next?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.repeatsTextField.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(next?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.projectTextField.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(next?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.textView.isFirstResponder)

        // sut
        waitSync()
        XCTAssertTrue(next?.fire() ?? false)
        // test
        XCTAssertTrue(viewController.titleTextField.isFirstResponder)
    }

    func test_nextButton_whenPressedAndHasNoProject_expectMissesProjectField() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        let next = viewController.toolbar.items?[safe: 2]
        viewController.repeatsTextField.becomeFirstResponder()

        // sut
        waitSync()
        XCTAssertTrue(next?.fire() ?? false)

        // test
        XCTAssertTrue(viewController.textView.isFirstResponder)
    }

    func test_doneButton_whenPressed_expectEditingEnds() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        viewController.titleTextField.becomeFirstResponder()

        // sut
        waitSync()
        XCTAssertTrue(viewController.toolbar.items?.last?.fire() ?? false)

        // test
        XCTAssertFalse(viewController.titleTextField.isFirstResponder)
    }

    func test_dateButton_whenPressed_expectDatePickersToggled() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        viewController.dateTextField.becomeFirstResponder()
        waitSync()

        // sut
        XCTAssertTrue(viewController.toolbar.items?[safe: 4]?.fire() ?? false)
        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.datePicker)

        // sut
        XCTAssertTrue(viewController.toolbar.items?[safe: 4]?.fire() ?? false)
        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.simpleDatePicker)
    }

    func test_dateButton_whenPressed_expectDateButtonChanges() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()
        viewController.dateTextField.becomeFirstResponder()
        waitSync()

        // sut
        let button1 = viewController.toolbar.items?[safe: 4]
        XCTAssertTrue(button1?.fire() ?? false)
        let button2 = viewController.toolbar.items?[safe: 4]

        // test
        XCTAssertNotNil(button1)
        XCTAssertNotNil(button2)
        XCTAssertNotEqual(button1, button2)
    }

    // MARK: - blocked

    func test_badge_whenBlocked_expectValue() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        let item2 = env.todoItem(type: .empty, name: "test")
        item.addToBlockedBy(item2)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.blockedBadgeLabel?.text, "1")
    }

    func test_badge_whenReloaded_expectValueChanges() {
        // mocks
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        let item2 = env.todoItem(type: .empty, name: "test")
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // precondition
        waitSync()
        XCTAssertEqual(viewController.blockedBadgeLabel?.text, "0")

        // sut
        navigationController.pushViewController(UIViewController(), animated: false)
        item.addToBlockedBy(item2)
        navigationController.popViewController(animated: true)

        // test
        waitSync()
        XCTAssertEqual(viewController.blockedBadgeLabel?.text, "1")
    }

    func test_blockedButton_whenPressed_expectOpensBlockedView() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.start()

        // sut
        XCTAssertTrue(viewController.blockedButton.fire())

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is BlockedByViewController)
    }

    func test_blockedButton_whenOnlyOneItem_expectDisabled() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // test
        waitSync()
        XCTAssertFalse(viewController.blockedButton.isEnabled)
    }

    func test_blockedButton_whenMoreThanOneItem_expectEnabled() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        _ = env.todoItem(type: .empty, name: "test")
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // test
        waitSync()
        XCTAssertTrue(viewController.blockedButton.isEnabled)
    }

    // MARK: - other

    func test_alert_whenDataError_expectThrown() {
        // mocks
        env.persistentContainer = .mock(fetchError: MockError.mock)
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.title, "Error")
    }

    // MARK: - ui

    func test_item_whenAppears_expectUIConfiguration() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let project = env.project(priority: 0, name: "proj")
        item.name = "foo"
        item.notes = "bar"
        item.date = Date(timeIntervalSince1970: 0)
        item.repeatState = .daily
        item.done = true
        item.project = project
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // test
        XCTAssertEqual(viewController.titleTextField.text, "foo")
        XCTAssertEqual(viewController.dateTextField.text, "Thursday 01/01/1970")
        XCTAssertEqual(viewController.repeatsTextField.text, "daily")
        XCTAssertEqual(viewController.projectTextField.text, "proj")
        XCTAssertEqual(viewController.textView.text, "bar")
    }

    func test_item_whenExisting_expectBackButton() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.itemDetailController.start()

        // test
        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
    }

    func test_item_whenNew_expectCancelButton() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()

        // test
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.isCancel ?? false)
    }

    func test_item_whenNew_expectSaveButton() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))
        env.itemDetailController.start()

        // test
        XCTAssertTrue(viewController.navigationItem.rightBarButtonItem?.isSave ?? false)
    }

    // MARK: - private

    private func triggerNavigationDelegate() {
        waitSync()
        navigationController.delegate?
            .navigationController?(navigationController, willShow: viewController, animated: false)
    }
}

// MARK: - UIBarButtonItem

private extension UIBarButtonItem {
    var isCancel: Bool {
        return String(describing: self).components(separatedBy: "systemItem=").last == "Cancel"
    }
    var isSave: Bool {
        return String(describing: self).components(separatedBy: "systemItem=").last == "Save"
    }
}
