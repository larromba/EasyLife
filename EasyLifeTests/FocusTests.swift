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

    func test_item_whenAppears_expectUIConfiguration() {
        XCTFail("todo")
    }

    func test_item_whenOpened_expectDoneAction() {
        XCTFail("todo")
    }

    func test_item_whenDone_expectNextItem() {
        XCTFail("todo")
    }

    func test_lastItem_whenDone_expectHidesView() {
        XCTFail("todo")
    }

    func test_focusButton_whenTodayItemsCantBeCompleted_expectAlertDisplayed() {
        // mocks
        env.inject()
        env.addToWindow()
        setupMissedState()
        env.focusController.setAlertController(alertController)
        env.focusController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func test_missingItemsAlert_whenNoPressed_expectViewDismissed() {
        // mocks
        env.inject()
        setupMissedState()
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
        setupMissedState()
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
            })
        }
    }

    // MARK: - private

    private func setupMissedState() {
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
