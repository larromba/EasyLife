import UIKit

protocol PlanCoordinating {
    func start()
}

final class PlanCoordinator: NSObject, PlanCoordinating {
    private let planController: PlanControlling
    private let itemDetailController: ItemDetailControlling
    private let blockedController: BlockedControlling
    private let navigationController: UINavigationController
    private var itemDetailContext: Context<TodoItem>?

    init(navigationController: UINavigationController, planController: PlanControlling,
         itemDetailController: ItemDetailControlling, blockedController: BlockedControlling) {
        self.navigationController = navigationController
        self.planController = planController
        self.itemDetailController = itemDetailController
        self.blockedController = blockedController
        super.init()
        navigationController.delegate = self
        planController.setDelegate(self)
        itemDetailController.setDelegate(self)
    }

    func start() {
        planController.start()
    }

    // MARK: - private

    private func clearContexts() {
        itemDetailContext = nil
    }
}

// MARK: - PlanControllerDelegate

extension PlanCoordinator: PlanControllerDelegate {
    func controller(_ controller: PlanController, didSelectItem item: TodoItem, sender: Segueable) {
        itemDetailContext = Context(object: item)
        sender.performSegue(withIdentifier: "openEventDetailViewController", sender: self)
    }
}

// MARK: - ItemDetailControllerDelegate

extension PlanCoordinator: ItemDetailControllerDelegate {
    func controllerFinished(_ controller: ItemDetailController) {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - UINavigationControllerDelegate

extension PlanCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        if let viewController = viewController as? ItemDetailViewControlling {
            guard let itemDetailContext = itemDetailContext else {
                assertionFailure("unexpected state")
                return
            }
            itemDetailController.setViewController(viewController)
            itemDetailController.setItem(itemDetailContext.object)
        } else if let viewController = viewController as? BlockedViewControlling {
            blockedController.setViewController(viewController)
        }
        clearContexts()
    }
}
