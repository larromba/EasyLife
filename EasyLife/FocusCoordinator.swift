import UIKit

// sourcery: name = FocusCoordinator
protocol FocusCoordinating: Mockable {
    func setNavigationController(_ navigationController: UINavigationController)
    func setViewController(_ viewController: FocusViewControlling)
    func setAlertController(_ alertController: AlertControlling)
}

final class FocusCoordinator: NSObject, FocusCoordinating {
    private let focusController: FocusControlling
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
        focusController.setAlertController(alertController)
    }
}

// MARK: - FocusCoordinatorDelegate

extension FocusCoordinator: FocusControllerDelegate {
    func controllerFinished(_ controller: FocusControlling) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UINavigationControllerDelegate

extension FocusCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        // 🦄
    }
}
