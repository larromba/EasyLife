import UIKit

protocol ArchiveCoordinating {
    func setNavigationController(_ navigationController: UINavigationController)
    func setViewController(_ viewController: ArchiveViewControlling)
    func setAlertController(_ alertController: AlertControlling)
}

final class ArchiveCoordinator: NSObject, ArchiveCoordinating {
    private let archiveController: ArchiveControlling
    private var navigationController: UINavigationController?

    init(archiveController: ArchiveControlling) {
        self.archiveController = archiveController
        super.init()
        archiveController.setDelegate(self)
    }

    func setNavigationController(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.delegate = self
    }

    func setViewController(_ viewController: ArchiveViewControlling) {
        archiveController.setViewController(viewController)
    }

    func setAlertController(_ alertController: AlertControlling) {
        archiveController.setAlertController(alertController)
    }
}

// MARK: - ArchiveControllerDelegate

extension ArchiveCoordinator: ArchiveControllerDelegate {
    func controllerFinished(_ controller: ArchiveController) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UINavigationControllerDelegate

extension ArchiveCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        // 🦄
    }
}
