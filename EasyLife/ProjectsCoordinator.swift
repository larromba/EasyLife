import AsyncAwait
import UIKit

// sourcery: name = ProjectsCoordinator
protocol ProjectsCoordinating: NavigationResettable, Mockable {
    func setNavigationController(_ navigationController: UINavigationController)
    func setViewController(_ viewController: ProjectsViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func start()
}

final class ProjectsCoordinator: NSObject, ProjectsCoordinating {
    private let projectsController: ProjectsControlling
    private var alertController: AlertControlling?
    private weak var navigationController: UINavigationController?

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
        self.alertController = alertController
    }

    func start() {
        projectsController.start()
    }

    func resetNavigation() {
        alertController = nil
        navigationController?.hardReset()
    }
}

// MARK: - ProjectsControllerDelegate

extension ProjectsCoordinator: ProjectsControllerDelegate {
    func controllerFinished(_ controller: ProjectsControlling) {
        alertController = nil
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func controller(_ controller: ProjectsControlling, showAlert alert: Alert) {
        alertController?.showAlert(alert)
    }

    func controller(_ controller: ProjectsControlling, setIsAlertButtonEnabled isEnabled: Bool, at index: Int) {
        alertController?.setIsButtonEnabled(isEnabled, at: index)
    }
}

// MARK: - UINavigationControllerDelegate

extension ProjectsCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        // 🦄
    }
}
