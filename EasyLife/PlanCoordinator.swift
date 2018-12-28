import UIKit

protocol PlanCoordinating {
    func start()
}

final class PlanCoordinator: NSObject, PlanCoordinating {
    private let planController: PlanControlling
    private let itemDetailController: ItemDetailControlling
    private let blockedController: BlockedControlling
    private let navigationController: UINavigationController
    private var context: ObjectContext<TodoItem>?
    private var lastNavigationStack = [UIViewController]()

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

    private func isMovingBack(for viewController: UIViewController) -> Bool {
        return navigationController.viewControllers.contains(viewController)
    }
}

// MARK: - PlanControllerDelegate

extension PlanCoordinator: PlanControllerDelegate {
    func controller(_ controller: PlanController, didSelectItem item: TodoItem, sender: Segueable) {
        context = ObjectContext(object: item)
        sender.performSegue(withIdentifier: "openItemDetailViewController", sender: self)
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
        defer { lastNavigationStack = navigationController.viewControllers }

        // if going back, ignore
        guard !lastNavigationStack.contains(viewController) else { return }

        // if first vc, reset the editing context
        guard !(viewController is PlanViewController) else {
            context = nil
            return
        }

        // if other vcs, pass through the context
        if let viewController = viewController as? ItemDetailViewControlling {
            itemDetailController.setViewController(viewController)
            itemDetailController.setAlertController(AlertController(presenter: viewController))
            if let item = context?.object {
                itemDetailController.setItem(item)
            }
        } else if let viewController = viewController as? BlockedViewControlling {
            blockedController.setViewController(viewController)
            blockedController.setAlertController(AlertController(presenter: viewController))
            if let item = context?.object {
                blockedController.setItem(item)
            }
        } else {
            assertionFailure("unhandled viewController: \(viewController.classForCoder)")
        }
    }
}
