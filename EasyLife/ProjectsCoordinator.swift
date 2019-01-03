import UIKit

protocol ProjectsCoordinating: Mockable {
    func setNavigationController(_ navigationController: UINavigationController)
    func setViewController(_ viewController: ProjectsViewControlling)
    func setAlertController(_ alertController: AlertControlling)
}

final class ProjectsCoordinator: NSObject, ProjectsCoordinating {
    private let projectsController: ProjectsControlling
    private var navigationController: UINavigationController?

    init(projectsController: ProjectsControlling) {
        self.projectsController = projectsController
        super.init()
        projectsController.setDelegate(self)
    }

    func setNavigationController(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.delegate = self
    }

    func setViewController(_ viewController: ProjectsViewControlling) {
        projectsController.setViewController(viewController)
    }

    func setAlertController(_ alertController: AlertControlling) {
        projectsController.setAlertController(alertController)
    }
}

// MARK: - ProjectsControllerDelegate

extension ProjectsCoordinator: ProjectsControllerDelegate {
    func controllerFinished(_ controller: ProjectsController) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UINavigationControllerDelegate

extension ProjectsCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        // 🦄
    }
}
