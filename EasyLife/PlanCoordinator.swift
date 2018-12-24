import UIKit

protocol PlanCoordinating {
    // 🦄
}

final class PlanCoordinator: NSObject, PlanCoordinating {
    private let planController: PlanController
    private let archiveController: ArchiveController
    private let navigationController: UINavigationController
    private var item: TodoItem?
    private weak var blockedViewController: BlockedViewController? // TODO: this?

    init(navigationController: UINavigationController, planController: PlanController,
         archiveController: ArchiveController) {
        self.navigationController = navigationController
        self.planController = planController
        self.archiveController = archiveController
        super.init()
        navigationController.delegate = self
        planController.setDelegate(self)
    }
}

// MARK: - PlanControllerDelegate

extension PlanCoordinator: PlanControllerDelegate {
    func controller(_ controller: PlanController, openItemDetailWithItem item: TodoItem, sender: UIViewController) {
        self.item = item
        sender.performSegue(withIdentifier: "openEventDetailViewController", sender: self)
    }
}

// MARK: - UINavigationControllerDelegate

extension PlanCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        if let viewController = viewController as? ItemDetailViewController {
            //viewController.dataSource.item = item // TODO: this
        } else if let viewController = viewController as? ArchiveViewControlling {
            archiveController.setViewController(viewController)
            archiveController.setAlertController(AlertController(presenter: viewController))
        }
    }
}
