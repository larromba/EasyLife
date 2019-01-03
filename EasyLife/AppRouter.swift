import UIKit

protocol AppRouting: StoryboardRouting, Mockable {
    func start()
}

final class AppRouter: AppRouting {
    private let planCoordinator: PlanCoordinating
    private let archiveCoordinator: ArchiveCoordinating
    private let projectsCoordinator: ProjectsCoordinating

    init(planCoordinator: PlanCoordinating, archiveCoordinator: ArchiveCoordinating,
         projectsCoordinator: ProjectsCoordinating) {
        self.planCoordinator = planCoordinator
        self.archiveCoordinator = archiveCoordinator
        self.projectsCoordinator = projectsCoordinator
    }

    func start() {
        planCoordinator.start()
    }

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
        }
    }
}
