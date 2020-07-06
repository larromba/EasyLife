@testable import EasyLife
import TestExtensions
import UIKit
import XCTest

final class BlockedByTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: BlockedByViewController!
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

    // MARK: - ui

    func test_item_whenHasName_expectDisplayed() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        _ = env.todoItem(type: .empty, name: "b")
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(section: 0), 1)
        XCTAssertEqual(viewController.title(row: 0), "b")
    }

    func test_item_whenBlockingItems_expectThoseItemsNotShown() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        _ = env.todoItem(type: .empty, name: "b", blockedBy: [item])
        _ = env.todoItem(type: .empty, name: "c", blockedBy: [item])
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(section: 0), 0)
    }

    func test_unblockButton_whenNoItemsBlocked_expectDisabled() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        _ = env.todoItem(type: .empty, name: "b")
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))

        // test
        waitSync()
        XCTAssertFalse(viewController.unblockButton.isEnabled)
    }

    func test_unblockButton_whenItemsBlocked_expectEnabled() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        let item2 = env.todoItem(type: .empty, name: "b", blockedBy: [item])
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item2, context: env.dataContextProvider.mainContext()))

        // test
        waitSync()
        XCTAssertTrue(viewController.unblockButton.isEnabled)
    }

    // MARK: - action

    func test_back_whenTapped_expectItemUpdated() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        _ = env.todoItem(type: .empty, name: "b")
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))
        env.addToWindow()
        waitSync()
        viewController.selectRow(0)

        // sut
        navigationController.popViewController(animated: false)

        // test
        waitSync()
        XCTAssertEqual(item.blockedBy?.count, 1)
    }

    func test_item_whenTapped_expectTogglesTick() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        _ = env.todoItem(type: .empty, name: "b")
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))

        // precondition
        waitSync()
        XCTAssertNil(viewController.cell(row: 0)?.iconImageView.image)

        // sut
        viewController.selectRow(0)
        // test
        XCTAssertEqual(viewController.cell(row: 0)?.iconImageView.image, Asset.Assets.tick.image)

        // sut
        viewController.selectRow(0)
        // test
        XCTAssertNil(viewController.cell(row: 0)?.iconImageView.image)
    }

    func test_unblockButton_whenPressed_expectAllItemsUnblocked() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        let item2 = env.todoItem(type: .empty, name: "b", blockedBy: [item])
        _ = env.todoItem(type: .empty, name: "c", blockedBy: [item])
        _ = env.todoItem(type: .empty, name: "d", blockedBy: [item])
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item2, context: env.dataContextProvider.mainContext()))

        // sut
        waitSync()
        XCTAssertTrue(viewController.unblockButton.fire())

        // test
        waitSync()
        for i in 0..<4 { XCTAssertNil(viewController.cell(row: i)?.iconImageView.image) }
    }

    // MARK: - order

    func test_rows_whenAppear_expectOrder() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, name: "a")
        _ = env.todoItem(type: .empty, name: "b")
        _ = env.todoItem(type: .empty, name: "c")
        _ = env.todoItem(type: .empty, name: "1")
        env.blockedByController.setViewController(viewController)
        env.blockedByController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))

        // test
        waitSync()
        XCTAssertEqual(viewController.title(row: 0), "1")
        XCTAssertEqual(viewController.title(row: 1), "b")
        XCTAssertEqual(viewController.title(row: 2), "c")
    }

    // MARK: - alert

    func test_alert_whenDataError_expectThrown() {
        // mocks
        env.persistentContainer = .mock(fetchError: MockError.mock)
        env.inject()
        env.addToWindow()
        triggerNavigationDelegate()
        let item = env.todoItem(type: .empty)
        env.blockedByController.setContext(.existing(item: item, context: env.dataContextProvider.mainContext()))

        // test
        waitSync()
        XCTAssertEqual(viewController.presentedViewController?.asAlertController?.title, "Error")
    }

    // MARK: - private

    private func triggerNavigationDelegate() {
        waitSync(for: 0.1)
        navigationController.delegate?
            .navigationController?(navigationController, willShow: viewController, animated: false)
    }
}

// MARK: - BlockedByViewController

private extension BlockedByViewController {
    func rows(section: Int) -> Int {
        return tableView(tableView, numberOfRowsInSection: section)
    }

    func cell(row: Int) -> BlockedCell? {
        let indexPath = IndexPath(row: row, section: 0)
        return tableView.cellForRow(at: indexPath) as? BlockedCell
    }

    func title(row: Int) -> String? {
        return cell(row: row)?.titleLabel.text
    }

    func selectRow(_ row: Int) {
        tableView(tableView, didSelectRowAt: IndexPath(row: row, section: 0))
    }
}
