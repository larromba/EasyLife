@testable import EasyLife
import Foundation
import TestExtensions
import XCTest

final class ShortcutTests: XCTestCase {
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

    func test_shortcuts_whenAppStarted_expectShortcutsSet() {
        // mock
        env.inject()

        // sut
        env.start()

        // test
        XCTAssertEqual(UIApplication.shared.shortcutItems, ShortcutItem.display.map { $0.item })
    }

    // MARK: - homescreen shortcut: new todo item

    func test_homescreenShortcut_whenNewTodoItemSelected_expectOpensItemDetailWithNewContext() {
        // mock
        env.inject()
        env.addToWindow()
        env.start()

        // sut
        waitSync()
        env.appController.processShortcutItem(ShortcutItem.newTodoItem.item)

        // test
        waitSync()
        guard let viewController = navigationController.viewControllers.last as? ItemDetailViewController else {
            XCTFail("expected ItemDetailViewController")
            return
        }
        XCTAssertTrue(viewController.viewState?.isNew ?? false)
    }

    func test_homescreenShortcut_whenNewTodoItemSelected_expectDismissesProjectsView() {
        routeProjectsView(thenFireShortcut: .newTodoItem)
    }

    func test_homescreenShortcut_whenNewTodoItemSelected_expectDismissesFocusView() {
        routeFocusView(thenFireShortcut: .newTodoItem)
    }

    func test_homescreenShortcut_whenNewTodoItemSelected_expectDismissesItemDetailView() {
        routeItemDetail(thenFireShortcut: .newTodoItem)
    }

    func test_homescreenShortcut_whenNewTodoItemSelected_expectDismissesBlockedView() {
        routeBlockedView(thenFireShortcut: .newTodoItem)
    }

    // MARK: - private

    private func routeProjectsView(thenFireShortcut shortcutItem: ShortcutItem) {
        // mock
        env.addToWindow()
        env.inject()
        env.start()

        // sut
        waitSync()
        viewController.projectsButton.fire()
        waitSync()
        env.appController.processShortcutItem(shortcutItem.item)

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
        XCTAssertNil(navigationController?.presentedViewController)
    }

    private func routeFocusView(thenFireShortcut shortcutItem: ShortcutItem) {
        // mock
        env.addToWindow()
        env.inject()
        env.start()

        // sut
        waitSync()
        viewController.focusButton.fire()
        waitSync()
        env.appController.processShortcutItem(shortcutItem.item)

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
        XCTAssertNil(navigationController?.presentedViewController)
    }

    private func routeItemDetail(thenFireShortcut shortcutItem: ShortcutItem) {
        // mock
        env.addToWindow()
        env.inject()
        env.start()

        // sut
        waitSync()
        viewController.addButton.fire()
        waitSync()
        env.appController.processShortcutItem(shortcutItem.item)

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    private func routeBlockedView(thenFireShortcut shortcutItem: ShortcutItem) {
        // mock
        env.addToWindow()
        env.inject()
        env.start()

        // sut
        waitSync()
        viewController.addButton.fire()
        waitSync()
        guard let viewController = navigationController.viewControllers.last as? ItemDetailViewController else {
            XCTFail("expected ItemDetailViewController")
            return
        }
        viewController.blockedButton.fire()
        waitSync()
        env.appController.processShortcutItem(shortcutItem.item)

        // test
        waitSync()
        XCTAssertTrue(navigationController.viewControllers.last is ItemDetailViewController)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }
}
