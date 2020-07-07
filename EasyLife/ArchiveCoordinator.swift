import UIKit

// sourcery: name = ArchiveCoordinator
protocol ArchiveCoordinating: Mockable {
    func setNavigationController(_ navigationController: UINavigationController)
    func setViewController(_ viewController: ArchiveViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func resetNavigation()
    func start()
}

final class ArchiveCoordinator: NSObject, ArchiveCoordinating {
    private let archiveController: ArchiveControlling
    private var alertController: AlertControlling?
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
        self.alertController = alertController
    }

    func start() {
        archiveController.start()
    }

    func resetNavigation() {
        alertController = nil
        navigationController?.hardReset()
    }
}

// MARK: - ArchiveControllerDelegate

extension ArchiveCoordinator: ArchiveControllerDelegate {
    func controllerFinished(_ controller: ArchiveControlling) {
        alertController = nil
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func controller(_ controller: ArchiveControlling, showAlert alert: Alert) {
        alertController?.showAlert(alert)
    }
}

// MARK: - UINavigationControllerDelegate

extension ArchiveCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        // 🦄
    }
}
