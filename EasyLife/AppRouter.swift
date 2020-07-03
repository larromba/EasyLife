import UIKit

protocol AppRouting: StoryboardRouting, Mockable {
    func start()
    func routeToNewTodoItem()
}

final class AppRouter: AppRouting {
    private let planCoordinator: PlanCoordinating
    private let focusCoordinator: FocusCoordinating
    private let archiveCoordinator: ArchiveCoordinating
    private let projectsCoordinator: ProjectsCoordinating

    init(planCoordinator: PlanCoordinating, focusCoordinator: FocusCoordinating,
         archiveCoordinator: ArchiveCoordinating, projectsCoordinator: ProjectsCoordinating) {
        self.planCoordinator = planCoordinator
        self.focusCoordinator = focusCoordinator
        self.archiveCoordinator = archiveCoordinator
        self.projectsCoordinator = projectsCoordinator
    }

    func start() {
        planCoordinator.start()
    }

    func routeToNewTodoItem() {
        resetAllNavigation()
        planCoordinator.openNewTodoItem()
    }

    // MARK: - StoryboardRouting

    func handleSegue(_ segue: UIStoryboardSegue) {
        guard let navigationController = segue.destination as? UINavigationController else { return }
        if let viewController = navigationController.viewControllers.first as? ProjectsViewControlling {
            projectsCoordinator.setViewController(viewController)
            projectsCoordinator.setNavigationController(navigationController)
            projectsCoordinator.setAlertController(AlertController(presenter: viewController))
        } else if let viewController = navigationController.viewControllers.first as? ArchiveViewControlling {
            archiveCoordinator.setViewController(viewController)
            archiveCoordinator.setNavigationController(navigationController)
            archiveCoordinator.setAlertController(AlertController(presenter: viewController))
        } else if let viewController = navigationController.viewControllers.first as? FocusViewControlling {
            focusCoordinator.setViewController(viewController)
            focusCoordinator.setNavigationController(navigationController)
            focusCoordinator.setAlertController(AlertController(presenter: viewController))
        } else {
            assertionFailure("unhandled route for view controller")
        }
    }

    // MARK: - private

    private func resetAllNavigation() {
        planCoordinator.resetNavigation()
        focusCoordinator.resetNavigation()
        archiveCoordinator.resetNavigation()
        projectsCoordinator.resetNavigation()
    }
}
