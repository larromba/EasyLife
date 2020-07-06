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
        viewController = UIStoryboard.plan
            .instantiateViewController(withIdentifier: "ItemDetailViewController") as? ItemDetailViewController
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
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()

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
        viewController.titleTextField.setText("foo")

        // sut
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.fire() ?? false)

        // test
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func test_cancelAlert_whenSaveButtonPressed_expectNewItemSaved() {
        // mocks
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))

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

        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.simpleDatePicker)
    }

    func test_dateField_whenPressedWithDate_expectDatePicker() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()

        // sut
        waitSync()
        viewController.dateTextField.becomeFirstResponder()

        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.datePicker)
    }

    func test_repeatField_whenPressed_expectRepeatPicker() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)

        // test
        XCTAssertEqual(viewController.repeatsTextField.inputView, viewController.repeatPicker)
    }

    func test_projectField_whenPressed_expectProjectPicker() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)

        // test
        XCTAssertEqual(viewController.projectTextField.inputView, viewController.projectPicker)
    }

    // MARK: - keyboard toolbar

    func test_previousButton_whenPressed_expectPreviousResponder() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
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
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
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
        _ = env.project(priority: 0, name: "test")
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
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
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
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
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
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
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
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
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
        viewController.dateTextField.becomeFirstResponder()
        waitSync()

        // sut
        let button1 = viewController.toolbar.items?[safe: 4]
        button1?.fire()
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
        let item = env.todoItem(type: .empty)
        let item2 = env.todoItem(type: .empty, name: "test")
        item.addToBlockedBy(item2)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()

        // test
        waitSync()
        XCTAssertEqual(viewController.blockedBadgeLabel?.text, "1")
    }

    func test_badge_whenReloaded_expectValueChanges() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        let item2 = env.todoItem(type: .empty, name: "test")
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()

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

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
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

        // test
        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
    }

    func test_item_whenNew_expectCancelButton() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))

        // test
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.isCancel ?? false)
    }

    func test_item_whenNew_expectSaveButton() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setContext(.new(item: item, context: env.childContext))

        // test
        XCTAssertTrue(viewController.navigationItem.rightBarButtonItem?.isSave ?? false)
    }

    // MARK: - private

    private func triggerNavigationDelegate() {
        waitSync(for: 0.1)
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
