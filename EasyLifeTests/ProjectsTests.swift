import AsyncAwait
@testable import EasyLife
import TestExtensions
import XCTest
import UIKit

final class ProjectsTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: ProjectsViewController!
    private var alertController: AlertController!
    private var env: AppTestEnvironment!

    override func setUp() {
        super.setUp()
        navigationController = UIStoryboard.project.instantiateInitialViewController() as? UINavigationController
        viewController = navigationController.viewControllers.first as? ProjectsViewController
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

    // MARK: - ui

    func testNoDataHidesTableView() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)

        // test
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    func testDataShowsTableView() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertFalse(viewController.tableView.isHidden)
    }

    func testDataShowsInCorrectSections() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        _ = env.project(priority: -1)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.prioritized), 1)
        XCTAssertEqual(viewController.rows(.other), 1)
    }

    func testBadgeShowsInPrioritySection() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertFalse(viewController.cell(row: 0, section: .prioritized)?.tagView.cornerLayerView.isHidden ?? true)
    }

    func testTextColorInPrioritySection() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.cell(row: 0, section: .prioritized)?.titleLabel.textColor, .black)
    }

    func testBadgeHidesInOtherSection() {
        // mocks
        env.inject()
        _ = env.project(priority: -1)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertTrue(viewController.cell(row: 0, section: .other)?.tagView.cornerLayerView.isHidden ?? false)
    }

    func testTextColorInOtherSection() {
        // mocks
        env.inject()
        _ = env.project(priority: -1)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.cell(row: 0, section: .other)?.titleLabel.textColor, Asset.Colors.grey.color)
    }

    // MARK: - add project

    func testAddProjectShowsNewProjectAlert() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func testNewProjectAlertWhenNoTextEnteredThenCantPressOK() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        XCTAssertFalse(alert.actions[safe: 1]?.isEnabled ?? true)
    }

    func testNewProjectAlertWhenTextEnteredThenCanPressOK() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.text = "test"
        alert.textFields?[safe: 0]?.sendActions(for: .editingChanged)
        XCTAssertTrue(alert.actions[safe: 1]?.isEnabled ?? false)
    }

    func testNewProjectWhenOkButtonPressedNewProjectIsCreated() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()
        XCTAssertTrue(viewController.addButton.fire())
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.text = "test"
        alert.textFields?[safe: 0]?.sendActions(for: .editingChanged)

        // sut
        XCTAssertTrue(alert.actions[safe: 1]?.fire() ?? false)

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let items = try await(self.env.dataManager.fetch(entityClass: Project.self, sortBy: nil,
                                                                 context: .main, predicate: nil))
                XCTAssertEqual(items.count, 1)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
            })
        }
    }

    // MARK: - edit project

    func testEditProjectShowsNewProjectAlert() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()

        // sut
        waitSync()
        viewController.tapCell(row: 0, section: .prioritized)

        // test
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func testEditProjectAlertWhenNoTextEnteredThenCantPressOK() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()

        // sut
        waitSync()
        viewController.tapCell(row: 0, section: .prioritized)

        // test
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        XCTAssertFalse(alert.actions[safe: 1]?.isEnabled ?? true)
    }

    func testEditProjectAlertWhenTextEnteredThenCanPressOK() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()

        // sut
        waitSync()
        viewController.tapCell(row: 0, section: .prioritized)

        // test
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.text = "test"
        alert.textFields?[safe: 0]?.sendActions(for: .editingChanged)
        XCTAssertTrue(alert.actions[safe: 1]?.isEnabled ?? false)
    }

    func testEditProjectWhenOkButtonPressedProjectIsUpdated() {
        // mocks
        env.inject()
        let project = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)
        env.addToWindow()
        waitSync()
        viewController.tapCell(row: 0, section: .prioritized)
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.text = "test"
        alert.textFields?[safe: 0]?.sendActions(for: .editingChanged)

        // sut
        XCTAssertTrue(alert.actions[safe: 1]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertEqual(project.name, "test")
    }

    // MARK: - actions

    func testCellPrioritizedActions() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .prioritized) else {
            XCTFail("expected actions")
            return
        }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions[safe: 0]?.isDelete ?? false)
        XCTAssertTrue(actions[safe: 1]?.isDeprioritize ?? false)
    }

    func testCellOtherActions() {
        // mocks
        env.inject()
        _ = env.project(priority: -1)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .other) else {
            XCTFail("expected actions")
            return
        }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions[safe: 0]?.isDelete ?? false)
        XCTAssertTrue(actions[safe: 1]?.isPrioritize ?? false)
    }

    func testCellOtherActionsMaxPriority() {
        // mocks
        env.inject()
        _ = env.project(priority: -1)
        _ = env.project(priority: 0)
        _ = env.project(priority: 1)
        _ = env.project(priority: 2)
        _ = env.project(priority: 3)
        _ = env.project(priority: 4)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        guard let actions = viewController.actions(row: 0, section: .other) else {
            XCTFail("expected actions")
            return
        }
        XCTAssertEqual(actions.count, 1)
        XCTAssertTrue(actions[safe: 0]?.isDelete ?? false)
    }

    func testPrioritizeActionPrioritizesProject() {
        // mocks
        env.inject()
        let project = env.project(priority: -1)
        env.projectsController.setViewController(viewController)
        waitSync()
        guard let action = viewController.actions(row: 0, section: .other)?[safe: 1] else {
            XCTFail("expected action")
            return
        }

        // precondition
        XCTAssertEqual(viewController.rows(.other), 1)
        XCTAssertEqual(viewController.rows(.prioritized), 0)

        // sut
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.other), 0)
        XCTAssertEqual(viewController.rows(.prioritized), 1)
        XCTAssertEqual(project.priority, 0)
    }

    func testDeprioritizeActionDeprioritizesProject() {
        // mocks
        env.inject()
        let project = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        waitSync()
        guard let action = viewController.actions(row: 0, section: .prioritized)?[safe: 1] else {
            XCTFail("expected action")
            return
        }

        // precondition
        XCTAssertEqual(viewController.rows(.other), 0)
        XCTAssertEqual(viewController.rows(.prioritized), 1)

        // sut
        XCTAssertTrue(action.fire())

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.other), 1)
        XCTAssertEqual(viewController.rows(.prioritized), 0)
        XCTAssertEqual(project.priority, -1)
    }

    func testDeleteActionDeletesProject() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        waitSync()
        guard let action = viewController.actions(row: 0, section: .prioritized)?[safe: 0] else {
            XCTFail("expected action")
            return
        }

        // sut
        XCTAssertTrue(action.fire())

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let items = try await(self.env.dataManager.fetch(entityClass: Project.self, sortBy: nil,
                                                                 context: .main, predicate: nil))
                XCTAssertEqual(items.count, 0)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
            })
        }
    }

    // MARK: - move cell

    func testMoveCellToPrioritySectionPrioritizesProjectToNextAvailablePriority() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        let project = env.project(priority: -1)
        env.projectsController.setViewController(viewController)
        waitSync()

        // precondition
        XCTAssertEqual(viewController.rows(.other), 1)
        XCTAssertEqual(viewController.rows(.prioritized), 1)

        // sut
        viewController.move(from: 0, fromSection: .other, to: 0, toSection: .prioritized)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.other), 0)
        XCTAssertEqual(viewController.rows(.prioritized), 2)
        XCTAssertEqual(project.priority, 1)
    }

    func testMoveCellToOtherSectionDeprioritizesProject() {
        // mocks
        env.inject()
        let project = env.project(priority: 0)
        _ = env.project(priority: -1)
        env.projectsController.setViewController(viewController)
        waitSync()

        // precondition
        XCTAssertEqual(viewController.rows(.other), 1)
        XCTAssertEqual(viewController.rows(.prioritized), 1)

        // sut
        viewController.move(from: 0, fromSection: .prioritized, to: 0, toSection: .other)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.other), 2)
        XCTAssertEqual(viewController.rows(.prioritized), 0)
        XCTAssertEqual(project.priority, -1)
    }

    func testMoveCellPrioritizesLesser() {
        // mocks
        env.inject()
        let project0 = env.project(priority: 0)
        let project1 = env.project(priority: 1)
        let project2 = env.project(priority: 2)
        env.projectsController.setViewController(viewController)
        waitSync()

        // sut
        viewController.move(from: 1, fromSection: .prioritized, to: 0, toSection: .prioritized)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.prioritized), 3)
        XCTAssertEqual(project0.priority, 1)
        XCTAssertEqual(project1.priority, 0)
        XCTAssertEqual(project2.priority, 2)
    }

    func testMoveCellPrioritizesGreater() {
        // mocks
        env.inject()
        let project0 = env.project(priority: 0)
        let project1 = env.project(priority: 1)
        let project2 = env.project(priority: 2)
        env.projectsController.setViewController(viewController)
        waitSync()

        // sut
        viewController.move(from: 0, fromSection: .prioritized, to: 1, toSection: .prioritized)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.prioritized), 3)
        XCTAssertEqual(project0.priority, 1)
        XCTAssertEqual(project1.priority, 0)
        XCTAssertEqual(project2.priority, 2)
    }

    func testCantMoveCellToPrioritySectionIfPriorityAtMax() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        _ = env.project(priority: 1)
        _ = env.project(priority: 2)
        _ = env.project(priority: 3)
        _ = env.project(priority: 4)
        _ = env.project(priority: -1)
        env.projectsController.setViewController(viewController)
        waitSync()

        // test
        XCTAssertFalse(viewController.canMove(row: 0, section: .other))
    }

    // MARK: - other

    func testEditButtonTogglesEditingMode() {
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        waitSync()

        // precondition
        XCTAssertFalse(viewController.tableView.isEditing)

        // sut
        XCTAssertTrue(viewController.editButton.fire())
        // test
        XCTAssertTrue(viewController.tableView.isEditing)

        // sut
        XCTAssertTrue(viewController.editButton.fire())
        // test
        XCTAssertFalse(viewController.tableView.isEditing)
    }

    func testDoneCloses() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setNavigationController(navigationController)
        let presenter = UIViewController()
        env.window.rootViewController = presenter
        env.window.makeKeyAndVisible()
        presenter.present(navigationController, animated: false, completion: nil)

        // sut
        viewController.doneButton.fire()

        // test
        waitSync()
        XCTAssertNil(presenter.presentedViewController)
    }

    func testErrorAlertShows() {
        // mocks
        env.isLoaded = false
        env.inject()
        env.addToWindow()
        env.projectsController.setViewController(viewController)
        env.projectsController.setAlertController(alertController)

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }
}

// MARK: - ProjectsViewController

private extension ProjectsViewController {
    func tapCell(row: Int, section: ProjectSection) {
        tableView(tableView, didSelectRowAt: IndexPath(row: row, section: section.rawValue))
    }

    func rows(_ section: ProjectSection) -> Int {
        return tableView.numberOfRows(inSection: section.rawValue)
    }

    func cell(row: Int, section: ProjectSection) -> ProjectCell? {
        let indexPath = IndexPath(row: row, section: section.rawValue)
        return tableView.cellForRow(at: indexPath) as? ProjectCell
    }

    func actions(row: Int, section: ProjectSection) -> [UITableViewRowAction]? {
        let indexPath = IndexPath(row: row, section: section.rawValue)
        return tableView(tableView, editActionsForRowAt: indexPath)
    }

    func move(from: Int, fromSection: ProjectSection, to: Int, toSection: ProjectSection) {
        let fromIndexPath = IndexPath(row: from, section: fromSection.rawValue)
        let toIndexPath = IndexPath(row: to, section: toSection.rawValue)
        tableView(tableView, moveRowAt: fromIndexPath, to: toIndexPath)
    }

    func canMove(row: Int, section: ProjectSection) -> Bool {
        let indexPath = IndexPath(row: row, section: section.rawValue)
        return tableView(tableView, canMoveRowAt: indexPath)
    }
}

// MARK: - UITableViewRowAction

private extension UITableViewRowAction {
    var isDeprioritize: Bool { return title == "Deprioritize" && backgroundColor == Asset.Colors.grey.color }
    var isPrioritize: Bool { return title == "Prioritize" && backgroundColor == Asset.Colors.green.color }
    var isDelete: Bool { return title == "Delete" && backgroundColor == Asset.Colors.red.color }
}
