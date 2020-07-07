import UIKit

// sourcery: name = FocusCoordinator
protocol FocusCoordinating: Mockable {
    func setNavigationController(_ navigationController: UINavigationController)
    func setViewController(_ viewController: FocusViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setTriggerDate(_ date: Date)
    func resetNavigation()
    func start()
}

final class FocusCoordinator: NSObject, FocusCoordinating {
    private let focusController: FocusControlling
    private var alertController: AlertControlling?
    private var navigationController: UINavigationController?

    init(focusController: FocusControlling) {
        self.focusController = focusController
        super.init()
        focusController.setDelegate(self)
    }

    func setNavigationController(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.delegate = self
    }

    func setViewController(_ viewController: FocusViewControlling) {
        focusController.setViewController(viewController)
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    func setTriggerDate(_ date: Date) {
        focusController.setTriggerDate(date)
    }

    func resetNavigation() {
        alertController = nil
        navigationController?.hardReset()
    }

    func start() {
        focusController.start()
    }
}

// MARK: - FocusCoordinatorDelegate

extension FocusCoordinator: FocusControllerDelegate {
    func controllerFinished(_ controller: FocusControlling) {
        alertController = nil
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func controller(_ controller: FocusControlling, showAlert alert: Alert) {
        alertController?.showAlert(alert)
    }
}

// MARK: - UINavigationControllerDelegate

extension FocusCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        // 🦄
    }
}
