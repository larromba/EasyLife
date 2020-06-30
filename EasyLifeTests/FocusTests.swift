import AsyncAwait
@testable import EasyLife
import Foundation
import TestExtensions
import XCTest

final class FocusTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: FocusViewController!
    private var alertController: AlertController!
    private var env: AppTestEnvironment!

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
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

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
        XCTAssertNil(presenter.presentingViewController)
    }

    func test_focusButton_whenTodayItemsCantBeCompleted_expectAlertDisplayed() {
        // mocks
        env.inject()
        env.addToWindow()
        setupMissingItems()
        env.focusController.setAlertController(alertController)
        env.focusController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func test_missingItemsAlert_whenNoPressed_expectViewDismissed() {
        // mocks
        env.inject()
        setupMissingItems()
        let presenter = addToPresenter()
        env.focusController.setAlertController(alertController)
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
        XCTAssertNil(presenter.presentingViewController)
    }

    func test_missingItemsAlert_whenYesPressed_expectMovesMissingItems() {
        // mocks
        env.inject()
        setupMissingItems()
        _ = addToPresenter()
        env.focusController.setAlertController(alertController)
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

    // MARK: - private

    private func setupMissingItems() {
        let laterItem = env.todoItem(type: .later)
        _ = env.todoItem(type: .today, blockedBy: [laterItem])
        _ = env.todoItem(type: .today)
    }

    private func addToPresenter() -> UIViewController {
        let presenter = UIViewController()
        env.window.rootViewController = presenter
        env.window.makeKeyAndVisible()
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
