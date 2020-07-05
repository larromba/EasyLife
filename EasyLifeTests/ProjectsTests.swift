import AsyncAwait
@testable import EasyLife
import TestExtensions
import UIKit
import XCTest

// swiftlint:disable file_length type_body_length
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

    func test_tableView_whenNoData_expectIsHidden() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)

        // test
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    func test_tableView_whenHasData_expectIsShowing() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertFalse(viewController.tableView.isHidden)
    }

    func test_projects_whenAppear_expectShownInCorrectSections() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        _ = env.project(priority: Project.defaultPriority)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.prioritized), 1)
        XCTAssertEqual(viewController.rows(.other), 1)
    }

    func test_prioritizedProject_whenAppears_expectBadgeIsShowing() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertFalse(viewController.cell(row: 0, section: .prioritized)?.tagView.cornerLayerView.isHidden ?? true)
    }

    func test_prioritizedProject_whenAppears_expectTextColor() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.cell(row: 0, section: .prioritized)?.titleLabel.textColor, .black)
    }

    func test_deprioritizedProject_whenAppears_expectBadgeIsHidden() {
        // mocks
        env.inject()
        _ = env.project(priority: Project.defaultPriority)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertTrue(viewController.cell(row: 0, section: .other)?.tagView.cornerLayerView.isHidden ?? false)
    }

    func test_deprioritizedProject_whenAppears_expecTextColor() {
        // mocks
        env.inject()
        _ = env.project(priority: Project.defaultPriority)
        env.projectsController.setViewController(viewController)

        // test
        waitSync()
        XCTAssertEqual(viewController.cell(row: 0, section: .other)?.titleLabel.textColor, Asset.Colors.grey.color)
    }

    // MARK: - add project

    func test_addButton_whenPressed_expectAlert() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        waitSync()
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func test_newProjectAlert_whenNoTextEntered_expectOKButtonDisabled() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
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

    func test_newProjectAlert_whenTextEntered_expectOKButtonEnabled() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
        env.addToWindow()

        // sut
        XCTAssertTrue(viewController.addButton.fire())

        // test
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.setText("test")
        XCTAssertTrue(alert.actions[safe: 1]?.isEnabled ?? false)
    }

    func test_newProjectAlert_whenOkButtonPressed_expectNewProjectCreated() {
        // mocks
        env.inject()
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
        env.addToWindow()
        XCTAssertTrue(viewController.addButton.fire())
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.setText("test")

        // sut
        XCTAssertTrue(alert.actions[safe: 1]?.fire() ?? false)

        // test
        waitAsync(delay: 0.5) { completion in
            async({
                let context = self.env.dataContextProvider.mainContext()
                let items = try await(context.fetch(entityClass: Project.self, sortBy: nil, predicate: nil))
                XCTAssertEqual(items.count, 1)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    // MARK: - edit project

    func test_cell_whenTapped_expectShowsAlert() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
        env.addToWindow()

        // sut
        waitSync()
        viewController.tapCell(row: 0, section: .prioritized)

        // test
        XCTAssertTrue(viewController.presentedViewController is UIAlertController)
    }

    func test_editNameAlert_whenNoText_expectOkButtonDisabled() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
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

    func test_editNameAlert_whenHasText_expectOkButtonEnabled() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
        env.addToWindow()

        // sut
        waitSync()
        viewController.tapCell(row: 0, section: .prioritized)

        // test
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.setText("test")
        XCTAssertTrue(alert.actions[safe: 1]?.isEnabled ?? false)
    }

    func test_editNameAlert_whenOkButtonPressed_expectProjectIsUpdated() {
        // mocks
        env.inject()
        let project = env.project(priority: 0)
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)
        env.addToWindow()
        waitSync()
        viewController.tapCell(row: 0, section: .prioritized)
        guard let alert = viewController.presentedViewController as? UIAlertController else {
            XCTFail("expected alert")
            return
        }
        alert.textFields?[safe: 0]?.setText("test")

        // sut
        XCTAssertTrue(alert.actions[safe: 1]?.fire() ?? false)

        // test
        waitSync()
        XCTAssertEqual(project.name, "test")
    }

    // MARK: - actions

    func test_prioritizedItem_whenOpened_expectActions() {
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

    func test_deprioritizedItem_whenOpened_expectActions() {
        // mocks
        env.inject()
        _ = env.project(priority: Project.defaultPriority)
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

    func test_deprioritizedItem_whenMaxItemsPrioritized_expectActions() {
        // mocks
        env.inject()
        _ = env.project(priority: Project.defaultPriority)
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

    func test_prioritizeAction_whenPressed_expectPrioritizesProject() {
        // mocks
        env.inject()
        let project = env.project(priority: Project.defaultPriority)
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

    func test_deprioritizeAction_whenPressed_expectDeprioritizesProject() {
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
        XCTAssertEqual(project.priority, Project.defaultPriority)
    }

    func test_deleteAction_whenPressed_expectDeletesProject() {
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
                let context = self.env.dataContextProvider.mainContext()
                let items = try await(context.fetch(entityClass: Project.self, sortBy: nil, predicate: nil))
                XCTAssertEqual(items.count, 0)
                completion()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                completion()
            })
        }
    }

    // MARK: - move cell

    func test_item_whenMovedToPrioritySection_expectPrioritizesProjectToNextAvailablePriority() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        let project = env.project(priority: Project.defaultPriority)
        env.projectsController.setViewController(viewController)
        waitSync()

        // precondition
        XCTAssertEqual(viewController.rows(.other), 1)
        XCTAssertEqual(viewController.rows(.prioritized), 1)

        // sut
        viewController.move(fromRow: 0, fromSection: .other, toRow: 0, toSection: .prioritized)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.other), 0)
        XCTAssertEqual(viewController.rows(.prioritized), 2)
        XCTAssertEqual(project.priority, 1)
    }

    func test_item_whenMovedToOtherSection_expectDeprioritizesProject() {
        // mocks
        env.inject()
        let project = env.project(priority: 0)
        _ = env.project(priority: Project.defaultPriority)
        env.projectsController.setViewController(viewController)
        waitSync()

        // precondition
        XCTAssertEqual(viewController.rows(.other), 1)
        XCTAssertEqual(viewController.rows(.prioritized), 1)

        // sut
        viewController.move(fromRow: 0, fromSection: .prioritized, toRow: 0, toSection: .other)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.other), 2)
        XCTAssertEqual(viewController.rows(.prioritized), 0)
        XCTAssertEqual(project.priority, Project.defaultPriority)
    }

    func test_item_whenMovedUpInsidePrioritySection_expectBetterPriority() {
        // mocks
        env.inject()
        let project0 = env.project(priority: 0)
        let project1 = env.project(priority: 1)
        let project2 = env.project(priority: 2)
        env.projectsController.setViewController(viewController)
        waitSync()

        // sut
        viewController.move(fromRow: 1, fromSection: .prioritized, toRow: 0, toSection: .prioritized)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.prioritized), 3)
        XCTAssertEqual(project0.priority, 1)
        XCTAssertEqual(project1.priority, 0)
        XCTAssertEqual(project2.priority, 2)
    }

    func test_item_whenMovedDownInsidePrioritySection_expectWorsePriority() {
        // mocks
        env.inject()
        let project0 = env.project(priority: 0)
        let project1 = env.project(priority: 1)
        let project2 = env.project(priority: 2)
        env.projectsController.setViewController(viewController)
        waitSync()

        // sut
        viewController.move(fromRow: 0, fromSection: .prioritized, toRow: 1, toSection: .prioritized)

        // test
        waitSync()
        XCTAssertEqual(viewController.rows(.prioritized), 3)
        XCTAssertEqual(project0.priority, 1)
        XCTAssertEqual(project1.priority, 0)
        XCTAssertEqual(project2.priority, 2)
    }

    func test_deprioritizedItem_whenMaxItemsPrioritixed_expectCantBePrioritized() {
        // mocks
        env.inject()
        _ = env.project(priority: 0)
        _ = env.project(priority: 1)
        _ = env.project(priority: 2)
        _ = env.project(priority: 3)
        _ = env.project(priority: 4)
        _ = env.project(priority: Project.defaultPriority)
        env.projectsController.setViewController(viewController)
        waitSync()

        // test
        XCTAssertFalse(viewController.canMove(row: 0, section: .other))
    }

    // MARK: - other

    func test_editButton_whenPressed_expectEditingModeToggled() {
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

    func test_doneButton_whenPressed_expectClosesView() {
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

    func test_alert_whenDataError_expectThrown() {
        // mocks
        env.persistentContainer = .mock(fetchError: MockError.mock)
        env.inject()
        env.addToWindow()
        env.projectsController.setViewController(viewController)
        env.projectsCoordinator.setAlertController(alertController)

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

    func move(fromRow: Int, fromSection: ProjectSection, toRow: Int, toSection: ProjectSection) {
        let fromIndexPath = IndexPath(row: fromRow, section: fromSection.rawValue)
        let toIndexPath = IndexPath(row: toRow, section: toSection.rawValue)
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
