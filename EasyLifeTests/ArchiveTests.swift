@testable import EasyLife
import TestExtensions
import XCTest
import UIKit

final class ArchiveTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: ArchiveViewController!
    private var alertController: AlertController!
    private var env: AppTestEnvironment!

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController() // TODO: from story?
        viewController = UIStoryboard.archive
            .instantiateViewController(withIdentifier: "ArchiveViewController") as? ArchiveViewController
        viewController.prepareView()
        navigationController.pushViewController(viewController, animated: false)
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

    // MARK: - ui

    func testNoDataHidesTableView() {
        // mocks
        env.inject()
        env.archiveController.setViewController(viewController)

        // test
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    func testDataShowsTableView() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty, isDone: true)
        env.archiveController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertFalse(viewController.tableView.isHidden)
    }

    func testOrder() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty, name: "a1", isDone: true)
        _ = env.todoItem(type: .empty, name: "a2", isDone: true)
        _ = env.todoItem(type: .empty, name: "b1", isDone: true)
        _ = env.todoItem(type: .empty, name: "x1", isDone: true)
        _ = env.todoItem(type: .empty, isDone: true)
        env.archiveController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.sections(), 4)
        XCTAssertEqual(viewController.title(row: 0, section: 0), "[no name]")
        XCTAssertEqual(viewController.title(row: 0, section: 1), "a1")
        XCTAssertEqual(viewController.title(row: 1, section: 1), "a2")
        XCTAssertEqual(viewController.title(row: 0, section: 2), "b1")
        XCTAssertEqual(viewController.title(row: 0, section: 3), "x1")
    }

    // MARK: - search

    func testSearchFiltersResults() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty, name: "this should appear 1", isDone: true)
        _ = env.todoItem(type: .empty, name: "this should appear 2", isDone: true)
        _ = env.todoItem(type: .empty, name: "foos definately arent part of it", isDone: true)
        _ = env.todoItem(type: .empty, name: "bars definately arent part of it", isDone: true)
        _ = env.todoItem(type: .empty, name: "cats definately arent part of it", isDone: true)
        _ = env.todoItem(type: .empty, name: "dogs definately arent part of it", isDone: true)
        env.archiveController.setViewController(viewController)

        // precondition
        waitSync()
        XCTAssertEqual(viewController.sections(), 5)

        // sut
        viewController.searchBar(viewController.searchBar, textDidChange: "should")

        // test
        XCTAssertEqual(viewController.sections(), 1)
    }

    func testBadSearchShowsNoResults() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty, name: "foos", isDone: true)
        _ = env.todoItem(type: .empty, name: "bars", isDone: true)
        _ = env.todoItem(type: .empty, name: "cats", isDone: true)
        _ = env.todoItem(type: .empty, name: "dogs", isDone: true)
        env.archiveController.setViewController(viewController)

        // precondition
        waitSync()
        XCTAssertEqual(viewController.sections(), 4)

        // sut
        viewController.searchBar(viewController.searchBar, textDidChange: "kevin and perry")

        // test
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    // MARK: - cell actions

    func testCellActions() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty, isDone: true)
        env.archiveController.setViewController(viewController)

        // test
        waitSync()
        guard let action = viewController.actions(row: 0, section: 0)?.first else { return XCTFail("expected action") }
        XCTAssertTrue(action.isUndo)
    }

    func testUndo() {
        // mocks
        env.inject()
        let item = env.todoItem(type: .empty, isDone: true)
        env.archiveController.setViewController(viewController)

        // sut
        waitSync()
        guard let action = viewController.actions(row: 0, section: 0)?.first else { return XCTFail("expected action") }
        action._handler(action, IndexPath())

        // test
        waitSync()
        XCTAssertFalse(item.done)
    }

    func testClearAllShowsAlert() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty, isDone: true)
        env.archiveController.setViewController(viewController)
        env.archiveController.setAlertController(alertController)
        env.addToWindow()

        // sut
        viewController.clearButton.fire()

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func testClearAllClearsAllItems() {
        // mocks
        env.inject()
        _ = env.todoItem(type: .empty, isDone: true)
        env.archiveController.setViewController(viewController)
        env.archiveController.setAlertController(alertController)
        env.addToWindow()
        waitSync()
        viewController.clearButton.fire()
        guard let alertController = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected UIAlertController")
            return
        }

        // sut
        alertController.triggerAction(alertController.actions[1])

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

    // MARK: - actions

    func testDoneCloses() {
        // mocks
        env.inject()
        env.archiveController.setViewController(viewController)
        env.archiveCoordinator.setNavigationController(navigationController)
        let presenter = UIViewController()
        env.window.rootViewController = presenter
        env.window.makeKeyAndVisible()
        presenter.present(navigationController, animated: false, completion: nil)

        // sut
        waitSync()
        viewController.doneButton.fire()

        // test
        waitSync()
        XCTAssertNil(presenter.presentedViewController)
    }

    // MARK: - other

    func testErrorAlertShows() {
        // mocks
        env.isLoaded = false
        env.inject()
        env.addToWindow()
        env.archiveController.setViewController(viewController)
        env.archiveController.setAlertController(alertController)

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }
}

// MARK: - ArchiveViewController

private extension ArchiveViewController {
    func sections() -> Int {
        return tableView.numberOfSections
    }

    func rows(section: Int) -> Int {
        return tableView(tableView, numberOfRowsInSection: section)
    }

    func cell(row: Int, section: Int) -> ArchiveCell? {
        let indexPath = IndexPath(row: row, section: section)
        return tableView.cellForRow(at: indexPath) as? ArchiveCell
    }

    func title(row: Int, section: Int) -> String? {
        return cell(row: row, section: section)?.titleLabel.text
    }

    func actions(row: Int, section: Int) -> [UITableViewRowAction]? {
        let indexPath = IndexPath(row: row, section: section)
        return tableView(tableView, editActionsForRowAt: indexPath)
    }
}

// MARK: - UITableViewRowAction

private extension UITableViewRowAction {
    var isUndo: Bool { return title == "Undo" && backgroundColor == Asset.Colors.grey.color }
}
