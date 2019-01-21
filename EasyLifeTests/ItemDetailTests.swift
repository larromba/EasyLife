import AsyncAwait
@testable import EasyLife
import TestExtensions
import PPBadgeView
import XCTest
import UIKit

final class ItemDetailTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: ItemDetailViewController!
    private var alertController: AlertController!
    private var env: AppTestEnvironment!

    override func setUp() {
        super.setUp()
        navigationController = UIStoryboard.plan.instantiateInitialViewController() as? UINavigationController
        viewController = UIStoryboard.plan
            .instantiateViewController(withIdentifier: "ItemDetailViewController") as? ItemDetailViewController
        viewController.prepareView()
        alertController = AlertController(presenter: viewController)
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

    func testSaveButtonInWarningAlertSavesNewItem() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.itemDetailController.setAlertController(alertController)
        env.addToWindow()

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
                let items = try await(self.env.dataManager.fetch(entityClass: TodoItem.self, sortBy: nil,
                                                                 context: .main, predicate: nil))
                XCTAssertEqual(items.count, 1)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
            })
        }
    }

    func testSaveButtonOnNewItemSavesItem() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // sut
        viewController.navigationItem.rightBarButtonItem?.fire()

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let items = try await(self.env.dataManager.fetch(entityClass: TodoItem.self, sortBy: nil,
                                                                 context: .main, predicate: nil))
                XCTAssertEqual(items.count, 1)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
            })
        }
    }

    func testBackButtonOnExistingItemSavesDataInput() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()

        // precondition
        waitSync()
        item.date = Date.distantPast
        XCTAssertTrue(item.hasChanges)

        // sut
        navigationController.popViewController(animated: false)

        // test
        waitSync()
        XCTAssertFalse(item.hasChanges)
    }

    func testDeleteButtonDeletesItem() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // sut
        viewController.navigationItem.rightBarButtonItem?.fire()

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let items = try await(self.env.dataManager.fetch(entityClass: TodoItem.self, sortBy: nil,
                                                                 context: .main, predicate: nil))
                XCTAssertEqual(items.count, 0)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
            })
        }
    }

    // MARK: - picker

    func testDateFieldUsesSimplePickerWhenNoDateSet() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.simpleDatePicker)
    }

    func testDateFieldUsesDatePickerWhenDateSet() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()

        // sut
        waitSync()
        viewController.dateTextField.becomeFirstResponder()

        // test
        XCTAssertEqual(viewController.dateTextField.inputView, viewController.datePicker)
    }

    func testRepeatFieldUsesRepeatPicker() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)

        // test
        XCTAssertEqual(viewController.repeatsTextField.inputView, viewController.repeatPicker)
    }

    func testProjectShowsProjectPicker() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)

        // test
        XCTAssertEqual(viewController.projectTextField.inputView, viewController.projectPicker)
    }

    // MARK: - keyboard toolbar

    func testPrevGoesThroughResponders() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()
        let prev = viewController.toolbar.items?[safe: 0]
        viewController.titleTextField.becomeFirstResponder()

        // sut
        waitSync()
        prev?.fire()
        // test
        XCTAssertTrue(viewController.textView.isFirstResponder)

        // sut
        waitSync()
        prev?.fire()
        // test
        XCTAssertTrue(viewController.projectTextField.isFirstResponder)

        // sut
        waitSync()
        prev?.fire()
        // test
        XCTAssertTrue(viewController.repeatsTextField.isFirstResponder)

        // sut
        waitSync()
        prev?.fire()
        // test
        XCTAssertTrue(viewController.dateTextField.isFirstResponder)

        // sut
        waitSync()
        prev?.fire()
        // test
        XCTAssertTrue(viewController.titleTextField.isFirstResponder)
    }

    func testPrevMissesProjectWhenNoProjectsExist() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()
        let prev = viewController.toolbar.items?[safe: 0]
        viewController.textView.becomeFirstResponder()

        // sut
        waitSync()
        prev?.fire()
        // test
        XCTAssertTrue(viewController.repeatsTextField.isFirstResponder)
    }

    func testNextGoesThroughResponders() {
        // mocks
        env.inject()
        _ = env.project(priority: 0, name: "test")
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()
        let next = viewController.toolbar.items?[safe: 2]
        viewController.titleTextField.becomeFirstResponder()

        // sut
        waitSync()
        next?.fire()
        // test
        XCTAssertTrue(viewController.dateTextField.isFirstResponder)

        // sut
        waitSync()
        next?.fire()
        // test
        XCTAssertTrue(viewController.repeatsTextField.isFirstResponder)

        // sut
        waitSync()
        next?.fire()
        // test
        XCTAssertTrue(viewController.projectTextField.isFirstResponder)

        // sut
        waitSync()
        next?.fire()
        // test
        XCTAssertTrue(viewController.textView.isFirstResponder)

        // sut
        waitSync()
        next?.fire()
        // test
        XCTAssertTrue(viewController.titleTextField.isFirstResponder)
    }

    func testNextMissesProjectWhenNoProjectsExist() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()
        let next = viewController.toolbar.items?[safe: 2]
        viewController.repeatsTextField.becomeFirstResponder()

        // sut
        waitSync()
        next?.fire()

        // test
        XCTAssertTrue(viewController.textView.isFirstResponder)
    }

    func testDoneButtonEndsEditing() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()
        viewController.titleTextField.becomeFirstResponder()

        // sut
        waitSync()
        XCTAssertTrue(viewController.toolbar.items?.last?.fire() ?? false)

        // test
        XCTAssertFalse(viewController.titleTextField.isFirstResponder)
    }

    func testDateButtonTogglesDatePickers() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
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

    func testDateButtonChangesWhenToggled() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
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

    func testBlockedBadgeValue() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        let item2 = env.todoItem(type: .empty, name: "test")
        item.addToBlockedBy(item2)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.addToWindow()

        // test
        waitSync()
        XCTAssertEqual(viewController.blockedBadgeLabel?.text, "1")
    }

    func testBlockedBadgeValueReloads() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        let item2 = env.todoItem(type: .empty, name: "test")
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
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

    func testBlockedButtonOpensBlockedByViewController() {
        // mocks
        env.inject()
        env.itemDetailController.setViewController(viewController)

        // sut
        XCTAssertTrue(viewController.blockedButton.fire())

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is BlockedByViewController)
    }

    func testBlockedButtonDisabledWhenOnly1Item() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // test
        waitSync()
        XCTAssertFalse(viewController.blockedButton.isEnabled)
    }

    func testBlockedButtonEnabled() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty)
        _ = env.todoItem(type: .empty, name: "test")
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // test
        waitSync()
        XCTAssertTrue(viewController.blockedButton.isEnabled)
    }

    // MARK: - other

    func testErrorAlertShows() {
        // mocks
        env.isLoaded = false
        env.inject()
        env.addToWindow()
        let item = env.todoItem(type: .empty)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setAlertController(alertController)
        env.itemDetailController.setItem(item)

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func testItemRendersInUI() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let project = env.project(priority: 0, name: "proj")
        item.name = "foo"
        item.notes = "bar"
        item.date = Date.distantPast
        item.repeatState = .daily
        item.done = true
        item.project = project
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // test
        XCTAssertEqual(viewController.titleTextField.text, "foo")
        XCTAssertEqual(viewController.dateTextField.text, "Saturday 01/01/0001")
        XCTAssertEqual(viewController.repeatsTextField.text, "daily")
        XCTAssertEqual(viewController.projectTextField.text, "proj")
        XCTAssertEqual(viewController.textView.text, "bar")
    }

    func testExistingItemDisplaysBackButton() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // test
        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
    }

    func testNewItemDisplaysCancelButton() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // test
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.isCancel ?? false)
    }

    func testDataUpdatesOnInput() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .today)
        let project = env.project(priority: 0)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)

        // sut
        waitSync()
        viewController.titleTextField.text = "foo"
        viewController.titleTextField.sendActions(for: .editingChanged)
        viewController.datePicker(viewController.simpleDatePicker, didSelectDate: Date.distantPast)
        viewController.pickerView(viewController.repeatPicker, didSelectRow: 1, inComponent: 0)
        viewController.pickerView(viewController.projectPicker, didSelectRow: 0, inComponent: 0)
        viewController.textView.text = "bar"
        viewController.textViewDidChange(viewController.textView)

        // test
        XCTAssertEqual(item.name, "foo")
        XCTAssertEqual(item.date, Date.distantPast)
        XCTAssertEqual(item.repeatState, .daily)
        XCTAssertEqual(item.project, project)
        XCTAssertEqual(item.notes, "bar")
    }

    func testCancelOnNewItemAfterDataInputShowsWarningAlert() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, isTransient: true)
        env.itemDetailController.setViewController(viewController)
        env.itemDetailController.setItem(item)
        env.itemDetailController.setAlertController(alertController)
        env.addToWindow()
        viewController.titleTextField.text = "foo"
        viewController.titleTextField.sendActions(for: .editingChanged)

        // sut
        XCTAssertTrue(viewController.navigationItem.leftBarButtonItem?.fire() ?? false)

        // test
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }
}

// MARK: - UIBarButtonItem

private extension UIBarButtonItem {
    var isCancel: Bool {
        return String(describing: self).components(separatedBy: "systemItem=").last == "Cancel"
    }
}
